"""Landing pages for the links the app shares: /i/?c= (friend invite),
/b/?h= (barber booking), /join/?s= (shop roster invite), plus a 404 router
that turns path-style links (/i/CODE, /b/handle) into the query form."""
import io, os, shutil, sys

OUT, ICON = sys.argv[1], sys.argv[2]
SITE = "https://thedarkknightmg.github.io/Fade"
PLAY = "https://play.google.com/store/apps/details?id=uz.fade.app"

CSS = """
:root{--bg:#f6f7f9;--card:#fff;--ink:#121417;--sub:#5d6470;--line:#e3e6eb;--accent:#2e8bff;--tint:#eaf3ff}
@media (prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#0d1117;--card:#161b22;--ink:#e8ebf0;--sub:#9aa3af;--line:#262d36;--accent:#58a6ff;--tint:#13233a}}
:root[data-theme=dark]{--bg:#0d1117;--card:#161b22;--ink:#e8ebf0;--sub:#9aa3af;--line:#262d36;--accent:#58a6ff;--tint:#13233a}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.6 Nunito,system-ui,sans-serif}
.wrap{max-width:520px;margin:0 auto;padding:24px 16px 56px}
header{display:flex;align-items:center;gap:12px;flex-wrap:wrap;margin-bottom:20px}
.logo{display:flex;align-items:center;gap:10px;font-weight:900;font-size:22px;color:var(--ink);text-decoration:none}
.logo img{width:38px;height:38px;border-radius:11px}
.langs{margin-left:auto;display:flex;gap:6px}
.langs button{border:1px solid var(--line);background:var(--card);color:var(--sub);border-radius:999px;padding:6px 11px;font:700 13px Nunito,sans-serif;cursor:pointer}
.langs button.on{background:var(--accent);border-color:var(--accent);color:#fff}
.card{background:var(--card);border:1px solid var(--line);border-radius:22px;padding:28px 22px;overflow-wrap:anywhere}
h1{font-size:27px;line-height:1.2;margin:0 0 8px;font-weight:900}
.lead{color:var(--sub);margin:0 0 20px}
.code{display:flex;align-items:center;justify-content:space-between;gap:12px;background:var(--tint);border-radius:16px;padding:14px 16px;margin:0 0 20px}
.code b{font-size:26px;font-weight:900;letter-spacing:2px}
.code button{border:0;background:var(--accent);color:#fff;border-radius:12px;padding:10px 14px;font:800 14px Nunito,sans-serif;cursor:pointer}
.cta{display:block;text-align:center;background:var(--accent);color:#fff;text-decoration:none;border-radius:16px;padding:16px;font-weight:900;font-size:17px;margin:0 0 22px}
ol{padding-left:22px;margin:0}li{margin:8px 0}
.note{color:var(--sub);font-size:13.5px;margin-top:22px}
[data-l]{display:none}body.uz [data-l=uz],body.ru [data-l=ru],body.en [data-l=en]{display:block}
"""

JS = """<script>
(function(){
var P=new URLSearchParams(location.search);
var val=(P.get('%(param)s')||'').trim().slice(0,64);
document.querySelectorAll('[data-v]').forEach(function(e){e.textContent=val?(%(fmt)s):''});
document.querySelectorAll('[data-if-v]').forEach(function(e){if(!val)e.style.display='none'});
document.querySelectorAll('[data-copy]').forEach(function(b){b.onclick=function(){
 var t=b.textContent;function ok(){b.textContent=b.dataset.done;setTimeout(function(){b.textContent=t},1600)}
 if(navigator.clipboard)navigator.clipboard.writeText(val).then(ok,function(){});else{var i=document.createElement('input');i.value=val;document.body.appendChild(i);i.select();try{document.execCommand('copy');ok()}catch(e){}i.remove()}}});
var ok=['uz','ru','en'],l=P.get('lang');
try{if(ok.indexOf(l)<0)l=localStorage.getItem('fade-lang')}catch(e){}
if(ok.indexOf(l)<0){var n=(navigator.language||'').slice(0,2);l=n==='ru'?'ru':n==='en'?'en':'uz'}
function set(x){document.body.className=x;document.documentElement.lang=x;
 document.querySelectorAll('.langs button').forEach(function(b){b.classList.toggle('on',b.dataset.set===x)});
 try{localStorage.setItem('fade-lang',x)}catch(e){}}
document.querySelectorAll('.langs button').forEach(function(b){b.onclick=function(){set(b.dataset.set)}});set(l)})();
</script>"""

