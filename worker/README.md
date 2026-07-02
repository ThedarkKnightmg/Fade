# Fade — free AI hair worker

A tiny Cloudflare Worker that does the real photo-realistic hair render for the
Fade app, using **Cloudflare Workers AI** (Stable Diffusion 1.5 inpainting).

- **No Google API key. No billing.** Runs on Cloudflare's free Workers AI tier
  (currently 10,000 "neurons"/day free — plenty for personal use).
- The app already supports it: paste the worker URL into **AI Hair → Connect AI
  → "Free — AI worker URL"** and leave the Gemini field blank.

The worker repaints **only** the masked hair region the app sends (a 768×768
square + a hair mask), so the face, skin and background stay exactly as shot.

---

## Option A — Dashboard (no tools, ~5 min)

1. Create a free account at **https://dash.cloudflare.com** (no card needed).
2. **Workers & Pages → Create application → Create Worker.**
   Name it `barber-ai` → **Deploy** (this creates a hello-world worker).
3. Click **Edit code**, delete everything, paste the contents of
   [`worker.js`](worker.js), then **Deploy**.
4. Add the AI binding so `env.AI` works:
   **Worker → Settings → Bindings → Add → Workers AI**
   - Variable name: **`AI`** (exactly)
   - Save, then **Deploy** once more.
5. Copy the worker URL at the top — it looks like:
   `https://barber-ai.<your-subdomain>.workers.dev`
6. In the **Fade app**: AI Hair → **Connect AI** → paste that URL into
   **"Free — AI worker URL"** → **Save**. Take a selfie → it now renders for real.

## Option B — Command line (wrangler)

```bash
cd worker
npm i -g wrangler
wrangler login
wrangler deploy
```

`wrangler.toml` already declares the `AI` binding, so the deploy is one command.
The URL is printed at the end — paste it into the app as in step 6 above.

---

## Test it without the app

```bash
# returns {"image":"<base64 png>"} on success
curl -X POST https://barber-ai.<your-subdomain>.workers.dev \
  -H "Content-Type: application/json" \
  -d '{"image":"<base64 of a 768x768 jpg/png>","prompt":"a realistic short textured crop, natural hair"}'
```

## Notes

- **Keep the image 768×768.** The app already does this. At 1024 the model
  returns an all-black image.
- The worker is keyless (anyone with the URL can call it). For personal use
  that's fine; if you want to lock it down later, check a shared secret in the
  `Authorization` header (the app sends one when you fill the Gemini key field,
  but you can add any header check you like).
- Model: `@cf/runwayml/stable-diffusion-v1-5-inpainting`. Swappable for a newer
  Workers AI image model by changing `MODEL` in `worker.js`.
