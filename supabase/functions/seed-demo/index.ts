// One-off demo seeder — creates a few REAL barbershops (with barbers + services)
// in the live tables so the real-catalogue read path has something to show.
// These are clearly demo rows (emails under @seed.fade.uz) you can delete once
// real shops onboard. Service role, so it can create the barber auth users the
// barbers table's profile_id FK requires.
//
// Run ONCE:  supabase functions deploy seed-demo   (then invoke, then delete)
// Safe to re-run: it clears prior @seed.fade.uz data first.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const SHOPS = [
  {
    name: "The Sharp Edge",
    address: "Amir Temur Avenue, Tashkent",
    lat: 41.3111, lng: 69.2797, premium: true,
    barber: { name: "Davron", email: "davron@seed.fade.uz", bio: "Fades & classic cuts", rating: 4.9 },
    services: [
      { name: "Haircut", price: 90000, min: 45 },
      { name: "Beard trim", price: 45000, min: 20 },
      { name: "Haircut + beard", price: 120000, min: 60 },
    ],
  },
  {
    name: "Northside Barbers",
    address: "Yunusobod district, Tashkent",
    lat: 41.3640, lng: 69.2894, premium: false,
    barber: { name: "Sardor", email: "sardor@seed.fade.uz", bio: "Neighbourhood barber since 2008", rating: 4.7 },
    services: [
      { name: "Haircut", price: 60000, min: 40 },
      { name: "Kids cut", price: 40000, min: 30 },
    ],
  },
  {
    name: "Chilanzar Cuts",
    address: "Chilonzor, Tashkent",
    lat: 41.2755, lng: 69.2035, premium: false,
    barber: { name: "Jasur", email: "jasur@seed.fade.uz", bio: "Skin fades a speciality", rating: 4.8 },
    services: [
      { name: "Skin fade", price: 75000, min: 45 },
      { name: "Line up", price: 35000, min: 15 },
      { name: "Hot towel shave", price: 55000, min: 30 },
    ],
  },
];

const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { "Content-Type": "application/json" } });

Deno.serve(async () => {
  try {
    // Clean any prior seed run: delete the @seed.fade.uz auth users (their
    // profiles + owned shops + barbers cascade away).
    const { data: list } = await admin.auth.admin.listUsers();
    for (const u of list.users) {
      if (u.email?.endsWith("@seed.fade.uz")) {
        await admin.auth.admin.deleteUser(u.id);
      }
    }

    const created: string[] = [];
    for (const shop of SHOPS) {
      // The barber needs a real profile → a real auth user.
      const { data: made, error: uErr } = await admin.auth.admin.createUser({
        email: shop.barber.email,
        email_confirm: true,
        user_metadata: { full_name: shop.barber.name },
      });
      if (uErr || !made.user) {
        console.error("seed user:", uErr);
        continue;
      }
      const profileId = made.user.id;

      const { data: shopRow, error: sErr } = await admin
        .from("barbershops")
        .insert({
          owner_id: profileId,
          name: shop.name,
          address: shop.address,
          lat: shop.lat,
          lng: shop.lng,
          is_premium: shop.premium,
        })
        .select("id")
        .single();
      if (sErr || !shopRow) {
        console.error("seed shop:", sErr);
        continue;
      }
      const shopId = shopRow.id;

      await admin.from("barbers").insert({
        profile_id: profileId,
        shop_id: shopId,
        display_name: shop.barber.name,
        bio: shop.barber.bio,
        rating: shop.barber.rating,
        is_active: true,
      });
      await admin.from("services").insert(
        shop.services.map((sv) => ({
          shop_id: shopId,
          name: sv.name,
          price: sv.price,
          duration_min: sv.min,
        })),
      );
      created.push(shop.name);
    }

    return json({ ok: true, seeded: created });
  } catch (e) {
    console.error("seed-demo:", e);
    return json({ error: String(e) }, 500);
  }
});
