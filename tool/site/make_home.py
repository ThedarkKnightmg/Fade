"""Fade marketing site v2: index.html (clients) + barbers.html, sharing site.css/site.js.
Motion: GSAP + ScrollTrigger (cdnjs). Every visible string is written three times
(uz/ru/en) as sibling spans; CSS shows one. Content stays readable with no JS."""
import io, sys

OUT = sys.argv[1]
PLAY = "https://play.google.com/store/apps/details?id=uz.fade.app"
EMAIL = "fade.privacy.uz@gmail.com"
GSAP = "https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5"


def T(uz, ru, en, tag="span"):
    return "".join(f'<{tag} data-l="{c}">{s}</{tag}>' for c, s in (("uz", uz), ("ru", ru), ("en", en)))


def shot(name, alt, eager=False):
    load = "eager" if eager else "lazy"
    return "".join(
        f'<img data-l="{c}" src="assets/{f}_{name}.webp" alt="{alt}" width="540" height="960" loading="{load}" decoding="async">'
        for c, f in (("uz", "uz"), ("ru", "ru"), ("en", "uz")))


SCISSORS = '''<svg class="scissors-svg" viewBox="0 0 72 44" aria-hidden="true">
<g class="bl-a"><path d="M33 22 L70 13 L68.5 18.5 Z"/><circle cx="14" cy="11" r="8.5" fill="none" stroke-width="4.5"/><path d="M21 15.5 L33 22" stroke-width="5" stroke-linecap="round"/></g>
<g class="bl-b"><path d="M33 22 L70 31 L68.5 25.5 Z"/><circle cx="14" cy="33" r="8.5" fill="none" stroke-width="4.5"/><path d="M21 28.5 L33 22" stroke-width="5" stroke-linecap="round"/></g>
<circle cx="33" cy="22" r="2.6" class="pivot"/></svg>'''

PLAY_ICON = ('<svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true"><path fill="currentColor" '
             'd="M3.6 2.2c-.3.3-.4.7-.4 1.2v17.2c0 .5.1.9.4 1.2l9.7-9.8-9.7-9.8Zm10.6 10.7 2.7 2.7-11 6.3c-.4.2-.8.3-1.1.2'
             'l9.4-9.2Zm0-1.8L4.8 1.9c.3-.1.7 0 1.1.2l11 6.3-2.7 2.7Zm4.3-2.1 3 1.7c.9.5.9 1.8 0 2.3l-3 1.7-3-3 3-2.7Z"/></svg>')


def play_btn(extra=""):
    return (f'<a class="btn btn-play mag {extra}" href="{PLAY}" rel="noopener">{PLAY_ICON}<span class="btn-stack">'
            f'<small>{T("Yuklab oling", "Скачайте в", "Get it on")}</small><b>Google Play</b></span></a>')


CLIPPER = ('<svg viewBox="0 0 120 48" aria-hidden="true">'
           '<rect class="cl-body" x="0" y="8" width="80" height="32" rx="16"/>'
           '<rect class="cl-stripe" x="14" y="20" width="30" height="8" rx="4"/><circle class="cl-dot" cx="58" cy="24" r="4"/>'
           '<rect class="cl-neck" x="76" y="11" width="13" height="26" rx="4"/>'
           '<rect class="cl-blade" x="87" y="5" width="14" height="38" rx="3"/><g class="cl-blade">'
           + "".join('<rect x="100" y="%.1f" width="10" height="2.6" rx="1.3"/>' % (6.5 + i * 4.6) for i in range(8))
           + '</g></svg>')

TICK = '<svg class="tick" viewBox="0 0 20 20" aria-hidden="true"><circle cx="10" cy="10" r="9"/><path d="M5.5 10.5l3 3 6-6.5"/></svg>'


def hair_bits():
    return ('<canvas class="hair" aria-hidden="true"></canvas>'
            f'<div class="trim-hint" aria-hidden="true"><span>{T("Sochimni oling ✂", "Подстриги меня ✂", "Trim me ✂")}</span></div>'
            f'<div class="fresh" aria-hidden="true">{T("Toza fade ✓", "Свежий фейд ✓", "Fresh fade ✓")}</div>')


