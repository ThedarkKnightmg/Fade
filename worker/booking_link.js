/**
 * Fade — booking-link landing page (Cloudflare Worker, free tier).
 *
 * Makes a shared barber link REALLY resolve. Deploy this and every
 * `https://<your-worker>.workers.dev/b/<handle>` a barber shares opens a real
 * page: the barber's name + an "Open in Fade" button (deep link) and a copy of
 * the code. No database needed — the handle in the URL is the barber id.
 *
 * ── Deploy (one time) ──────────────────────────────────────────────────────
 *   1. npm i -g wrangler        (if you don't have it)
 *   2. wrangler login
 *   3. From this folder:  wrangler deploy worker/booking_link.js --name fade-link
 *      → gives you  https://fade-link.<your-subdomain>.workers.dev
 *   4. In the app, set  AppState.bookingLinkBase  to that host
 *      (e.g. 'fade-link.yourname.workers.dev') and rebuild. Done — every shared
 *      link now opens this page.
 *
 * The "Open in Fade" button uses the fade://b/<handle> deep link; if the app
 * isn't installed the page still shows the invite (and you can drop your Play
 * Store URL into APP_STORE_URL below to send them to install).
 */

const APP_STORE_URL = ''; // e.g. 'https://play.google.com/store/apps/details?id=...'

function esc(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));
}

function prettyName(handle) {
  const h = (handle || '').replace(/[^a-z0-9]/gi, '');
  if (!h) return 'your barber';
  return h.charAt(0).toUpperCase() + h.slice(1);
}

function page(handle) {
  const name = esc(prettyName(handle));
  const deep = `fade://b/${esc(handle)}`;
  const install = APP_STORE_URL
    ? `<a class="ghost" href="${esc(APP_STORE_URL)}">Don't have Fade? Install it</a>`
    : `<p class="muted">Open this in the Fade app to book.</p>`;
  return `<!doctype html><html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Book ${name} on Fade</title>
<style>
  :root { --accent:#2E8BFF; --deep:#1E6FE0; --ink:#1B2434; }
  * { box-sizing:border-box; margin:0; }
  body { font-family:-apple-system,Segoe UI,Roboto,system-ui,sans-serif;
    background:linear-gradient(160deg,#EEF1F6,#DCE6F7); color:var(--ink);
    min-height:100vh; display:flex; align-items:center; justify-content:center; padding:24px; }
  .card { background:#fff; border-radius:28px; padding:34px 26px; max-width:380px; width:100%;
    text-align:center; box-shadow:0 24px 60px -18px #12233a55; }
  .badge { width:74px; height:74px; border-radius:22px; margin:0 auto 18px;
    background:linear-gradient(135deg,#4FA3FF,var(--deep)); display:flex; align-items:center;
    justify-content:center; box-shadow:0 12px 26px -8px #2E8BFF88; }
  .badge svg { width:38px; height:38px; }
  h1 { font-size:24px; font-weight:800; letter-spacing:-.3px; }
  .sub { color:#5b6675; margin-top:8px; font-size:15px; line-height:1.45; }
  .btn { display:block; margin-top:22px; padding:16px; border-radius:999px; font-weight:800;
    font-size:16px; text-decoration:none; color:#fff; background:var(--accent);
    box-shadow:0 10px 22px -8px #2E8BFF99; }
  .btn:active { transform:translateY(1px); }
  .ghost { display:inline-block; margin-top:16px; color:var(--accent); font-weight:700;
    text-decoration:none; font-size:14px; }
  .muted { margin-top:16px; color:#8a94a6; font-size:13px; }
  .brand { margin-top:22px; color:#8a94a6; font-size:12px; letter-spacing:2px; font-weight:700; }
</style></head>
<body>
  <div class="card">
    <div class="badge">
      <svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"
        stroke-linecap="round" stroke-linejoin="round">
        <circle cx="6" cy="6" r="3"/><circle cx="6" cy="18" r="3"/>
        <line x1="20" y1="4" x2="8.12" y2="15.88"/><line x1="14.47" y1="14.48" x2="20" y2="20"/>
        <line x1="8.12" y1="8.12" x2="12" y2="12"/>
      </svg>
    </div>
    <h1>Book ${name}</h1>
    <p class="sub">${name} is taking bookings on Fade. Tap below to pick a time.</p>
    <a class="btn" href="${deep}">Open in Fade</a>
    ${install}
    <div class="brand">FADE ✂️</div>
  </div>
  <script>
    // If the app is installed, try to jump straight in.
    setTimeout(function(){ try { window.location.href = "${deep}"; } catch(e){} }, 400);
  </script>
</body></html>`;
}

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const m = url.pathname.match(/^\/b\/([^/?#]+)/i);
    const handle = m ? decodeURIComponent(m[1]) : '';
    return new Response(page(handle), {
      headers: { 'content-type': 'text/html; charset=utf-8' },
    });
  },
};
