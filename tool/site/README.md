# Website generators

The public site (fade.uz / thedarkknightmg.github.io/Fade) lives on the
`gh-pages` branch. These scripts write it:

- `make_site.py ROOT OUT` — privacy / terms / delete-account pages from `assets/legal/legal.json`
- `make_links.py OUT ICON` — landing pages for shared links (`/i/`, `/b/`, `/join/`) + `404.html` router
- `make_home.py OUT` — homepage (`index.html`), `barbers.html`, `site.css`, `site.js`

`make_home.py` expects images in `OUT/assets/` (web-sized app screenshots
`{uz,ru}_{home,shop,map,barber,schedule,requests}.webp`, stickers from
`assets/tiles/`, `icon.png`, `og-home.jpg`). Run `make_site.py` before
`make_home.py`; both write `index.html` and the homepage must win.
