"""Fade marketing site: index.html (clients) + barbers.html, sharing site.css/site.js.
Every visible string is written three times (uz/ru/en) as sibling spans; CSS shows one."""
import io, sys

OUT = sys.argv[1]
PLAY = "https://play.google.com/store/apps/details?id=uz.fade.app"
EMAIL = "fade.privacy.uz@gmail.com"


def T(uz, ru, en, tag="span"):
    return "".join(f'<{tag} data-l="{c}">{s}</{tag}>' for c, s in (("uz", uz), ("ru", ru), ("en", en)))


def shot(name, alt, cls="", eager=False):
    load = "eager" if eager else "lazy"
    return (f'<img class="{cls}" data-l="uz" src="assets/uz_{name}.webp" alt="{alt}" width="540" height="960" loading="{load}">'
            f'<img class="{cls}" data-l="ru" src="assets/ru_{name}.webp" alt="{alt}" width="540" height="960" loading="{load}">'
            f'<img class="{cls}" data-l="en" src="assets/uz_{name}.webp" alt="{alt}" width="540" height="960" loading="{load}">')


PLAY_ICON = ('<svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true"><path fill="currentColor" '
             'd="M3.6 2.2c-.3.3-.4.7-.4 1.2v17.2c0 .5.1.9.4 1.2l9.7-9.8-9.7-9.8Zm10.6 10.7 2.7 2.7-11 6.3c-.4.2-.8.3-1.1.2'
             'l9.4-9.2Zm0-1.8L4.8 1.9c.3-.1.7 0 1.1.2l11 6.3-2.7 2.7Zm4.3-2.1 3 1.7c.9.5.9 1.8 0 2.3l-3 1.7-3-3 3-2.7Z"/></svg>')


def play_btn(cls="btn btn-play"):
    return (f'<a class="{cls}" href="{PLAY}" rel="noopener">{PLAY_ICON}<span class="btn-stack">'
            f'<small>{T("Yuklab oling", "Скачайте в", "Get it on")}</small><b>Google Play</b></span></a>')


def nav(active):
    links = [
        ("index.html#how", T("Qanday ishlaydi", "Как это работает", "How it works"), "home"),
        ("barbers.html", T("Sartaroshlar uchun", "Для барберов", "For barbers"), "barbers"),
        ("index.html#faq" if active == "home" else "barbers.html#faq", T("Savollar", "Вопросы", "FAQ"), "faq"),
    ]
    items = "".join(f'<a href="{h}"{" aria-current=page" if k == active else ""}>{t}</a>' for h, t, k in links)
    return f'''
<header class="top">
  <div class="top-in">
    <a class="logo" href="index.html"><img src="assets/icon.png" alt="" width="36" height="36">Fade</a>
    <nav class="links">{items}</nav>
    <div class="langs" role="group" aria-label="Language">
      <button data-set="uz">UZ</button><button data-set="ru">RU</button><button data-set="en">EN</button>
    </div>
    <a class="btn btn-sm" href="{PLAY}" rel="noopener">{T("Yuklab olish", "Скачать", "Download")}</a>
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
      <b>{T("Fade", "Fade", "Fade")}</b>
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
        f'<details class="qa reveal"><summary>{q}<i aria-hidden="true"></i></summary><div class="qa-a">{a}</div></details>'
        for q, a in items)


def doc(title, desc, og, body, active):
    return f'''<!doctype html>
<html lang="uz">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title}</title>
<meta name="description" content="{desc}">
<meta name="theme-color" content="#2e8bff">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{desc}">
<meta property="og:image" content="https://thedarkknightmg.github.io/Fade/assets/{og}">
<meta property="og:type" content="website">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="assets/icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@500;700;800;900&display=swap" rel="stylesheet">
<link rel="stylesheet" href="site.css">
</head>
<body class="uz">
{nav(active)}
<main>{body}</main>
{footer()}
<script src="site.js"></script>
</body>
</html>'''


PERF = '<div class="perf" aria-hidden="true"><span></span></div>'

# ───────────────────────────── index.html (clients) ─────────────────────────────
HOME = f'''
<section class="hero wrap">
  <div class="hero-copy">
    <p class="eyebrow rise" style="--d:0">{T("Toshkent · mijozlar uchun bepul", "Ташкент · бесплатно для клиентов", "Tashkent · free for clients")}</p>
    <h1 class="rise" style="--d:1">{T("Sartaroshga navbat —<br><em>bir tegishda.</em>", "Запись к барберу —<br><em>в одно касание.</em>", "Your barber,<br><em>booked in a tap.</em>")}</h1>
    <p class="lead rise" style="--d:2">{T("Yaqin atrofdagi sartaroshxonalarni xaritada toping, narx va sharhlarni ko‘ring, bo‘sh vaqtni tanlang. Qo‘ng‘iroq ham, navbat kutish ham yo‘q.",
        "Найдите барбершопы рядом на карте, сравните цены и отзывы, выберите свободное время. Без звонков и очередей.",
        "Find barbershops near you on the map, compare prices and reviews, pick a free slot. No calls, no queues.")}</p>
    <div class="cta-row rise" style="--d:3">
      {play_btn()}
      <a class="btn btn-ghost" href="barbers.html">{T("Sartaroshmisiz?", "Вы барбер?", "Are you a barber?")} <span aria-hidden="true">→</span></a>
    </div>
    <ul class="ticks rise" style="--d:4">
      <li>{T("Qo‘ng‘iroqsiz", "Без звонков", "No calls")}</li>
      <li>{T("Narxlar oldindan", "Цены заранее", "Prices up front")}</li>
      <li>{T("To‘lov sartaroshxonada", "Оплата в барбершопе", "Pay at the shop")}</li>
    </ul>
  </div>
  <div class="hero-art">
    <div class="phone tilt">{shot("home", "Fade", eager=True)}</div>
    <img class="sticker s-star float" src="assets/ai_star.webp" alt="" width="200" height="200">
    <img class="sticker s-pin float2" src="assets/map.webp" alt="" width="200" height="200">
    <div class="ticket pop">
      <div class="ticket-top"><span class="dot"></span>{T("Yozildingiz", "Вы записаны", "You're booked")}</div>
      <b>{T("Ertaga · 09:30", "Завтра · 09:30", "Tomorrow · 09:30")}</b>
      <span class="muted">{T("Soch + soqol", "Стрижка + борода", "Cut + beard")}</span>
    </div>
  </div>