def booth():
    days = [T("Bugun", "Сегодня", "Today"), T("Ertaga", "Завтра", "Tomorrow"), T("Indinga", "Послезавтра", "In 2 days")]
    times = ["09:30", "10:15", "11:00", "12:30", "14:00", "15:30", "17:00", "18:30"]
    d = "".join(f'<button type="button"{" class=on" if i == 1 else ""}>{x}</button>' for i, x in enumerate(days))
    t = "".join(f'<button type="button">{x}</button>' for x in times)
    return f"""
<div class="booth" data-demo="book">
  <span class="demo-tag">Demo</span>
  <div class="booth-head"><img src="assets/face.webp" alt="" width="54" height="54" loading="lazy">
    <div><b>{T("Soch + soqol", "Стрижка + борода", "Cut + beard")}</b><span>{T("45 daqiqa", "45 минут", "45 minutes")}</span></div></div>
  <div class="days" data-on="1">{d}<i class="day-ink"></i></div>
  <div class="slots">{t}</div>
  <div class="printer">
    <div class="printer-slot"></div>
    <div class="paper">
      <p class="paper-hint">{T("Vaqtni bosing — chipta shu yerdan chiqadi", "Нажмите на время — отсюда выйдет талон", "Tap a time — your ticket prints here")}</p>
      <div class="pticket"><div class="ticket-top">{TICK}{T("Yozildingiz", "Вы записаны", "You're booked")}</div>
        <b><span data-out="day"></span> · <span data-out="time"></span></b>
        <small>{T("Bu demo. Haqiqiy navbat — ilovada.", "Это демо. Настоящая запись — в приложении.", "This is a demo. The real thing is in the app.")}</small></div>
    </div>
  </div>
  <a class="btn booth-cta" href="{PLAY}" rel="noopener">{T("Ilovada band qilish", "Записаться в приложении", "Book it in the app")} <span class="arr">→</span></a>
</div>"""


def desk():
    reqs = [("A", "Aziz", T("Soch olish", "Стрижка", "Haircut"), "15:00", 60000),
            ("J", "Jasur", T("Soch + soqol", "Стрижка + борода", "Cut + beard"), "16:30", 90000),
            ("S", "Sardor", T("Soch olish", "Стрижка", "Haircut"), "18:00", 60000)]
    som = T("so‘m", "сум", "so‘m")
    rows = "".join(f'<div class="trow"><span>{t}</span><i><span>{n} · {sv}</span></i></div>' for _a, n, sv, t, _p in reqs)
    cards = "".join(
        f'<div class="req" data-price="{p}"><div class="req-av">{a}</div><div><b>{n}</b><span>{sv} · {t} · {format(p, ",").replace(",", "&nbsp;")}</span></div>'
        f'<button type="button">{T("Qabul qilish", "Принять", "Accept")}</button></div>'
        for a, n, sv, t, p in reqs)
    return f"""
<div class="desk" data-demo="accept">
  <span class="demo-tag">Demo</span>
  <div class="desk-top"><span>{T("Bugungi daromad", "Доход за сегодня", "Today's earnings")}</span><b class="earn"><span data-earn>0</span> <small>{som}</small></b></div>
  <div class="timeline">{rows}</div>
  <div class="req-stack">{cards}</div>
  <div class="desk-done"><span>{T("Kun to‘ldi! Haqiqiy mijozlar — ilovada.", "День заполнен! Настоящие клиенты — в приложении.", "Day's full! Real clients are in the app.")}</span>
    <button type="button" data-reset>{T("Yana", "Ещё раз", "Again")}</button></div>
</div>"""


def pole(cls=""):
    return f'<div class="pole {cls}" aria-hidden="true"><div class="pole-stripes"></div><div class="pole-shine"></div></div>'


def nav(active):
    links = [
        ("index.html#how", T("Qanday ishlaydi", "Как это работает", "How it works"), "how"),
        ("barbers.html", T("Sartaroshlar uchun", "Для барберов", "For barbers"), "barbers"),
        ("index.html#faq" if active != "barbers" else "barbers.html#faq", T("Savollar", "Вопросы", "FAQ"), "faq"),
    ]
    items = "".join(f'<a href="{h}"{" aria-current=page" if k == active else ""}>{t}</a>' for h, t, k in links)
    return f'''
<div class="progress" aria-hidden="true"></div>
<header class="top">
  <div class="top-in">
    <a class="logo" href="index.html"><img src="assets/icon.png" alt="" width="36" height="36">Fade</a>
    <nav class="links">{items}</nav>
    <div class="langs" role="group" aria-label="Language">
      <button data-set="uz">UZ</button><button data-set="ru">RU</button><button data-set="en">EN</button>
    </div>
    <a class="btn btn-sm mag" href="{PLAY}" rel="noopener">{T("Yuklab olish", "Скачать", "Download")}</a>
  </div>
</header>'''