NOTE = {
    "uz": "Play’da ilova topilmasa — Fade hozir sinov bosqichida. Havolani yuborgan odamdan taklif so‘rang.",
    "ru": "Если Play пишет, что приложение недоступно, — Fade сейчас в тестировании. Попросите приглашение у того, кто прислал ссылку.",
    "en": "If Play says the app isn't available, Fade is still in testing. Ask whoever sent you this link for an invite.",
}
GET = {"uz": "Fade’ni yuklab olish", "ru": "Скачать Fade", "en": "Get Fade"}
COPY = {"uz": ("Nusxa olish", "Nusxa olindi"), "ru": ("Скопировать", "Скопировано"), "en": ("Copy", "Copied")}

PAGES = {
    "i": dict(param="c", fmt="val",
              og=("Do‘stingiz sizni Fade’ga taklif qildi", "Toshkent sartaroshlariga bir tegishda navbat. Taklif kodingiz ichkarida."),
              title={"uz": "Do‘stingiz sizni Fade’ga taklif qildi",
                     "ru": "Друг приглашает вас в Fade",
                     "en": "A friend invited you to Fade"},
              lead={"uz": "Toshkentdagi sartaroshxonalarga bir tegishda navbat oling.",
                    "ru": "Запись в барбершопы Ташкента в одно нажатие.",
                    "en": "Book Tashkent barbers in one tap."},
              code=True,
              steps={"uz": ["Fade’ni o‘rnating va ro‘yxatdan o‘ting.",
                            "<b>Sozlamalar → Do‘stlarni taklif qiling</b> bo‘limini oching.",
                            "<b>Do‘st kodi bormi?</b> maydoniga kodni kiriting va <b>Qo‘llash</b>ni bosing."],
                     "ru": ["Установите Fade и зарегистрируйтесь.",
                            "Откройте <b>Настройки → Пригласить друзей</b>.",
                            "В поле <b>Есть код друга?</b> вставьте код и нажмите <b>Применить</b>."],
                     "en": ["Install Fade and sign up.",
                            "Open <b>Settings → Invite friends &amp; earn</b>.",
                            "Under <b>Have a friend's code?</b> paste the code and tap <b>Apply</b>."]}),
    "b": dict(param="h", fmt="val.charAt(0).toUpperCase()+val.slice(1)",
              og=("Fade orqali sartaroshga yoziling", "Bo‘sh vaqtni tanlang — navbatsiz, qo‘ng‘iroqsiz."),
              title={"uz": "<span data-v></span> bilan soch oldirish",
                     "ru": "Запись к барберу <span data-v></span>",
                     "en": "Book a cut with <span data-v></span>"},
              lead={"uz": "Bo‘sh vaqtni Fade’da tanlang — qo‘ng‘iroqsiz, navbatsiz.",
                    "ru": "Выберите свободное время в Fade — без звонков и очередей.",
                    "en": "Pick a free slot in Fade — no calls, no queue."},
              code=False,
              steps={"uz": ["Fade’ni o‘rnating va oching.",
                            "Sartaroshxonani qidiruv yoki xaritadan toping.",
                            "Yoki sartaroshdagi QR kodni <b>Profil → Barberni skanerlash</b> orqali skanerlang."],
                     "ru": ["Установите и откройте Fade.",
                            "Найдите барбершоп через поиск или на карте.",
                            "Или отсканируйте QR-код барбера: <b>Профиль → Сканировать барбера</b>."],
                     "en": ["Install and open Fade.",
                            "Find the shop by search or on the map.",
                            "Or scan the barber's QR code: <b>Profile → Scan a barber</b>."]}),
    "join": dict(param="s", fmt="val",
                 og=("Sartaroshxonangizga Fade’da qo‘shiling", "Mijozlar sizni ro‘yxatda ko‘rib, to‘g‘ridan-to‘g‘ri yozilishadi."),
                 title={"uz": "Sartaroshxonangiz Fade’da",
                        "ru": "Ваш барбершоп уже в Fade",
                        "en": "Your shop is on Fade"},
                 lead={"uz": "Hamkasbingiz sizni ro‘yxatga taklif qildi — mijozlar sizga to‘g‘ridan-to‘g‘ri yozilishi uchun.",
                       "ru": "Коллега приглашает вас в состав — чтобы клиенты записывались прямо к вам.",
                       "en": "A colleague invited you to the roster, so clients can book you directly."},
                 code=False,
                 steps={"uz": ["Fade’ni o‘rnating va ro‘yxatdan o‘ting.",
                               "<b>Profil → Barber bo‘ling</b> ni bosing.",
                               "Sartaroshxonangizni toping va unga qo‘shiling."],
                        "ru": ["Установите Fade и зарегистрируйтесь.",
                               "Нажмите <b>Профиль → Стать барбером</b>.",
                               "Найдите свой барбершоп и присоединитесь."],
                        "en": ["Install Fade and sign up.",
                               "Tap <b>Profile → Become a barber</b>.",
                               "Find your shop and join it."]}),
}


