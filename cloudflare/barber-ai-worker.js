// Barber - free AI hair-edit worker (Cloudflare Workers AI)
// Changes the hair on the user's photo and returns the edited image.
// Free on Cloudflare's Workers AI daily allowance.
//
// HOW IT STAYS RELIABLE (SD-1.5 on Workers AI is quirky):
//   * It randomly returns an ALL-BLACK image (~2KB) on some seeds. We detect
//     that by byte size (a real edit is 300KB+) and retry.
//   * The INPAINTING model (best for "hair only, keep face") is the flakiest,
//     so we try it a few times, then FALL BACK to img2img, which is reliable.
//   * width/height stay 768 (this model returns black at 1024).
//
// HOW TO UPDATE:
//   1. In the worker editor: click inside, press Ctrl+A, then Delete.
//   2. Paste THIS whole file.
//   3. Click "Deploy" (top-right). Saving alone does not publish it.
//   4. Keep the Workers AI binding (Settings > Bindings), variable name: AI

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

const MIN_OK_BYTES = 20000; // a black 768 PNG is ~2KB; a real edit is 300KB+.
const INPAINT_TRIES = 3; // face-preserving but flaky
const IMG2IMG_TRIES = 2; // reliable fallback

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: CORS });
    }
    if (request.method !== "POST") {
      return new Response("POST only", { status: 405, headers: CORS });
    }

    try {
      const body = await request.json();
      const image = body.image;
      const mask = body.mask;
      const prompt = body.prompt;
      const steps = body.steps;

      if (!image) {
        return json({ error: "No image provided" }, 400);
      }

      const imgArr = Array.from(
        Uint8Array.from(atob(image), function (c) {
          return c.charCodeAt(0);
        })
      );
      const maskArr = mask
        ? Array.from(
            Uint8Array.from(atob(mask), function (c) {
              return c.charCodeAt(0);
            })
          )
        : null;

      const finalPrompt =
        (prompt || "a new hairstyle") +
        ", on the same person, keep the exact same face and identity, " +
        "photorealistic portrait photo, natural detailed hair, soft studio " +
        "lighting, high quality, sharp focus";

      const negativePrompt =
        "disfigured, deformed face, mutated, distorted, asymmetric, " +
        "extra faces, extra eyes, bad anatomy, blurry, grainy, cartoon, " +
        "anime, painting, drawing, 3d render, plastic skin, lowres, " +
        "jpeg artifacts, text, watermark, signature, black image";

      const numSteps = typeof steps === "number" ? steps : 20;

      // Runs one model and returns the raw PNG bytes.
      async function gen(model, extra) {
        const params = {
          prompt: finalPrompt,
          negative_prompt: negativePrompt,
          image: imgArr,
          num_steps: numSteps,
          guidance: 8,
          width: 768,
          height: 768,
        };
        for (const k in extra) params[k] = extra[k];
        const result = await env.AI.run(model, params);
        return await new Response(result).arrayBuffer();
      }

      const ok = function (b) {
        return b && b.byteLength >= MIN_OK_BYTES;
      };

      let buf = null;

      // 1) Inpaint (changes ONLY the hair, keeps the face) at strength 0.75.
      //    Flaky -> try a few seeds before giving up on it.
      if (maskArr) {
        for (let i = 0; i < INPAINT_TRIES && !ok(buf); i++) {
          buf = await gen("@cf/runwayml/stable-diffusion-v1-5-inpainting", {
            mask: maskArr,
            strength: 0.75,
          });
        }
      }

      // 2) Fallback: img2img at 0.55 (reliable; redraws a bit more but never
      //    comes back blank). Guarantees the user gets a real image.
      for (let i = 0; i < IMG2IMG_TRIES && !ok(buf); i++) {
        buf = await gen("@cf/runwayml/stable-diffusion-v1-5-img2img", {
          strength: 0.55,
        });
      }

      if (!ok(buf)) {
        return json({ error: "The AI is busy right now. Please try again." }, 502);
      }
      return json({ image: toBase64(buf) });
    } catch (e) {
      return json({ error: String(e && e.message ? e.message : e) }, 500);
    }
  },
};

function json(obj, status) {
  return new Response(JSON.stringify(obj), {
    status: status || 200,
    headers: Object.assign({}, CORS, {
      "Content-Type": "application/json",
    }),
  });
}

function toBase64(buf) {
  const bytes = new Uint8Array(buf);
  let binary = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode.apply(null, bytes.subarray(i, i + chunk));
  }
  return btoa(binary);
}