</section>

{PERF}

<section id="how" class="wrap section">
  <p class="kicker reveal">{T("Qanday ishlaydi", "Как это работает", "How it works")}</p>
  <h2 class="reveal">{T("Uch qadam — va siz kreslodasiz.", "Три шага — и вы в кресле.", "Three steps to the chair.")}</h2>
  <ol class="steps">
    <li class="step reveal"><img src="assets/map.webp" alt="" width="120" height="120" loading="lazy"><span class="num">01</span>
      <h3>{T("Yaqinini toping", "Найдите рядом", "Find one nearby")}</h3>
      <p>{T("Xaritada atrofingizdagi sartaroshxonalar, narxlar va reyting.", "Барбершопы вокруг вас на карте — с ценами и рейтингом.", "Shops around you on the map, with prices and ratings.")}</p></li>
    <li class="step reveal"><img src="assets/book.webp" alt="" width="120" height="120" loading="lazy"><span class="num">02</span>
      <h3>{T("Vaqtni tanlang", "Выберите время", "Pick a time")}</h3>
      <p>{T("Ustani va bo‘sh soatni tanlang — sartarosh tasdiqlaydi.", "Выберите мастера и свободный час — барбер подтвердит.", "Choose the barber and a free slot — they confirm it.")}</p></li>
    <li class="step reveal"><img src="assets/cuts.webp" alt="" width="120" height="120" loading="lazy"><span class="num">03</span>
      <h3>{T("Keling va o‘tiring", "Приходите и садитесь", "Walk in and sit down")}</h3>
      <p>{T("Kelganingizda QR kodni skanerlang — navbat kutmasdan.", "По приходу отсканируйте QR-код — без ожидания.", "Scan the shop's QR on arrival — no waiting around.")}</p></li>
  </ol>
</section>

<section class="ai-band">
  <div class="wrap ai-in">
    <div class="ai-copy reveal">
      <p class="kicker light">{T("AI sinash", "AI-примерка", "AI try-on")}</p>
      <h2>{T("Soch turmagini<br>oldindan ko‘ring.", "Посмотрите стрижку<br>заранее.", "See the cut<br>before the cut.")}</h2>
      <p>{T("Rasmingizga turli turmaklarni sinab ko‘ring va sartaroshga aynan nimani xohlashingizni ko‘rsating. Endi “tepasini ozroq” deb tushuntirish shart emas.",
          "Примерьте разные стрижки на своё фото и покажите барберу, чего именно хотите. Больше не нужно объяснять «сверху чуть-чуть».",
          "Try different styles on your own photo and show your barber exactly what you want. No more explaining “just a little off the top”.")}</p>
    </div>
    <img class="ai-star float" src="assets/ai_star.webp" alt="" width="320" height="320" loading="lazy">
  </div>
</section>

<section class="wrap section">
  <p class="kicker reveal">{T("Ilova ichida", "Внутри приложения", "Inside the app")}</p>
  <h2 class="reveal">{T("Hammasi bir joyda.", "Всё в одном месте.", "Everything in one place.")}</h2>
  <div class="gallery reveal" tabindex="0" aria-label="Screens">
    <figure><div class="phone sm">{shot("home", "Home")}</div><figcaption>{T("Bosh sahifa", "Главная", "Home")}</figcaption></figure>
    <figure><div class="phone sm">{shot("shop", "Shop")}</div><figcaption>{T("Narx, reyting, sharhlar", "Цены, рейтинг, отзывы", "Prices, ratings, reviews")}</figcaption></figure>
    <figure><div class="phone sm">{shot("map", "Map")}</div><figcaption>{T("Xaritada yaqinlari", "Рядом на карте", "Nearby on the map")}</figcaption></figure>
  </div>
</section>