def page(key, p):
    langs = "".join(f'<button data-set="{c}">{n}</button>' for c, n in (("uz", "UZ"), ("ru", "RU"), ("en", "EN")))
    body = []
    for c in ("uz", "ru", "en"):
        code = ""
        if p["code"]:
            code = (f'<div class="code" data-if-v><b data-v></b>'
                    f'<button data-copy data-done="{COPY[c][1]}">{COPY[c][0]}</button></div>')
        steps = "".join(f"<li>{s}</li>" for s in p["steps"][c])
        body.append(f'<div data-l="{c}"><h1>{p["title"][c]}</h1><p class="lead">{p["lead"][c]}</p>{code}'
                    f'<a class="cta" href="{PLAY}">{GET[c]}</a><ol>{steps}</ol>'
                    f'<p class="note">{NOTE[c]}</p></div>')
    t, d = p["og"]
    return (f'<!doctype html><html lang="uz"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width,initial-scale=1">'
            f'<title>Fade</title><meta name="description" content="{d}">'
            f'<meta property="og:title" content="{t}"><meta property="og:description" content="{d}">'
            f'<meta property="og:image" content="{SITE}/og.png"><meta property="og:type" content="website">'
            f'<meta name="twitter:card" content="summary">'
            f'<link rel="icon" href="../og.png">'
            f'<link rel="preconnect" href="https://fonts.googleapis.com">'
            f'<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;700;800;900&display=swap" rel="stylesheet">'
            f'<style>{CSS}</style></head><body class="uz"><div class="wrap">'
            f'<header><a class="logo" href="../index.html"><img src="../og.png" alt="">Fade</a>'
            f'<div class="langs">{langs}</div></header>'
            f'<main class="card">{"".join(body)}</main></div>'
            f'{JS % dict(param=p["param"], fmt=p["fmt"])}</body></html>')


for key, p in PAGES.items():
    os.makedirs(f"{OUT}/{key}", exist_ok=True)
    io.open(f"{OUT}/{key}/index.html", "w", encoding="utf-8", newline="\n").write(page(key, p))
shutil.copy(ICON, f"{OUT}/og.png")

# Path-style links (/Fade/i/CODE, /Fade/b/handle, /Fade/join/ID) land on
# GitHub's 404 page — route them to the query form instead.
ROUTER = """<!doctype html><html><head><meta charset="utf-8"><title>Fade</title><script>
(function(){var base=location.pathname.indexOf('/Fade/')===0?'/Fade/':'/';
var m=location.pathname.match(/\/(i|b|join)\/([^\/?#]+)/);
var q={i:'c',b:'h',join:'s'};
location.replace(m?base+m[1]+'/?'+q[m[1]]+'='+m[2]:base);})();
</script></head><body></body></html>"""
io.open(f"{OUT}/404.html", "w", encoding="utf-8", newline="\n").write(ROUTER)
print("ok")
