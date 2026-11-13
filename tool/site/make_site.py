"""Builds the public legal site (GitHub Pages) from assets/legal/legal.json."""
import html, io, json, re, sys
ROOT, OUT = sys.argv[1], sys.argv[2]
d = json.load(io.open(ROOT + "/assets/legal/legal.json", encoding="utf-8"))
EMAIL = "fade.privacy.uz@gmail.com"
LANGS = [("uz", "O‘zbekcha"), ("ru", "Русский"), ("en", "English")]


def md(s):
    s = html.escape(s, quote=False)
    s = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", s)
    return s.replace(EMAIL, f'<a href="mailto:{EMAIL}">{EMAIL}</a>')


CSS = """
:root{--bg:#f6f7f9;--card:#fff;--ink:#121417;--sub:#5d6470;--line:#e3e6eb;--accent:#2e8bff;--tint:#eaf3ff}
@media (prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#0d1117;--card:#161b22;--ink:#e8ebf0;--sub:#9aa3af;--line:#262d36;--accent:#58a6ff;--tint:#13233a}}
:root[data-theme=dark]{--bg:#0d1117;--card:#161b22;--ink:#e8ebf0;--sub:#9aa3af;--line:#262d36;--accent:#58a6ff;--tint:#13233a}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.65 Nunito,system-ui,sans-serif}
.wrap{max-width:760px;margin:0 auto;padding:24px 16px 64px}
header{display:flex;align-items:center;gap:12px;flex-wrap:wrap;margin-bottom:20px}
.logo{display:flex;align-items:center;gap:10px;font-weight:900;font-size:22px;color:var(--ink);text-decoration:none}
.logo span{display:inline-grid;place-items:center;width:38px;height:38px;border-radius:11px;background:var(--accent);color:#fff;font-size:20px}
.langs{margin-left:auto;display:flex;gap:6px;flex-wrap:wrap}
.langs button{border:1px solid var(--line);background:var(--card);color:var(--sub);border-radius:999px;padding:6px 12px;font:700 13px Nunito,sans-serif;cursor:pointer}
.langs button.on{background:var(--accent);border-color:var(--accent);color:#fff}
.card{background:var(--card);border:1px solid var(--line);border-radius:20px;padding:28px 22px;overflow-wrap:anywhere}
h1{font-size:28px;line-height:1.2;margin:0 0 6px;font-weight:900}h2{font-size:19px;margin:28px 0 8px;font-weight:800}
.upd{color:var(--sub);font-size:14px;margin:0 0 18px}ul,ol{padding-left:22px}li{margin:6px 0}
a{color:var(--accent)}nav.foot{margin-top:24px;gap:16px;flex-wrap:wrap;font-size:14px}
.steps li{margin:10px 0}.note{background:var(--tint);border-radius:14px;padding:14px 16px}
[data-l]{display:none}body.uz [data-l=uz],body.ru [data-l=ru],body.en [data-l=en]{display:block}
body.uz nav[data-l=uz],body.ru nav[data-l=ru],body.en nav[data-l=en]{display:flex}
"""

JS = """
<script>
(function(){var ok=['uz','ru','en'];var q=new URLSearchParams(location.search).get('lang');var l=ok.indexOf(q)>=0?q:null;
try{if(!l)l=localStorage.getItem('fade-lang')}catch(e){}if(ok.indexOf(l)<0)l='uz';
function set(x){document.body.className=x;document.documentElement.lang=x;document.querySelectorAll('.langs button').forEach(function(b){b.classList.toggle('on',b.dataset.set===x)});try{localStorage.setItem('fade-lang',x)}catch(e){}}
document.querySelectorAll('.langs button').forEach(function(b){b.onclick=function(){set(b.dataset.set)}});set(l)})();
</script>"""

NAV = {
    "uz": [("index.html", "Bosh sahifa"), ("privacy.html", "Maxfiylik siyosati"),
           ("terms.html", "Foydalanish shartlari"), ("delete-account.html", "Hisobni o‘chirish")],
    "ru": [("index.html", "Главная"), ("privacy.html", "Политика конфиденциальности"),
           ("terms.html", "Условия использования"), ("delete-account.html", "Удаление аккаунта")],
    "en": [("index.html", "Home"), ("privacy.html", "Privacy Policy"),
           ("terms.html", "Terms of Use"), ("delete-account.html", "Delete account")],
}