<section class="wrap section punch-sec">
  <div class="punch-copy reveal">
    <p class="kicker">{T("Fade ballari", "Баллы Fade", "Fade Points")}</p>
    <h2>{T("Har tashrif — kartangizga belgi.", "Каждый визит — отметка в карте.", "Every visit punches your card.")}</h2>
    <p class="lead">{T("Har bir soch olish va har bir taklif qilingan do‘st sizni bepul soch olishga yaqinlashtiradi.",
        "Каждая стрижка и каждый приглашённый друг приближают вас к бесплатной стрижке.",
        "Every cut and every friend you invite moves you toward a free haircut.")}</p>
  </div>
  <div class="punch reveal" aria-hidden="true">
    <div class="punch-head"><b>Fade</b><span>{T("Sodiqlik kartasi", "Карта лояльности", "Loyalty card")}</span></div>
    <div class="holes">{"".join(f'<i style="--i:{i}"></i>' for i in range(16))}</div>
    <div class="punch-foot">{T("Bepul soch olish", "Бесплатная стрижка", "Free haircut")} <span>✂</span></div>
  </div>
</section>

<section class="wrap">
  <a class="barber-band reveal" href="barbers.html">
    <div>
      <p class="kicker light">{T("Sartaroshlar uchun", "Для барберов", "For barbers")}</p>
      <h2>{T("Bo‘sh soatlaringizni mijozlar to‘ldirsin.", "Пусть клиенты заполнят ваши свободные часы.", "Let clients fill your empty hours.")}</h2>
    </div>
    <span class="band-go">{T("Batafsil", "Подробнее", "Learn more")} →</span>
    <img src="assets/cuts.webp" alt="" width="260" height="200" loading="lazy">
  </a>
</section>

<section id="faq" class="wrap section narrow">
  <p class="kicker reveal">{T("Savollar", "Вопросы", "FAQ")}</p>
  <h2 class="reveal">{T("Ko‘p so‘raladi.", "Часто спрашивают.", "Good questions.")}</h2>
  {faq([
    (T("Fade pullikmi?", "Fade платный?", "Does Fade cost anything?"),
     T("Yo‘q, mijozlar uchun ilova bepul. Siz faqat soch olish uchun sartaroshxonada to‘laysiz.", "Нет, для клиентов приложение бесплатное. Вы платите только за стрижку в барбершопе.", "No — the app is free for clients. You only pay for the haircut, at the shop.")),
    (T("Qanday to‘layman?", "Как оплатить?", "How do I pay?"),
     T("Hozircha to‘lov sartaroshxonaning o‘zida. Ilovada narx oldindan ko‘rsatiladi, kutilmagan narx bo‘lmaydi.", "Пока оплата прямо в барбершопе. Цена видна в приложении заранее — без сюрпризов.", "For now you pay at the shop. The price is shown in the app up front, so there are no surprises.")),
    (T("Qaysi shaharlarda ishlaydi?", "В каких городах работает?", "Which cities?"),
     T("Hozircha Toshkentda. Yangi sartaroshxonalar har hafta qo‘shilmoqda.", "Пока в Ташкенте. Новые барбершопы добавляются постоянно.", "Tashkent for now, with new shops joining all the time.")),
    (T("Yozilishni bekor qilsam bo‘ladimi?", "Можно отменить запись?", "Can I cancel?"),
     T("Ha, “Mening yozuvlarim” bo‘limidan. Iltimos, oldindan bekor qiling — sartarosh vaqtini boshqa mijozga bera oladi.", "Да, в разделе «Мои записи». Пожалуйста, отменяйте заранее — барбер сможет отдать время другому клиенту.", "Yes, from “My bookings”. Please cancel early so the barber can give the slot to someone else.")),
    (T("Do‘stimdan taklif kodi oldim. Qayerga kiritaman?", "Мне прислали код друга. Куда его ввести?", "A friend sent me a code. Where does it go?"),
     T("Ro‘yxatdan o‘ting, so‘ng <b>Sozlamalar → Do‘stlarni taklif qiling → Do‘st kodi bormi?</b>", "Зарегистрируйтесь, затем <b>Настройки → Пригласить друзей → Есть код друга?</b>", "Sign up, then <b>Settings → Invite friends &amp; earn → Have a friend's code?</b>")),
    (T("Ma’lumotlarimni qanday o‘chiraman?", "Как удалить мои данные?", "How do I delete my data?"),
     T('Ilovada: Profil → Sozlamalar → Hisobni o‘chirish. Yoki <a href="delete-account.html">bu sahifadagi</a> yo‘riqnoma bo‘yicha.', 'В приложении: Профиль → Настройки → Удалить аккаунт. Или по инструкции <a href="delete-account.html">на этой странице</a>.', 'In the app: Profile → Settings → Delete account, or follow <a href="delete-account.html">this page</a>.')),
  ])}
</section>

<section class="wrap final reveal">
  <h2>{T("Keyingi soch olishingiz — Fade’da.", "Следующая стрижка — через Fade.", "Book your next cut on Fade.")}</h2>
  {play_btn()}