def footer():
    return f'''
<footer class="foot">
  <div class="wrap foot-in">
    <div>
      <a class="logo" href="index.html"><img src="assets/icon.png" alt="" width="32" height="32">Fade</a>
      <p class="muted">{T("Toshkent sartaroshlariga onlayn navbat.", "Онлайн-запись к барберам Ташкента.", "Online booking for Tashkent barbers.")}</p>
    </div>
    <div class="foot-col">
      <b>Fade</b>
      <a href="index.html">{T("Mijozlar uchun", "Для клиентов", "For clients")}</a>
      <a href="barbers.html">{T("Sartaroshlar uchun", "Для барберов", "For barbers")}</a>
      <a href="{PLAY}" rel="noopener">Google Play</a>
    </div>
    <div class="foot-col">
      <b>{T("Hujjatlar", "Документы", "Legal")}</b>
      <a href="privacy.html">{T("Maxfiylik siyosati", "Конфиденциальность", "Privacy Policy")}</a>
      <a href="terms.html">{T("Foydalanish shartlari", "Условия использования", "Terms of Use")}</a>
      <a href="delete-account.html">{T("Hisobni o‘chirish", "Удаление аккаунта", "Delete account")}</a>
    </div>
    <div class="foot-col">
      <b>{T("Aloqa", "Контакты", "Contact")}</b>
      <a href="mailto:{EMAIL}">{EMAIL}</a>
      <span class="muted">{T("Toshkent, O‘zbekiston", "Ташкент, Узбекистан", "Tashkent, Uzbekistan")}</span>
    </div>
  </div>
  <div class="wrap legal-line muted">© 2026 Fade</div>
</footer>'''


def faq(items):
    return "".join(
        f'<details class="qa"><summary>{q}<i aria-hidden="true"></i></summary><div class="qa-a"><div class="qa-in">{a}</div></div></details>'
        for q, a in items)


def marquee(words, dark=True):
    def run(c):
        out = []
        for i, w in enumerate(words[c]):
            out.append(f'<span class="{"mq-o" if i % 2 else "mq-f"}">{w}</span><span class="mq-dot">✂</span>')
        return "".join(out)
    tracks = "".join(f'<div class="mq-track" data-l="{c}">{run(c) * 2}</div>' for c in ("uz", "ru", "en"))
    return f'<section class="marquee{" dark" if dark else ""}" aria-hidden="true">{tracks}</section>'


def cutline():
    return f'<div class="cut wrap" aria-hidden="true"><div class="cut-track"><div class="cut-done"></div></div><div class="cut-sc">{SCISSORS}</div></div>'


def showcase(sec_id, kicker, title, steps, screens, extra=""):
    st = "".join(
        f'<div class="sstep"><span class="snum">0{i + 1}</span><h3>{h}</h3><p>{p}</p></div>'
        for i, (h, p) in enumerate(steps))
    sc = "".join(f'<div class="scr">{shot(n, a)}</div>' for n, a in screens)
    return f'''
<section class="show" id="{sec_id}">
  <div class="show-in wrap">
    <div class="show-copy">
      <p class="kicker">{kicker}</p>
      <h2 class="split">{title}</h2>
      <div class="show-steps">{st}</div>
      <div class="show-bar"><i></i></div>
    </div>
    <div class="show-stage">
      <div class="show-glow"></div>
      <div class="phone-rise"><div class="phone show-phone"><div class="screens">{sc}</div>{extra}</div></div>
    </div>
  </div>
</section>'''


def ticket(top, big, small, cls=""):
    return (f'<div class="ticket {cls}"><div class="ticket-top"><svg class="tick" viewBox="0 0 20 20" aria-hidden="true">'
            f'<circle cx="10" cy="10" r="9"/><path d="M5.5 10.5l3 3 6-6.5"/></svg>{top}</div>'
            f'<b>{big}</b><span class="muted">{small}</span></div>')


def doc(title, desc, body, active):
    return f'''<!doctype html>
<html lang="uz">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>{title}</title>
<meta name="description" content="{desc}">
<meta name="theme-color" content="#2e8bff">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{desc}">
<meta property="og:image" content="https://thedarkknightmg.github.io/Fade/assets/og-home.jpg">
<meta property="og:type" content="website">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="assets/icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@500;700;800;900;1000&display=swap" rel="stylesheet">
<link rel="stylesheet" href="site.css">
<script>
(function(){{var d=document.documentElement,r=matchMedia('(prefers-reduced-motion: reduce)').matches;
if(r)return;d.classList.add('js');
try{{var s=sessionStorage;if(!s.getItem('fade-intro')||s.getItem('fade-nav')){{d.classList.add('intro');s.setItem('fade-intro','1')}}}}catch(e){{}}
setTimeout(function(){{if(!window.gsap){{d.classList.remove('js','intro')}}}},3500);}})();
</script>
</head>
<body class="uz">
<div class="intro-ov" aria-hidden="true"><div class="intro-word">Fade</div></div>
<canvas class="clips" aria-hidden="true"></canvas>
<div class="clipper" aria-hidden="true"><div class="clipper-in">{CLIPPER}</div></div>
<div class="cursor" aria-hidden="true"></div><div class="cursor-dot" aria-hidden="true"></div>
{nav(active)}
<main>{body}</main>
{footer()}
<script src="{GSAP}/gsap.min.js" defer></script>
<script src="{GSAP}/ScrollTrigger.min.js" defer></script>
<script src="site.js" defer></script>
</body>
</html>'''


LM = [(58.5, 35.4), (90, 36), (60, 43.7), (88, 43.7), (82.6, 54), (79, 63.5), (73, 77), (32.6, 61), (12, 50), (62, 25)]
MESH = [(9, 0), (0, 1), (0, 2), (2, 3), (1, 3), (2, 4), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (7, 2), (5, 7)]