def page(title, body):
    langs = "".join(f'<button data-set="{c}">{n}</button>' for c, n in LANGS)
    foot = "".join(
        f'<nav class="foot" data-l="{c}">' + "".join(f'<a href="{h}">{t}</a>' for h, t in NAV[c]) + "</nav>"
        for c, _ in LANGS)
    return (f'<!doctype html><html lang="uz"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width,initial-scale=1">'
            f'<title>{html.escape(title)}</title>'
            f'<link rel="preconnect" href="https://fonts.googleapis.com">'
            f'<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;700;800;900&display=swap" rel="stylesheet">'
            f'<style>{CSS}</style></head><body class="uz"><div class="wrap">'
            f'<header><a class="logo" href="index.html"><span>✂</span>Fade</a><div class="langs">{langs}</div></header>'
            f'<main class="card">{body}</main>{foot}</div>{JS}</body></html>')


UPD = {"uz": "Oxirgi yangilanish", "ru": "Последнее обновление", "en": "Last updated"}


def legal(key):
    doc = d[key]
    out = []
    for c, _ in LANGS:
        parts = [f'<div data-l="{c}"><h1>{html.escape(doc["title"][c])}</h1>',
                 f'<p class="upd">{UPD[c]}: {doc["updated"]}</p>',
                 f'<p>{md(doc["intro"][c])}</p>']
        for s in doc["sections"]:
            parts.append(f'<h2>{html.escape(s["title"][c])}</h2>')
            for b in s["blocks"]:
                if b["type"] == "p":
                    parts.append(f'<p>{md(b["text"][c])}</p>')
                else:
                    parts.append("<ul>" + "".join(f"<li>{md(i[c])}</li>" for i in b["items"]) + "</ul>")
        parts.append("</div>")
        out.append("".join(parts))
    return page(doc["title"]["en"] + " — Fade", "".join(out))