</section>
'''

# ───────────────────────────── barbers.html ─────────────────────────────
def perk(icon, uz, ru, en, puz, pru, pen):
    return f'<li class="perk reveal"><span class="perk-ic" aria-hidden="true">{icon}</span><h3>{T(uz, ru, en)}</h3><p>{T(puz, pru, pen)}</p></li>'


BARBERS = f'''
<section class="hero wrap">
  <div class="hero-copy">
    <p class="eyebrow rise" style="--d:0">{T("Sartaroshlar va sartaroshxonalar uchun", "Для барберов и барбершопов", "For barbers and barbershops")}</p>
    <h1 class="rise" style="--d:1">{T("Bo‘sh kreslo —<br><em>yo‘qotilgan pul.</em>", "Пустое кресло —<br><em>потерянные деньги.</em>", "An empty chair<br><em>is lost money.</em>")}</h1>
    <p class="lead rise" style="--d:2">{T("Fade yaqin atrofdagi mijozlarga sizni xaritada ko‘rsatadi va ular bo‘sh soatlaringizga o‘zlari yoziladi. Qo‘ng‘iroqlarsiz, daftarsiz.",
        "Fade показывает вас клиентам поблизости на карте, и они сами записываются в ваши свободные часы. Без звонков и блокнота.",
        "Fade puts you on the map for clients nearby, and they book your free hours themselves. No calls, no notebook.")}</p>
    <div class="cta-row rise" style="--d:3">
      {play_btn()}
      <a class="btn btn-ghost" href="mailto:{EMAIL}?subject=Fade%20%E2%80%94%20barbershop">{T("Bizga yozing", "Написать нам", "Contact us")} <span aria-hidden="true">→</span></a>
    </div>
    <ul class="ticks rise" style="--d:4">
      <li>{T("Ro‘yxatdan o‘tish bepul", "Регистрация бесплатна", "Free to join")}</li>
      <li>{T("Telefoningizdan boshqarasiz", "Всё с телефона", "Run it from your phone")}</li>
    </ul>
  </div>
  <div class="hero-art">
    <div class="phone tilt">{shot("barber", "Fade for barbers", eager=True)}</div>
    <img class="sticker s-chair float" src="assets/cuts.webp" alt="" width="240" height="180">
    <div class="ticket pop">
      <div class="ticket-top"><span class="dot"></span>{T("Yangi so‘rov", "Новая заявка", "New request")}</div>
      <b>{T("Bugun · 18:00", "Сегодня · 18:00", "Today · 18:00")}</b>
      <span class="muted">{T("Qabul qilish — bir tegish", "Принять — одно касание", "Accept in one tap")}</span>
    </div>
  </div>
</section>

{PERF}

<section class="wrap section">
  <p class="kicker reveal">{T("Nimalar beradi", "Что вы получаете", "What you get")}</p>
  <h2 class="reveal">{T("Ish kuningiz — tartibda.", "Рабочий день — под контролем.", "Your day, under control.")}</h2>
  <ul class="perks">
    {perk("📍", "Xaritada ko‘rinasiz", "Вас видно на карте", "You're on the map",
          "Yaqin atrofdagi mijozlar sizni topadi — narxlaringiz va ishlaringiz bilan.", "Клиенты рядом находят вас — с ценами и работами.", "Clients nearby find you, with your prices and your work.")}
    {perk("⚡", "So‘rovlar bir tegishda", "Заявки в одно касание", "One-tap requests",
          "Yangi yozuvni qabul qiling yoki boshqa vaqt taklif qiling.", "Примите запись или предложите другое время.", "Accept a booking or suggest another time.")}
    {perk("🗓", "Jadval ko‘z oldida", "Расписание перед глазами", "Your schedule at a glance",
          "Bugungi mijozlar, bo‘sh soatlar va kutilayotgan daromad.", "Клиенты на сегодня, свободные часы и ожидаемый доход.", "Today's clients, free hours and expected earnings.")}
    {perk("▣", "QR orqali kelishni belgilash", "Отметка прихода по QR", "QR arrival check-in",
          "Mijoz kelganda plakatingizdagi QR’ni skanerlaydi — kim kelgani aniq.", "Клиент сканирует QR на вашем постере — видно, кто пришёл.", "Clients scan the QR on your poster, so you know who actually showed up.")}
    {perk("★", "Sharhlar sizniki", "Отзывы — ваши", "Reviews that are yours",
          "Haqiqiy tashriflardan keyingi sharhlar sizning profilingizga yoziladi.", "Отзывы после реальных визитов пишутся в ваш профиль.", "Reviews from real visits are written to your own profile.")}
    {perk("✂", "Doimiy mijozlar", "Постоянные клиенты", "Regulars come back",
          "Mijoz bir tegishda “odatdagisini” qayta band qiladi.", "Клиент повторяет «как обычно» в одно касание.", "Clients rebook “the usual” in one tap.")}
  </ul>
</section>

<section class="wrap section split">
  <div class="phone sm reveal">{shot("requests", "Requests")}</div>
  <div class="reveal">
    <p class="kicker">{T("Qanday qo‘shilish", "Как подключиться", "How to join")}</p>
    <h2>{T("5 daqiqada ishga tushasiz.", "Запуск за 5 минут.", "Live in five minutes.")}</h2>
    <ol class="join">
      <li>{T("Fade’ni Google Play’dan o‘rnating va ro‘yxatdan o‘ting.", "Установите Fade из Google Play и зарегистрируйтесь.", "Install Fade from Google Play and sign up.")}</li>
      <li>{T("<b>Profil → Barber bo‘ling</b> ni bosing.", "Нажмите <b>Профиль → Стать барбером</b>.", "Tap <b>Profile → Become a barber</b>.")}</li>
      <li>{T("Sartaroshxonangizni toping — yo‘q bo‘lsa, xaritada o‘zingiz qo‘shing.", "Найдите свой барбершоп — если его нет, добавьте сами на карте.", "Find your shop — if it isn't there yet, add it on the map yourself.")}</li>
      <li>{T("Xizmatlar va narxlarni kiriting, hamkasblarni havola orqali taklif qiling.", "Добавьте услуги и цены, пригласите коллег по ссылке.", "Add your services and prices, and invite colleagues with a link.")}</li>
    </ol>
    {play_btn()}
  </div>