def scan():
    pts = [(x * 2.7, y * 4.44) for x, y in LM]
    lines = "".join(f'<line x1="{pts[a][0]:.1f}" y1="{pts[a][1]:.1f}" x2="{pts[b][0]:.1f}" y2="{pts[b][1]:.1f}"/>' for a, b in MESH)
    dots = "".join(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="3.2"/>' for x, y in pts)
    return f'''
<div class="scan" aria-hidden="true">
  <div class="scan-ring"></div><div class="scan-ring r2"></div>
  <div class="scan-face">
    <img src="assets/face.webp" alt="" width="270" height="444" loading="lazy">
    <svg class="scan-mesh" viewBox="0 0 270 444" preserveAspectRatio="none"><g class="mesh-l">{lines}</g><g class="mesh-d">{dots}</g></svg>
    <div class="scan-beam"></div>
  </div>
  <div class="scan-tag tag-a"><i></i>{T("Yuz shakli: oval", "Форма лица: овал", "Face shape: oval")}</div>
  <div class="scan-tag tag-b"><i></i><span class="cycle" data-words="Skin fade|Pompadour|Crop|Undercut|Buzz cut">Skin fade</span></div>
</div>'''


# ───────────────────────────── index.html ─────────────────────────────
HOME = f'''
<section class="hero wrap">
  <div class="hero-copy">
    {hair_bits()}
    <p class="eyebrow">{T("Toshkent · mijozlar uchun bepul", "Ташкент · бесплатно для клиентов", "Tashkent · free for clients")}</p>
    <h1 class="h-split">{T("Sartaroshga navbat — <em>bir tegishda.</em>", "Запись к барберу — <em>в одно касание.</em>", "Your barber, <em>booked in a tap.</em>")}</h1>
    <p class="lead">{T("Yaqin atrofdagi sartaroshxonalarni xaritada toping, narx va sharhlarni ko‘ring, bo‘sh vaqtni tanlang. Qo‘ng‘iroq ham, navbat kutish ham yo‘q.",
        "Найдите барбершопы рядом на карте, сравните цены и отзывы, выберите свободное время. Без звонков и очередей.",
        "Find barbershops near you on the map, compare prices and reviews, pick a free slot. No calls, no queues.")}</p>
    <div class="cta-row">
      {play_btn()}
      <a class="btn btn-ghost mag" href="barbers.html">{T("Sartaroshmisiz?", "Вы барбер?", "Are you a barber?")} <span class="arr" aria-hidden="true">→</span></a>
    </div>
    <ul class="ticks">
      <li>{T("Qo‘ng‘iroqsiz", "Без звонков", "No calls")}</li>
      <li>{T("Narxlar oldindan", "Цены заранее", "Prices up front")}</li>
      <li>{T("To‘lov sartaroshxonada", "Оплата в барбершопе", "Pay at the shop")}</li>
    </ul>
  </div>
  <div class="hero-art">
    {pole()}
    <div class="phone-wrap"><div class="phone hero-phone">{shot("home", "Fade", eager=True)}</div></div>
    <img class="sticker s-star" data-depth="1.4" src="assets/ai_star.webp" alt="" width="200" height="200">
    <img class="sticker s-pin" data-depth="-1" src="assets/map.webp" alt="" width="200" height="200">
    {ticket(T("Yozildingiz", "Вы записаны", "You're booked"), T("Ertaga · 09:30", "Завтра · 09:30", "Tomorrow · 09:30"), T("Soch + soqol", "Стрижка + борода", "Cut + beard"))}
  </div>
  <a class="scroll-hint" href="#how" aria-label="Scroll"><span></span></a>
</section>

{marquee({"uz": ["Soch olish", "Soqol", "Fade", "Navbatsiz", "Toshkent"],
          "ru": ["Стрижка", "Борода", "Fade", "Без очереди", "Ташкент"],
          "en": ["Haircut", "Beard", "Fade", "No queue", "Tashkent"]})}

{showcase("how", T("Qanday ishlaydi", "Как это работает", "How it works"),
  T("Uch qadam — va siz kreslodasiz.", "Три шага — и вы в кресле.", "Three steps to the chair."),
  [(T("Yaqinini toping", "Найдите рядом", "Find one nearby"),
    T("Xaritada atrofingizdagi sartaroshxonalar — narx va reyting bilan.", "Барбершопы вокруг вас на карте — с ценами и рейтингом.", "Shops around you on the map, with prices and ratings.")),
   (T("Usta va vaqtni tanlang", "Выберите мастера и время", "Pick a barber and a time"),
    T("Sharhlarni o‘qing, xizmatni tanlang, bo‘sh soatni band qiling.", "Читайте отзывы, выбирайте услугу и свободный час.", "Read reviews, choose the service, grab a free slot.")),
   (T("Keling va o‘tiring", "Приходите и садитесь", "Walk in and sit down"),
    T("Kelganingizda QR’ni skanerlang — navbat kutish yo‘q.", "По приходу отсканируйте QR — никакого ожидания.", "Scan the shop's QR on arrival — no waiting around."))],
  [("map", "Map"), ("shop", "Shop"), ("home", "Home")],
  ticket(T("Yozildingiz", "Вы записаны", "You're booked"), T("Ertaga · 09:30", "Завтра · 09:30", "Tomorrow · 09:30"), T("Kelishingizni kutamiz", "Ждём вас", "See you there"), "show-ticket"))}

{cutline()}

<section class="ai">
  <div class="ai-bg" aria-hidden="true"></div>
  <div class="wrap ai-in">
    <div class="ai-copy">
      <p class="kicker light">{T("AI sinash", "AI-примерка", "AI try-on")}</p>
      <h2 class="split">{T("Soch turmagini oldindan ko‘ring.", "Посмотрите стрижку заранее.", "See the cut before the cut.")}</h2>
      <p class="fade-up">{T("Ilova yuzingiz shaklini telefonning o‘zida aniqlaydi va mos turmaklarni taklif qiladi. Rasmingizda sinab ko‘ring — sartaroshga aynan nimani xohlashingizni ko‘rsating.",
          "Приложение определяет форму лица прямо на телефоне и подбирает подходящие стрижки. Примерьте их на своё фото и покажите барберу, чего именно хотите.",
          "The app reads your face shape right on your phone and suggests cuts that suit it. Try them on your photo and show your barber exactly what you want.")}</p>
    </div>
    {scan()}
  </div>
</section>

<section class="wrap section demo-sec" id="try">
  <div>
    <p class="kicker">{T("Sinab ko‘ring", "Попробуйте", "Try it")}</p>
    <h2 class="split">{T("Vaqtni tanlang. Tamom.", "Выберите время. Готово.", "Pick a time. Done.")}</h2>
    <p class="lead fade-up">{T("Shu yerning o‘zida bosib ko‘ring — ilovada ham xuddi shunday tez.", "Нажмите прямо здесь — в приложении всё так же быстро.", "Tap right here — it's just as quick in the app.")}</p>
  </div>
  {booth()}
</section>

<section class="wrap section punch-sec">
  <div class="punch-copy">
    <p class="kicker">{T("Fade ballari", "Баллы Fade", "Fade Points")}</p>
    <h2 class="split">{T("Har tashrif — kartangizga belgi.", "Каждый визит — отметка в карте.", "Every visit punches your card.")}</h2>
    <p class="lead fade-up">{T("Har bir soch olish va har bir taklif qilingan do‘st sizni bepul soch olishga yaqinlashtiradi.",
        "Каждая стрижка и каждый приглашённый друг приближают вас к бесплатной стрижке.",
        "Every cut and every friend you invite moves you toward a free haircut.")}</p>
  </div>
  <div class="punch" aria-hidden="true">
    <div class="punch-head"><b>Fade</b><span>{T("Sodiqlik kartasi", "Карта лояльности", "Loyalty card")}</span></div>
    <div class="holes">{"".join("<i><b></b></i>" for _ in range(16))}</div>
    <div class="punch-foot">{T("Bepul soch olish", "Бесплатная стрижка", "Free haircut")} <span class="gift">✂</span></div>
  </div>
</section>

<section class="wrap">
  <a class="band" href="barbers.html">
    <div class="band-stripes" aria-hidden="true"></div>
    <div class="band-copy">
      <p class="kicker light">{T("Sartaroshlar uchun", "Для барберов", "For barbers")}</p>
      <h2>{T("Bo‘sh soatlaringizni mijozlar to‘ldirsin.", "Пусть клиенты заполнят ваши свободные часы.", "Let clients fill your empty hours.")}</h2>
    </div>
    <span class="band-go mag">{T("Batafsil", "Подробнее", "Learn more")} <span class="arr">→</span></span>
  </a>
</section>

<section id="faq" class="wrap section narrow">
  <p class="kicker">{T("Savollar", "Вопросы", "FAQ")}</p>
  <h2 class="split">{T("Ko‘p so‘raladi.", "Часто спрашивают.", "Good questions.")}</h2>
  <div class="faq">{faq([
    (T("Fade pullikmi?", "Fade платный?", "Does Fade cost anything?"),
     T("Yo‘q, mijozlar uchun ilova bepul. Siz faqat soch olish uchun sartaroshxonada to‘laysiz.", "Нет, для клиентов приложение бесплатное. Вы платите только за стрижку в барбершопе.", "No — the app is free for clients. You only pay for the haircut, at the shop.")),
    (T("Qanday to‘layman?", "Как оплатить?", "How do I pay?"),
     T("Hozircha to‘lov sartaroshxonaning o‘zida. Ilovada narx oldindan ko‘rsatiladi, kutilmagan narx bo‘lmaydi.", "Пока оплата прямо в барбершопе. Цена видна в приложении заранее — без сюрпризов.", "For now you pay at the shop. The price is shown in the app up front, so there are no surprises.")),
    (T("Qaysi shaharlarda ishlaydi?", "В каких городах работает?", "Which cities?"),
     T("Hozircha Toshkentda. Yangi sartaroshxonalar qo‘shilib bormoqda.", "Пока в Ташкенте. Новые барбершопы продолжают подключаться.", "Tashkent for now, with new shops joining.")),
    (T("Yozilishni bekor qilsam bo‘ladimi?", "Можно отменить запись?", "Can I cancel?"),
     T("Ha, “Mening yozuvlarim” bo‘limidan. Iltimos, oldindan bekor qiling — sartarosh vaqtini boshqa mijozga bera oladi.", "Да, в разделе «Мои записи». Пожалуйста, отменяйте заранее — барбер сможет отдать время другому клиенту.", "Yes, from “My bookings”. Please cancel early so the barber can give the slot to someone else.")),
    (T("Do‘stimdan taklif kodi oldim. Qayerga kiritaman?", "Мне прислали код друга. Куда его ввести?", "A friend sent me a code. Where does it go?"),
     T("Ro‘yxatdan o‘ting, so‘ng <b>Sozlamalar → Do‘stlarni taklif qiling → Do‘st kodi bormi?</b>", "Зарегистрируйтесь, затем <b>Настройки → Пригласить друзей → Есть код друга?</b>", "Sign up, then <b>Settings → Invite friends &amp; earn → Have a friend's code?</b>")),
    (T("Ma’lumotlarimni qanday o‘chiraman?", "Как удалить мои данные?", "How do I delete my data?"),
     T('Ilovada: Profil → Sozlamalar → Hisobni o‘chirish. Yoki <a href="delete-account.html">bu sahifadagi</a> yo‘riqnoma bo‘yicha.', 'В приложении: Профиль → Настройки → Удалить аккаунт. Или по инструкции <a href="delete-account.html">на этой странице</a>.', 'In the app: Profile → Settings → Delete account, or follow <a href="delete-account.html">this page</a>.')),
  ])}</div>
</section>

<section class="final">
  <div class="final-word" aria-hidden="true">Fade</div>
  <h2 class="split">{T("Keyingi soch olishingiz — bir tegishda.", "Следующая стрижка — в одно касание.", "Your next cut is one tap away.")}</h2>
  {play_btn("big")}
</section>
'''

# ───────────────────────────── barbers.html ─────────────────────────────
def perk(icon, h, p):
    return f'<li class="perk tilt-card"><span class="perk-ic" aria-hidden="true">{icon}</span><h3>{h}</h3><p>{p}</p></li>'


BARBERS = f'''
<section class="hero wrap">
  <div class="hero-copy">
    {hair_bits()}
    <p class="eyebrow">{T("Sartaroshlar va sartaroshxonalar uchun", "Для барберов и барбершопов", "For barbers and barbershops")}</p>
    <h1 class="h-split">{T("Bo‘sh kreslo — <em>yo‘qotilgan pul.</em>", "Пустое кресло — <em>потерянные деньги.</em>", "An empty chair <em>is lost money.</em>")}</h1>
    <p class="lead">{T("Fade yaqin atrofdagi mijozlarga sizni xaritada ko‘rsatadi va ular bo‘sh soatlaringizga o‘zlari yoziladi. Qo‘ng‘iroqlarsiz, daftarsiz.",
        "Fade показывает вас клиентам поблизости на карте, и они сами записываются в ваши свободные часы. Без звонков и блокнота.",
        "Fade puts you on the map for clients nearby, and they book your free hours themselves. No calls, no notebook.")}</p>
    <div class="cta-row">
      {play_btn()}
      <a class="btn btn-ghost mag" href="mailto:{EMAIL}?subject=Fade%20%E2%80%94%20barbershop">{T("Bizga yozing", "Написать нам", "Contact us")} <span class="arr" aria-hidden="true">→</span></a>
    </div>
    <ul class="ticks">
      <li>{T("Ro‘yxatdan o‘tish bepul", "Регистрация бесплатна", "Free to join")}</li>
      <li>{T("Telefoningizdan boshqarasiz", "Всё с телефона", "Run it from your phone")}</li>
    </ul>
  </div>
  <div class="hero-art">
    {pole()}
    <div class="phone-wrap"><div class="phone hero-phone">{shot("barber", "Fade for barbers", eager=True)}</div></div>
    <img class="sticker s-chair" data-depth="-1" src="assets/cuts.webp" alt="" width="240" height="180">
    <img class="sticker s-star sm" data-depth="1.4" src="assets/ai_star.webp" alt="" width="200" height="200">
    {ticket(T("Yangi so‘rov", "Новая заявка", "New request"), T("Bugun · 18:00", "Сегодня · 18:00", "Today · 18:00"), T("Qabul qilish — bir tegish", "Принять — одно касание", "Accept in one tap"))}
  </div>
  <a class="scroll-hint" href="#day" aria-label="Scroll"><span></span></a>
</section>

{marquee({"uz": ["Ko‘proq mijoz", "Kamroq qo‘ng‘iroq", "Bo‘sh soat yo‘q", "Fade"],
          "ru": ["Больше клиентов", "Меньше звонков", "Ни одного пустого часа", "Fade"],
          "en": ["More clients", "Fewer calls", "No empty hours", "Fade"]})}

{showcase("day", T("Fade bilan bir kun", "Один день с Fade", "A day on Fade"),
  T("Ish kuningiz — kaftingizda.", "Рабочий день — у вас в руке.", "Your whole day, in your hand."),
  [(T("Kuningiz bir qarashda", "День как на ладони", "Your day at a glance"),
    T("Keyingi mijoz, bugungi yozuvlar va kutilayotgan daromad — bitta ekranda.", "Следующий клиент, записи на сегодня и ожидаемый доход — на одном экране.", "Next client, today's bookings and expected earnings — on one screen.")),
   (T("So‘rovlar bir tegishda", "Заявки в одно касание", "Requests in one tap"),
    T("Yangi yozuvni qabul qiling yoki boshqa vaqt taklif qiling.", "Примите запись или предложите другое время.", "Accept a booking or suggest another time.")),
   (T("Jadval tartibda", "Расписание в порядке", "A tidy schedule"),
    T("Bo‘sh soatlar ko‘rinib turadi — mijozlar aynan ularga yoziladi.", "Свободные часы видны — клиенты записываются именно на них.", "Your free hours are visible, and that's exactly where clients book."))],
  [("barber", "Dashboard"), ("requests", "Requests"), ("schedule", "Schedule")])}

{cutline()}

<section class="wrap section">
  <p class="kicker">{T("Nimalar beradi", "Что вы получаете", "What you get")}</p>
  <h2 class="split">{T("Mijozlar sizni o‘zi topadi.", "Клиенты находят вас сами.", "Clients find you on their own.")}</h2>
  <ul class="perks">
    {perk("📍", T("Xaritada ko‘rinasiz", "Вас видно на карте", "You're on the map"), T("Yaqin atrofdagi mijozlar sizni narxlaringiz bilan topadi.", "Клиенты рядом находят вас вместе с ценами.", "Clients nearby find you, prices included."))}
    {perk("⚡", T("So‘rovlar bir tegishda", "Заявки в одно касание", "One-tap requests"), T("Qabul qiling yoki boshqa vaqt taklif qiling.", "Примите или предложите другое время.", "Accept, or suggest another time."))}
    {perk("🗓", T("Jadval ko‘z oldida", "Расписание перед глазами", "Schedule at a glance"), T("Bugungi mijozlar, bo‘sh soatlar va kutilayotgan daromad.", "Клиенты на сегодня, свободные часы и ожидаемый доход.", "Today's clients, free hours and expected earnings."))}
    {perk("▣", T("QR orqali kelishni belgilash", "Отметка прихода по QR", "QR arrival check-in"), T("Mijoz plakatingizdagi QR’ni skanerlaydi — kim kelgani aniq.", "Клиент сканирует QR на вашем постере — видно, кто пришёл.", "Clients scan your poster's QR, so you know who showed up."))}
    {perk("★", T("Sharhlar sizniki", "Отзывы — ваши", "Reviews that are yours"), T("Haqiqiy tashriflardan keyingi sharhlar profilingizga yoziladi.", "Отзывы после реальных визитов пишутся в ваш профиль.", "Reviews from real visits go to your own profile."))}
    {perk("✂", T("Doimiy mijozlar", "Постоянные клиенты", "Regulars come back"), T("Mijoz “odatdagisini” bir tegishda qayta band qiladi.", "Клиент повторяет «как обычно» в одно касание.", "Clients rebook “the usual” in one tap."))}
  </ul>
</section>

<section class="wrap section demo-sec" id="try">
  <div>
    <p class="kicker">{T("Sinab ko‘ring", "Попробуйте", "Try it")}</p>
    <h2 class="split">{T("Kunni uch tegishda to‘ldiring.", "Заполните день в три касания.", "Fill your day in three taps.")}</h2>
    <p class="lead fade-up">{T("So‘rovlarni qabul qiling va daromad qanday o‘sishini ko‘ring.", "Принимайте заявки и смотрите, как растёт доход.", "Accept the requests and watch the earnings add up.")}</p>
  </div>
  {desk()}
</section>

<section class="wrap section join-sec">
  <div>
    <p class="kicker">{T("Qanday qo‘shilish", "Как подключиться", "How to join")}</p>
    <h2 class="split">{T("5 daqiqada ishga tushasiz.", "Запуск за 5 минут.", "Live in five minutes.")}</h2>
    {play_btn()}
  </div>
  <ol class="join">
    <li>{T("Fade’ni Google Play’dan o‘rnating va ro‘yxatdan o‘ting.", "Установите Fade из Google Play и зарегистрируйтесь.", "Install Fade from Google Play and sign up.")}</li>
    <li>{T("<b>Profil → Barber bo‘ling</b> ni bosing.", "Нажмите <b>Профиль → Стать барбером</b>.", "Tap <b>Profile → Become a barber</b>.")}</li>
    <li>{T("Sartaroshxonangizni toping — yo‘q bo‘lsa, xaritada o‘zingiz qo‘shing.", "Найдите свой барбершоп — если его нет, добавьте сами на карте.", "Find your shop — if it isn't there yet, add it on the map yourself.")}</li>
    <li>{T("Xizmatlar va narxlarni kiriting, hamkasblarni havola orqali taklif qiling.", "Добавьте услуги и цены, пригласите коллег по ссылке.", "Add your services and prices, and invite colleagues with a link.")}</li>
  </ol>
</section>

<section id="faq" class="wrap section narrow">
  <p class="kicker">{T("Savollar", "Вопросы", "FAQ")}</p>
  <h2 class="split">{T("Sartaroshlar so‘raydi.", "Барберы спрашивают.", "Barbers ask.")}</h2>
  <div class="faq">{faq([
    (T("Qo‘shilish pullikmi?", "Подключение платное?", "Does it cost anything to join?"),
     T("Yo‘q, ro‘yxatdan o‘tish va profil yaratish bepul.", "Нет, регистрация и создание профиля бесплатны.", "No — signing up and creating your profile is free.")),
    (T("Mijoz qanday to‘laydi?", "Как платит клиент?", "How do clients pay?"),
     T("Hozircha mijoz to‘g‘ridan-to‘g‘ri sizga, sartaroshxonada to‘laydi.", "Пока клиент платит напрямую вам, в барбершопе.", "For now clients pay you directly, at the shop.")),
    (T("Sartaroshxona egasining ruxsati kerakmi?", "Нужно разрешение владельца барбершопа?", "Do I need the shop owner's permission?"),
     T("Siz o‘zingizni sartarosh sifatida qo‘shasiz. Sartaroshxona Fade’da bo‘lmasa, uni birinchi bo‘lib qo‘shishingiz va hamkasblarni taklif qilishingiz mumkin.", "Вы добавляете себя как барбера. Если барбершопа ещё нет в Fade, вы можете добавить его первым и пригласить коллег.", "You join as a barber. If your shop isn't on Fade yet, you can add it first and invite your colleagues.")),
    (T("Mijoz kelmasa-chi?", "А если клиент не придёт?", "What if a client doesn't show up?"),
     T("Mijoz kelganda QR kodni skanerlaydi, shuning uchun kim kelgani va kim kelmagani ko‘rinib turadi.", "Клиент сканирует QR по приходу — видно, кто пришёл, а кто нет.", "Clients scan your QR when they arrive, so you can see who came and who didn't.")),
    (T("Savol qolsa?", "Остались вопросы?", "Still have questions?"),
     T(f'Yozing: <a href="mailto:{EMAIL}">{EMAIL}</a> — sartaroshxonangizni sozlashga yordam beramiz.', f'Пишите: <a href="mailto:{EMAIL}">{EMAIL}</a> — поможем настроить ваш барбершоп.', f'Email <a href="mailto:{EMAIL}">{EMAIL}</a> and we\'ll help set up your shop.')),
  ])}</div>
</section>

<section class="final">
  <div class="final-word" aria-hidden="true">Fade</div>
  <h2 class="split">{T("Kreslongiz bo‘sh turmasin.", "Пусть кресло не простаивает.", "Keep your chair busy.")}</h2>
  {play_btn("big")}
</section>
'''

CSS = io.open(sys.argv[2], encoding="utf-8").read()
JS = io.open(sys.argv[3], encoding="utf-8").read()
io.open(f"{OUT}/site.css", "w", encoding="utf-8", newline="\n").write(CSS)
io.open(f"{OUT}/site.js", "w", encoding="utf-8", newline="\n").write(JS)
io.open(f"{OUT}/index.html", "w", encoding="utf-8", newline="\n").write(doc(
    "Fade — sartaroshga onlayn navbat, Toshkent",
    "Toshkent sartaroshxonalariga bir tegishda yoziling: xarita, narxlar, sharhlar va AI turmak sinash.",
    HOME, "how"))
io.open(f"{OUT}/barbers.html", "w", encoding="utf-8", newline="\n").write(doc(
    "Fade sartaroshlar uchun — bo‘sh kreslo bo‘lmasin",
    "Yaqin atrofdagi mijozlar sizni xaritada topadi va bo‘sh soatlaringizga o‘zlari yoziladi. Ro‘yxatdan o‘tish bepul.",
    BARBERS, "barbers"))
print("ok")