E = EMAIL
DELETE = {
    "uz": f"""<h1>Fade hisobini o‘chirish</h1><p class="upd">Fade ilovasi · ishlab chiquvchi: Fade</p>
<p>Hisobingizni va unga bog‘liq ma’lumotlarni istalgan vaqtda o‘chirishingiz mumkin.</p>
<h2>Ilova orqali (eng tez)</h2><ol class="steps"><li>Fade ilovasini oching va hisobingizga kiring.</li>
<li><strong>Profil → Sozlamalar</strong> bo‘limiga o‘ting.</li><li><strong>Hisobni o‘chirish</strong> tugmasini bosing va tasdiqlang.</li></ol>
<h2>Ilovasiz</h2><p><a href="mailto:{E}?subject=Fade%20hisobini%20o%E2%80%98chirish">{E}</a> manziliga “Hisobni o‘chirish” mavzusida xat yozing va hisobga bog‘langan telefon raqamini ko‘rsating. Shaxsingizni tasdiqlashni so‘rashimiz mumkin.</p>
<h2>Nima o‘chiriladi</h2><ul><li>Ism, telefon raqami, elektron pochta, profil surati</li>
<li>Navbatlar tarixi, xabarlar, sharhlar, saqlangan sartaroshxonalar, ballar</li>
<li>Sartaroshlar uchun: sartaroshxona profili, jadval, ish suratlari</li></ul>
<h2>Nima saqlanib qoladi va qancha vaqt</h2><p class="note">Ma’lumotlar asosiy tizimlardan odatda <strong>30 kun</strong> ichida o‘chiriladi. Zaxira nusxalarda qisqa muddat qolishi mumkin. Qonun talab qiladigan to‘lov va buxgalteriya yozuvlari (summa, sana, to‘lov holati) qonunda belgilangan muddat davomida saqlanadi. Shaxsni aniqlamaydigan umumlashtirilgan statistika saqlanishi mumkin.</p>""",
    "ru": f"""<h1>Удаление аккаунта Fade</h1><p class="upd">Приложение Fade · разработчик: Fade</p>
<p>Вы можете удалить аккаунт и связанные с ним данные в любой момент.</p>
<h2>В приложении (быстрее всего)</h2><ol class="steps"><li>Откройте Fade и войдите в аккаунт.</li>
<li>Перейдите в <strong>Профиль → Настройки</strong>.</li><li>Нажмите <strong>Удалить аккаунт</strong> и подтвердите.</li></ol>
<h2>Без приложения</h2><p>Напишите на <a href="mailto:{E}?subject=Fade%20%E2%80%94%20delete%20account">{E}</a> с темой «Удалить аккаунт» и укажите номер телефона, привязанный к аккаунту. Мы можем попросить подтвердить личность.</p>
<h2>Что удаляется</h2><ul><li>Имя, номер телефона, email, фото профиля</li>
<li>История записей, сообщения, отзывы, избранные салоны, баллы</li>
<li>Для барберов: профиль салона, расписание, фото работ</li></ul>
<h2>Что сохраняется и как долго</h2><p class="note">Данные удаляются из рабочих систем, как правило, в течение <strong>30 дней</strong>. В резервных копиях они могут оставаться ещё недолго. Платёжные и бухгалтерские записи, которых требует закон (сумма, дата, статус платежа), хранятся в установленный законом срок. Может сохраняться обезличенная статистика.</p>""",
    "en": f"""<h1>Delete your Fade account</h1><p class="upd">Fade app · developer: Fade</p>
<p>You can delete your account and the data linked to it at any time.</p>
<h2>In the app (fastest)</h2><ol class="steps"><li>Open Fade and sign in.</li>
<li>Go to <strong>Profile → Settings</strong>.</li><li>Tap <strong>Delete account</strong> and confirm.</li></ol>
<h2>Without the app</h2><p>Email <a href="mailto:{E}?subject=Delete%20my%20Fade%20account">{E}</a> with the subject “Delete my account” and include the phone number on the account. We may ask you to confirm it’s you.</p>
<h2>What is deleted</h2><ul><li>Name, phone number, email, profile photo</li>
<li>Booking history, messages, reviews, saved shops, points</li>
<li>For barbers: shop profile, schedule, work photos</li></ul>
<h2>What is kept, and for how long</h2><p class="note">Data is removed from live systems, ordinarily within <strong>30 days</strong>. Copies may remain briefly in backups. Payment and accounting records the law requires (amount, date, status) are kept for the legally required period. Anonymous aggregate statistics may be kept.</p>""",
}

INDEX = {
    "uz": f"""<h1>Fade — sartaroshga navbat</h1><p>Toshkentdagi sartaroshxonalarga onlayn yoziling: ustani tanlang, vaqtni bosing, keling. Yangi turmakni AI bilan oldindan ko‘ring.</p>
<p class="note">Fade tez orada Google Play’da. Savollar: <a href="mailto:{E}">{E}</a></p>""",
    "ru": f"""<h1>Fade — запись к барберу</h1><p>Онлайн-запись в барбершопы Ташкента: выберите мастера, нажмите на время, приходите. Примерьте новую стрижку с AI заранее.</p>
<p class="note">Fade скоро в Google Play. Вопросы: <a href="mailto:{E}">{E}</a></p>""",
    "en": f"""<h1>Fade — book your barber</h1><p>Book Tashkent barbershops online: pick a barber, tap a time, show up. Preview a new haircut with AI first.</p>
<p class="note">Fade is coming to Google Play. Questions: <a href="mailto:{E}">{E}</a></p>""",
}


def multi(dct):
    return "".join(f'<div data-l="{c}">{dct[c]}</div>' for c, _ in LANGS)


files = {"privacy.html": legal("privacy"), "terms.html": legal("terms"),
         "delete-account.html": page("Delete account — Fade", multi(DELETE)),
         "index.html": page("Fade — book your barber", multi(INDEX))}
for name, content in files.items():
    io.open(f"{OUT}/{name}", "w", encoding="utf-8").write(content)
io.open(f"{OUT}/.nojekyll", "w").write("")
print("built", list(files))
