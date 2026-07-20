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

const COVER = (seed: string) =>
  `https://images.unsplash.com/${seed}?auto=format&fit=crop&w=800&q=70`;

const SHOPS = [
  {
    name: "The Sharp Edge",
    address: "Amir Temur Avenue, Tashkent",
    lat: 41.3111, lng: 69.2797, premium: true,
    tagline: "Premium cuts, classic soul",
    description: "A refined chair on Amir Temur — precision fades and a proper hot-towel finish.",
    cover: COVER("photo-1503951914875-452162b0f3f1"),
    hours: "Mon–Sat · 10:00–21:00",
    tags: ["Premium", "Fades", "Beard"],
    priceLevel: 3, featured: true,
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
    tagline: "Your neighbourhood barber since 2008",
    description: "Friendly, no-fuss cuts for the whole mahalla.",
    cover: COVER("photo-1585747860715-2ba37e788b70"),
    hours: "Every day · 09:00–20:00",
    tags: ["Family", "Kids"],
    priceLevel: 2, featured: false,
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
    tagline: "Skin fades done right",
    description: "Sharp skin fades, clean line-ups and a proper straight-razor shave.",
    cover: COVER("photo-1521490878406-4f74a34c9e2a"),
    hours: "Tue–Sun · 10:00–22:00",
    tags: ["Skin fade", "Shave"],
    priceLevel: 2, featured: false,
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
    // Clean any prior seed run. NOTE: barbershops.owner_id is ON DELETE SET
    // NULL, so deleting the seed user does NOT remove their shop — it just
    // orphans it. So delete the shops explicitly by name first (services
    // cascade), THEN the seed users (profiles + barbers cascade).
    for (const shop of SHOPS) {
      await admin.from("barbershops").delete().eq("name", shop.name);
    }
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
          tagline: shop.tagline,
          description: shop.description,
          cover_image_url: shop.cover,
          opening_hours: shop.hours,
          tags: shop.tags,
          price_level: shop.priceLevel,
          is_featured: shop.featured,
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
