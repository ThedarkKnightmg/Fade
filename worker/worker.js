// Fade — free AI hair worker (Cloudflare Workers AI)
// ---------------------------------------------------
// Repaints ONLY the masked hair region of a selfie with Stable Diffusion 1.5
// inpainting, running on Cloudflare's FREE Workers AI tier — no Google key,
// no billing.
//
// The contract matches the Fade app (lib/core/ai/hair_ai_service.dart):
//   Request  (POST, JSON): { image: <base64 png>, mask: <base64 png>,
//                            hairstyle: <str>, color: <str>, prompt: <str> }
//   Response (JSON):       { image: <base64 png> }
//
// IMPORTANT: the app sends a 768x768 square. Keep it 768 — at 1024 this model
// returns an all-black image.

const MODEL = "@cf/runwayml/stable-diffusion-v1-5-inpainting";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

// base64 string -> Uint8Array of the file's bytes.
function b64ToBytes(b64) {
  const clean = b64.includes("base64,") ? b64.split("base64,")[1] : b64;
  const bin = atob(clean);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

// Uint8Array -> base64 string (chunked so large images don't blow the stack).
function bytesToB64(bytes) {
  let bin = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    bin += String.fromCharCode.apply(null, bytes.subarray(i, i + chunk));
  }
  return btoa(bin);
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: CORS });
    }
    if (request.method !== "POST") {
      return Response.json(
        { error: "POST only" },
        { status: 405, headers: CORS }
      );
    }

    try {
      const body = await request.json();
      if (!body || !body.image) {
        return Response.json(
          { error: "missing image" },
          { status: 400, headers: CORS }
        );
      }

      const prompt =
        (body.prompt && String(body.prompt)) ||
        `a realistic ${body.color || ""} ${
          body.hairstyle || "haircut"
        }, natural hair texture`;

      const inputs = {
        prompt,
        // Source photo bytes (768x768 square sent by the app).
        image: [...b64ToBytes(body.image)],
        num_steps: 20, // Workers AI max
        strength: 1, // fully repaint inside the mask
        guidance: 7.5,
        negative_prompt:
          "different face, distorted face, two heads, extra head, blurry, " +
          "deformed, disfigured, lowres, watermark, text, hat",
      };
      // The model REQUIRES the mask under `mask_image`. White = repaint (the
      // hair), black = keep (face + background are copied through untouched).
      if (!body.mask) {
        return Response.json(
          { error: "missing mask" },
          { status: 400, headers: CORS }
        );
      }
      inputs.mask_image = [...b64ToBytes(body.mask)];

      const result = await env.AI.run(MODEL, inputs);

      // Image models return a binary PNG stream — turn it into base64.
      const buf = new Uint8Array(await new Response(result).arrayBuffer());
      return Response.json({ image: bytesToB64(buf) }, { headers: CORS });
    } catch (err) {
      return Response.json(
        { error: String((err && err.message) || err) },
        { status: 500, headers: CORS }
      );
    }
  },
};