</section>

<section id="faq" class="wrap section narrow">
  <p class="kicker reveal">{T("Savollar", "Вопросы", "FAQ")}</p>
  <h2 class="reveal">{T("Sartaroshlar so‘raydi.", "Барберы спрашивают.", "Barbers ask.")}</h2>
  {faq([
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
  ])}
</section>

<section class="wrap final reveal">
  <h2>{T("Kreslongiz bo‘sh turmasin.", "Пусть кресло не простаивает.", "Keep your chair busy.")}</h2>
  {play_btn()}
</section>
'''

CSS = r'''
:root{--bg:#f5f2eb;--paper:#fffdf8;--ink:#14161a;--sub:#5f6670;--line:#e4ded2;--accent:#2e8bff;--deep:#165cd6;--tint:#e6f0ff;--gold:#ffd66b;--shadow:0 30px 60px -28px rgba(20,30,60,.35)}
@media (prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#0e1114;--paper:#161a20;--ink:#eef0f3;--sub:#9aa3ae;--line:#262c34;--accent:#4a9bff;--deep:#2e7bf0;--tint:#132338;--shadow:0 30px 60px -28px rgba(0,0,0,.7)}}
:root[data-theme=dark]{--bg:#0e1114;--paper:#161a20;--ink:#eef0f3;--sub:#9aa3ae;--line:#262c34;--accent:#4a9bff;--deep:#2e7bf0;--tint:#132338;--shadow:0 30px 60px -28px rgba(0,0,0,.7)}
*{box-sizing:border-box}html{scroll-behavior:smooth;-webkit-text-size-adjust:100%}
body{margin:0;background:var(--bg);color:var(--ink);font:500 17px/1.6 Nunito,system-ui,sans-serif;overflow-x:hidden}
body::before{content:"";position:fixed;inset:0;pointer-events:none;z-index:-1;opacity:.5;
 background-image:radial-gradient(circle at 1px 1px,color-mix(in srgb,var(--ink) 9%,transparent) 1px,transparent 0);background-size:22px 22px}
img{max-width:100%;display:block}a{color:var(--accent)}
body.uz [data-l]:not([data-l=uz]),body.ru [data-l]:not([data-l=ru]),body.en [data-l]:not([data-l=en]){display:none!important}
.wrap{max-width:1160px;margin:0 auto;padding:0 20px}.narrow{max-width:820px}
.muted{color:var(--sub)}
/* header */
.top{position:sticky;top:0;z-index:20;background:color-mix(in srgb,var(--bg) 82%,transparent);backdrop-filter:saturate(1.4) blur(14px);-webkit-backdrop-filter:saturate(1.4) blur(14px);border-bottom:1px solid color-mix(in srgb,var(--line) 70%,transparent)}
.top-in{max-width:1160px;margin:0 auto;padding:12px 20px;display:flex;align-items:center;gap:18px}
.logo{display:flex;align-items:center;gap:10px;font-weight:900;font-size:22px;color:var(--ink);text-decoration:none;letter-spacing:-.02em}
.logo img{border-radius:10px}
.links{display:flex;gap:22px;margin-left:12px}
.links a{color:var(--sub);text-decoration:none;font-weight:800;font-size:15px}.links a:hover,.links a[aria-current]{color:var(--ink)}
.langs{margin-left:auto;display:flex;background:var(--paper);border:1px solid var(--line);border-radius:999px;padding:3px}
.langs button{border:0;background:none;color:var(--sub);border-radius:999px;padding:5px 10px;font:800 12.5px Nunito,sans-serif;cursor:pointer}
.langs button.on{background:var(--ink);color:var(--bg)}
/* buttons */
.btn{display:inline-flex;align-items:center;gap:10px;border-radius:16px;padding:14px 22px;font-weight:900;font-size:16px;text-decoration:none;background:var(--accent);color:#fff;
 transition:transform .18s cubic-bezier(.25,1,.5,1),box-shadow .18s,background .18s;box-shadow:0 10px 24px -12px color-mix(in srgb,var(--accent) 80%,transparent)}
.btn:hover{transform:translateY(-2px);background:var(--deep)}.btn:active{transform:translateY(0) scale(.98)}
.btn-sm{padding:9px 16px;font-size:14px;border-radius:12px}
.btn-play{background:var(--ink);color:var(--bg);padding:11px 22px 11px 18px;box-shadow:var(--shadow)}.btn-play:hover{background:var(--ink)}
.btn-stack{display:flex;flex-direction:column;line-height:1.1;text-align:left}.btn-stack small{font-size:11.5px;font-weight:700;opacity:.75}.btn-stack b{font-size:19px;font-weight:900;letter-spacing:-.01em}
.btn-ghost{background:transparent;color:var(--ink);box-shadow:inset 0 0 0 2px var(--line)}.btn-ghost:hover{background:var(--paper)}
/* hero */
.hero{display:grid;grid-template-columns:1.1fr .9fr;gap:40px;align-items:center;padding-top:56px;padding-bottom:40px}
.eyebrow{display:inline-block;background:var(--tint);color:var(--deep);font-weight:900;font-size:13.5px;letter-spacing:.02em;border-radius:999px;padding:7px 14px;margin:0 0 18px}
:root[data-theme=dark] .eyebrow{color:var(--accent)}
h1{font-size:clamp(42px,6.6vw,84px);line-height:.98;letter-spacing:-.035em;font-weight:900;margin:0 0 22px}
h1 em{font-style:normal;color:var(--accent);position:relative;white-space:nowrap;isolation:isolate}
h1 em::after{content:"";position:absolute;left:2%;right:4%;bottom:-.04em;height:.16em;border-radius:99px;background:var(--gold);z-index:-1;transform-origin:left;animation:swipe .9s .7s cubic-bezier(.22,1,.36,1) both}
h2{font-size:clamp(30px,4.2vw,52px);line-height:1.04;letter-spacing:-.03em;font-weight:900;margin:0 0 28px}
h3{font-size:20px;font-weight:900;margin:0 0 6px;letter-spacing:-.01em}
.lead{font-size:clamp(17px,1.6vw,20px);color:var(--sub);max-width:34em;margin:0 0 28px}
.cta-row{display:flex;gap:12px;flex-wrap:wrap;align-items:center}
.ticks{list-style:none;padding:0;margin:26px 0 0;display:flex;flex-wrap:wrap;gap:8px 20px;color:var(--sub);font-weight:800;font-size:14.5px}
.ticks li::before{content:"✓";color:var(--accent);margin-right:7px;font-weight:900}
.hero-art{position:relative;display:grid;place-items:center;min-height:560px}
.phone{position:relative;width:290px;border-radius:44px;padding:9px;background:#0d0f13;box-shadow:var(--shadow),inset 0 0 0 1.5px #3a404b}
.phone img{border-radius:36px;width:100%;height:auto;aspect-ratio:9/16;object-fit:cover}
.phone.sm{width:240px;border-radius:38px;padding:8px}.phone.sm img{border-radius:31px}
.tilt{transform:rotate(-4deg)}
.sticker{position:absolute;filter:drop-shadow(0 18px 24px rgba(20,30,60,.22))}
.s-star{width:150px;top:2%;right:-2%}.s-pin{width:150px;bottom:6%;left:-4%}.s-chair{width:210px;bottom:4%;left:-10%}
.ticket{position:absolute;right:-4%;bottom:16%;background:var(--paper);border-radius:18px;padding:14px 18px;box-shadow:var(--shadow);display:flex;flex-direction:column;min-width:190px;
 border:1px solid var(--line);-webkit-mask:radial-gradient(circle 9px at 0 50%,transparent 98%,#000) left/51% 100% no-repeat,radial-gradient(circle 9px at 100% 50%,transparent 98%,#000) right/51% 100% no-repeat;
 mask:radial-gradient(circle 9px at 0 50%,transparent 98%,#000) left/51% 100% no-repeat,radial-gradient(circle 9px at 100% 50%,transparent 98%,#000) right/51% 100% no-repeat}
.ticket b{font-size:21px;font-weight:900;letter-spacing:-.01em}.ticket .muted{font-size:14px;font-weight:700}
.ticket-top{display:flex;align-items:center;gap:7px;font-size:12.5px;font-weight:900;color:#16a34a;text-transform:uppercase;letter-spacing:.06em;margin-bottom:2px}
.dot{width:8px;height:8px;border-radius:50%;background:#22c55e;box-shadow:0 0 0 4px color-mix(in srgb,#22c55e 25%,transparent)}
/* perforation divider */
.perf{max-width:1160px;margin:10px auto;padding:0 20px}.perf span{display:block;height:2px;background:repeating-linear-gradient(90deg,var(--line) 0 10px,transparent 10px 20px)}
.section{padding-top:84px;padding-bottom:20px}
.kicker{font-size:13.5px;font-weight:900;text-transform:uppercase;letter-spacing:.12em;color:var(--accent);margin:0 0 12px}.kicker.light{color:#bcd8ff}
/* steps */
.steps{list-style:none;padding:0;margin:0;display:grid;grid-template-columns:repeat(3,1fr);gap:18px}
.step{position:relative;background:var(--paper);border:1px solid var(--line);border-radius:26px;padding:26px 24px 28px;overflow:hidden;transition:transform .25s cubic-bezier(.25,1,.5,1)}
.step:hover{transform:translateY(-4px)}
.step img{width:110px;height:110px;object-fit:contain;margin:0 0 16px}
.step .num{position:absolute;top:18px;right:22px;font-size:46px;font-weight:900;color:color-mix(in srgb,var(--ink) 7%,transparent);letter-spacing:-.04em}
.step p{color:var(--sub);margin:0}
/* AI band */
.ai-band{margin-top:90px;background:linear-gradient(135deg,#1b6fe8,#0f3fa8);color:#fff;position:relative;overflow:hidden}
.ai-band::after{content:"";position:absolute;inset:0;background:radial-gradient(600px 300px at 80% 30%,rgba(255,255,255,.18),transparent 70%)}
.ai-in{display:grid;grid-template-columns:1.2fr .8fr;align-items:center;gap:30px;padding-top:80px;padding-bottom:80px;position:relative;z-index:1}
.ai-in p{color:#dbe9ff;font-size:19px;max-width:32em}.ai-in h2{color:#fff}
.ai-star{width:300px;justify-self:center;filter:drop-shadow(0 30px 40px rgba(0,0,0,.35))}
/* gallery */
.gallery{display:flex;gap:26px;overflow-x:auto;scroll-snap-type:x mandatory;padding:10px 4px 26px;margin:0 -4px;scrollbar-width:thin}
.gallery figure{margin:0;scroll-snap-align:start;flex:0 0 auto;display:flex;flex-direction:column;align-items:center;gap:14px}
.gallery figcaption{font-weight:900;color:var(--sub);font-size:15px}
/* punch card */
.punch-sec{display:grid;grid-template-columns:1fr 1fr;gap:40px;align-items:center}
.punch{background:var(--paper);border:1px solid var(--line);border-radius:28px;padding:26px;box-shadow:var(--shadow);transform:rotate(2deg)}
.punch-head{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:20px}.punch-head b{font-size:26px;font-weight:900;color:var(--accent)}.punch-head span{color:var(--sub);font-weight:800;font-size:14px}
.holes{display:grid;grid-template-columns:repeat(8,1fr);gap:12px}
.holes i{aspect-ratio:1;border-radius:50%;border:2px dashed var(--line);display:block;position:relative}
.holes i::after{content:"";position:absolute;inset:3px;border-radius:50%;background:var(--accent);transform:scale(0);transition:transform .45s cubic-bezier(.22,1,.36,1);transition-delay:calc(var(--i)*70ms)}
.punch.in .holes i:nth-child(-n+11)::after{transform:scale(1)}
.holes i:last-child{border-color:var(--gold);border-style:solid}
.punch-foot{margin-top:20px;padding-top:16px;border-top:2px dashed var(--line);font-weight:900;display:flex;justify-content:space-between}
/* barber band */
.barber-band{margin-top:90px;display:grid;grid-template-columns:1fr auto;align-items:end;gap:20px;position:relative;overflow:hidden;border-radius:32px;padding:46px 40px;background:var(--ink);color:var(--bg);text-decoration:none;transition:transform .25s cubic-bezier(.25,1,.5,1)}
.barber-band:hover{transform:translateY(-3px)}
.barber-band h2{margin:0;max-width:13em;color:var(--bg)}
.barber-band img{position:absolute;right:170px;top:-10px;width:230px;opacity:.95;pointer-events:none}
.band-go{background:var(--accent);color:#fff;font-weight:900;border-radius:14px;padding:13px 20px;position:relative;z-index:1;white-space:nowrap}
/* perks */
.perks{list-style:none;padding:0;margin:0;display:grid;grid-template-columns:repeat(3,1fr);gap:16px}
.perk{background:var(--paper);border:1px solid var(--line);border-radius:24px;padding:24px}
.perk p{color:var(--sub);margin:0}
.perk-ic{display:grid;place-items:center;width:46px;height:46px;border-radius:14px;background:var(--tint);color:var(--accent);font-size:22px;font-weight:900;margin-bottom:16px}
.split{display:grid;grid-template-columns:auto 1fr;gap:60px;align-items:center}
.join{padding-left:0;list-style:none;counter-reset:j;margin:0 0 28px}
.join li{counter-increment:j;position:relative;padding:12px 0 12px 54px;border-bottom:1px dashed var(--line);font-size:17.5px}
.join li::before{content:counter(j);position:absolute;left:0;top:10px;width:36px;height:36px;border-radius:12px;background:var(--ink);color:var(--bg);display:grid;place-items:center;font-weight:900}
/* faq */
.qa{background:var(--paper);border:1px solid var(--line);border-radius:20px;margin:0 0 10px;overflow:hidden}
.qa summary{list-style:none;cursor:pointer;padding:20px 22px;font-weight:900;font-size:18px;display:flex;justify-content:space-between;gap:16px;align-items:center}
.qa summary::-webkit-details-marker{display:none}
.qa summary i{flex:0 0 28px;height:28px;border-radius:50%;background:var(--tint);position:relative;transition:transform .3s cubic-bezier(.25,1,.5,1)}
.qa summary i::before,.qa summary i::after{content:"";position:absolute;left:8px;right:8px;top:13px;height:2px;background:var(--accent);border-radius:2px}
.qa summary i::after{transform:rotate(90deg)}.qa[open] summary i{transform:rotate(45deg)}
.qa-a{padding:0 22px 20px;color:var(--sub)}
/* final + footer */
.final{text-align:center;padding-top:100px;padding-bottom:100px;display:flex;flex-direction:column;align-items:center}
.final h2{max-width:16em}
.foot{border-top:1px solid var(--line);padding:48px 0 30px;background:var(--paper)}
.foot-in{display:grid;grid-template-columns:1.4fr 1fr 1fr 1.3fr;gap:30px}
.foot-col{display:flex;flex-direction:column;gap:8px;font-size:15px}.foot-col b{font-weight:900;margin-bottom:4px}
.foot-col a{color:var(--sub);text-decoration:none;overflow-wrap:anywhere}.foot-col a:hover{color:var(--accent)}
.legal-line{margin-top:30px;font-size:14px}
/* motion */
@keyframes rise{from{opacity:0;transform:translateY(18px)}to{opacity:1;transform:none}}
@keyframes swipe{from{transform:scaleX(0)}to{transform:scaleX(1)}}
@keyframes float{0%,100%{transform:translateY(0) rotate(0)}50%{transform:translateY(-12px) rotate(4deg)}}
@keyframes pop{from{opacity:0;transform:translateY(16px) scale(.94)}to{opacity:1;transform:none}}
.rise{animation:rise .8s calc(var(--d)*90ms + 80ms) cubic-bezier(.22,1,.36,1) both}
.float{animation:float 6s ease-in-out infinite}.float2{animation:float 7s 1s ease-in-out infinite}
.pop{animation:pop .7s .9s cubic-bezier(.22,1,.36,1) both}
.reveal{opacity:0;transform:translateY(22px);transition:opacity .7s cubic-bezier(.22,1,.36,1),transform .7s cubic-bezier(.22,1,.36,1)}
.reveal.in{opacity:1;transform:none}.punch.reveal.in{transform:rotate(2deg)}
.no-js .reveal{opacity:1;transform:none}
@media (prefers-reduced-motion:reduce){*,*::before,*::after{animation:none!important;transition:none!important}.reveal{opacity:1;transform:none}.holes i::after{transform:scale(1)}}
/* responsive */
@media (max-width:960px){
 .hero,.ai-in,.punch-sec,.split{grid-template-columns:1fr}
 .hero{padding-top:34px;gap:10px}.hero-art{min-height:520px}
 .steps,.perks{grid-template-columns:1fr 1fr}
 .split .phone{justify-self:center;order:2}
 .foot-in{grid-template-columns:1fr 1fr}
 .barber-band img{display:none}
}
@media (max-width:640px){
 .links{display:none}.top-in{gap:10px;padding:10px 16px}.wrap{padding:0 16px}.btn-sm{padding:8px 12px}
 .steps,.perks{grid-template-columns:1fr}
 .hero-art{min-height:470px}.phone{width:236px;border-radius:38px}.phone img{border-radius:30px}
 .s-star,.s-pin{width:96px}.s-pin{left:0}.s-chair{width:150px;left:-2%}
 .ticket{right:0;bottom:8%;min-width:0;padding:12px 16px}.ticket b{font-size:18px}
 .ai-star{width:200px}.barber-band{grid-template-columns:1fr;padding:34px 24px}
 .section{padding-top:64px}.foot-in{grid-template-columns:1fr}
 .holes{gap:8px}.punch{transform:none}.punch.reveal.in{transform:none}
}
'''

JS = r'''(function(){
var ok=['uz','ru','en'],P=new URLSearchParams(location.search),l=P.get('lang');
try{if(ok.indexOf(l)<0)l=localStorage.getItem('fade-lang')}catch(e){}
if(ok.indexOf(l)<0){var n=(navigator.language||'').slice(0,2);l=n==='ru'?'ru':n==='en'?'en':'uz'}
var titles={uz:document.title,ru:document.title,en:document.title};
function set(x){document.body.className=x;document.documentElement.lang=x;
 document.querySelectorAll('.langs button').forEach(function(b){b.classList.toggle('on',b.dataset.set===x);b.setAttribute('aria-pressed',b.dataset.set===x)});
 try{localStorage.setItem('fade-lang',x)}catch(e){}}
document.querySelectorAll('.langs button').forEach(function(b){b.onclick=function(){set(b.dataset.set)}});set(l);
var els=document.querySelectorAll('.reveal');
if(!('IntersectionObserver' in window)){els.forEach(function(e){e.classList.add('in')});return}
var io=new IntersectionObserver(function(es){es.forEach(function(e){if(e.isIntersecting){e.target.classList.add('in');io.unobserve(e.target)}})},{threshold:.15,rootMargin:'0px 0px -40px 0px'});
els.forEach(function(e){io.observe(e)});
})();'''

io.open(f"{OUT}/site.css", "w", encoding="utf-8", newline="\n").write(CSS.strip() + "\n")
io.open(f"{OUT}/site.js", "w", encoding="utf-8", newline="\n").write(JS + "\n")
io.open(f"{OUT}/index.html", "w", encoding="utf-8", newline="\n").write(doc(
    "Fade — sartaroshga onlayn navbat, Toshkent",
    "Toshkent sartaroshxonalariga bir tegishda yoziling: xarita, narxlar, sharhlar va AI turmak sinash.",
    "og-home.jpg", HOME, "home"))
io.open(f"{OUT}/barbers.html", "w", encoding="utf-8", newline="\n").write(doc(
    "Fade sartaroshlar uchun — bo‘sh kreslo bo‘lmasin",
    "Yaqin atrofdagi mijozlar sizni xaritada topadi va bo‘sh soatlaringizga o‘zlari yoziladi. Ro‘yxatdan o‘tish bepul.",
    "og-home.jpg", BARBERS, "barbers"))
print("ok")
