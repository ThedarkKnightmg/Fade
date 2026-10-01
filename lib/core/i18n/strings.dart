import '../../data/app_state.dart';
import 'app_language.dart';

/// App copy in English / Russian / Uzbek. Every getter reads the live
/// language from [AppState], and the root rebuilds the whole app whenever
/// the language changes — so `L.x` always reflects the current language.
///
/// Coverage focuses on the core journey (Home, Map, Booking). Add a getter
/// here and use `L.x` to localize more.
class L {
  L._();

  static String _t(String en, String ru, String uz) {
    switch (AppState.instance.language) {
      case AppLanguage.ru:
        return ru;
      case AppLanguage.uz:
        return uz;
      case AppLanguage.en:
        return en;
    }
  }

  // ── "Pick your barber" nudge (new accounts) ───────────
  static String get pickBarberTitle => _t('Choose your barber',
      'Выберите барбера', 'Sartaroshingizni tanlang');
  static String get pickBarberBody => _t(
      'Pick the person you want in your corner. Rebooking them is then one tap.',
      'Выберите своего мастера — потом запись к нему в одно касание.',
      'Oʻz ustangizni tanlang — keyin unga yozilish bir bosishda.');
  static String get pickBarberCta =>
      _t('Find a barber', 'Найти барбера', 'Sartarosh topish');

  // ── Waiting-chair mini game ("Scissor Master") ────────
  static String get gameTitle =>
      _t('Scissor Master', 'Мастер ножниц', 'Qaychi ustasi');
  static String get gameKillTime => _t('Kill time while you wait',
      'Скоротать время в ожидании', 'Kutish vaqtini oʻtkazing');
  static String get gameHowTo => _t(
      'Swipe to cut the hair. Never cut a comb — and never let hair hit the floor.',
      'Проводите пальцем, чтобы срезать волосы. Не режьте расчёски и не роняйте волосы на пол.',
      'Sochni kesish uchun barmoqni suring. Taroqni kesmang va sochni yerga tushirmang.');
  static String get gamePlay => _t('Play', 'Играть', 'Oʻynash');
  static String get gameCombo => _t('combo', 'комбо', 'kombo');
  static String get gameBestCombo =>
      _t('Best combo', 'Лучшее комбо', 'Eng yaxshi kombo');
  static String get gameCutComb =>
      _t('Blade jammed!', 'Лезвие застряло!', 'Tigʻ tiqilib qoldi!');
  static String get gameMissedHair =>
      _t('Hair on the floor', 'Волосы на полу', 'Soch yerga tushdi');
  static String get gameOver => _t('Game over', 'Игра окончена', 'Oʻyin tugadi');
  static String gameEarnedPoints(int som) => _t(
      '+$som Fade Points earned',
      '+$som Fade Points начислено',
      '+$som Fade Points ishlab topildi');

  // The explainer. The whole reason someone plays a second time is believing
  // the tokens are worth something, so this says plainly what they are: money
  // off a real haircut, not a score.
  static String get gameTokensTitle => _t('Cut the blue tokens',
      'Режьте синие жетоны', 'Koʻk tokenlarni kesing');
  static String get gameTokensBody => _t(
      'Every blue token is real money off your next haircut — 1 Fade Point = 1 so‘m. Cut one and it goes straight to your balance.',
      'Каждый синий жетон — это реальная скидка на следующую стрижку: 1 Fade Point = 1 сум. Срезали — сразу на баланс.',
      'Har bir koʻk token — keyingi soch olishingizga haqiqiy chegirma: 1 Fade Point = 1 soʻm. Kesdingiz — darrov balansingizga tushadi.');
  // NOTE: there is deliberately no "N tokens left / up to X so'm" string. The
  // daily cap is enforced but never advertised — leading with the ceiling told
  // a new player how little they could win before they had played at all.
  static String get gameTokensSpent => _t(
      'Today’s tokens are all collected — come back tomorrow.',
      'Все жетоны на сегодня собраны — возвращайтесь завтра.',
      'Bugungi tokenlar yigʻib boʻlindi — ertaga qaytib keling.');
  static String gameBankedThisRun(int som) => _t(
      'Banked this run: $som so‘m',
      'Заработано за игру: $som сум',
      'Bu oʻyinda: $som soʻm');
  // Reactions. A game that never says anything back is a spreadsheet — these
  // are the difference between "score increased" and a barber shouting across
  // the shop. Escalating so a 5-cut stroke is louder than a 2.
  static String get gameNice => _t('Nice!', 'Неплохо!', 'Zoʻr!');
  static String get gameSharp => _t('Sharp!', 'Чётко!', 'Aniq!');
  static String get gameMaster => _t('MASTER!', 'МАСТЕР!', 'USTA!');
  static String get gameLegend => _t('LEGEND!', 'ЛЕГЕНДА!', 'AFSONA!');
  static String get gameOops => _t('Oops!', 'Ой!', 'Voy!');
  static String get gameOnFire => _t('ON FIRE', 'В УДАРЕ', 'ALANGADA');

  // ── Second game: "Toza chiziq" (Clean Line) ───────────
  static String get gamesTitle => _t('Games', 'Игры', 'Oʻyinlar');
  static String get lineGameTitle =>
      _t('Clean Line', 'Чистая линия', 'Toza chiziq');
  static String get lineGameTagline => _t('Trace the perfect fade line',
      'Проведите идеальную линию', 'Mukammal fade chizigʻini chizing');
  static String get lineGameHowTo => _t(
      'Drag along the dotted line without leaving it. The steadier your hand, the higher the score.',
      'Ведите пальцем по пунктиру, не сходя с него. Чем ровнее рука, тем выше счёт.',
      'Nuqtali chiziq boʻylab barmoqni yuriting, undan chiqmang. Qoʻlingiz qanchalik tinch boʻlsa, ball shuncha yuqori.');
  static String get lineGameSlipped =>
      _t('Hand slipped!', 'Рука дрогнула!', 'Qoʻl sirgʻalib ketdi!');
  static String lineGameAccuracy(int pct) => _t(
      'Accuracy $pct%', 'Точность $pct%', 'Aniqlik $pct%');
  static String get lineGameLevel => _t('Line', 'Линия', 'Chiziq');
  static String get lineGamePerfectLine =>
      _t('PERFECT LINE', 'ИДЕАЛЬНАЯ ЛИНИЯ', 'MUKAMMAL CHIZIQ');

  static String get gamePaused => _t('Paused', 'Пауза', 'Pauza');
  static String get gameResume => _t('Resume', 'Продолжить', 'Davom etish');
  static String gameSoClose(int n) => _t(
      'Just $n off your record!',
      'До рекорда всего $n!',
      'Rekordgacha atigi $n!');

  static String get gameFadePoints =>
      _t('FADE POINTS', 'FADE POINTS', 'FADE POINTS');
  static String get gameSomOffNextCut => _t(
      'so‘m off your next haircut',
      'сум скидки на следующую стрижку',
      'keyingi soch olishingizga chegirma');
  static String gameTotalBalance(int som) => _t(
      'Your Fade Points: $som so‘m',
      'Ваши Fade Points: $som сум',
      'Sizning Fade Points: $som soʻm');
  static String get gameScore => _t('Score', 'Счёт', 'Hisob');
  static String get gameBest => _t('Best', 'Рекорд', 'Rekord');
  static String get gameNewBest =>
      _t('New record!', 'Новый рекорд!', 'Yangi rekord!');
  static String get gameAgain => _t('Play again', 'Ещё раз', 'Yana oʻynash');

  // ── Form validation ───────────────────────────────────
  // These are the most-seen strings in the whole app — every mistyped field
  // shows one — and they were the last block still hardcoded in English.
  static String get vEmailEmpty =>
      _t('Enter your email.', 'Введите email.', 'Email kiriting.');
  static String get vEmailLong => _t('That email is too long.',
      'Слишком длинный email.', 'Email juda uzun.');
  static String get vEmailBad => _t('Enter a valid email address.',
      'Введите корректный email.', 'Toʻgʻri email kiriting.');
  static String get vPassEmpty =>
      _t('Enter a password.', 'Введите пароль.', 'Parol kiriting.');
  static String vPassShort(int min) => _t(
      'Use at least $min characters.',
      'Минимум $min символов.',
      'Kamida $min ta belgi kiriting.');
  static String get vPassLong => _t('That password is too long.',
      'Слишком длинный пароль.', 'Parol juda uzun.');
  static String vFieldRequired(String field) =>
      _t('$field is required.', 'Поле «$field» обязательно.', '$field majburiy.');
  static String vFieldLong(String field) => _t(
      '$field is too long.', 'Поле «$field» слишком длинное.', '$field juda uzun.');
  static String get vNameEmpty =>
      _t('Enter your name.', 'Введите имя.', 'Ismingizni kiriting.');
  static String get vNameShort => _t('That name looks too short.',
      'Имя слишком короткое.', 'Ism juda qisqa.');
  static String get vNameLong =>
      _t('That name is too long.', 'Имя слишком длинное.', 'Ism juda uzun.');
  static String get vPhoneEmpty => _t('Enter your phone number.',
      'Введите номер телефона.', 'Telefon raqamingizni kiriting.');
  static String get vPhoneChars => _t('Use digits and + ( ) - only.',
      'Только цифры и + ( ) -.', 'Faqat raqamlar va + ( ) - belgilari.');
  static String get vPhoneBad => _t('Enter a valid phone number.',
      'Введите корректный номер.', 'Toʻgʻri raqam kiriting.');

  // ── Face shapes + why a cut suits you ─────────────────
  static String faceBlurb(String shape) => switch (shape) {
        'Oval' => _t('Balanced proportions — almost any cut works on you.',
            'Сбалансированные пропорции — вам идёт почти любая стрижка.',
            'Muvozanatli nisbatlar — deyarli har qanday soch turi yarashadi.'),
        'Round' => _t(
            'Soft, even width and height — height on top adds definition.',
            'Мягкая, ровная форма — объём сверху добавит выразительности.',
            'Yumshoq, bir tekis shakl — tepadagi balandlik aniqlik qoʻshadi.'),
        'Square' => _t('Strong jaw and forehead — sharp, structured cuts suit you.',
            'Сильная челюсть и лоб — вам идут чёткие структурные стрижки.',
            'Kuchli jagʻ va peshona — aniq, tuzilgan soch turlari yarashadi.'),
        'Heart' => _t(
            'Wider forehead, narrower chin — softer, fuller sides balance it.',
            'Широкий лоб, узкий подбородок — мягкие объёмные бока уравновесят.',
            'Keng peshona, tor iyak — yumshoq, toʻliq yon tomonlar muvozanatlaydi.'),
        'Oblong' => _t(
            'Longer than wide — shorter sides and low volume keep it even.',
            'Вытянутая форма — короткие бока и низкий объём выровняют.',
            'Choʻziq shakl — kalta yonlar va past hajm tenglashtiradi.'),
        _ => _t('Wide cheekbones — fuller tops and fringes flatter the angles.',
            'Широкие скулы — объём сверху и чёлка смягчат углы.',
            'Keng yonoqlar — tepadagi hajm va chelka burchaklarni yumshatadi.'),
      };

  static String suitsYouBecause(String styleName, String why) => _t(
      '$styleName suits you because $why.',
      '$styleName вам подходит, потому что $why.',
      '$styleName sizga mos, chunki $why.');

  static String whyForShape(String shape) => switch (shape) {
        'Oval' => _t(
            'your balanced proportions let it sit cleanly without fighting your features',
            'ваши сбалансированные пропорции позволяют ей лечь аккуратно',
            'muvozanatli nisbatlaringiz unga toza yotishga imkon beradi'),
        'Round' => _t('its height on top lengthens a softer, rounder face',
            'объём сверху визуально вытягивает более округлое лицо',
            'tepadagi balandlik yumaloqroq yuzni choʻzib koʻrsatadi'),
        'Square' => _t(
            'it works with a strong jaw instead of squaring it off further',
            'она работает с сильной челюстью, а не утяжеляет её',
            'u kuchli jagʻ bilan ishlaydi, uni yanada burchakli qilmaydi'),
        'Heart' => _t('fuller sides balance a wider forehead and narrower chin',
            'объёмные бока уравновешивают широкий лоб и узкий подбородок',
            'toʻliq yon tomonlar keng peshona va tor iyakni muvozanatlaydi'),
        'Oblong' => _t(
            'shorter sides and low volume stop a longer face reading even longer',
            'короткие бока и низкий объём не вытягивают лицо ещё больше',
            'kalta yonlar va past hajm choʻziq yuzni yanada uzaytirmaydi'),
        _ => _t('volume and a fringe up top soften prominent cheekbones',
            'объём и чёлка сверху смягчают выразительные скулы',
            'tepadagi hajm va chelka yonoqlarni yumshatadi'),
      };

  // ── Notification channel (shown in Android system settings) ──
  static String get notifChannelDesc => _t('Booking updates and requests',
      'Обновления записей и заявки', 'Yozuv yangiliklari va soʻrovlar');

  // ── Sign in with Apple ────────────────────────────────
  static String get continueWithApple => _t('Continue with Apple',
      'Продолжить с Apple', 'Apple bilan davom etish');
  static String get appleFailed => _t(
      "Apple sign-in didn't complete — try again",
      'Не удалось войти через Apple — попробуйте снова',
      'Apple orqali kirish yakunlanmadi — qayta urining');

  // ── Shop publish state (barber onboarding) ────────────
  // A shop that only saved locally is invisible to every client, so the barber
  // must be told plainly rather than left waiting for bookings that cannot come.
  static String get shopLiveTitle =>
      _t('Your shop is live', 'Ваш салон опубликован', 'Saloningiz efirda');
  static String get shopLiveBody => _t(
      'Clients can find you on the map and book you right now.',
      'Клиенты уже видят вас на карте и могут записаться.',
      'Mijozlar sizni xaritada koʻradi va hoziroq yozila oladi.');
  static String get shopNotPublishedTitle => _t(
      'Saved on this device only',
      'Сохранено только на этом устройстве',
      'Faqat shu qurilmada saqlandi');
  static String get shopNotPublishedBody => _t(
      'Your shop has NOT been published yet, so clients cannot see or book it. Sign in and publish to go live.',
      'Ваш салон ещё НЕ опубликован — клиенты его не видят. Войдите и опубликуйте, чтобы начать работу.',
      'Saloningiz hali EʼLON QILINMAGAN — mijozlar uni koʻrmaydi. Ishni boshlash uchun tizimga kiring va eʼlon qiling.');
  static String get shopPublishRetry =>
      _t('Publish now', 'Опубликовать', 'Hozir eʼlon qilish');
  static String get shopPublishFailed => _t(
      'Still not published — check your connection and sign-in.',
      'Опубликовать не удалось — проверьте связь и вход.',
      'Eʼlon qilinmadi — aloqa va tizimga kirishni tekshiring.');

  // ── Catalogue states ──────────────────────────────────
  // What the browse surfaces say when there is no real supply to show. The app
  // used to fall back to the demo shops here, which meant a client could book a
  // barbershop that does not exist and never hear back.
  static String get catalogueLoading => _t('Finding barbershops…',
      'Ищем барбершопы…', 'Barbershoplar qidirilmoqda…');
  static String get catalogueEmptyTitle => _t('No barbershops here yet',
      'Здесь пока нет барбершопов', "Bu yerda hali barbershop yo'q");
  static String get catalogueEmptyBody => _t(
      'Fade is just opening in your city. We’ll show shops the moment the first one joins.',
      'Fade только открывается в вашем городе. Мы покажем салоны, как только появится первый.',
      'Fade shahringizda endi ochilmoqda. Birinchi salon qoʻshilishi bilan koʻrsatamiz.');
  static String get catalogueFailedTitle =>
      _t('Couldn’t load barbershops', 'Не удалось загрузить', 'Yuklab boʻlmadi');
  static String get catalogueFailedBody => _t(
      'Check your connection and try again.',
      'Проверьте соединение и повторите попытку.',
      'Aloqani tekshiring va qayta urining.');
  static String get tryAgain =>
      _t('Try again', 'Повторить', 'Qayta urinish');
  static String get nothingToBookYet => _t(
      'No barbershops available to book yet.',
      'Пока нет салонов для записи.',
      "Hozircha yozuv uchun salon yo'q.");

  // ── Home ──────────────────────────────────────────────
  static String get findShopsNearYou =>
      _t('Find shops near you', 'Барбершопы рядом', 'Yaqin barbershoplar');
  static String get shopsNearYou =>
      _t('Shops near you', 'Рядом с вами', 'Sizga yaqin');
  static String get tapToDetect => _t('Tap to detect your location',
      'Нажмите, чтобы определить локацию', 'Joylashuvni aniqlash uchun bosing');
  static String get enterAddress =>
      _t('Enter address', 'Ввести адрес', 'Manzilni kiriting');
  static String get editAddress =>
      _t('Edit address', 'Изменить адрес', 'Manzilni tahrirlash');
  static String get share => _t('Share', 'Поделиться', 'Ulashish');
  static String get myBookings =>
      _t('My Bookings', 'Мои записи', 'Mening yozuvlarim');
  static String get noUpcomingCuts => _t(
      'No upcoming cuts yet', 'Нет предстоящих записей', "Hozircha yozuv yo'q");
  static String get nextVisit =>
      _t('NEXT VISIT', 'БЛИЖАЙШИЙ ВИЗИТ', 'KEYINGI TASHRIF');
  static String get thisVisit =>
      _t('this visit', 'этот визит', 'shu tashrif');
  static String get allUpcoming =>
      _t('all upcoming', 'все визиты', 'barcha tashriflar');
  static String get tapToSwitch =>
      _t('tap to switch', 'сменить', 'almashtirish');
  static String get bookNextCut => _t(
      'Book your next cut — tap to get started',
      'Запишитесь на стрижку — нажмите, чтобы начать',
      "Keyingi soch olishga yoziling — boshlash uchun bosing");
  static String get premiumPartners =>
      _t('Premium partners', 'Премиум-партнёры', 'Premium hamkorlar');
  static String get barbershops =>
      _t('Barbershops', 'Барбершопы', 'Barbershoplar');
  static String get moreBarbershops =>
      _t('More barbershops', 'Ещё барбершопы', 'Yana barbershoplar');
  static String get seeAll => _t('See all', 'Все', 'Barchasi');

  static String get today => _t('Today', 'Сегодня', 'Bugun');
  static String get tomorrow => _t('Tomorrow', 'Завтра', 'Ertaga');
  static String inDays(int n) =>
      _t('In $n days', 'Через $n дн.', '$n kundan keyin');

  static String upcomingNext(int n, String when) => _t(
      '$n upcoming · next $when',
      '$n записей · ближайшая $when',
      "$n ta yozuv · keyingisi $when");

  // ── Home menu / dialogs ───────────────────────────────
  static String get searchShops =>
      _t('Search shops', 'Поиск барбершопов', 'Barbershop qidirish');
  static String get shopsOnMap =>
      _t('Shops on the map', 'Барбершопы на карте', 'Xaritada barbershoplar');
  static String get myProfile =>
      _t('My profile', 'Мой профиль', 'Mening profilim');
  static String get yourAddress =>
      _t('Your address', 'Ваш адрес', 'Sizning manzilingiz');
  static String get addressHelp => _t(
      'We use it to find the closest shops.',
      'Мы используем его, чтобы найти ближайшие барбершопы.',
      "Eng yaqin barbershoplarni topish uchun ishlatamiz.");
  static String get cancel => _t('Cancel', 'Отмена', 'Bekor qilish');
  static String get save => _t('Save', 'Сохранить', 'Saqlash');
  static String get addressSaved =>
      _t('Address saved', 'Адрес сохранён', 'Manzil saqlandi');
  static String get findingLocation => _t('Finding your location…',
      'Определяем локацию…', 'Joylashuv aniqlanmoqda…');
  static String get locationFailed => _t(
      "Couldn't get your location — enter it manually.",
      'Не удалось определить локацию — введите вручную.',
      "Joylashuvni aniqlab bo'lmadi — qo'lda kiriting.");
  static String get locationDetected => _t('📍 Location detected',
      '📍 Локация определена', '📍 Joylashuv aniqlandi');
  static String get inviteCopied => _t('Invite link copied to clipboard',
      'Ссылка-приглашение скопирована', 'Taklif havolasi nusxalandi');

  // ── Map ───────────────────────────────────────────────
  static String get pricesInSom =>
      _t("PRICES IN SO'M", 'ЦЕНЫ В СУМАХ', "NARXLAR SO'MDA");
  static String get shopsWord =>
      _t('Shops', 'Барбершопы', 'Barbershoplar');
  static String get onTheMap => _t('on the map', 'на карте', 'xaritada');
  static String get tapPriceTag => _t('tap a price tag to pick your shop',
      'нажмите на цену, чтобы выбрать', 'tanlash uchun narxga bosing');
  static String shopsNearby(int n) => _t(
      '$n shops nearby', '$n барбершопов рядом', '$n ta barbershop yaqinda');
  // Map filter chips.
  static String get mapFilterAll => _t('All', 'Все', 'Hammasi');
  static String get mapFilterPremium =>
      _t('Premium', 'Премиум', 'Premium');
  static String get mapFilterHot => _t('Popular', 'Популярные', 'Ommabop');
  static String get mapFilterBudget =>
      _t('Budget', 'Бюджет', 'Arzon');
  static String get mapFilterPrice => _t('Price', 'Цена', 'Narx');
  static String get filterTopRated =>
      _t('Top rated', 'Топ', 'Eng yaxshi');
  static String get setBudgetTitle =>
      _t('Your budget', 'Ваш бюджет', 'Byudjetingiz');
  static String cheapestRightNow(String som) => _t(
      "Cheapest right now: $som so'm",
      'Сейчас самый дешёвый: $som сум',
      "Ayni damda eng arzoni: $som so'm");
  static String get anyPrice =>
      _t('Any price', 'Любая цена', 'Har qanday narx');
  static String get applyWord => _t('Apply', 'Применить', "Qo'llash");
  static String mapNoShopsUnder(String som) => _t(
      "No shops under $som so'm",
      'Нет барбершопов дешевле $som сум',
      "$som so'mdan arzon barbershop yo'q");
  static String mapCheapestIs(String som) => _t(
      "Cheapest is $som so'm", 'Самый дешёвый — $som сум',
      "Eng arzoni — $som so'm");
  static String get showCheapest => _t(
      'Show cheapest', 'Показать дешёвые', "Arzonlarini ko'rsatish");

  static String get openShop => _t('Open shop', 'Открыть', 'Ochish');
  static String get bookHere => _t('Book here', 'Записаться', 'Yozilish');
  static String fromPrice(String price) =>
      _t('from $price', 'от $price', '$price dan');

  // ── Booking ───────────────────────────────────────────
  static String get newWord => _t('New', 'Новая', 'Yangi');
  static String get bookingWord => _t('booking', 'запись', 'yozuv');
  static String get services => _t('Services', 'Услуги', 'Xizmatlar');
  static String get tickWhatYouNeed => _t('tick what you need',
      'отметьте нужное', 'keraklisini belgilang');
  static String get whenAndWho =>
      _t('When & who', 'Когда и кто', 'Qachon va kim');
  static String get withLabel => _t('with', 'мастер', 'usta');
  static String get dayLabel => _t('day', 'день', 'kun');
  static String timeFor(String date) =>
      _t('time · $date', 'время · $date', 'vaqt · $date');
  static String get confirmBooking =>
      _t('Confirm booking', 'Подтвердить запись', 'Yozuvni tasdiqlash');
  static String confirmPrice(String price) => _t(
      'Confirm · $price', 'Подтвердить · $price', 'Tasdiqlash · $price');
  static String get allChairsTaken => _t(
      'All chairs taken — try another day.',
      'Все кресла заняты — выберите другой день.',
      "Barcha o'rindiqlar band — boshqa kunni tanlang.");
  static String get bookedLegend => _t('Crossed-out times are already booked',
      'Зачёркнутое время уже занято', 'Chizilgan vaqtlar band qilingan');
  static String get requestedLook =>
      _t('Requested look', 'Желаемый образ', 'Tanlangan uslub');
  static String get pickServiceFirst => _t('Tick at least one service ✂️',
      'Отметьте хотя бы одну услугу ✂️', 'Kamida bitta xizmatni belgilang ✂️');
  static String get pickTimeFirst => _t('Pick a chair time ⏰',
      'Выберите время ⏰', 'Vaqtni tanlang ⏰');

  // ── Profile ───────────────────────────────────────────
  static String get language => _t('Language', 'Язык', 'Til');

  // ── Home: location & header ───────────────────────────
  static String get setLocation =>
      _t('Set location', 'Указать адрес', 'Manzilni tanlang');
  static String get locateMe => _t('Locate me', 'Моя локация', 'Joylashuvim');
  static String get locationExplainer => _t(
      "Allow location and we'll show the closest barbershops, how far each "
          'one is, and put your area in the top bar.',
      'Разрешите доступ к локации — покажем ближайшие барбершопы, расстояние '
          'и ваш район в шапке.',
      "Joylashuvga ruxsat bering — eng yaqin barbershoplar, masofa va "
          "hududingizni yuqorida ko'rsatamiz.");
  static String get notNow => _t('Not now', 'Не сейчас', 'Hozir emas');
  static String get allow => _t('Allow', 'Разрешить', 'Ruxsat berish');
  static String get addressExample => _t(
      '142 Brook Street, Downtown', 'ул. Навои 12, центр', "Navoiy ko'chasi 12");
  static String get bookYourUsual =>
      _t('Book your usual', 'Записаться как обычно', 'Odatdagidek yozilish');
  static String get rebook => _t('Rebook', 'Повторить', 'Qayta yozilish');

  // ── Bonus / VIP sheet ─────────────────────────────────
  static String get fadePoints =>
      _t('Fade points', 'Баллы Fade', 'Fade ballari');
  static String get rewardsVipProgress => _t('Your rewards & VIP progress',
      'Награды и прогресс VIP', 'Mukofotlar va VIP jarayoni');
  static String streakWeeks(int n) =>
      _t('🔥 $n wks', '🔥 $n нед.', '🔥 $n hafta');
  static String cutsToVip(int n) => _t(
      '$n cuts to VIP — priority booking & recognition',
      '$n стрижек до VIP — приоритет и статус',
      "VIPgacha $n soch — ustuvor yozuv va e'tirof");
  static String get vipUnlocked => _t(
      'VIP unlocked — priority booking & top-of-list slots 🎉',
      'VIP открыт — приоритетная запись 🎉',
      'VIP ochildi — ustuvor yozuv 🎉');
  static String get perkPriority =>
      _t('Priority booking', 'Приоритетная запись', 'Ustuvor yozuv');
  static String get perkPrioritySub => _t('Jump ahead when slots are tight',
      'Проходите вперёд, когда мест мало', "Joylar kam bo'lganda oldinga o'ting");
  static String get perkSkipQueue =>
      _t('Skip-the-queue pass', 'Пропуск очереди', "Navbatsiz o'tish");
  static String get perkSkipQueueSub => _t('Earned as you stack up cuts',
      'Копится с каждой стрижкой', "Har soch bilan to'planadi");
  static String get perkRecognition =>
      _t('Top-of-list recognition', 'Статус в топе списка', "Ro'yxat boshida");
  static String get perkRecognitionSub => _t('Your barber sees you first',
      'Барбер видит вас первым', "Barber sizni birinchi ko'radi");
  static String get openProfile =>
      _t('Open profile', 'Открыть профиль', 'Profilni ochish');

  // ── Address picker ────────────────────────────────────
  static String get setYourLocation =>
      _t('Set your location', 'Укажите локацию', 'Joylashuvni tanlang');
  static String get typeYourAddress =>
      _t('Type your address', 'Введите адрес', 'Manzilni kiriting');
  static String get setWord => _t('Set', 'ОК', 'OK');
  static String get dragToPin => _t('Drag the map to pin your spot',
      'Двигайте карту, чтобы поставить точку', "Nuqta qo'yish uchun xaritani suring");
  static String get useThisLocation =>
      _t('Use this location', 'Выбрать эту точку', 'Shu joyni tanlash');
  static String get saving => _t('Saving…', 'Сохранение…', 'Saqlanmoqda…');
  static String get locationPinFailed => _t(
      "Couldn't get your location — pin it on the map.",
      'Не удалось определить локацию — отметьте на карте.',
      'Joylashuv aniqlanmadi — xaritada belgilang.');

  // ── Home shell ────────────────────────────────────────
  static String get messages => _t('Messages', 'Сообщения', 'Xabarlar');
  static String get messagesSoon => _t('Chat with your barber — coming soon.',
      'Чат с барбером — скоро.', 'Barber bilan chat — tez orada.');

  // ── Settings + contact verification ───────────────────
  static String get settingsTitle =>
      _t('Settings', 'Настройки', 'Sozlamalar');
  static String get manageShopSettings => _t('Shop, services & settings',
      'Барбершоп, услуги, настройки', 'Barbershop, xizmatlar, sozlamalar');
  static String get appAndAccount => _t('App & account',
      'Приложение и аккаунт', 'Ilova va akkaunt');
  static String get appAndAccountSub => _t('Language, notifications, sign out',
      'Язык, уведомления, выход', 'Til, bildirishnomalar, chiqish');
  static String get growBookingsTitle =>
      _t('Get more bookings', 'Больше записей', "Ko'proq yozuv");
  static String get growBookingsSub => _t(
      'Share your QR — regulars book you free',
      'Поделитесь QR — постоянные записываются бесплатно',
      "QR ulashing — doimiylar bepul yoziladi");
  static String get boostSellTitle =>
      _t('Turbo Boost', 'Turbo Boost', 'Turbo Boost');
  static String get boostSellSub => _t(
      'Top of search for an hour — or go VIP',
      'Час в топе поиска — или VIP',
      "Bir soat qidiruv tepasida — yoki VIP");
  static String get boostedNowChip =>
      _t('Live 🚀', 'В топе 🚀', 'Tepada 🚀');
  // ── Skeuomorphic coin wallet ──
  static String get walletTotalLabel =>
      _t('Total balance', 'Общий баланс', 'Umumiy balans');
  static String get coinCredit => _t('Credit', 'Кредит', 'Kredit');
  static String get coinEarned => _t('Earned', 'Заработано', 'Ishlangan');
  static String get coinTips => _t('Tips', 'Чаевые', 'Choychaqa');
  static String get walletThisWeek =>
      _t('this week', 'за неделю', 'shu hafta');
  static String get actTopUp => _t('Top up', 'Пополнить', "To'ldirish");
  static String get actActivity => _t('Activity', 'История', 'Faoliyat');
  static String get actBoost => _t('Boost', 'Boost', 'Boost');
  static String get topUpAddedToast =>
      _t('Credit topped up ✓', 'Кредит пополнен ✓', "Kredit to'ldirildi ✓");

  // ── Help & feedback ──
  static String get clientWord => _t('Client', 'Клиент', 'Mijoz');
  static String get beforeWord => _t('Before', 'До', 'Oldin');
  static String get afterWord => _t('After', 'После', 'Keyin');
  static String get dragToCompare => _t('Drag to compare',
      'Потяните для сравнения', 'Solishtirish uchun torting');
  static String get aiWorking => _t('Cutting your new look…',
      'Создаём новый образ…', "Yangi qiyofa yaratilmoqda…");

  // ── Chat ─────────────────────────────────────────────────────────────
  static String get lastSeenRecently =>
      _t('last seen recently', 'был(а) недавно', 'yaqinda kirgan');
  static String get comingSoon =>
      _t('Coming soon', 'Скоро', 'Tez orada');
  static String get stickersBarber =>
      _t('Barbershop', 'Барбершоп', 'Sartaroshxona');
  static String get stickersReactions =>
      _t('Reactions', 'Реакции', 'Reaksiyalar');

  // ── Consent gate (first run) ─────────────────────────────────────────
  static String get consentTitle =>
      _t('Before we start', 'Прежде чем начать', 'Boshlashdan oldin');
  static String get consentSub => _t(
      'Please review and accept our terms. It takes a minute — you can read the full documents any time in Settings.',
      'Пожалуйста, ознакомьтесь и примите наши условия. Полные документы всегда доступны в настройках.',
      "Iltimos, shartlarimizni koʻrib chiqing va qabul qiling. Toʻliq hujjatlar sozlamalarda doim mavjud.");
  static String get consentCheckbox => _t(
      'I have read and agree to the Terms of Use and Privacy Policy',
      'Я прочитал(а) и принимаю Условия использования и Политику конфиденциальности',
      "Men Foydalanish shartlari va Maxfiylik siyosatini oʻqidim va roziman");
  static String get consentOpenTerms =>
      _t('Read Terms of Use', 'Условия использования', 'Foydalanish shartlari');
  static String get consentOpenPrivacy => _t('Read Privacy Policy',
      'Политика конфиденциальности', 'Maxfiylik siyosati');
  static String get consentContinue =>
      _t('Agree & continue', 'Принять и продолжить', 'Qabul qilib davom etish');
  static String get consentAgeNote => _t(
      'You must be 16 or older to use Fade.',
      'Вам должно быть 16 лет или больше.',
      "Fade’dan foydalanish uchun 16 yoshdan katta boʻlishingiz kerak.");

  // ── Legal (Terms of Use / Privacy Policy) ────────────────────────────
  static String get legalSection =>
      _t('Legal', 'Правовая информация', 'Huquqiy');
  static String get termsOfUse => _t(
      'Terms of Use', 'Условия использования', 'Foydalanish shartlari');
  static String get privacyPolicy => _t('Privacy Policy',
      'Политика конфиденциальности', 'Maxfiylik siyosati');
  static String get lastUpdated =>
      _t('Last updated', 'Обновлено', 'Yangilangan');
  // Acceptance line on the sign-in screen, built as
  //   [prefix] (Terms of Use) [mid] (Privacy Policy) [suffix]
  // so the two links stay tappable while each language keeps natural word order.
  static String get agreePrefix => _t(
      'By continuing, you agree to our ',
      'Продолжая, вы соглашаетесь с ',
      'Davom ettirib, siz ');
  static String get agreeMid => _t(' and ', ' и ', ' va ');
  static String get agreeSuffix =>
      _t('.', '.', 'ga rozilik bildirasiz.');

  // ── Reliability & loyalty ────────────────────────────────────────────
  static String get relTrusted =>
      _t('Trusted regular', 'Надёжный клиент', 'Ishonchli mijoz');
  static String get relNew =>
      _t('New client', 'Новый клиент', 'Yangi mijoz');
  static String get relWatch =>
      _t('Missed a slot before', 'Пропускал запись', 'Avval kelmagan');
  static String get relRestricted =>
      _t('Frequent no-shows', 'Часто не приходит', 'Tez-tez kelmaydi');
  static String get trustedTag => _t('Trusted', 'Надёжный', 'Ishonchli');
  static String get trustedPerk => _t('Instant booking, no deposit',
      'Мгновенная бронь, без залога', "Tez band qilish, garovsiz");
  static String trustedIn(int n) => _t(
      n == 1 ? '1 visit to Trusted' : '$n visits to Trusted',
      n == 1 ? '1 визит до статуса «Надёжный»' : '$n визита до «Надёжного»',
      "$n tashrif — Ishonchli maqomga");
  static String get trustedPerksTitle =>
      _t('Trusted perks', 'Привилегии «Надёжного»', 'Ishonchli imtiyozlari');
  // Fade Points cashback wallet.
  static String get fadePointsSpend => _t('Ready to spend on your next cut',
      'Можно потратить на следующую стрижку',
      "Keyingi soch olishga sarflashga tayyor");
  static String get fadePointsRule => _t(
      'Earn on every cut · min 10,000 to spend · 6-month expiry',
      'Баллы за каждую стрижку · от 10 000 · срок 6 мес.',
      "Har olishda ball · 10 000 dan · 6 oy muddat");
  static String get vipStatusTitle =>
      _t('VIP progress', 'Прогресс VIP', 'VIP jarayoni');
  static String pointsEarnedToast(int n) =>
      _t('+$n Fade Points', '+$n баллов Fade', "+$n Fade ball");
  // Referrals.
  static String get inviteRow =>
      _t('Invite friends & earn', 'Пригласить друзей', "Do‘stlarni taklif qiling");
  static String get inviteTitle => _t('Invite friends, earn points',
      'Пригласите друзей и зарабатывайте', "Do‘st taklif qiling, ball yig‘ing");
  static String get inviteSub => _t(
      'You earn 5,000 Fade Points when a friend gets their first cut.',
      'Вы получаете 5 000 баллов, когда друг подстрижётся впервые.',
      "Do‘stingiz birinchi marta soch oldirsa, 5 000 ball olasiz.");
  static String get inviteYourCode => _t('Your code', 'Ваш код', 'Sizning kodingiz');
  static String get inviteShare => _t('Share', 'Поделиться', 'Ulashish');
  static String get inviteHaveCode =>
      _t("Have a friend's code?", 'Есть код друга?', "Do‘st kodi bormi?");
  static String get inviteApply => _t('Apply', 'Применить', 'Qo‘llash');
  static String get inviteApplied => _t('Code applied — enjoy your first cut!',
      'Код применён — приятной первой стрижки!',
      "Kod qo‘llandi — birinchi olishdan zavqlaning!");
  static String get inviteFailed =>
      _t("That code didn't work", 'Код не подошёл', "Kod ishlamadi");
  static String inviteShareMessage(String code) => _t(
      'Book barbers on Fade ✂️ Use my code $code and we both win. https://fade.uz/i/$code',
      'Барбершопы в Fade ✂️ Введи мой код $code — бонус нам обоим. https://fade.uz/i/$code',
      "Fade’da sartaroshlar ✂️ Mening kodim $code — ikkalamizga bonus. https://fade.uz/i/$code");
  static String get tPerkInstant => _t('Instant booking — no waiting to be confirmed',
      'Мгновенная бронь — без ожидания подтверждения',
      "Tez band qilish — tasdiqni kutmasdan");
  static String get tPerkPriority => _t('Priority — you jump the barber’s queue',
      'Приоритет — вы первыми в очереди барбера',
      "Ustuvorlik — sartarosh navbatida birinchi");
  static String get tPerkNoDeposit => _t('No deposit or card hold, ever',
      'Никогда никакого залога', "Hech qachon garov yo‘q");
  static String get tPerkFreeCancel => _t('Free cancellation — no late fees',
      'Бесплатная отмена — без штрафов', "Bepul bekor qilish — jarimasiz");
  static String get tPerkBadge => _t('A Trusted badge barbers see on your booking',
      'Значок «Надёжный», который видит барбер',
      "Sartarosh ko‘radigan Ishonchli nishoni");
  static String freeCutIn(int n) => _t(
      n == 1 ? '1 visit to a free cut' : '$n visits to a free cut',
      n == 1 ? '1 визит до бесплатной' : '$n визита до бесплатной',
      "$n tashrif — bepul olishga");
  static String get freeCutReady =>
      _t('Free cut earned!', 'Бесплатная стрижка!', 'Bepul soch olish!');

  static String get helpFeedback =>
      _t('Help & feedback', 'Помощь и отзыв', 'Yordam va fikr');
  static String get helpFeedbackSub => _t(
      'Report a bug, suggest an idea, or just tell us',
      'Сообщите об ошибке, предложите идею или просто напишите',
      "Xatolik haqida yozing, g'oya bering yoki shunchaki ayting");
  static String get feedbackTitle =>
      _t("What's wrong?", 'Что случилось?', 'Nima bo\'ldi?');
  static String get feedbackSub => _t(
      'We read every message and fix fast.',
      'Мы читаем каждое сообщение и быстро чиним.',
      "Har bir xabarni o'qiymiz va tez tuzatamiz.");
  static String get fbBug => _t('Bug', 'Ошибка', 'Xatolik');
  static String get fbIdea => _t('Idea', 'Идея', "G'oya");
  static String get fbOther => _t('Other', 'Другое', 'Boshqa');
  static String get fbMessageHint => _t(
      'Describe what happened…',
      'Опишите, что произошло…',
      'Nima bo\'lganini yozing…');
  static String get fbContactHint => _t(
      'Phone or Telegram (optional)',
      'Телефон или Telegram (необязательно)',
      'Telefon yoki Telegram (ixtiyoriy)');
  static String get fbSend => _t('Send', 'Отправить', 'Yuborish');
  static String get fbThanks => _t(
      "Thank you! We're on it 🙌",
      'Спасибо! Уже разбираемся 🙌',
      "Rahmat! Ko'rib chiqyapmiz 🙌");
  static String get fbEmpty => _t(
      'Please write a few words first',
      'Сначала напишите пару слов',
      "Avval bir-ikki so'z yozing");
  static String get fbEmailUs =>
      _t('Or email us', 'Или напишите на почту', 'Yoki pochtaga yozing');
  static String get yourPasses =>
      _t('Your passes', 'Ваши пассы', 'Sizning passlaringiz');
  static String get perkDoublePoints =>
      _t('Double loyalty points', 'Двойные баллы', 'Ikki barobar ball');
  static String get accountSection =>
      _t('Account', 'Аккаунт', 'Hisob');
  static String get preferencesSection =>
      _t('Preferences', 'Предпочтения', 'Sozlamalar');
  static String get aboutSection => _t('About', 'О приложении', 'Ilova haqida');
  static String get editNameTitle =>
      _t('Edit name', 'Изменить имя', "Ismni o'zgartirish");
  static String get changeEmailTitle =>
      _t('Change email', 'Изменить email', "Email o'zgartirish");
  static String get changePhoneTitle =>
      _t('Change phone', 'Изменить телефон', "Telefon o'zgartirish");
  static String get newEmailLabel =>
      _t('New email', 'Новый email', 'Yangi email');
  static String get newPhoneLabel =>
      _t('New phone', 'Новый телефон', 'Yangi telefon');
  static String get weWillVerify => _t(
      "We'll send a code to confirm it's really you.",
      'Мы отправим код для подтверждения.',
      "Tasdiqlash uchun kod yuboramiz.");
  static String get verifyEmailTitle =>
      _t('Verify your email', 'Подтвердите email', 'Emailni tasdiqlang');
  static String get verifyPhoneTitle =>
      _t('Verify your phone', 'Подтвердите телефон', 'Telefonni tasdiqlang');
  static String verifyCodeSentTo(String target) => _t(
      'Enter the 4-digit code we sent to $target',
      'Введите 4-значный код, отправленный на $target',
      "$target raqamiga yuborilgan 4 xonali kodni kiriting");
  static String get demoCodeLabel =>
      _t('Demo code', 'Демо-код', 'Demo kod');
  static String get otpSending =>
      _t('Sending your code…', 'Отправляем код…', 'Kod yuborilmoqda…');
  static String get otpVerified =>
      _t('Verified ✓', 'Подтверждено ✓', 'Tasdiqlandi ✓');
  static String get verifyWord => _t('Verify', 'Подтвердить', 'Tasdiqlash');
  static String get resendCode =>
      _t('Resend code', 'Отправить снова', 'Qayta yuborish');
  static String resendInSec(int s) =>
      _t('Resend in ${s}s', 'Повтор через $sс', '${s}s dan keyin qayta');
  static String get wrongCode => _t('That code is not right. Try again.',
      'Неверный код. Попробуйте ещё раз.', "Kod noto'g'ri. Qayta urining.");
  static String get newCodeSent => _t('A new code is on its way.',
      'Новый код отправлен.', 'Yangi kod yuborildi.');
  static String get emailUpdated => _t('Email verified & updated',
      'Email подтверждён и обновлён', 'Email tasdiqlandi va yangilandi');
  static String get phoneUpdated => _t('Phone verified & updated',
      'Телефон подтверждён и обновлён', 'Telefon tasdiqlandi va yangilandi');
  static String get tapToVerifyChange => _t("Tap to change — we'll verify it",
      'Нажмите, чтобы изменить — с подтверждением',
      "O'zgartirish uchun bosing — tasdiqlanadi");
  static String get appVersionLabel =>
      _t('Version', 'Версия', 'Versiya');

  // ── Profile screen ────────────────────────────────────
  static String get editProfile =>
      _t('Edit profile', 'Редактировать профиль', 'Profilni tahrirlash');
  static String get nameWord => _t('Name', 'Имя', 'Ism');
  static String get emailWord => _t('Email', 'Эл. почта', 'Email');
  static String get phoneWord => _t('Phone', 'Телефон', 'Telefon');
  static String get saveChanges => _t('Save changes', 'Сохранить', 'Saqlash');
  static String get enterValidName => _t('Enter a valid name.',
      'Введите корректное имя.', "To'g'ri ism kiriting.");
  static String get enterValidEmail => _t('Enter a valid email.',
      'Введите корректный email.', "To'g'ri email kiriting.");
  static String get profileUpdated =>
      _t('Profile updated', 'Профиль обновлён', 'Profil yangilandi');
  static String get inviteCopiedFriend => _t(
      'Invite copied — share it with a friend ✂️',
      'Приглашение скопировано — поделитесь с другом ✂️',
      "Taklif nusxalandi — do'stingizga ulashing ✂️");
  static String get signOutQ => _t('Sign out?', 'Выйти?', 'Chiqish?');
  static String get stay => _t('Stay', 'Остаться', 'Qolish');
  static String get signOut => _t('Sign out', 'Выйти', 'Chiqish');
  static String get signOutBody => _t('Your notes stay right here.',
      'Ваши данные останутся здесь.', 'Maʼlumotlaringiz shu yerda qoladi.');
  static String get deleteAccount =>
      _t('Delete account', 'Удалить аккаунт', 'Hisobni o‘chirish');
  static String get deleteAccountQ => _t('Delete your account?',
      'Удалить аккаунт?', 'Hisobni o‘chirasizmi?');
  static String get deleteAccountBody => _t(
      'This permanently removes your account and personal data — bookings, messages, reviews and profile. This can’t be undone.',
      'Это навсегда удалит ваш аккаунт и данные — записи, сообщения, отзывы и профиль. Отменить нельзя.',
      'Bu hisobingiz va shaxsiy maʼlumotlaringizni — yozuvlar, xabarlar, sharhlar va profilni butunlay o‘chiradi. Buni qaytarib bo‘lmaydi.');
  static String get deleteForever =>
      _t('Delete forever', 'Удалить навсегда', 'Butunlay o‘chirish');
  static String get deletingAccount =>
      _t('Deleting…', 'Удаление…', 'O‘chirilmoqda…');
  static String get cutsLabel => _t('cuts', 'стрижек', 'soch');
  static String get upcomingLabel => _t('upcoming', 'визитов', 'tashrif');
  static String get savedShops => _t('saved shops', 'избранное', 'saqlangan');
  static String get bookAgain =>
      _t('Book again', 'Записаться снова', 'Qayta yozilish');
  static String get changeWord => _t('Change', 'Сменить', 'Almashtirish');
  static String get darkMode => _t('Dark mode', 'Тёмная тема', 'Tungi rejim');
  static String get reminders => _t('Reminders', 'Напоминания', 'Eslatmalar');

  // ── Bookings ──────────────────────────────────────────
  static String get findAShop =>
      _t('Find a shop', 'Найти барбершоп', 'Barbershop topish');
  static String get cancelThisOne =>
      _t('Cancel this one?', 'Отменить запись?', 'Yozuvni bekor qilish?');
  static String get keepIt => _t('Keep it', 'Оставить', 'Qoldirish');
  static String get cancelIt => _t('Cancel it', 'Отменить', 'Bekor qilish');
  static String get nothingHere => _t('nothing on this page yet…',
      'здесь пока пусто…', "bu yerda hozircha bo'sh…");
  static String get cancelBody => _t('The chair goes back up for grabs.',
      'Кресло снова станет свободным.', "O'rindiq yana bo'shaydi.");

  // ── Booking confirmation ──────────────────────────────
  static String get chairLockedIn => _t(
      'Your chair is locked in. See you soon ✂️',
      'Кресло забронировано. До встречи ✂️',
      "O'rindiq band qilindi. Ko'rishguncha ✂️");
  static String get doneWord => _t('Done', 'Готово', 'Tayyor');
  static String get addToCalendar =>
      _t('Add to calendar', 'В календарь', 'Kalendarga');
  static String get apptCopied => _t('Appointment details copied 🗓',
      'Детали записи скопированы 🗓', 'Yozuv tafsilotlari nusxalandi 🗓');

  // ── AI studio ─────────────────────────────────────────
  static String get aiHairStudio =>
      _t('AI Hair Studio', 'AI-студия причёсок', 'AI soch studiyasi');
  static String get connectAi => _t('Connect AI', 'Подключить AI', 'AI ulash');
  static String get takeSelfie =>
      _t('Take a selfie', 'Сделать селфи', 'Selfi olish');
  static String get uploadPhoto =>
      _t('Upload a photo', 'Загрузить фото', 'Surat yuklash');
  static String get newPhoto => _t('New photo', 'Новое фото', 'Yangi surat');
  // Kept short on purpose: this is a CTA in a row that also carries the look's
  // name, so a long translation is what pushed the bar into overflow. The look
  // is named directly beside the button, so "Book"/"Записаться"/"Yozilish"
  // reads unambiguously.
  static String get bookThisLook =>
      _t('Book this look', 'Записаться', 'Yozilish');
  static String get pickACut =>
      _t('Pick a cut', 'Выберите стрижку', 'Soch turini tanlang');
  static String get hairColour => _t('Hair colour', 'Цвет волос', 'Soch rangi');
  static String get yourAiPreview =>
      _t('Your AI preview', 'Ваш AI-превью', "AI ko'rinishingiz");
  static String get faceShapeLabel =>
      _t('Face shape', 'Форма лица', 'Yuz shakli');
  static String get matchWord => _t('match', 'совпадение', 'mos');
  static String get alsoGreatOnYou =>
      _t('Also great on you', 'Вам также подойдёт', 'Sizga yana mos keladi');
  // Honest disclosure: the selfie is sent to an AI service to build the
  // preview — it does NOT stay on the device. The old copy ("processed only for
  // your preview") implied on-device processing, which is false and a
  // suspension risk. See the consent gate before the first upload.
  static String get photoPrivacy => _t(
      'To create your preview, your photo is sent to an AI service, used only for this render, and not kept.',
      'Для превью фото отправляется в AI-сервис, используется только для этого рендера и не сохраняется.',
      "Ko'rinishni yaratish uchun surat AI xizmatiga yuboriladi, faqat shu render uchun ishlatiladi va saqlanmaydi.");
  static String get aiConsentTitle => _t('Create your AI preview?',
      'Создать AI-превью?', 'AI ko\'rinish yaratilsinmi?');
  static String get aiConsentBody => _t(
      'Your photo will be sent to an AI service to generate the hairstyle preview, then discarded. It is never shown to barbers or other users. Continue?',
      'Ваше фото будет отправлено в AI-сервис для генерации превью, затем удалено. Оно не показывается барберам или другим пользователям. Продолжить?',
      "Suratingiz soch ko'rinishini yaratish uchun AI xizmatiga yuboriladi, so'ng o'chiriladi. U barberlarga yoki boshqalarga ko'rsatilmaydi. Davom etamizmi?");
  static String get aiConsentAccept =>
      _t('Send & generate', 'Отправить', 'Yuborish');
  static String get aiPhotoUnreadable => _t(
      "Couldn't read this photo. Try another one.",
      'Не удалось прочитать фото. Попробуйте другое.',
      "Bu suratni o'qib bo'lmadi. Boshqasini tanlang.");
  static String get aiRenderFailed => _t(
      "AI render didn't work", 'Не удалось сгенерировать', 'AI ishlamadi');
  static String get connectAiForHair => _t('Connect AI for photo-real hair',
      'Подключите AI для реалистичных причёсок', 'Realistik sochlar uchun AI ulang');
  static String get noPhotoSelected => _t(
      'No photo selected — try the demo face.',
      'Фото не выбрано — попробуйте демо.',
      "Surat tanlanmadi — demoni sinab ko'ring.");

  // ── Shop detail ───────────────────────────────────────
  static String get insideTheShop =>
      _t('Inside the shop', 'Внутри', 'Ichkarida');
  static String get bookNow => _t('Book now', 'Записаться', 'Yozilish');
  static String get reviewsWord => _t('Reviews', 'Отзывы', 'Sharhlar');
  static String get writeWord => _t('Write', 'Написать', 'Yozish');
  static String get postReview => _t('Post review', 'Опубликовать', 'Joylash');
  static String get reviewEmpty => _t('Add a few words first ✍️',
      'Напишите пару слов ✍️', "Avval bir necha so'z yozing ✍️");
  static String get reviewThanks => _t('Thanks for your review ✂️',
      'Спасибо за отзыв ✂️', 'Sharhingiz uchun rahmat ✂️');
  static String get howWasVisit =>
      _t('How was your visit?', 'Как прошёл визит?', 'Tashrifingiz qanday o‘tdi?');
  static String get leaveReview =>
      _t('Leave a review', 'Оставить отзыв', 'Sharh qoldirish');
  static String get rateYourVisit => _t('Rate your visit',
      'Оцените визит', 'Tashrifingizni baholang');
  static String reviewsCount(int n) =>
      _t('$n reviews', '$n отзывов', '$n sharh');

  // ── Home quick actions ────────────────────────────────
  static String get quickBook => _t('Book', 'Запись', 'Yozilish');
  static String get quickBookSub =>
      _t('find your barber', 'найти барбера', 'barber topish');
  static String get quickAi => _t('AI style', 'AI-стиль', 'AI sinash');
  static String get quickAiSub =>
      _t('see your style', 'ваш новый образ', 'yangi uslub');
  static String get quickNear => _t('Near me', 'Рядом', 'Yaqinda');
  static String get quickNearSub =>
      _t('shops on map', 'на карте', 'xaritada');
  static String get quickCuts => _t('Visits', 'Визиты', 'Yozuvlar');
  static String get quickCutsSub =>
      _t('your visits', 'ваши визиты', 'tashriflar');

  // ════════════════════════════════════════════════════════
  //  BARBER MODE
  // ════════════════════════════════════════════════════════

  // ── Barber: shared ────────────────────────────────────
  static String get youWord => _t('You', 'Вы', 'Siz');
  static String barberHi(String name) =>
      _t('Hi, $name 👋', 'Привет, $name 👋', 'Salom, $name 👋');
  static String get upcomingWord =>
      _t('Upcoming', 'Предстоящие', 'Kelgusi');
  static String get bookedWord => _t('Booked', 'Доход', 'Daromad');
  static String get completedWord =>
      _t('Completed', 'Завершено', 'Yakunlandi');

  // ── Barber: Today dashboard ───────────────────────────
  static String barberNewRequests(int n) => _t(
      n == 1 ? '1 new request' : '$n new requests',
      'Новых заявок: $n',
      "Yangi so'rovlar: $n");
  static String get tapToConfirmDecline => _t('Tap to confirm or decline',
      'Нажмите, чтобы подтвердить или отклонить',
      'Tasdiqlash yoki rad etish uchun bosing');
  static String get allCaughtUp =>
      _t("You're all caught up", 'Всё разобрано', 'Hammasi tartibda');
  static String get noRequestsWaiting => _t('No requests waiting right now.',
      'Сейчас нет ожидающих заявок.', "Hozircha kutayotgan so'rov yo'q.");
  static String get nextClient =>
      _t('Next client', 'Следующий клиент', 'Keyingi mijoz');
  static String get todaysSchedule =>
      _t("Today's schedule", 'Расписание на сегодня', 'Bugungi jadval');
  static String get nothingBookedToday => _t(
      'Nothing booked today — enjoy the break ☕',
      'На сегодня записей нет — отдохните ☕',
      "Bugun yozuv yo'q — dam oling ☕");

  // ── Barber: Requests ──────────────────────────────────
  static String get requestsTitle => _t('Requests', 'Заявки', "So'rovlar");
  static String get noPendingRequests => _t('No pending requests right now',
      'Сейчас нет новых заявок', "Hozircha yangi so'rov yo'q");
  static String clientsWaiting(int n) => _t(
      n == 1 ? '1 client waiting for your OK' : '$n clients waiting for your OK',
      'Ждут вашего подтверждения: $n',
      'Tasdigʻingizni kutmoqda: $n');
  static String get allCaughtUpCut =>
      _t('All caught up ✂️', 'Всё разобрано ✂️', 'Hammasi tayyor ✂️');
  static String get newRequestsAppearHere => _t(
      'New requests will appear here.',
      'Новые заявки появятся здесь.',
      "Yangi so'rovlar shu yerda chiqadi.");
  static String get decline => _t('Decline', 'Отклонить', 'Rad etish');
  static String get declinedToast => _t('Declined', 'Отклонено', 'Rad etildi');
  static String confirmedToast(String name) => _t(
      'Confirmed — $name notified ✓',
      'Подтверждено — $name уведомлён ✓',
      'Tasdiqlandi — $name xabardor qilindi ✓');

  // ── Barber: Schedule ──────────────────────────────────
  static String get scheduleTitle =>
      _t('Schedule', 'Расписание', 'Jadval');
  static String upcomingCountLabel(int n) =>
      _t('$n upcoming', 'Предстоящих: $n', 'Kelgusi: $n');
  static String get freeWord => _t('free', 'свободно', "bo'sh");
  static String bookingsCount(int n) => _t(
      n == 1 ? '1 booking' : '$n bookings', 'Записей: $n', 'Yozuvlar: $n');
  static String get nothingBooked =>
      _t('Nothing booked', 'Нет записей', "Yozuv yo'q");
  static String get dayWideOpen => _t('This day is wide open.',
      'Этот день полностью свободен.', "Bu kun butunlay bo'sh.");
  // status labels (sheet)
  static String get stPendingRequest =>
      _t('Pending request', 'Ожидает подтверждения', 'Tasdiq kutilmoqda');
  static String get stConfirmed =>
      _t('Confirmed', 'Подтверждено', 'Tasdiqlandi');
  static String get stCompleted =>
      _t('Completed', 'Завершено', 'Yakunlandi');
  static String get stNoShow => _t('No-show', 'Не пришёл', 'Kelmadi');
  static String get stDeclined => _t('Declined', 'Отклонено', 'Rad etildi');
  static String get stCancelled => _t('Cancelled', 'Отменено', 'Bekor qilindi');
  // tags (uppercase pills)
  static String get tagPending => _t('PENDING', 'ОЖИДАЕТ', 'KUTILMOQDA');
  static String get tagConfirmed => _t('CONFIRMED', 'ПОДТВ.', 'TASDIQ');
  static String get tagDone => _t('DONE', 'ГОТОВО', 'TAYYOR');
  static String get tagNoShow => _t('NO-SHOW', 'НЕ ПРИШЁЛ', 'KELMADI');
  // actions
  static String get markDone => _t('Mark done', 'Завершить', 'Yakunlash');
  static String get noShowAction => _t('No-show', 'Не пришёл', 'Kelmadi');
  static String get confirmWord =>
      _t('Confirm', 'Подтвердить', 'Tasdiqlash');
  static String get closeWord => _t('Close', 'Закрыть', 'Yopish');

  // ── Barber: Profile ───────────────────────────────────
  static String get barberTag => _t('BARBER', 'БАРБЕР', 'SARTAROSH');
  static String get profileTab => _t('Profile', 'Профиль', 'Profil');

  // ── Bottom nav labels (short — they live inside the active chip) ──
  static String get navHome => _t('Home', 'Главная', 'Bosh');
  static String get navExplore => _t('Explore', 'Обзор', 'Kashf');
  static String get navChats => _t('Chats', 'Чаты', 'Chatlar');
  static String get navProfile => _t('Profile', 'Профиль', 'Profil');
  static String get navToday => _t('Today', 'Сегодня', 'Bugun');
  static String get navRequests => _t('Requests', 'Заявки', "So'rovlar");
  static String get navSchedule => _t('Schedule', 'График', 'Jadval');

  // ── Home feed mode toggle (Shops | Barbers) + spotlight badges ──
  static String get feedShops => _t('Shops', 'Салоны', 'Salonlar');
  static String get feedBarbers => _t('Barbers', 'Барберы', 'Barberlar');
  static String get boostedPill => _t('Boosted', 'В топе', 'Topda');
  static String get searchBarbersHint =>
      _t('Find your barber…', 'Найти барбера…', 'Barberingizni toping…');

  // ── "Continue with Telegram" (the market-native primary sign-in) ──
  static String get tgContinue => _t('Continue with Telegram',
      'Войти через Telegram', 'Telegram orqali kirish');
  static String get tgWaiting => _t(
      'In Telegram: tap START, then share your number…',
      'В Telegram: нажмите START и поделитесь номером…',
      "Telegramda: START bosing, so'ng raqamni ulashing…");
  static String get tgVerifiesNumber => _t(
      'Telegram confirms your number — no SMS needed',
      'Telegram подтвердит ваш номер — SMS не нужен',
      'Telegram raqamingizni tasdiqlaydi — SMS kerak emas');
  static String get tgFailed => _t(
      "Telegram sign-in didn't complete — try again",
      'Вход через Telegram не завершён — попробуйте ещё раз',
      "Telegram orqali kirish yakunlanmadi — qayta urining");
  static String get tgOr =>
      _t('or sign up with details', 'или по данным', "yoki ma'lumotlar bilan");
  static String get tgDefaultName => _t('Telegram user',
      'Пользователь Telegram', 'Telegram foydalanuvchisi');

  // ── "Continue with Google" (one tap, verified email, no typing) ──
  static String get googleContinue => _t('Continue with Google',
      'Войти через Google', 'Google orqali kirish');
  static String get googleSigningIn =>
      _t('Signing in…', 'Вход…', 'Kirilmoqda…');
  static String get googleFailed => _t(
      "Google sign-in didn't complete — try again",
      'Вход через Google не завершён — попробуйте ещё раз',
      'Google orqali kirish yakunlanmadi — qayta urining');
  // Debug builds only — a real user never sees this.
  static String get googleNotConfigured => _t(
      'Google sign-in needs its Web client ID (SupabaseConfig)',
      'Для входа через Google нужен Web client ID (SupabaseConfig)',
      'Google uchun Web client ID kerak (SupabaseConfig)');

  // ── The auth gate (the front door — identity before anything else) ──
  static String get authClientTitle =>
      _t('Book in ', 'Записаться за ', 'Yozilish ');
  static String get authClientTitleMark =>
      _t('one tap', 'одно касание', 'bir bosishda');
  static String get authBarberTitle => _t('Your chair,\n', 'Ваше кресло,\n', 'Kreslongiz,\n');
  static String get authBarberTitleMark =>
      _t('your rules', 'ваши правила', 'sizning qoidangiz');
  static String get authClientWhy => _t(
      'Sign in with the app you already use. Your barber gets a number to reach you on if he runs late — nothing else.',
      'Войдите через привычное приложение. Барберу нужен только номер, чтобы предупредить об опоздании.',
      "O'zingiz ishlatadigan ilova orqali kiring. Barberga faqat kechiksa xabar berish uchun raqam kerak.");
  static String get authBarberWhy => _t(
      'Clients only book barbers with a verified number. Sign in once and your chair goes live.',
      'Клиенты записываются только к барберам с подтверждённым номером. Войдите — и кресло активно.',
      "Mijozlar faqat tasdiqlangan raqamli barberlarga yoziladi. Kiring — kreslongiz faol bo'ladi.");
  static String get authTrustClient => _t(
      'Fade never sees a password. Your number is used for bookings only — never shown to other clients.',
      'Fade не видит пароль. Номер используется только для записей и не виден другим клиентам.',
      "Fade parolni ko'rmaydi. Raqam faqat yozilish uchun — boshqa mijozlarga ko'rinmaydi.");
  static String get authTrustBarber => _t(
      'Fade never sees a password. A verified number is what clients trust — and what keeps no-shows accountable.',
      'Fade не видит пароль. Подтверждённый номер — это доверие клиентов и защита от неявок.',
      "Fade parolni ko'rmaydi. Tasdiqlangan raqam — mijoz ishonchi va kelmaganlik uchun javobgarlik.");
  static String get authNoProviders => _t(
      'No sign-in method is configured in this build.',
      'В этой сборке не настроен ни один способ входа.',
      "Bu buildda hech qanday kirish usuli sozlanmagan.");
  static String get barberPhoneVerified => _t('Verified — clients reach you here',
      'Подтверждён — клиенты звонят сюда', 'Tasdiqlangan — mijozlar shu raqamga');
  static String get barberPhoneChatOnly => _t(
      'Clients will message you in the app',
      'Клиенты будут писать вам в приложении',
      'Mijozlar sizga ilova orqali yozadi');
  static String get barberPhoneMissing => _t('No number on your account',
      'На аккаунте нет номера', 'Hisobingizda raqam yo\'q');
  static String get authPhoneInstead => _t('No Telegram? Use my phone number',
      'Нет Telegram? Войти по номеру', 'Telegram yo\'qmi? Raqam orqali');
  static String get authSmsSub => _t(
      "We'll text you a code to confirm the number.",
      'Отправим код в SMS для подтверждения номера.',
      "Raqamni tasdiqlash uchun SMS kod yuboramiz.");
  static String get authSendCode =>
      _t('Send code', 'Отправить код', 'Kod yuborish');
  static String get okGotIt => _t('Got it', 'Понятно', 'Tushunarli');
  static String get payComingSoonTitle => _t('Payments launching soon',
      'Оплата скоро заработает', "To'lovlar tez orada");
  static String get payComingSoonSub => _t(
      "Card payments go live shortly — you'll be able to activate this then.",
      'Оплата картой скоро появится — тогда это можно будет активировать.',
      "Karta orqali to'lov tez orada ishga tushadi — o'shanda faollashtirasiz.");
  static String get tgPhraseLabel => _t('Your check phrase',
      'Ваша проверочная фраза', 'Tekshiruv so\'zingiz');
  static String get tgNeedsContactShare => _t(
      'Telegram confirmed you but shared no number — tap the contact button and retry',
      'Telegram подтвердил вас, но не передал номер — нажмите кнопку контакта и повторите',
      "Telegram sizni tasdiqladi, lekin raqam ulashilmadi — kontakt tugmasini bosing va qayta uring");

  // ── Display-time translation for CATALOGUE text ─────────────────────────
  // The mock data ships English (service names, specialties, taglines, tags).
  // tr() localizes them at display time; unknown strings pass through
  // unchanged, so user-created services etc. are always safe to wrap. Real
  // backend data will arrive localized and simply flow through.
  static String tr(String s) {
    final m = _dataTr[s];
    if (m == null) return s;
    return _t(s, m.$1, m.$2);
  }

  static const Map<String, (String, String)> _dataTr = {
    // ── Hairstyles ────────────────────────────────────────────────────────
    // These live in HairData as English literals because the same strings are
    // sent to the image model as a prompt. Only the DISPLAY sites go through
    // L.tr; the prompt sites deliberately keep the English.
    'Classic Taper': ('Классический тейпер', 'Klassik teyper'),
    'Textured Crop': ('Текстурный кроп', 'Teksturali krop'),
    'Pompadour': ('Помпадур', 'Pompadur'),
    'Buzz Cut': ('Под машинку', 'Mashinka bilan'),
    'Slick Back': ('Зачёс назад', 'Orqaga taralgan'),
    'Curly Top': ('Кудри сверху', 'Jingalak soch'),
    'Clean, gradual fade on the sides with length kept on top. Timeless and office-friendly.':
        (
      'Аккуратное растушёванное сведение по бокам, длина сверху. Классика на все времена.',
      'Yon tomonlarda toza fade, tepada uzunlik saqlanadi. Har doim mos keladigan klassika.'
    ),
    'Choppy, textured top with a faded back and sides. Adds movement and hides thinning.':
        (
      'Рваный текстурный верх с выбритыми боками. Добавляет объём и скрывает поредение.',
      'Tepasi teksturali, yon va orqa tomoni fade. Harakat qoʻshadi va siyraklikni yashiradi.'
    ),
    'Volume swept up and back from the forehead. Bold, retro, and full of height.':
        (
      'Объём зачёсан вверх и назад ото лба. Смело, ретро и с высотой.',
      'Peshonadan yuqoriga va orqaga taralgan hajm. Dadil, retro va balandlik beradi.'
    ),
    'Uniform short clipper cut. Fuss-free, sharp, and lets a strong jaw do the talking.':
        (
      'Ровная короткая стрижка машинкой. Просто, чётко и подчёркивает челюсть.',
      'Bir xil kalta mashinka olish. Sodda, aniq va jagʻni namoyon qiladi.'
    ),
    'Everything combed straight back with a glossy finish. Confident and grown-up.':
        (
      'Всё зачёсано назад с глянцевым финишем. Уверенно и по-взрослому.',
      'Hammasi orqaga taralgan, yaltiroq tugatish bilan. Ishonchli va yetuk.'
    ),
    'Natural curl left long on top with tidy sides. Adds height and softens a strong jaw.':
        (
      'Естественные кудри сверху, аккуратные бока. Добавляет высоту и смягчает челюсть.',
      'Tepada tabiiy jingalak, yonlari ozoda. Balandlik qoʻshadi va jagʻni yumshatadi.'
    ),
    // Length + upkeep chips
    'Short sides': ('Короткие бока', 'Kalta yonlar'),
    'Short': ('Короткая', 'Kalta'),
    'Medium': ('Средняя', 'Oʻrtacha'),
    'Very short': ('Очень короткая', 'Juda kalta'),
    'Medium / long': ('Средняя / длинная', 'Oʻrtacha / uzun'),
    'No upkeep': ('Без ухода', 'Parvarishsiz'),
    'Low upkeep': ('Простой уход', 'Oson parvarish'),
    'Medium upkeep': ('Средний уход', 'Oʻrtacha parvarish'),
    'High upkeep': ('Требует ухода', 'Parvarish talab qiladi'),

    // Services
    'Classic Haircut': ('Классическая стрижка', 'Klassik soch olish'),
    'Beard Trim': ('Оформление бороды', 'Soqolga shakl berish'),
    'Hot Towel Shave': (
      'Бритьё с горячим полотенцем',
      'Issiq sochiqli soqol olish'
    ),
    'Hair & Beard Combo': ('Стрижка + борода', 'Soch + soqol kombo'),
    'Kids Cut': ('Детская стрижка', 'Bolalar soch olishi'),
    'Hair Color': ('Окрашивание', "Soch bo'yash"),
    // Service descriptions
    'Precision cut tailored to your style and face shape.': (
      'Точная стрижка под ваш стиль и форму лица.',
      "Uslubingiz va yuz shaklingizga mos aniq soch olish."
    ),
    'Shaping, lining, and conditioning for a defined look.': (
      'Форма, контуры и уход для чёткого образа.',
      "Shakl, kontur va parvarish — aniq ko'rinish uchun."
    ),
    'Traditional straight-razor shave with hot towel finish.': (
      'Классическое бритьё опасной бритвой, финиш — горячее полотенце.',
      "An'anaviy ustara bilan, yakunida issiq sochiq."
    ),
    'Full service: haircut plus beard shaping and styling.': (
      'Полный сервис: стрижка плюс оформление бороды.',
      "To'liq xizmat: soch olish va soqolga shakl berish."
    ),
    'Patient, careful cuts for kids under 12.': (
      'Терпеливо и аккуратно — детям до 12 лет.',
      "12 yoshgacha bolalarga sabr bilan, ehtiyotkorona."
    ),
    'Single-process color, gloss, or grey blending.': (
      'Окрашивание, глянец или маскировка седины.',
      "Bo'yash, jilo yoki oq sochlarni tekislash."
    ),
    // Barber specialties
    'Fades & textures': ('Фейды и текстуры', 'Feyd va tekstura'),
    'Classic & beard': ('Классика и борода', 'Klassika va soqol'),
    'Modern styles': ('Современные стили', 'Zamonaviy uslublar'),
    'Kids & families': ('Дети и семьи', 'Bolalar va oilalar'),
    // Shop taglines
    'Premium cuts, classic vibes': (
      'Премиум-стрижки, классический вайб',
      'Premium soch olish, klassik ruh'
    ),
    'Neighborhood cuts since 2008': (
      'Стрижки по-соседски с 2008 года',
      '2008 yildan beri mahalla sartaroshi'
    ),
    "Modern men's grooming": (
      'Современный мужской груминг',
      'Zamonaviy erkaklar parvarishi'
    ),
    'Sharp cuts, sharper attitude': (
      'Острые стрижки, дерзкий характер',
      "O'tkir soch olish, o'tkir xarakter"
    ),
    'Traditional barbering reimagined': (
      'Традиции барберинга по-новому',
      "An'anaviy sartaroshlik yangicha"
    ),
    // Shop tags
    'Premium': ('Премиум', 'Premium'),
    'Beard expert': ('Эксперт по бороде', 'Soqol ustasi'),
    'Fades': ('Фейды', 'Feyd'),
    'Family-friendly': ('Для всей семьи', 'Oilaviy'),
    'Classic': ('Классика', 'Klassika'),
    'Walk-ins': ('Без записи', 'Navbatsiz'),
    'Color': ('Окрашивание', "Bo'yash"),
    'Skincare': ('Уход за кожей', 'Teri parvarishi'),
    'Modern': ('Модерн', 'Zamonaviy'),
    'Lineups': ('Контуры', 'Konturlar'),
    'Trendy': ('В тренде', 'Trendda'),
    'Traditional': ('Традиции', "An'anaviy"),
    'Hot towel': ('Горячее полотенце', 'Issiq sochiq'),
    // Categories
    'Haircut': ('Стрижка', 'Soch olish'),
    'Beard': ('Борода', 'Soqol'),
    'Shave': ('Бритьё', 'Soqol olish'),
    'Kids': ('Детям', 'Bolalar'),
  };
  static String get yourServices =>
      _t('Your services', 'Ваши услуги', 'Xizmatlaringiz');
  static String get bookingAsClient => _t('Booking as a client?',
      'Записаться как клиент?', 'Mijoz sifatida yozilasizmi?');
  static String get switchClientBody => _t(
      'Switch back to the customer side to book your own cuts.',
      'Вернитесь на сторону клиента, чтобы записаться самому.',
      "O'zingiz yozilish uchun mijoz tomoniga qayting.");
  static String get switchToClient =>
      _t('Switch to Client mode', 'В режим клиента', 'Mijoz rejimiga');

  // ── Barber: service management ────────────────────────
  static String get servicesHint => _t(
      'Tap a service to edit price & time, or switch it off.',
      'Нажмите на услугу, чтобы изменить цену и время, или выключите её.',
      "Narx va vaqtni tahrirlash uchun xizmatga bosing yoki o'chiring.");
  static String get addServiceWord =>
      _t('Add service', 'Добавить услугу', "Xizmat qo'shish");
  static String get editServiceWord =>
      _t('Edit service', 'Изменить услугу', 'Xizmatni tahrirlash');
  static String get newServiceWord =>
      _t('New service', 'Новая услуга', 'Yangi xizmat');
  static String get serviceNameLabel =>
      _t('Service name', 'Название услуги', 'Xizmat nomi');
  static String get priceSomLabel =>
      _t("Price (so'm)", 'Цена (сум)', "Narx (so'm)");
  static String get durationMinLabel =>
      _t('Duration (min)', 'Время (мин)', 'Davomiyligi (daq)');
  static String get removeServiceQ => _t('Remove this service?',
      'Удалить эту услугу?', "Bu xizmat o'chirilsinmi?");
  static String get removeWord => _t('Remove', 'Удалить', "O'chirish");
  static String get offWord => _t('Off', 'Выкл', "O'chiq");
  static String get onWord => _t('On', 'Вкл', 'Yoniq');

  // ════════════════════════════════════════════════════════
  //  ONBOARDING
  // ════════════════════════════════════════════════════════

  // ── Role choice ───────────────────────────────────────
  static String get howUseFade => _t('How will you\nuse Fade?',
      'Как вы будете\nиспользовать Fade?', "Fade'dan qanday\nfoydalanasiz?");
  static String get pickYourSide => _t(
      'Pick your side — you can switch anytime.',
      'Выберите сторону — переключиться можно в любой момент.',
      'Tomoningizni tanlang — istalgan vaqtda almashtirasiz.');
  static String get imAClient => _t("I'm a Client", 'Я клиент', 'Men mijozman');
  static String get clientRoleSub => _t(
      'Find shops, book cuts, try styles with AI.',
      'Ищите барбершопы, записывайтесь, примеряйте образы с AI.',
      'Barbershop toping, yoziling, AI bilan uslub sinang.');
  static String get imABarber => _t("I'm a Barber", 'Я барбер', 'Men barberman');
  static String get barberRoleSub => _t(
      'Take bookings, confirm clients, manage your day.',
      'Принимайте записи, подтверждайте клиентов, ведите день.',
      'Yozuvlarni qabul qiling, mijozlarni tasdiqlang, kuningizni boshqaring.');

  // ── Barber registration ───────────────────────────────
  static String get leaveBarberSetupQ => _t('Leave barber setup?',
      'Выйти из настройки барбера?', 'Barber sozlashdan chiqasizmi?');
  static String get leaveBarberSetupBody => _t(
      "You'll be signed out and can choose again — as a client or a barber.",
      'Вы выйдете из аккаунта и сможете выбрать снова — клиент или барбер.',
      "Hisobdan chiqasiz va qaytadan tanlashingiz mumkin — mijoz yoki barber sifatida.");
  static String get languageNext =>
      _t('Continue', 'Далее', 'Davom etish');
  static String get setUpBarberProfile => _t('Set up your\nbarber profile',
      'Настройте свой\nпрофиль барбера', 'Barber profilingizni\nsozlang');
  static String get clientsSeeThis => _t(
      'Clients see this when they book you.',
      'Клиенты видят это при записи к вам.',
      "Mijozlar yozilganda buni ko'radi.");
  static String get addPhoto => _t('Add photo', 'Добавить фото', "Surat qo'shish");
  static String get firstNameLabel => _t('First name', 'Имя', 'Ism');
  static String get surnameLabel => _t('Surname', 'Фамилия', 'Familiya');
  static String get ageLabel => _t('Age', 'Возраст', 'Yosh');
  static String get shopNameLabel =>
      _t('Shop name', 'Название барбершопа', 'Barbershop nomi');
  static String get shopAddressLabel =>
      _t('Shop address', 'Адрес барбершопа', 'Barbershop manzili');
  static String get locatingWord =>
      _t('Locating…', 'Определяем…', 'Aniqlanmoqda…');
  static String get useMyLocation =>
      _t('Use my location', 'Моя локация', 'Joylashuvim');
  static String get finishOpenBarber => _t('Finish & open Barber mode',
      'Готово — открыть режим барбера', 'Tayyor — barber rejimini ochish');
  static String get errFirstName =>
      _t('Enter your first name', 'Введите имя', 'Ismingizni kiriting');
  static String get errSurname => _t(
      'Enter your surname', 'Введите фамилию', 'Familiyangizni kiriting');
  static String get errAge => _t('Enter a valid age (16–90)',
      'Введите возраст (16–90)', 'Yosh kiriting (16–90)');
  static String get errPhone => _t('Enter your phone number',
      'Введите номер телефона', 'Telefon raqamingizni kiriting');
  static String get errShopName => _t('Enter your shop name',
      'Введите название барбершопа', 'Barbershop nomini kiriting');
  static String get errShopAddress => _t('Add your shop address / location',
      'Укажите адрес барбершопа', "Barbershop manzilini qo'shing");
  static String get myLocationWord =>
      _t('My location', 'Моя локация', 'Mening joylashuvim');

  // ── Barber: attach to a shop (don't create one) ───────
  static String get chooseYourShop => _t('Choose your barbershop',
      'Выберите барбершоп', 'Barbershopni tanlang');
  static String get pickShopOnMap => _t(
      'Pick the shop you work at — on the map',
      'Выберите барбершоп, где вы работаете — на карте',
      'Ishlaydigan barbershopingizni xaritadan tanlang');
  static String get errChooseShop => _t('Pick the shop you work at',
      'Выберите ваш барбершоп', 'Ishlaydigan barbershopingizni tanlang');
  static String get selectShopTitle =>
      _t('Select your shop', 'Выберите барбершоп', 'Barbershopni tanlang');
  static String get whereDoYouCut => _t(
      'Where do you cut hair?', 'Где вы стрижёте?', 'Qayerda soch olasiz?');
  static String get searchYourShopHint => _t('Search your shop by name…',
      'Найдите барбершоп по названию…', 'Barbershopni nomi bo\'yicha qidiring…');
  static String get beFirstHere => _t(
      'Be the first barber here — put it on the map.',
      'Станьте первым барбером здесь — добавьте на карту.',
      'Bu yerda birinchi barber bo\'ling — xaritaga qo\'shing.');
  static String get iWorkHere =>
      _t('I work here', 'Я работаю здесь', 'Men shu yerda ishlayman');
  static String get notListedShop => _t(
      "Can't find your shop?",
      'Не нашли свой барбершоп?',
      "Barbershopingiz yo'qmi?");
  static String get addShopIn60 => _t(
      'Add it to the map in 60 seconds',
      'Добавьте его на карту за 60 секунд',
      "Uni 60 soniyada xaritaga qo'shing");

  // ── Barber: owner vs. staff role ──────────────────────
  static String get yourRoleHere => _t('Your role here', 'Ваша роль',
      'Bu yerdagi rolingiz');
  static String get ownerRole =>
      _t('I own it', 'Я владелец', 'Men egasiman');
  static String get ownerRoleSub => _t('Manage the shop',
      'Управляю барбершопом', 'Barbershopni boshqaraman');
  static String get staffRole =>
      _t('I work here', 'Я работаю', 'Men ishlayman');
  static String get staffRoleSub => _t('Run my chair',
      'Веду своё кресло', "O'z o'rindig'im");
  static String get managedByOwner => _t(
      'The shop owner manages these details.',
      'Эти данные настраивает владелец барбершопа.',
      "Bu ma'lumotlarni barbershop egasi boshqaradi.");

  // ══ The Leader Loop — first-barber onboarding ═════════════
  static String leaderStepOf(int i, int n) =>
      _t('Step $i of $n', 'Шаг $i из $n', "$n dan $i-qadam");
  static String get sixtySeconds =>
      _t('≈ 60 seconds', '≈ 60 секунд', '≈ 60 soniya');

  // Step 1 · Geo-tag
  static String get pinShopTitle =>
      _t('Pin your shop', 'Отметьте барбершоп', 'Barbershopni belgilang');
  static String get pinShopSub => _t(
      'Drag the map so the pin sits on your door.',
      'Двигайте карту, чтобы булавка была на двери.',
      "Xaritani suring — belgi eshigingizda tursin.");
  static String get streetAddressLabel =>
      _t('Street address', 'Адрес', 'Ko\'cha manzili');
  static String get outsideCity => _t(
      "That's outside Tashkent — drag the pin back.",
      'Это вне Ташкента — верните булавку.',
      "Bu Toshkentdan tashqarida — belgini qaytaring.");

  // Step 2 · The Leader pitch
  static String get firstBarberHere => _t("You're the first\nbarber here",
      'Вы первый\nбарбер здесь', 'Siz bu yerdagi\nbirinchi barbersiz');
  static String get firstHereTag =>
      _t('FIRST HERE', 'ПЕРВЫЙ ЗДЕСЬ', 'BIRINCHI');
  static String get leaderPitchBody => _t(
      'Claim the Leader role to run this storefront — set the photo, shape the layout, and bring your coworkers in.',
      'Станьте Лидером: настройте фото, вид витрины и позовите коллег.',
      'Lider bo\'ling — suratni qo\'ying, ko\'rinishni sozlang va hamkasblaringizni chaqiring.');
  static String get leaderPerkStorefront => _t('Control the storefront layout',
      'Управляйте видом витрины', 'Vitrina ko\'rinishini boshqaring');
  static String get leaderPerkPhoto => _t('Upload the shop profile photo',
      'Загрузите фото барбершопа', 'Barbershop suratini yuklang');
  static String get leaderPerkInvite => _t('Invite & manage your coworkers',
      'Приглашайте и ведите команду', 'Hamkasblarni chaqiring va boshqaring');
  static String get claimLeaderRole =>
      _t('Claim Leader role', 'Стать Лидером', 'Lider bo\'lish');
  static String get justJoinAsBarber => _t(
      'No thanks — just let me rent a chair',
      'Нет, просто арендую кресло',
      "Yo'q — shunchaki o'rindiq ijaraga olaman");
  static String get leaderBadge => _t('LEADER', 'ЛИДЕР', 'LIDER');

  // Step 3 · Trust capture
  static String get proveRealTitle =>
      _t('One quick proof', 'Быстрое подтверждение', 'Bitta tez tasdiq');
  static String get proveRealSub => _t(
      'Snap your storefront, your chair, or a business card. Our team reviews it later — you get in right now.',
      'Сфотографируйте витрину, кресло или визитку. Мы проверим позже — вы заходите сейчас.',
      "Vitrina, o'rindiq yoki tashrifnomani suratga oling. Keyin tekshiramiz — hozir kirasiz.");
  static String get proofStorefront =>
      _t('Storefront sign', 'Вывеска', 'Vitrina belgisi');
  static String get proofWorkstation =>
      _t('Your workstation', 'Ваше рабочее место', 'Ish joyingiz');
  static String get proofCard =>
      _t('A business card', 'Визитка', 'Tashrifnoma');
  static String get takePhoto => _t('Take photo', 'Сделать фото', 'Suratga olish');
  static String get retakePhoto => _t('Retake', 'Переснять', 'Qayta olish');
  static String get skipForNow =>
      _t('Skip for now', 'Пропустить', "O'tkazib yuborish");
  static String get tempLeaderGranted => _t(
      'Leader access is live while we review',
      'Доступ Лидера активен, пока идёт проверка',
      "Tekshiruv davomida Lider huquqi ochiq");

  // Step 4 · The viral loop
  static String get bringYourTeam => _t('Shop created!\nBring your team',
      'Барбершоп готов!\nПозовите команду', 'Barbershop tayyor!\nJamoangizni chaqiring');
  static String get bringTeamSub => _t(
      'A full shop books more clients. Send your coworkers a one-tap invite to your roster.',
      'Полный барбершоп получает больше записей. Отправьте коллегам приглашение в один тап.',
      "To'la barbershop ko'proq mijoz oladi. Hamkasblaringizga bir bosishda taklif yuboring.");
  static String inviteMessageFor(String shop, String link) => _t(
      'Hey! I just added our shop "$shop" to Fade. Tap to join the roster so clients can see you work here: $link',
      'Привет! Я добавил наш барбершоп «$shop» в Fade. Нажми, чтобы попасть в состав: $link',
      'Salom! "$shop" barbershopimizni Fade\'ga qo\'shdim. Ro\'yxatga qo\'shilish uchun bosing: $link');
  static String get inviteViaTelegram =>
      _t('Invite via Telegram', 'Пригласить в Telegram', 'Telegram orqali');
  static String get inviteViaWhatsapp =>
      _t('Invite via WhatsApp', 'Пригласить в WhatsApp', 'WhatsApp orqali');
  static String get copyInvite =>
      _t('Copy invite link', 'Копировать ссылку', 'Havolani nusxalash');
  static String get enterMyShop =>
      _t('Enter my shop', 'Открыть барбершоп', 'Barbershopga kirish');
  static String get inviteLater =>
      _t("I'll invite later", 'Приглашу позже', 'Keyinroq chaqiraman');

  // Celebration
  static String youLeadNow(String shop) =>
      _t('You lead\n$shop', 'Вы ведёте\n$shop', 'Siz $shop\nyetakchisisiz');
  static String get welcomeLeader =>
      _t('Welcome, Leader', 'Добро пожаловать, Лидер', 'Xush kelibsiz, Lider');
  static String get shopIsLive => _t('Your shop is live on the map',
      'Ваш барбершоп на карте', 'Barbershopingiz xaritada');
  static String get joinedAsBarber => _t('You\'re on the roster',
      'Вы в составе', 'Siz ro\'yxatdasiz');

  // ══ Flow B — coworker onboarding ═════════════════════════
  static String get theTeam => _t('the team', 'команда', 'jamoa');
  static String get youAreInvited =>
      _t("YOU'RE INVITED", 'ВАС ПРИГЛАСИЛИ', 'SIZ TAKLIF QILINDINGIZ');
  static String invitedToRoster(String name) => _t(
      '$name invited you to join the digital roster',
      '$name пригласил вас в цифровой состав',
      "$name sizni raqamli ro'yxatga taklif qildi");
  static String get theCrew => _t('The crew', 'Команда', 'Jamoa');
  static String get joinThisStaff => _t(
      'Join this shop staff', 'Вступить в команду', "Jamoaga qo'shilish");
  static String get notMyShop => _t(
      'Not my shop', 'Не мой барбершоп', 'Mening barbershopim emas');
  static String get makeItYours =>
      _t('Make it\nyours', 'Сделайте\nсвоим', "O'zingizniki\nqiling");
  static String get makeItYoursSub => _t(
      'Your bio, your prices, your best work.',
      'Ваше био, цены и лучшие работы.',
      'Bio, narxlar va eng yaxshi ishlaringiz.');
  static String get yourBioLabel =>
      _t('Short bio', 'Кратко о себе', 'Qisqacha bio');
  static String get priceOverrideLabel => _t('Your price list (optional)',
      'Ваши цены (необязательно)', 'Narxlaringiz (ixtiyoriy)');
  static String get portfolioLabel =>
      _t('Portfolio', 'Портфолио', 'Portfolio');
  static String get sendJoinRequest => _t(
      'Send join request', 'Отправить заявку', "So'rov yuborish");
  static String get pendingWord =>
      _t('PENDING', 'ОЖИДАНИЕ', 'KUTILMOQDA');
  static String get waitingLeaderConfirm => _t(
      'Waiting for the\nLeader to confirm',
      'Ждём подтверждения\nЛидера',
      "Lider tasdig'ini\nkutmoqda");
  static String autoApproveIn(int h, int m) => _t(
      'Auto-approves in ${h}h ${m}m if no reply',
      'Авто-одобрение через $hч $mм',
      "Javob bo'lmasa ${h}s ${m}d da avtomatik");
  static String get whileYouWait =>
      _t('While you wait', 'Пока вы ждёте', 'Kutar ekansiz');
  static String get setUpPayouts => _t(
      'Set up card payouts', 'Настроить выплаты', "Kartaga to'lovni sozlash");
  static String get setAvailability => _t('Set your availability',
      'Указать доступность', 'Ish vaqtini belgilash');
  static String get addPortfolioItem => _t('Add portfolio photos',
      'Добавить фото работ', "Ish suratlarini qo'shish");
  static String get enterAppWhileWait => _t('Enter the app while you wait',
      'Войти, пока ждёте', 'Kutar ekan ilovaga kirish');
  static String get addWord => _t('Add', 'Добавить', "Qo'shish");

  // ══ Leader side — roster requests (Flow B, screen 4) ═════
  static String get rosterRequests =>
      _t('Join requests', 'Заявки в команду', "Ro'yxatga so'rovlar");
  static String get rosterRequestsSub => _t(
      'Barbers who want to join your shop',
      'Барберы, желающие присоединиться',
      "Barbershopingizga qo'shilmoqchilar");
  static String wantsToJoin(String name) => _t(
      '$name wants to join your staff',
      '$name хочет в вашу команду',
      "$name jamoangizga qo'shilmoqchi");
  static String get acceptWord => _t('Accept', 'Принять', 'Qabul');
  static String get denyWord => _t('Deny', 'Отклонить', 'Rad etish');
  static String autoPassesIn(int h) =>
      _t('auto-passes in ${h}h', 'авто через $hч', "${h}s da avto");
  static String barberAdded(String name) => _t(
      '$name added to your roster ✓',
      '$name в команде ✓',
      "$name qo'shildi ✓");
  static String barberDenied(String name) =>
      _t('Declined $name', '$name отклонён', "$name rad etildi");

  // ══ No-show shield & cancellation policy (#4) ═════════════
  static String get policyTitle => _t(
      'Cancellation policy', 'Политика отмены', 'Bekor qilish siyosati');
  static String get policyFreeUntil => _t('Free to cancel until 4 hours before',
      'Бесплатная отмена до 4 часов', "4 soat oldin bepul bekor qilinadi");
  static String get policyFeeLine => _t('Cancel later or miss it and 50% applies',
      'Позже или неявка — платите 50%', "Keyin yoki kelmasangiz — 50%");
  static String policyFeeAmount(String fee) =>
      _t('That would be $fee', 'Это составит $fee', "Bu $fee bo'ladi");
  static String get lateCancelTitle => _t("You're inside the 4-hour window",
      'Осталось меньше 4 часов', "4 soatdan kam qoldi");
  static String get lateCancelBody => _t(
      "Cancelling now means a 50% fee to protect your barber's time.",
      'Отмена сейчас — 50% комиссии за время барбера.',
      "Hozir bekor qilsangiz, barber vaqti uchun 50% to'lov.");
  static String cancelAndPayFee(String fee) => _t('Cancel & accept $fee fee',
      'Отменить и оплатить $fee', "Bekor qilish va $fee to'lash");
  static String get feeAppliedShort =>
      _t('Fee applied', 'Списана комиссия', "To'lov qo'llandi");
  static String noShowFeeRecorded(String fee) => _t('No-show fee recorded: $fee',
      'Комиссия за неявку: $fee', "Kelmaganlik uchun: $fee");
  static String get waiveFee => _t('Waive fee', 'Отменить комиссию', "To'lovni kechirish");
  static String get feeWaived => _t('Fee waived', 'Комиссия отменена', "To'lov kechirildi");
  static String get cardOnFileTitle =>
      _t('Secure this slot', 'Забронировать слот', 'Slotni band qilish');
  static String get cardOnFileBody => _t(
      "For high-value slots we place a temporary hold — not a charge. You're only charged if you cancel late or miss it.",
      'Для дорогих слотов — временная блокировка, не списание. Плата только при поздней отмене или неявке.',
      "Qimmat slotlar uchun vaqtincha ushlab turamiz — to'lov emas. Faqat kech bekor qilsangiz yoki kelmasangiz olinadi.");
  static String get itsAHoldNotCharge => _t('This is a hold, not a charge',
      'Это блокировка, не списание', "Bu ushlab turish, to'lov emas");
  static String continueWithProvider(String provider) => _t(
      'Continue with $provider', 'Продолжить с $provider', '$provider bilan davom etish');
  static String get cardOnFileAdded => _t('Card-on-file authorized',
      'Карта привязана', 'Karta biriktirildi');
  static String get protectedTag => _t('PROTECTED', 'ЗАЩИЩЁН', 'HIMOYALANGAN');
  static String get atRiskTag => _t('AT RISK', 'РИСК', 'XAVFDA');
  static String get repeatCancellerTag =>
      _t('REPEAT CANCELLER', 'ЧАСТЫЕ ОТМЕНЫ', "TEZ-TEZ BEKOR");
  static String get maybeLater => _t('Maybe later', 'Позже', 'Keyinroq');

  // ══ Walk-ins & calendar sync (#5) ════════════════════════
  static String get walkInWord => _t('Walk-in', 'Без записи', 'Navbatsiz');
  static String get logWalkInTitle =>
      _t('Log a walk-in', 'Добавить без записи', "Navbatsiz qo'shish");
  static String get logWalkInSub => _t(
      'Free forever — your calendar, your rules.',
      'Бесплатно навсегда — ваш календарь.',
      'Abadiy bepul — sizning kalendaringiz.');
  static String get walkInNameLabel =>
      _t('Client name', 'Имя клиента', 'Mijoz ismi');
  static String get walkInFreeTag =>
      _t('FREE · 0% commission', 'БЕСПЛАТНО · 0%', 'BEPUL · 0%');
  static String get walkInAdded => _t('Walk-in added — slot locked',
      'Добавлено — слот занят', "Qo'shildi — slot band");
  static String get serviceWord => _t('Service', 'Услуга', 'Xizmat');
  static String get removeWalkInQ => _t('Remove this walk-in?',
      'Удалить эту запись?', "Bu yozuvni o'chirasizmi?");
  static String get calendarSyncLabel =>
      _t('Calendar sync', 'Синхронизация', 'Kalendar sinxronizatsiyasi');
  static String get calendarSyncTitle => _t('Two-way calendar sync',
      'Двусторонняя синхронизация', 'Ikki tomonlama sinxronizatsiya');
  static String get calendarSyncBody => _t(
      "Connect Google or Apple Calendar and Fade blocks any time you're already busy — and pushes your Fade bookings back out. No more double-booking across the app, walk-ins and DMs.",
      'Подключите Google или Apple Календарь — Fade заблокирует занятое время и добавит ваши записи в календарь.',
      "Google yoki Apple Kalendarni ulang — Fade band vaqtlaringizni bloklaydi va yozuvlaringizni kalendarga qo'shadi.");
  static String get connectGoogleCal =>
      _t('Google Calendar', 'Google Календарь', 'Google Kalendar');
  static String get connectAppleCal =>
      _t('Apple Calendar', 'Apple Календарь', 'Apple Kalendar');
  static String get calConnected =>
      _t('Connected', 'Подключено', 'Ulangan');
  static String get calNotConnected =>
      _t('Not connected', 'Не подключено', 'Ulanmagan');
  static String get calBackendNote => _t(
      'Live sync connects with the backend — the busy-block engine already works offline.',
      'Живая синхронизация — с бэкендом; блокировка времени уже работает офлайн.',
      "Jonli sinxronizatsiya backend bilan — band-vaqt bloklash allaqachon ishlaydi.");
  static String get calConnectedToast =>
      _t('Calendar connected', 'Календарь подключён', 'Kalendar ulandi');

  // ══ Dual-key reviews (#3) ════════════════════════════════
  static String get rateYourBarber =>
      _t('Rate your barber', 'Оцените барбера', 'Barberni baholang');
  static String get rateTheShop =>
      _t('Rate the shop', 'Оцените барбершоп', 'Barbershopni baholang');
  static String get talentWord => _t('talent', 'мастерство', 'mahorat');
  static String get talentRating => _t('Talent', 'Мастерство', 'Mahorat');
  static String get shopRatingWord => _t('Shop', 'Барбершоп', 'Barbershop');
  static String get barberReviewHint => _t('How was the cut itself?',
      'Как сама стрижка?', 'Soch olish qanday edi?');
  static String get shopReviewHint => _t('Clean chairs, good vibe?',
      'Чисто, приятная атмосфера?', 'Toza, yoqimli muhitmi?');
  static String get barberTag2 => _t('BARBER', 'БАРБЕР', 'SARTAROSH');
  static String get shopTag => _t('SHOP', 'БАРБЕРШОП', 'BARBERSHOP');
  static String get reviewNeedsOne => _t('Rate the barber or the shop first ✍️',
      'Оцените барбера или барбершоп ✍️', 'Barber yoki barbershopni baholang ✍️');

  // ══ Barber wallet & tiered commission ════════════════════
  static String get walletTitle => _t('Wallet', 'Кошелёк', 'Hamyon');
  static String get walletBalanceLabel =>
      _t('Balance', 'Баланс', 'Balans');
  static String get walletVending => _t(
      'Load a little, keep booking. A small 5% per booking — half that on VIP.',
      'Пополните немного и принимайте записи. Небольшие 5% с записи — вдвое меньше на VIP.',
      "Ozgina soling va yozuvlarni qabul qiling. Har yozuvdan 5% — VIP'da yarmi.");
  static String get walletLowWarn => _t(
      'Low balance — top up to keep getting new clients',
      'Мало средств — пополните, чтобы получать клиентов',
      "Balans kam — yangi mijozlar uchun to'ldiring");
  static String get topUpWord => _t('Top up', 'Пополнить', "To'ldirish");
  static String get walletActivity => _t('Activity', 'История', 'Faoliyat');
  // ── Transaction feed (money in vs. commission out) ──
  static String get walletLegendIn =>
      _t('money in', 'приход', 'kirim');
  static String get walletLegendFee =>
      _t('commission', 'комиссия', 'komissiya');
  static String get walletFreeTag => _t('FREE', 'БЕСПЛ.', 'BEPUL');
  static String get txMoneyIn => _t('Money in', 'Пополнение', 'Kirim');
  static String get txCommissionFee =>
      _t('Commission fee', 'Комиссия', 'Komissiya');
  static String get txKeptFree =>
      _t('Regular — no fee', 'Постоянный — без сбора', 'Doimiy — bepul');
  static String get dateToday => _t('Today', 'Сегодня', 'Bugun');
  static String get dateYesterday =>
      _t('Yesterday', 'Вчера', 'Kecha');
  static String get howFeesWork =>
      _t('How fees work', 'Как работают сборы', "To'lovlar qanday");
  static String get tierFreeTitle => _t('Calendar & walk-ins',
      'Календарь и без записи', 'Kalendar va navbatsiz');
  static String get tierFreeSub =>
      _t('Free forever · 0%', 'Бесплатно · 0%', 'Abadiy bepul · 0%');
  static String get tierNewTitle =>
      _t('A new client Fade delivers', 'Новый клиент от Fade', 'Fade yangi mijoz');
  static String get tierNewSub =>
      _t('Just 5% · a fair value-match', 'Всего 5%', 'Atigi 5%');
  static String get tierRegularTitle => _t('Your regulars via your link',
      'Постоянные по вашей ссылке', 'Doimiylar havolangiz orqali');
  static String get tierRegularSub =>
      _t('~0% · they follow you', '~0% · они за вами', '~0% · siz bilan');
  static String get tierVipTitle =>
      _t('VIP Turbo Boost', 'VIP ускорение', 'VIP Turbo');
  static String get tierVipSub => _t('Top placement · beat the neighborhood',
      'Топ-место в районе', 'Hududda tepada');
  static String get yourLinkLabel =>
      _t('Your booking link', 'Ваша ссылка', 'Havolangiz');
  static String get shareYourLink =>
      _t('Share — regulars book free', 'Поделиться', 'Ulashish');
  static String get scanToBookMe =>
      _t('Scan to book me', 'Сканируй, чтобы записаться', 'Yozilish uchun skanerlang');
  static String get qrStickerHint => _t(
      'Regulars who scan this book you at 0% — stick it on your mirror.',
      'Постоянные по этому QR платят 0% — повесьте у зеркала.',
      'Bu QR orqali doimiylar 0% to\'laydi — koʻzguga yopishtiring.');
  static String get shareSticker =>
      _t('Share my QR', 'Поделиться QR', 'QR ulashish');
  static String get inviteClientsTitle =>
      _t('Invite clients', 'Пригласить клиентов', 'Mijoz taklif qiling');
  static String get inviteClientsSub => _t(
      'Send your link — friends book you in a tap',
      'Отправьте ссылку — запишутся в один тап',
      "Havolangizni yuboring — bir tegishda yoziladi");
  static String get shareVerb => _t('Share', 'Поделиться', 'Ulashish');
  static String get copyVerb => _t('Copy', 'Копировать', 'Nusxa');
  static String shareInviteMsg(String url) => _t(
      '✂️ Book your next haircut with me on Fade — $url',
      '✂️ Записывайтесь ко мне на стрижку в Fade — $url',
      "✂️ Fade orqali menga soch olishga yoziling — $url");
  static String get showThisToClients => _t('Clients scan this to book you',
      'Клиенты сканируют, чтобы записаться',
      'Mijozlar buni skanerlab yoziladi');
  // Client scanning a barber's code.
  static String get scanBarberTitle =>
      _t('Scan a barber', 'Сканировать барбера', 'Barberni skanerlash');
  static String get scanBarberHint => _t(
      "Point at a barber's Fade QR to book them",
      'Наведите на QR барбера в Fade, чтобы записаться',
      "Yozilish uchun barberning Fade QR-kodiga to'g'rilang");
  static String get scanNoBarber => _t(
      "That QR isn't a Fade barber link",
      'Это не ссылка барбера Fade',
      'Bu Fade barber havolasi emas');
  static String get scanTooEarly => _t(
      'Too early — verify at the appointment time',
      'Рано — подтвердите ко времени записи',
      'Erta — yozuv vaqtida tasdiqlang');
  static String get scanNeedTopUp => _t(
      'Top up your wallet to complete this cut',
      'Пополните кошелёк, чтобы завершить',
      "Yakunlash uchun hamyonni to'ldiring");
  static String get scanAlreadyDone => _t(
      'Already checked in', 'Уже отмечен', 'Allaqachon belgilangan');
  static String get slotTakenWarn => _t(
      'That slot is already taken',
      'Это время уже занято',
      "Bu vaqt allaqachon band");
  static String get linkCopiedToast =>
      _t('Link copied ✓', 'Ссылка скопирована ✓', 'Havola nusxalandi ✓');
  static String get getVipBoost => _t('Get VIP Boost', 'Купить VIP', 'VIP olish');
  static String topUpBySom(String som) =>
      _t('Add $som', 'Пополнить $som', "$som qo'shish");
  static String get walletVendingHint => _t(
      'Empty balance = empty chair. Loaded balance = packed schedule.',
      'Пустой баланс = пустое кресло. Полный = полное расписание.',
      "Bo'sh balans = bo'sh o'rindiq. To'la balans = to'la jadval.");

  // ══ QR check-in handshake ════════════════════════════════
  static String get bookingTicket =>
      _t('Booking ticket', 'Билет записи', 'Yozuv chiptasi');
  static String get showTicket =>
      _t('Show ticket', 'Показать билет', 'Chiptani ko\'rsatish');
  static String get showBookingTicket => _t('Show booking ticket',
      'Показать билет записи', 'Yozuv chiptasini ko\'rsatish');
  static String get ticketRefreshHint => _t(
      'This code refreshes every 30 seconds',
      'Код обновляется каждые 30 секунд',
      'Kod har 30 soniyada yangilanadi');
  static String get showAtCounter => _t(
      'Show this to your barber at the chair',
      'Покажите барберу в кресле',
      "O'rindiqda barberga ko'rsating");
  static String get scanClient =>
      _t('Scan client', 'Сканировать клиента', 'Mijozni skanerlash');
  static String get verifyingHandshake =>
      _t('Verifying…', 'Проверка…', 'Tekshirilmoqda…');

  // ── Check-in: the barber SHOWS a QR, the client SCANS it ──
  static String get checkInTitle =>
      _t('Check-in', 'Отметка визита', 'Tashrifni belgilash');
  static String get checkInShowHint => _t(
      'Show this to your client — they scan it to check in.',
      'Покажите это клиенту — он сканирует, чтобы отметиться.',
      'Buni mijozga ko\'rsating — u skanerlab belgilanadi.');
  static String get checkInManual =>
      _t('Check in', 'Отметить', 'Belgilash');
  static String get checkInScanTitle => _t("Scan the barber's code",
      'Сканируйте код барбера', 'Barber kodini skanerlang');
  static String get checkInScanHint => _t(
      "Point at the barber's check-in QR",
      'Наведите на QR-код барбера',
      'Barberning QR-kodiga to\'g\'rilang');
  static String get checkInNotBarberQr => _t(
      "That's not a barber check-in code",
      'Это не код отметки барбера',
      'Bu barber belgilash kodi emas');
  static String get checkInWrongBarber => _t(
      "That code is for a different barber than your booking",
      'Этот код другого барбера, не из вашей записи',
      "Bu kod yozuvingizdagidan boshqa barberniki");
  static String get checkedInOk =>
      _t('Checked in — enjoy your cut! ✂️', 'Визит отмечен! ✂️', 'Belgilandi! ✂️');
  static String get checkInTryLater => _t(
      "Couldn't check in just now — ask your barber",
      'Не удалось отметиться — обратитесь к барберу',
      'Hozir belgilanmadi — barberga ayting');
  static String get checkedInTitle =>
      _t('Checked in', 'Визит отмечен', 'Belgilandi');
  static String get checkedInSub => _t('Your visit is confirmed.',
      'Ваш визит подтверждён.', 'Tashrifingiz tasdiqlandi.');
  static String get checkInPromptTitle => _t('Check in at the chair',
      'Отметьтесь у кресла', 'Kresloda belgilaning');
  static String get checkInPromptSub => _t(
      "Scan your barber's QR when you arrive to confirm your visit.",
      'Отсканируйте QR барбера по прибытии, чтобы подтвердить визит.',
      'Kelganingizda barber QR-kodini skanerlab tasdiqlang.');
  static String get checkInScanCta => _t("Scan barber's QR",
      'Сканировать QR барбера', 'Barber QR-kodini skanerlash');
  static String get scanTodayTitle =>
      _t("Today's check-ins", 'Сегодняшние визиты', 'Bugungi tashriflar');
  static String get scanEmpty => _t('No one left to check in today',
      'Некого отметить сегодня', 'Bugun belgilash uchun hech kim yo\'q');
  static String get verifiedCheckedIn =>
      _t('Verified — checked in', 'Подтверждено — визит начат', 'Tasdiqlandi — kirdi');
  static String get commissionCharged =>
      _t('Commission charged', 'Комиссия списана', 'Komissiya olindi');
  static String get overdueTitle => _t('Overdue — not checked in',
      'Просрочено — не отмечен', 'Muddati o\'tgan — belgilanmagan');
  static String get markNoShowNoFee => _t('Mark no-show (no commission)',
      'Отметить неявку (без комиссии)', 'Kelmadi deb belgilash (komissiyasiz)');
  static String vipProgressLine(int n, int goal) => _t(
      '$n / $goal verified visits → VIP',
      '$n / $goal подтверждённых визитов → VIP',
      '$n / $goal tasdiqlangan tashrif → VIP');
  static String get vipUnlockedTitle =>
      _t('VIP unlocked 🎉', 'VIP открыт 🎉', 'VIP ochildi 🎉');
  static String get vipPerkSub => _t(
      'Priority slots & recognition — never a discount, always earned',
      'Приоритетные слоты и признание — не скидка, а заслуга',
      'Ustuvor slotlar va e\'tirof — chegirma emas, mukofot');
  static String get noShowCaution =>
      _t('3 no-shows = account blocked', '3 неявки = блокировка', '3 marta kelmaslik = bloklash');
  static String get bannedTitle =>
      _t('Booking paused', 'Запись приостановлена', 'Yozuv to\'xtatildi');
  static String get bannedBody => _t(
      'Your account is blocked after 3 no-shows. Contact the shop to restore booking.',
      'Аккаунт заблокирован после 3 неявок. Обратитесь в барбершоп.',
      "3 marta kelmaganingizdan so'ng bloklandi. Barbershop bilan bog'laning.");
  static String get reviewLockedHint => _t(
      'You can review after a visit here',
      'Отзыв можно оставить после визита',
      'Sharhni tashrifdan keyin qoldirasiz');

  // ══ VIP Turbo Boost (Tier 4) ═════════════════════════════
  static String get vipBoostHeadline => _t('Turbo Boost\nyour chair',
      'Разгоните\nсвоё кресло', "O'rindig'ingizni\ntezlashtiring");
  static String get vipBoostPitch => _t(
      "You've seen what Fade delivers. VIP puts you ahead of every barber in the neighborhood.",
      'Вы видели, что даёт Fade. VIP ставит вас впереди всех барберов района.',
      "Fade nima berishini ko'rdingiz. VIP sizni hududdagi barcha barberlardan oldinga qo'yadi.");
  static String get vipPerkGoldPin => _t('Gold pin on the map',
      'Золотая метка на карте', 'Xaritada oltin belgi');
  static String get vipPerkGoldPinSub => _t('Your shop stands out instantly',
      'Ваш барбершоп заметен сразу', 'Barbershopingiz darhol ajralib turadi');
  static String get vipPerkTopSearch => _t('Top of the search',
      'Топ в поиске', 'Qidiruvda birinchi');
  static String get vipPerkTopSearchSub => _t('First in your area\'s results',
      'Первый в результатах района', 'Hudud natijalarida birinchi');
  static String get vipPerkBadgePhoto => _t('Premium badge on your photo',
      'Премиум-значок на фото', 'Suratingizda premium belgi');
  static String get vipPerkBadgePhotoSub => _t('Clients see the gold tier',
      'Клиенты видят золотой уровень', 'Mijozlar oltin darajani ko\'radi');
  static String get vipPerkRosterTop => _t('Top of the shop roster',
      'Первый в составе барбершопа', "Ro'yxatda eng tepada");
  static String get vipPerkRosterTopSub => _t('First chair clients see',
      'Первое кресло для клиентов', 'Mijozlar ko\'radigan birinchi o\'rindiq');
  static String vipPerMonth(String som) =>
      _t('$som / month', '$som / месяц', '$som / oy');
  static String get buyVipNow =>
      _t('Activate VIP Boost', 'Активировать VIP', 'VIP faollashtirish');
  static String get vipActivated => _t('VIP active — you\'re boosted 🚀',
      'VIP активен — вы в топе 🚀', 'VIP faol — siz tepadasiz 🚀');
  static String vipActiveUntil(String date) =>
      _t('VIP active until $date', 'VIP до $date', '$date gacha VIP');
  static String get vipTag => _t('VIP', 'VIP', 'VIP');

  // ══ Barber Fuel — pay-as-you-go boosts (micro-transactions) ══
  static String get fuelTitle => _t('Barber Fuel', 'Топливо', 'Yoqilg\'i');
  static String get fillChairNow => _t('Fill your chair right now',
      'Заполните кресло прямо сейчас', 'O\'rindig\'ingizni hoziroq to\'ldiring');
  static String get fillChairNowSub => _t(
      'A dead hour? Spend one Up to jump to the top for an hour.',
      'Пустой час? Потратьте один Up — час в топе.',
      'Bo\'sh soatmi? Bitta Up sarflab, bir soat tepada bo\'ling.');
  static String upsInWallet(int n) => _t(
      '$n Ups in your wallet', '$n Up в кошельке', 'Hamyonda $n Up');
  static String get useBoostNow =>
      _t('Use a boost now', 'Использовать Boost', 'Boostni ishlatish');
  static String boostedUntilTime(String t) => _t('Boosted until $t 🚀',
      'В топе до $t 🚀', '$t gacha tepada 🚀');
  static String get outOfUps => _t('Out of Ups — grab a pack below',
      'Нет Up — купите пакет ниже', 'Up tugadi — quyidan paket oling');
  static String get boostOnToast => _t("Boost on — you're at the top 🚀",
      'Boost включён — вы в топе 🚀', 'Boost yoqildi — tepadasiz 🚀');
  static String upsUnit(int n) => _t('$n Ups', '$n Up', '$n Up');
  static String perBoostLabel(String som) =>
      _t('$som / boost', '$som / Boost', '$som / Boost');
  static String get bestValue =>
      _t('Best value', 'Выгодно', 'Eng foydali');
  // ── Boost: animated "what it does" showcase ──
  static String get boostRiseTitle => _t('Jump to the top — for an hour',
      'В топ — на один час', 'Bir soatga — tepaga');
  static String get boostRiseSub => _t(
      "Spend one Up and you're #1 in your area for 60 minutes — right when your chair is empty.",
      'Потратьте один Up — и вы №1 в районе на 60 минут, как раз когда кресло пустует.',
      "Bitta Up sarflang — 60 daqiqa hududda №1 bo'lasiz, aynan o'rindiq bo'sh paytda.");
  static String get boostYouRow =>
      _t('You · boosted', 'Вы · в топе', 'Siz · tepada');
  static String get boostTopTag => _t('TOP', 'ТОП', 'TOP');
  static String get boostHourLabel => _t('1 hour left', 'остался 1 час',
      '1 soat qoldi');
  static String get boostProofSuffix => _t('more walk-ins in a boosted hour',
      'больше клиентов за час в топе', "tepadagi soatda ko'proq mijoz");
  static String get boostProofSub => _t(
      'The moment you flip it on, new clients see you first.',
      'Как только включаете — новые клиенты видят вас первым.',
      "Yoqishingiz bilan yangi mijozlar sizni birinchi ko'radi.");
  static String get orGoUnlimited => _t('Or go unlimited',
      'Или безлимит', 'Yoki cheksiz');
  static String upsAddedToast(int n) =>
      _t('$n Ups added ⚡', '$n Up добавлено ⚡', '$n Up qo\'shildi ⚡');
  static String get buyWord => _t('Buy', 'Купить', 'Sotib olish');

  // ── Client registration ───────────────────────────────
  static String get whatsYourName =>
      _t("What's your\nname?", 'Как вас\nзовут?', 'Ismingiz\nnima?');
  static String get soBarberKnows => _t('So your barber knows who booked.',
      'Чтобы барбер знал, кто записался.', 'Barber kim yozilganini bilishi uchun.');
  static String get photoOptional =>
      _t('Photo (optional)', 'Фото (необязательно)', 'Surat (ixtiyoriy)');
  static String get phoneOptional =>
      _t('Phone (optional)', 'Телефон (необязательно)', 'Telefon (ixtiyoriy)');
  static String get continueWord => _t('Continue', 'Продолжить', 'Davom etish');

  // ── Onboarding intro ──────────────────────────────────
  static String get bookYourBarberLine =>
      _t('Book your barber\n', 'Запишись к барберу\n', 'Barberingizga\n');
  static String get inSeconds =>
      _t('in seconds', 'за секунды', 'soniyalarda');
  static String get onboardingSub => _t(
      'Find a shop nearby, pick a time, done.\nNo calls, no waiting in line.',
      'Найдите барбершоп рядом, выберите время — готово.\nБез звонков и очередей.',
      "Yaqin barbershop toping, vaqt tanlang — tamom.\nQo'ng'iroqsiz, navbatsiz.");
  static String get getStarted =>
      _t('Get started', 'Начать', 'Boshlash');

  // ════════════════════════════════════════════════════════
  //  CLIENT EXTRAS (review, confirm, explore, bookings, etc.)
  // ════════════════════════════════════════════════════════

  // ── Booking review ────────────────────────────────────
  static String get reviewBookingTitle =>
      _t('Review booking', 'Проверьте запись', 'Yozuvni tekshiring');
  static String get locationLabel =>
      _t('Location', 'Локация', 'Joylashuv');
  static String get barberLabel => _t('Barber', 'Барбер', 'Sartarosh');
  static String get serviceLabel => _t('Service', 'Услуга', 'Xizmat');
  static String get whenLabel => _t('When', 'Когда', 'Qachon');
  static String get totalLabel => _t('Total', 'Итого', 'Jami');

  // ── Booking confirmation ──────────────────────────────
  static String get requestSent =>
      _t('Request sent!', 'Заявка отправлена!', "So'rov yuborildi!");
  static String get bookedExcl =>
      _t('Booked!', 'Записано!', 'Yozildi!');
  static String sentToBarber(String name) => _t(
      "Sent to $name — your home card updates the moment they reply.",
      'Отправлено $name — карточка на главной обновится, как только ответят.',
      "$name'ga yuborildi — javob berishi bilan bosh sahifadagi karta yangilanadi.");

  // ── Waiting for reply (request pending the barber's confirmation) ──
  static String get waitingTitle =>
      _t('Waiting for reply', 'Ожидаем ответа', 'Javob kutilmoqda');
  static String waitingSub(String name) => _t(
      '$name is reviewing your request',
      '$name рассматривает вашу заявку',
      "$name so'rovingizni ko'rib chiqmoqda");
  static String waitingMany(int n) => _t(
      '$n requests awaiting confirmation',
      '$n заявок ожидают подтверждения',
      "$n ta so'rov tasdiqlanishini kutmoqda");
  static String get waitingHint => _t(
      'This card updates the moment they reply',
      'Эта карточка обновится, как только ответят',
      'Javob berishlari bilan bu karta yangilanadi');

  // ── Explore ───────────────────────────────────────────
  static String get searchShopsHint => _t('Search shops, fades, beards…',
      'Поиск барбершопов, фейдов…', 'Barbershop, fade, soqol qidirish…');
  static String get filterAll => _t('All', 'Все', 'Hammasi');
  static String get filterFeatured => _t('Featured', 'Топ', 'Tanlangan');
  static String get filterNearby => _t('Nearby', 'Рядом', 'Yaqin');
  static String get filterSaved => _t('Saved', 'Избранное', 'Saqlangan');
  static String get nothingMatches => _t('hmm, nothing matches that…',
      'хм, ничего не найдено…', 'hmm, hech nima topilmadi…');

  // ── My bookings ───────────────────────────────────────
  static String get tabPast => _t('Past', 'Прошлые', "O'tgan");
  static String get tabCancelled =>
      _t('Cancelled', 'Отменённые', 'Bekor qilingan');
  static String get likedIt => _t('liked it?', 'понравилось?', 'yoqdimi?');
  static String get changedMind => _t('changed your mind?', 'передумали?',
      "fikringiz o'zgardimi?");

  // ── Profile ───────────────────────────────────────────
  static String get barberModeTitle =>
      _t('Barber mode', 'Режим барбера', 'Barber rejimi');
  static String get barberModeSub => _t('Manage bookings & confirm clients',
      'Записи и подтверждение клиентов', 'Yozuvlar va mijozlarni tasdiqlash');
  static String get becomeBarber =>
      _t('Become a barber', 'Стать барбером', 'Barber bo\'ling');
  static String get becomeBarberSub => _t(
      'Open your chair, take bookings, earn',
      'Откройте кресло, принимайте записи, зарабатывайте',
      "O'rindig'ingizni oching, yozuvlar oling, daromad qiling");
  static String get becomeBarberCta =>
      _t('Start', 'Начать', 'Boshlash');
  static String get searchBarbers => _t('Search barbershops, styles…',
      'Барбершопы, стрижки…', 'Barbershoplar, soch turmagi…');
  static String get clientsWord => _t('Clients', 'Клиенты', 'Mijozlar');
  static String get allVisitsWord =>
      _t('All visits', 'Все визиты', 'Barcha tashriflar');
  static String visitsCount(int n) =>
      _t('$n visits', '$n визитов', '$n tashrif');
  static String lastVisitShort(String d) =>
      _t('last $d', 'посл. $d', 'oxirgi $d');
  static String get regularWord => _t('Regular', 'Постоянный', 'Doimiy');
  static String get statCuts => _t('Cuts', 'Стрижки', 'Soch olish');
  static String get statHours => _t('Hours', 'Часы', 'Soatlar');
  static String get statRating => _t('Rating', 'Рейтинг', 'Reyting');
  static String get statResponse => _t('Response', 'Ответ', 'Javob');
  static String acceptAllN(int n) => _t(
      'Accept all ($n)', 'Принять все ($n)', 'Hammasini qabul qilish ($n)');

  // ── Barber intro / first-run setup ──
  static String get biWelcomeTitle => _t('Set up your chair',
      'Настройте своё кресло', "O'rindig'ingizni sozlang");
  static String get biWelcomeSub => _t(
      "Three quick steps and you're taking bookings.",
      'Три быстрых шага — и вы принимаете записи.',
      "Uch qadam — va yozuvlar qabul qilasiz.");
  static String get biStart => _t("Let's go", 'Начать', 'Boshlaymiz');
  // The welcome page's three selling points. They used to borrow strings from
  // elsewhere — one was a *notification body*, another was the next page's own
  // subtitle — so the page repeated itself and sold nothing.
  static String get biPerkChair => _t(
      'Your chair, your prices, your hours.',
      'Ваше кресло, ваши цены, ваш график.',
      "O'rindiq, narx va vaqt — hammasi sizniki.");
  static String get biPerkBookings => _t(
      'Requests land here — accept or decline in one tap.',
      'Заявки приходят сюда — одно касание, и готово.',
      "So'rovlar shu yerga keladi — bir bosishda qabul qiling.");
  static String get biPerkMap => _t(
      'Clients nearby find you on the map.',
      'Клиенты рядом находят вас на карте.',
      'Yaqindagi mijozlar sizni xaritadan topadi.');
  static String get biGoalTitle => _t("What's your weekly goal?",
      'Ваша цель на неделю?', 'Haftalik maqsadingiz?');
  static String get biGoalSub => _t(
      "We'll track your earnings toward it.",
      'Мы будем отслеживать ваш заработок.',
      'Daromadingizni shu tomon kuzatamiz.');
  static String get biPhotoTitle =>
      _t('Add your photos', 'Добавьте фото', "Suratlaringizni qo'shing");
  static String get biPhotoSub => _t(
      'A clear profile photo and a few of your best cuts win clients.',
      'Чёткое фото профиля и пара лучших работ привлекут клиентов.',
      "Aniq profil surati va bir nechta ishingiz mijoz jalb qiladi.");
  static String get biYourPhoto => _t('Your photo', 'Ваше фото', 'Suratingiz');
  static String get biYourWork =>
      _t('Your work', 'Ваши работы', 'Ishlaringiz');
  static String get biReadyTitle =>
      _t("You're all set! ✂️", 'Всё готово! ✂️', 'Hammasi tayyor! ✂️');
  static String get biReadySub => _t(
      'Your chair is live. New requests will land right here.',
      'Ваше кресло активно. Новые заявки будут приходить сюда.',
      "O'rindiq faol. Yangi so'rovlar shu yerga keladi.");
  static String get biEnter => _t('Enter barber mode',
      'Войти в режим барбера', 'Barber rejimiga kirish');
  static String get biNext => _t('Continue', 'Далее', 'Davom etish');
  // Photos are required, so nothing skips any more. biSkip is gone with the
  // button: at 42px wide it wrapped "O'tkazib yuborish" to one letter per line.
  static String get biRequired => _t('Required', 'Нужно', 'Majburiy');
  static String get biNeedPhoto => _t(
      'Add your profile photo — clients pick a face they can see',
      'Добавьте фото профиля — клиенты выбирают того, кого видят',
      "Profil suratini qo'shing — mijoz ko'rgan odamini tanlaydi");
  static String get biNeedWork => _t(
      'Add at least one photo of your work',
      'Добавьте хотя бы одно фото своей работы',
      "Ishingizdan kamida bitta surat qo'shing");

  // ── Intro: how money & commissions work ──
  static String get biMoneyTitle => _t('How you get paid',
      'Как вы получаете деньги', 'Qanday pul olasiz');
  static String get biMoneySub => _t(
      'Simple and fair — you keep your price. Here is the whole deal.',
      'Просто и честно — цена остаётся вашей. Вот и всё.',
      "Sodda va halol — narx sizniki. Mana hammasi.");
  // Card 1 is about WHERE the money lands, not about a percentage — it used to
  // say "you keep 100% of your price", which flatly contradicted the 5% fee on
  // the card right below it. Direct payment is the real benefit, and it's true.
  static String get biMoneyKeepTitle => _t('Clients pay you directly',
      'Клиенты платят вам напрямую', "Mijoz to'g'ridan-to'g'ri to'laydi");
  static String get biMoneyKeepSub => _t(
      'Cash or card, at your chair. Your earnings never sit in a Fade account.',
      'Наличными или картой, у кресла. Ваш заработок не лежит на счету Fade.',
      "Naqd yoki karta — kreslongizda. Daromadingiz Fade hisobida turmaydi.");
  // The honest fee. 95% is the anchor (and the badge); the 5% is stated plainly
  // right under it. The old copy promised "0% forever" after a client's first
  // visit — but commissionSomFor() charges EVERY non-walk-in booking, so the
  // app broke that promise on visit two and the barber found out from their
  // own wallet. Never write a number here the ledger won't back up.
  static String get biMoneyCommTitle => _t('You keep 95% of every booking',
      'Вы оставляете 95% с каждой записи', "Har bir yozuvdan 95% sizniki");
  static String get biMoneyCommSub => _t(
      'Fade takes 5% on bookings the app brings you. Walk-ins you add yourself are always free.',
      'Fade берёт 5% с записей, которые приводит приложение. Своих клиентов вы вносите сами — бесплатно.',
      "Fade ilova olib kelgan yozuvlardan 5% oladi. O'zingiz kiritgan mijozlar — doim bepul.");
  static String get biMoneyCashTitle => _t('Cashback — up to 2% back',
      'Кешбэк — до 2% назад', 'Keshbek — 2% gacha qaytadi');
  static String get biMoneyCashSub => _t(
      'We may return part of the fee to barbers whose clients keep coming back.',
      'Часть комиссии может вернуться барберам, к которым клиенты возвращаются.',
      "Mijozlari qaytib keladigan barberlarga to'lovning bir qismi qaytishi mumkin.");
  static String get biMoneyWalletTitle => _t("It's all in your wallet",
      'Всё в вашем кошельке', "Hammasi hamyoningizda");
  static String get biMoneyWalletSub => _t(
      'Top up once; every fee and payout shows up as a clear transaction you can check.',
      'Пополните один раз; каждый сбор и выплата — понятная запись.',
      "Bir marta to'ldiring; har bir to'lov aniq yozuv bo'lib turadi.");
  static String get biMoneyBoostTitle => _t('Boost & VIP are optional',
      'Boost и VIP — по желанию', "Boost va VIP — ixtiyoriy");
  static String get biMoneyBoostSub => _t(
      'Pay only if you want the top spot. Never taken from your earnings.',
      'Платите, только если хотите быть в топе. Из заработка не берётся.',
      "Faqat tepada bo'lishni xohlasangiz to'laysiz. Daromaddan olinmaydi.");

  // ── QR scanner ──
  static String get scanOpenCamera => _t('Scan a QR code',
      'Сканировать QR-код', 'QR-kodni skanerlash');
  static String get scanPointHint => _t(
      "Point at the client's Fade ticket",
      'Наведите на билет клиента Fade',
      "Mijozning Fade chiptasiga qarating");
  static String get scanNotTicket => _t(
      'Not a Fade ticket — try again',
      'Это не билет Fade — попробуйте снова',
      'Bu Fade chiptasi emas — qayta urining');

  // ── Choose / create workplace ──
  static String get wpTitle => _t('Where will you work?',
      'Где вы будете работать?', 'Qayerda ishlaysiz?');
  static String get wpSub => _t(
      'Pick your barbershop on the map, or add a new one.',
      'Выберите барбершоп на карте или добавьте новый.',
      'Xaritadan barbershop tanlang yoki yangisini qo\'shing.');
  static String get wpWorkHere => _t('Work here', 'Работать здесь', 'Shu yerda');
  static String get wpCreateNew => _t('Create a new barbershop',
      'Создать новый барбершоп', 'Yangi barbershop yaratish');
  static String get wpNoneHere => _t("Can't find yours?",
      'Не нашли свой?', 'O\'zingiznikini topmadingizmi?');
  static String get csTitle => _t('New barbershop',
      'Новый барбершоп', 'Yangi barbershop');
  static String get csLocation =>
      _t('Location', 'Локация', 'Manzil');
  static String get csSetOnMap =>
      _t('Set on map', 'Указать на карте', 'Xaritada belgilash');
  static String get csName =>
      _t('Barbershop name', 'Название', 'Nomi');
  static String get csInfo => _t('About the shop',
      'О барбершопе', 'Barbershop haqida');
  static String get csInfoHint => _t(
      'Tell clients what makes your shop great…',
      'Расскажите клиентам о вашем барбершопе…',
      'Mijozlarga barbershopingiz haqida ayting…');
  static String get csPhotos => _t('Photos', 'Фото', 'Suratlar');
  static String get csHours => _t('Working hours', 'Часы работы', 'Ish vaqti');
  static String get csFrom => _t('From', 'С', 'Dan');
  static String get csTill => _t('Till', 'До', 'Gacha');
  static String get csOffDays => _t('Days off', 'Выходные', 'Dam olish kunlari');
  static String get csCreate => _t('Create & start working',
      'Создать и начать', 'Yaratish va boshlash');
  static String get csNeedPhotos => _t(
      'Add at least one photo — it’s the only thing clients see on the map',
      'Добавьте хотя бы одно фото — только его клиенты видят на карте',
      "Kamida bitta surat qo'shing — xaritada mijoz shuni ko'radi");
  static String get csNeedName => _t('Add a name and a location first',
      'Сначала укажите название и локацию',
      'Avval nom va manzil kiriting');
  // ── Payment ──
  static String get payTitle => _t('Payment', 'Оплата', "To'lov");
  static String get payChoose => _t('Payment method',
      'Способ оплаты', "To'lov usuli");
  static String payPay(String som) =>
      _t('Pay $som so\'m', 'Оплатить $som сум', "$som so'm to'lash");
  static String payVia(String provider) => _t(
      'Contacting $provider…', 'Соединение с $provider…',
      '$provider bilan bog\'lanmoqda…');
  static String get paySuccess => _t('Payment successful ✓',
      'Оплата прошла ✓', "To'lov muvaffaqiyatli ✓");
  static String get payMethodsTitle =>
      _t('Payment methods', 'Способы оплаты', "To'lov usullari");
  static String get payMethodsSub => _t('Payme, Click, Uzum, cards',
      'Payme, Click, Uzum, карты', 'Payme, Click, Uzum, kartalar');
  static String get payDefault => _t('Default', 'По умолчанию', 'Asosiy');
  static String get payTopUpAmount =>
      _t('Top-up amount', 'Сумма пополнения', "To'ldirish summasi");
  static String get payStubNote => _t(
      'Demo — no real charge. Connects to the provider in production.',
      'Демо — без реального списания. В продакшене — переход к провайдеру.',
      'Demo — haqiqiy to\'lov yo\'q. Ishlab chiqarishda provayderga o\'tadi.');

  // ── Boost ⇄ VIP hub ──
  static String get tabBoost => _t('Boost', 'Boost', 'Boost');
  static String get boostHubTitle =>
      _t('Grow your chair', 'Развивайте кресло', "O'rindig'ingizni o'stiring");
  static String get boostTabSub => _t(
      'Pay per hour — jump to the top when you want.',
      'Оплата за час — в топ, когда захотите.',
      "Soatlik to'lov — xohlaganda tepaga chiqing.");
  static String get vipTabSub => _t(
      'One price a month — always at the top.',
      'Одна цена в месяц — всегда в топе.',
      "Oyiga bir narx — doim tepada.");
  static String get vipActiveChip => _t('Active', 'Активна', 'Faol');

  static String weekdayShort(int d) {
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const ru = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    const uz = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    final i = (d - 1).clamp(0, 6);
    return _t(en[i], ru[i], uz[i]);
  }

  // ── Device notifications ──
  static String get notifConfirmedTitle =>
      _t('Booking confirmed ✂️', 'Запись подтверждена ✂️',
          'Yozuv tasdiqlandi ✂️');
  static String notifConfirmedBody(String time, String shop) => _t(
      '$time at $shop — see you there!',
      '$time в $shop — до встречи!',
      '$time, $shop — ko\'rishguncha!');
  static String get notifDeclinedTitle => _t('Booking declined',
      'Запись отклонена', 'Yozuv rad etildi');
  static String notifDeclinedBody(String shop) => _t(
      '$shop can\'t take this one — pick another time.',
      '$shop не может принять — выберите другое время.',
      '$shop qabul qila olmaydi — boshqa vaqt tanlang.');
  static String get notifNewRequestTitle => _t('New booking request 💈',
      'Новая заявка 💈', 'Yangi so\'rov 💈');
  static String notifNewRequestBody(String name, String time) => _t(
      '$name wants $time — accept or decline.',
      '$name хочет на $time — примите или отклоните.',
      '$name $time ga yozilmoqchi — qabul qiling yoki rad eting.');
  static String get notifHelloTitle => _t('Notifications are on 🔔',
      'Уведомления включены 🔔', 'Bildirishnomalar yoqildi 🔔');
  static String get notifHelloBody => _t(
      'Booking updates and requests will land right here.',
      'Обновления записей и заявки будут приходить сюда.',
      'Yozuv yangiliklari va so\'rovlar shu yerga keladi.');
  static String get vipClub => _t('VIP Club', 'VIP-клуб', 'VIP klub');
  static String get noBarberPinned => _t(
      'no barber pinned yet — find your person',
      'барбер ещё не выбран — найдите своего',
      "barber tanlanmagan — o'zingiznikini toping");
  static String get memberSincePrefix =>
      _t('member since', 'с нами с', "a'zo:");
  static String get madeWith =>
      _t('made with ✂️', 'сделано с ✂️', '✂️ bilan');

  // ── Barber profile sheet (atelier) ────────────────────
  static String get ratingWord => _t('rating', 'рейтинг', 'reyting');
  static String get behindChair => _t('behind chair', 'опыт', 'tajriba');
  static String get reviewsLower => _t('reviews', 'отзывов', 'sharh');
  static String bookWithName(String name) =>
      _t('Book with $name', 'Записаться к $name', "$name'ga yozilish");
  static String get forgetMyBarber =>
      _t('Forget my barber', 'Убрать барбера', 'Barberni olib tashlash');
  static String get makeMyBarber => _t('Make them my barber',
      'Сделать моим барбером', 'Mening barberim qilish');

  // ── Messages / chat ───────────────────────────────────
  static String get barbersYouBooked => _t("Barbers you've booked with",
      'Барберы, к кому вы записывались', 'Siz yozilgan barberlar');
  static String get noMessagesYet =>
      _t('No messages yet', 'Сообщений пока нет', "Hozircha xabar yo'q");
  static String sayHiTo(String name) => _t('Say hi 👋 — text $name',
      'Поздоровайтесь 👋 — напишите $name', "Salom 👋 — $name'ga yozing");
  static String get messageHint => _t('Message…', 'Сообщение…', 'Xabar…');
  static String get yourClients => _t('Your clients',
      'Ваши клиенты', 'Mijozlaringiz');
  static String get clientsMessageHere => _t(
      'Clients who book with you show up here — message them anytime.',
      'Клиенты, которые к вам записались, появятся здесь — пишите им в любое время.',
      "Sizga yozilgan mijozlar shu yerda chiqadi — istalgan vaqt yozing.");
  static String get tapToMessage =>
      _t('Tap to message ✍️', 'Нажмите, чтобы написать ✍️', 'Yozish uchun bosing ✍️');

  // ── Shop detail extra ─────────────────────────────────
  static String get reviewHint => _t('How was the cut? Be honest…',
      'Как вам стрижка? Честно…', "Soch qanday bo'ldi? Rostini…");

  // ── Style / AI extras ─────────────────────────────────
  static String get yourLook =>
      _t('Your look', 'Ваш образ', 'Sizning uslubingiz');
  static String get fitWord => _t('Fit', 'Подгон', 'Moslash');
  static String get colourWord => _t('Colour', 'Цвет', 'Rang');
  static String get addYourPhoto =>
      _t('Add your photo', 'Добавьте фото', "Suratingizni qo'shing");
  static String get readingFace => _t('Reading your face…',
      'Анализируем лицо…', "Yuzingiz o'qilmoqda…");
  static String get dragToFit => _t('drag to fit',
      'двигайте, чтобы подогнать', 'moslash uchun suring');
  static String get tryDemoFace =>
      _t('or try a demo face →', 'или демо-лицо →', 'yoki demo yuz →');

  // ════════════════════════════════════════════════════════
  //  BARBER: breaks / lunch
  // ════════════════════════════════════════════════════════
  static String get minShort => _t('min', 'мин', 'daq');
  static String get breakWord => _t('Break', 'Перерыв', 'Tanaffus');
  static String get lunchWord => _t('Lunch', 'Обед', 'Tushlik');
  static String get addBreak =>
      _t('Add break', 'Добавить перерыв', "Tanaffus qo'shish");
  static String get blockTimeOff =>
      _t('Block time off', 'Заблокировать время', 'Vaqtni bloklash');
  static String get labelWord => _t('Label', 'Название', 'Nomi');
  static String get startWord => _t('Start', 'Начало', 'Boshlanish');
  static String get everyDay => _t('Every day', 'Каждый день', 'Har kuni');
  static String get thisDayOnly =>
      _t('This day only', 'Только этот день', 'Faqat shu kun');
  static String get removeBreakQ => _t('Remove this break?',
      'Удалить этот перерыв?', "Bu tanaffus o'chirilsinmi?");
  static String breakEvery(String time) =>
      _t('every day · $time', 'каждый день · $time', "har kuni · $time");

  // ════════════════════════════════════════════════════════
  //  BARBER: Today cockpit
  // ════════════════════════════════════════════════════════
  static String get goodMorning =>
      _t('Good morning', 'Доброе утро', 'Xayrli tong');
  static String get goodAfternoon =>
      _t('Good afternoon', 'Добрый день', 'Xayrli kun');
  static String get goodEvening =>
      _t('Good evening', 'Добрый вечер', 'Xayrli kech');
  static String cutsLeftToday(int n) => _t(
      n == 1 ? '1 cut left today' : '$n cuts left today',
      'Осталось сегодня: $n',
      'Bugun qoldi: $n');
  static String get allDoneToday =>
      _t('All done for today 🎉', 'На сегодня всё 🎉', 'Bugunga hammasi 🎉');
  static String get nextUp => _t('Next up', 'Далее', 'Keyingi');
  static String get earnedToday =>
      _t('Earned today', 'Заработано', 'Bugun ishlandi');
  static String get reviewRequests =>
      _t('Review requests', 'Заявки', "So'rovlarni ko'rish");
  static String inHm(int h, int m) => _t(
      h > 0 ? 'in ${h}h ${m}m' : 'in ${m}m',
      h > 0 ? 'через $h ч $m мин' : 'через $m мин',
      h > 0 ? '$h soat $m daqdan keyin' : '$m daqdan keyin');
  static String get startingNow =>
      _t('starting now', 'уже сейчас', 'hozir boshlanmoqda');
  static String get viewFullDay =>
      _t('View full day', 'Весь день', "Kun jadvali");

  // ── Requests redesign ─────────────────────────────────
  static String get swipeToAct => _t('Swipe → confirm  ·  ← decline',
      'Свайп → принять  ·  ← отклонить', 'Surish → qabul  ·  ← rad');
  static String get confirmedShort =>
      _t('Confirmed ✓', 'Принято ✓', 'Qabul qilindi ✓');

  // ── Barber: availability + next-booking dashboard ─────
  static String get receivingBookings => _t("You're receiving bookings",
      'Вы принимаете записи', 'Siz yozuvlarni qabul qilyapsiz');
  static String get receivingSub => _t(
      'New requests will appear here as soon as they come in.',
      'Новые заявки появятся здесь, как только поступят.',
      "Yangi so'rovlar kelishi bilan shu yerda chiqadi.");
  static String get youreOffline =>
      _t("You're offline", 'Вы офлайн', 'Siz oflaynsiz');
  static String get offlineSub => _t(
      'Turn on to start receiving bookings.',
      'Включите, чтобы принимать записи.',
      'Yozuvlarni qabul qilish uchun yoqing.');
  static String get nextBookingCap =>
      _t('NEXT BOOKING', 'СЛЕДУЮЩАЯ ЗАПИСЬ', 'KEYINGI YOZUV');
  static String get navigateWord =>
      _t('Navigate', 'Маршрут', 'Yo‘nalish');
  static String get viewDetails =>
      _t('View details', 'Подробнее', 'Batafsil');
  static String get bookingsTodayCap =>
      _t('BOOKINGS TODAY', 'ЗАПИСЕЙ СЕГОДНЯ', 'BUGUN YOZUVLAR');
  static String get expectedCap =>
      _t('EXPECTED', 'ОЖИДАЕТСЯ', 'KUTILMOQDA');
  static String get cutHistory =>
      _t('Cut history', 'История стрижек', 'Soch tarixi');
  static String completedEarned(int n, String money) => _t(
      '$n completed · $money earned',
      '$n завершено · $money заработано',
      '$n yakunlandi · $money ishlandi');
  static String get todaysEarningsCap =>
      _t("TODAY'S EARNINGS", 'ДОХОД ЗА СЕГОДНЯ', 'BUGUNGI DAROMAD');
  static String get noUpcomingBookings => _t('No upcoming bookings',
      'Нет предстоящих записей', "Kelgusi yozuvlar yo'q");
  static String get chairOpen => _t('Your chair is open — enjoy the break ☕',
      'Кресло свободно — отдохните ☕', "Kreslo bo'sh — dam oling ☕");
  static String get thisWeek => _t('this week', 'на этой неделе', 'shu hafta');

  // ── Live incoming-request pop-up ──────────────────────
  static String get newBookingRequest => _t('New booking request!',
      'Новая заявка!', "Yangi yozuv so'rovi!");
  static String get estimatedPay =>
      _t('ESTIMATED PAY', 'ОЖИДАЕМАЯ ОПЛАТА', "TAXMINIY TO'LOV");
  static String get urgentWord => _t('Urgent', 'Срочно', 'Shoshilinch');
  static String get acceptBooking =>
      _t('Accept booking', 'Принять', 'Qabul qilish');
  static String ratingJobs(String rating, int jobs) => _t(
      '$rating · $jobs cuts', '$rating · $jobs стрижек', '$rating · $jobs soch');
  static String kmAway(String km) =>
      _t('$km km', '$km км', '$km km');

  // ── Earnings goal + 7-day chart ───────────────────────
  static String get weeklyGoalCap => _t('WEEKLY EARNINGS GOAL',
      'ЦЕЛЬ НА НЕДЕЛЮ', 'HAFTALIK MAQSAD');
  static String get onTrack => _t('On track', 'В графике', 'Maromida');
  static String get keepGoing =>
      _t('Keep going', 'Продолжайте', 'Davom eting');
  static String get goalReached =>
      _t('Goal reached 🎉', 'Цель достигнута 🎉', 'Maqsadga yetdingiz 🎉');
  static String toGoLabel(String money) =>
      _t('$money to go', 'осталось $money', '$money qoldi');
  static String get last7DaysCap =>
      _t('LAST 7 DAYS', 'ПОСЛЕДНИЕ 7 ДНЕЙ', "OXIRGI 7 KUN");
  static String get earnedLegend =>
      _t('Earned', 'Заработано', 'Ishlangan');
  static String get expectedLegend =>
      _t('Expected', 'Ожидается', 'Kutilmoqda');
  static String get setWeeklyGoalTitle => _t('Weekly earnings goal',
      'Цель заработка на неделю', 'Haftalik daromad maqsadi');
  static String get goalSomLabel =>
      _t("Goal (so'm)", 'Цель (сум)', "Maqsad (so'm)");

  // ── Cut history screen ────────────────────────────────
  static String get everythingCompleted => _t("Everything you've completed",
      'Всё, что вы завершили', 'Siz yakunlagan barchasi');
  static String get tabAllTime =>
      _t('All time', 'За всё время', 'Butun vaqt');
  static String get tabThisMonth =>
      _t('This month', 'Этот месяц', 'Shu oy');
  static String get tabThisWeekCap =>
      _t('This week', 'Эта неделя', 'Shu hafta');
  static String get completedCap =>
      _t('COMPLETED', 'ЗАВЕРШЕНО', 'YAKUNLANDI');
  static String get earnedCap => _t('EARNED', 'ЗАРАБОТАНО', 'ISHLANDI');
  static String get avgRatingCap =>
      _t('AVG RATING', 'СРЕДНИЙ РЕЙТИНГ', "O'RTACHA REYTING");
  static String get noCompletedYet => _t('No completed cuts yet',
      'Пока нет завершённых стрижек', "Hali yakunlangan soch yo'q");
  static String get yesterdayWord =>
      _t('Yesterday', 'Вчера', 'Kecha');

  // ── Barber: working hours + shop ──────────────────────
  static String get workingHoursTitle =>
      _t('Working hours', 'Рабочие часы', 'Ish vaqti');
  static String get opensLabel => _t('Opens', 'Открытие', 'Ochilish');
  static String get closesLabel => _t('Closes', 'Закрытие', 'Yopilish');
  static String get myShopTitle =>
      _t('My shop', 'Мой барбершоп', 'Mening barbershopim');
  static String get shopPhotosTitle =>
      _t('Shop photos', 'Фото барбершопа', 'Barbershop suratlari');
  static String get addPhotosWord =>
      _t('Add photo', 'Добавить фото', "Surat qo'shish");
  static String get descriptionLabel =>
      _t('Description', 'Описание', 'Tavsif');
  static String get addDescriptionHint => _t(
      'Tell clients about your shop…',
      'Расскажите клиентам о барбершопе…',
      "Mijozlarga barbershopingiz haqida ayting…");
  static String get noShopPhotos => _t('No photos yet — add a few ✨',
      'Пока нет фото — добавьте ✨', "Hozircha surat yo'q — qo'shing ✨");
  static String get noPhotosYet =>
      _t('No photos yet.', 'Пока нет фото.', "Hozircha surat yo'q.");
  static String get noDescriptionYet => _t('No description yet.',
      'Пока нет описания.', "Hozircha tavsif yo'q.");
  static String get shopLocationTitle =>
      _t('Shop location', 'Локация барбершопа', 'Barbershop joylashuvi');
  static String get dragToPlaceShop => _t('Drag the map to place your shop',
      'Двигайте карту, чтобы указать барбершоп',
      'Barbershopni belgilash uchun xaritani suring');
  static String get locationSaved =>
      _t('Location saved', 'Локация сохранена', 'Joylashuv saqlandi');

  // ════════════════════════════════════════════════════════
  //  Coverage sweep — auth, booking, profile, AI/style, widgets
  // ════════════════════════════════════════════════════════

  // ── Auth (login / register) ───────────────────────────
  static String get authWelcome => _t('Welcome\n', 'С возвращением\n', 'Xush kelibsiz\n');
  static String get authWelcomeBack => _t('back!', '!', 'yana!');
  static String get authWelcomeSub => _t('Your chair is exactly where you left it.', 'Ваше кресло ждёт вас там же, где вы его оставили.', "O'rindig'ingiz aynan qoldirgan joyingizda turibdi.");
  static String get authPassword => _t('Password', 'Пароль', 'Parol');
  static String get authForgotPw => _t('Forgot password?', 'Забыли пароль?', 'Parolni unutdingizmi?');
  static String get authEnterEmailFirst => _t('Enter your email first, then tap again.', 'Сначала введите email, затем нажмите снова.', "Avval emailingizni kiriting, so'ng qayta bosing.");
  static String authResetLinkSent(String email) => _t('Reset link sent to $email', 'Ссылка для сброса отправлена на $email', "Tiklash havolasi $email manziliga yuborildi");
  static String get authSignIn => _t('Sign in', 'Войти', 'Kirish');
  static String get authOrContinue => _t('or continue with', 'или войти через', 'yoki davom eting');
  static String get authNewHere => _t('New here?  ', 'Впервые здесь?  ', 'Yangimisiz?  ');
  static String get authCreateAccount => _t('Create account', 'Создать аккаунт', 'Hisob yaratish');
  static String get authGrabYour => _t('Grab your\n', 'Займите своё\n', "O'z\n");
  static String get authOwnChair => _t('own chair', 'кресло', "o'rindig'ingizni oling");
  static String get authOneMinute => _t('One minute now, zero waiting later.', 'Минута сейчас — ноль ожидания потом.', 'Hozir bir daqiqa, keyin umuman kutmaysiz.');
  static String get authFullName => _t('Full name', 'Полное имя', "To'liq ism");
  static String get authMin8Chars => _t('min. 8 characters', 'мин. 8 символов', 'kamida 8 ta belgi');
  static String get authAlreadyHaveAcct => _t('Already have an account?  ', 'Уже есть аккаунт?  ', 'Hisobingiz bormi?  ');

  // ── Lists / profile ───────────────────────────────────
  static String get pfMyAppointments => _t('My appointments', 'Мои записи', 'Mening yozuvlarim');
  static String get pfTagCancelled => _t('CANCELLED', 'ОТМЕНЕНО', 'BEKOR');
  static String get pfTagDeclined => _t('DECLINED', 'ОТКЛОНЕНО', 'RAD ETILDI');
  static String get pfMessagesEmptyBody => _t(
      'Book a cut at a shop, then message your barber here if you need to.',
      'Запишитесь в барбершоп, а потом при необходимости напишите барберу здесь.',
      "Barbershopga yoziling, keyin kerak bo'lsa barberingizga shu yerda yozing.");
  static String get pfEveryShop => _t('Every shop in town', 'Все барбершопы города', 'Shahardagi barcha barbershoplar');
  static String pfInviteShare(String code) => _t(
      'Book your next cut on Fade with my code $code — we both move up to VIP. ✂️',
      'Запишись на стрижку в Fade по моему коду $code — мы оба поднимемся до VIP. ✂️',
      "Fade'da keyingi sochingizni mening kodim $code bilan yozing — ikkalamiz ham VIP'ga ko'tarilamiz. ✂️");
  static String get pfMyBarber => _t('MY BARBER', 'МОЙ БАРБЕР', 'MENING BARBERIM');
  static String pfAtShop(String name) => _t('at $name', 'в $name', "$name'da");
  static String get pfBookYourBarber => _t('book your barber', 'запишись к барберу', 'barberingizga yoziling');

  // ── Shared widgets ────────────────────────────────────
  static String get wdInviteVip => _t('Invite friends, go VIP', 'Приглашай друзей — стань VIP', "Do'stlarni taklif qil, VIP bo'l");
  static String get wdInviteVipSub => _t(
      'You both earn points toward VIP when a friend books their first cut with your code.',
      'Вы оба получаете баллы к VIP, когда друг записывается на первую стрижку по вашему коду.',
      "Do'stingiz kodingiz bilan birinchi soch olishga yozilganda, ikkalangiz ham VIP uchun ball olasiz.");
  static String get wdGetThere => _t('Get there', 'Как добраться', 'Qanday borish');
  static String get wdAnyone => _t('Anyone', 'Любой', 'Har kim');
  static String get wdPremium => _t('PREMIUM', 'ПРЕМИУМ', 'PREMIUM');
  static String get wdMyBarber => _t('MY BARBER', 'МОЙ БАРБЕР', 'MENING BARBERIM');
  static String wdBookedThisWeek(int n) => _t('$n booked this week', 'Записей за неделю: $n', "Bu hafta $n ta yozildi");
  static String wdLeftToday(int n) => _t('$n left today', 'Осталось сегодня: $n', 'Bugun $n qoldi');
  static String wdYearsReviews(int years, int reviews) => _t(
      '$years yrs · $reviews reviews',
      '$years лет · $reviews отзывов',
      '$years yil · $reviews sharh');

  // ── Shop detail: booking cockpit ──────────────────────
  static String get bkChooseATime => _t('Choose a time', 'Выберите время', 'Vaqt tanlang');
  static String get bkPickATime => _t('Pick a time', 'Выберите время', 'Vaqtni tanlang');
  static String get bkPickAService => _t('Pick a service', 'Выберите услугу', 'Xizmat tanlang');
  static String get bkFreeChairs => _t('free chairs', 'свободные кресла', "bo'sh o'rindiqlar");
  static String get bkPremiumBadge => _t('PREMIUM', 'ПРЕМИУМ', 'PREMIUM');
  static String get bkBookYourVisit => _t('Book your visit', 'Запишитесь на визит', 'Tashrifingizga yoziling');
  static String bkServicesCount(int n) => _t('$n services', '$n услуг', '$n xizmat');
  static String bkMakeMyBarber(String name) => _t('Make $name my barber', 'Сделать $name моим барбером', "$name'ni mening barberim qilish");
  static String bkIsYourBarber(String name) => _t('$name is your barber — tap to unpin', '$name — ваш барбер, нажмите, чтобы убрать', "$name — sizning barberingiz, olib tashlash uchun bosing");
  static String bkMessageAfterBook(String name) => _t('Message $name after you book', 'Напишите $name после записи', "Yozilgach $name'ga yozing");
  static String bkMessageName(String name) => _t('Message $name', 'Написать $name', "$name'ga yozing");
  static String bkMoreReviews(int n) => _t('+ $n more reviews', '+ ещё $n отзывов', '+ yana $n sharh');
  static String bkFullyBooked(String day) => _t('Fully booked $day — try another day', 'Всё занято $day — выберите другой день', 'Hammasi band $day — boshqa kunni tanlang');
  static String bkOnlySlotsLeft(int count, String day) => _t('Only $count slots left $day', 'Осталось всего $count слотов $day', "Faqat $count ta joy qoldi $day");
  static String bkSlotsOpen(int count, String day) => _t('$count slots open $day', '$count свободных слотов $day', "$count ta joy bo'sh $day");
  // Booking confirmation: variable reward
  static String get bkPriorityPass => _t('Priority booking pass', 'Пропуск на приоритетную запись', 'Ustuvor yozuv passi');
  static String get bkPriorityPassSub => _t('First pick of slots next time', 'Первый выбор слотов в следующий раз', "Keyingi safar joylardan birinchi tanlov");
  static String get bkSkipQueuePass => _t('Skip-the-queue pass', 'Пропуск очереди', "Navbatsiz o'tish passi");
  static String get bkSkipQueueSub => _t('Jump the waitlist once', 'Один раз без очереди', "Bir marta navbatsiz");
  static String get bkEarnedThisBooking => _t('Earned on this booking', 'Начислено за эту запись', 'Shu yozuv uchun berildi');
  static String get bkPlusOnePerk => _t('+1 toward your next perk', '+1 к следующему бонусу', 'Keyingi bonusga +1');
  static String get bkLoyaltyProgressSaved => _t('Loyalty progress saved', 'Прогресс сохранён', 'Progress saqlandi');
  static String get bkYouJustEarned => _t('YOU JUST EARNED', 'ВЫ ПОЛУЧИЛИ', 'SIZ YUTDINGIZ');
  static String get bkNoteNo => _t('NOTE №', 'ЗАПИСЬ №', 'YOZUV №');
  static String get bkPerkUnlocked => _t('Perk unlocked! 🎉', 'Бонус открыт! 🎉', 'Bonus ochildi! 🎉');
  static String bkCutsToNextPerk(int remaining) => _t('$remaining ${remaining == 1 ? 'cut' : 'cuts'} to your next perk', 'До бонуса ещё $remaining стрижек', 'Keyingi bonusgacha $remaining soch');
  static String bkCutsCount(int n) => _t('$n cuts', '$n стрижек', '$n soch');
  static String bkCalDetails(String name) => _t('With $name — booked via Fade', 'С $name — записано через Fade', 'Fade orqali $name bilan');
  static String bkCalClipboard(String service, String barber, String shop, String when) => _t('$service with $barber at $shop — $when', '$service у $barber в $shop — $when', "$shop, $barber — $service — $when");

  // ── AI hair studio (extras) ───────────────────────────
  static String get stAiHairIntro => _t(
      'Take a selfie and our AI re-renders your hair so you can see a new cut on your real face before you book.',
      'Сделайте селфи — AI перерисует ваши волосы, и вы увидите новую стрижку на своём лице ещё до записи.',
      "Selfi oling — AI sochingizni qayta chizadi va yozilishdan oldin yangi soch turini o'z yuzingizda ko'rasiz.");
  static String get stTryDemoFace => _t('try a demo face →', 'демо-лицо →', 'demo yuz →');
  static String get stAiRender => _t('AI render', 'AI-рендер', 'AI render');
  static String get stStylisedPreview => _t('Stylised preview', 'Стилизованное превью', "Uslublangan ko'rinish");
  static String get stTapCheckKey => _t(
      'Tap to check your AI key and try again.',
      'Нажмите, чтобы проверить AI-ключ и повторить.',
      "AI kalitini tekshirish va qayta urinish uchun bosing.");
  static String get stStylisedPreviewTapAddKey => _t(
      'This is a stylised preview. Tap to add your Google AI key and re-render real hair on your photo.',
      'Это стилизованное превью. Нажмите, чтобы добавить Google AI-ключ и получить реалистичные волосы на фото.',
      "Bu uslublangan ko'rinish. Google AI kalitini qo'shib, suratingizda haqiqiy sochni chizish uchun bosing.");
  static String get stFreeWorkerUrl => _t('Free — AI worker URL', 'Бесплатно — URL AI-воркера', 'Bepul — AI worker URL');
  static String get stFreeWorkerHint => _t(
      'Free Cloudflare worker (I give you the code + steps). Leave blank if unused.',
      'Бесплатный Cloudflare-воркер (код и шаги я дам). Оставьте пустым, если не нужен.',
      "Bepul Cloudflare worker (kod va qadamlarni beraman). Kerak bo'lmasa, bo'sh qoldiring.");
  static String get stPremiumGeminiKey => _t('Premium — Gemini key', 'Премиум — ключ Gemini', 'Premium — Gemini kaliti');
  static String get stNeedsBilling => _t('(needs billing)', '(нужна оплата)', "(to'lov kerak)");
  static String get stSave => _t('Save', 'Сохранить', 'Saqlash');

  // ── Camera screen ─────────────────────────────────────
  static String get stHoldStill => _t('Hold still — try again.', 'Не двигайтесь — попробуйте снова.', "Qimirlamang — qayta urinib ko'ring.");
  static String get stOpeningCamera => _t('Opening camera…', 'Открываем камеру…', 'Kamera ochilmoqda…');
  static String get stCameraUnavailable => _t('Camera unavailable', 'Камера недоступна', 'Kamera mavjud emas');
  static String get stCameraUnavailableBody => _t(
      'We couldn’t open the camera (it may be blocked, or this device has none). Upload a photo instead.',
      'Не удалось открыть камеру (возможно, доступ заблокирован или её нет). Загрузите фото вместо этого.',
      "Kamerani ochib bo'lmadi (bloklangan yoki qurilmada yo'q bo'lishi mumkin). Buning o'rniga surat yuklang.");
  static String get stOpening => _t('Opening…', 'Открываем…', 'Ochilmoqda…');

  // ── Face scan ─────────────────────────────────────────
  static String get stAiAnalysing => _t('AI is analysing', 'AI анализирует', 'AI tahlil qilmoqda');
  static String get stFaceStatus1 => _t('Detecting your face…', 'Определяем лицо…', 'Yuzingiz aniqlanmoqda…');
  static String get stFaceStatus2 => _t('Mapping your features…', 'Считываем черты…', "Yuz qirralari o'qilmoqda…");
  static String get stFaceStatus3 => _t('Reading face shape…', 'Определяем форму лица…', 'Yuz shakli aniqlanmoqda…');
  static String get stFaceStatus4 => _t('Matching the best cuts…', 'Подбираем лучшие стрижки…', 'Eng mos soch turlari tanlanmoqda…');

  // ── Style studio (extras) ─────────────────────────────
  static String get stTryOn => _t('TRY-ON', 'ПРИМЕРКА', "SINAB KO'RISH");
  static String get stTryANew => _t('Try a new ', 'Попробуйте новый ', 'Yangi ');
  static String get stLookWord => _t('look', 'образ', 'uslub');
  static String get stSeeEachCut => _t(
      'Add your photo and see each cut on your own face.',
      'Добавьте фото и примерьте каждую стрижку на своём лице.',
      "Suratingizni qo'shing va har bir soch turini o'z yuzingizda ko'ring.");
  static String get stPhotoStaysOnDevice => _t(
      'Your face is analysed on your device; your photo is used only to create your preview.',
      'Анализ лица — на устройстве; фото используется только для создания превью.',
      "Yuz qurilmada tahlil qilinadi; surat faqat namuna yaratish uchun ishlatiladi.");
  static String get stFaceTheCamera => _t(
      'Face the camera, good light, hair off your forehead.',
      'Смотрите в камеру, хороший свет, волосы убраны со лба.',
      "Kameraga qarang, yorug'lik yaxshi bo'lsin, sochni peshonadan oling.");
  static String get stFindingBestCut => _t(
      'Finding the cut that frames you best.',
      'Подбираем стрижку, которая вам к лицу.',
      "Sizga eng mos keladigan soch turini tanlayapmiz.");
  static String get stNoPhotoDemoSelfie => _t(
      'No photo selected — try "demo selfie" to preview.',
      'Фото не выбрано — попробуйте «демо-селфи» для превью.',
      "Surat tanlanmadi — ko'rish uchun \"demo selfi\"ni sinab ko'ring.");
  static String get stGreatFit => _t('GREAT FIT', 'ОТЛИЧНО', 'JUDA MOS');
  static String get stWorthATry => _t('WORTH A TRY', 'СТОИТ ПОПРОБОВАТЬ', "SINAB KO'RING");
  static String get stWeThink => _t('We think ', 'Мы думаем, ', 'Bizningcha, ');
  static String stSuitsYourFace(String shape) => _t(
      ' suits your $shape face — but try them all:',
      ' подойдёт вашему $shape лицу — но попробуйте все:',
      " $shape yuzingizga mos keladi — lekin hammasini sinab ko'ring:");
  static String stFaceLabel(String shape) => _t('$shape face', '$shape лицо', '$shape yuz');

  // ── Atelier ───────────────────────────────────────────
  static String get stTheWord => _t('The ', '', '');
  static String get stBarbersWord => _t('barbers', 'барберы', 'barberlar');
  static String get stPickAMaster => _t(
      'pick a master, keep them forever',
      'выберите мастера и оставайтесь с ним',
      "usta tanlang va u bilan qoling");
  static String get stNoOneCutsThat => _t(
      'no one cuts that here… yet',
      'здесь такого пока не стригут…',
      "bu yerda buni hali hech kim qirqmaydi…");
  static String get stMyBarberPill => _t('MY BARBER', 'МОЙ БАРБЕР', 'MENING BARBERIM');

  // ── Misc ──────────────────────────────────────────────
  static String get verifiedWord => _t('verified', 'подтверждено', 'tasdiqlangan');
  static String get walletWord => _t('WALLET', 'КОШЕЛЁК', 'HAMYON');

  // ── VIP explainer (animated walkthrough before payment) ──
  static String get vipExplainTitle =>
      _t('Become a VIP barber', 'Станьте VIP-барбером', "VIP barber bo'ling");
  static String get vipExplainSub => _t(
      "Here's exactly what VIP does for your chair — see it, then activate.",
      'Вот что именно VIP даёт вашему креслу — посмотрите, затем активируйте.',
      "VIP kresloingizga aynan nima berishini ko'ring — so'ng faollashtiring.");
  static String get vipStandOutTitle =>
      _t('Stand out on the map', 'Выделяйтесь на карте', 'Xaritada ajralib turing');
  static String get vipStandOutSub => _t(
      'Regular shops are small navy dots. VIP turns you into the gold pin clients spot first.',
      'Обычные барбершопы — маленькие тёмные точки. VIP делает вас золотой меткой, которую замечают первой.',
      "Oddiy barbershoplar — kichik to'q nuqtalar. VIP sizni mijozlar birinchi ko'radigan oltin belgiga aylantiradi.");
  static String get vipRiseTitle => _t(
      'Jump to the top of search', 'Поднимайтесь в топ поиска', 'Qidiruvda tepaga chiqing');
  static String get vipRiseSub => _t(
      'VIP lifts you above everyone nearby — first seen, first booked.',
      'VIP поднимает вас выше всех рядом — вас видят и бронируют первыми.',
      "VIP sizni yaqin-atrofdagilardan tepaga ko'taradi — birinchi ko'rinasiz, birinchi buyurtma olasiz.");
  static String get vipYouPin => _t('YOU', 'ВЫ', 'SIZ');
  static String get vipYouRow => _t('You · VIP', 'Вы · VIP', 'Siz · VIP');
  static String get vipNearbyRow =>
      _t('A barber nearby', 'Барбер рядом', 'Yaqindagi barber');
  static String get vipProofSuffix =>
      _t('more bookings', 'больше записей', "ko'proq buyurtma");
  static String get vipProofSub => _t(
      'VIP barbers fill more of their empty hours.',
      'VIP-барберы заполняют больше пустых часов.',
      "VIP barberlar bo'sh soatlarini ko'proq to'ldiradi.");
  static String get vipEverythingTitle =>
      _t('Everything included', 'Всё включено', 'Hammasi kiritilgan');
  static String get vipActivate =>
      _t('Activate VIP', 'Активировать VIP', 'VIPni faollashtirish');
  static String get vipYoureInTitle =>
      _t("You're VIP ✨", 'Вы VIP ✨', 'Siz VIP ✨');
  // Lower-commission advantage.
  static String get vipFeeWas => '5%';
  static String get vipFeeNow => '2.5%';
  static String get vipFeeCardTitle => _t('Half the commission',
      'Комиссия вдвое меньше', 'Komissiya yarmiga kam');
  static String get vipFeeCardSub => _t(
      'Your 5% new-client fee drops to 2.5% — and being on top brings you more new clients to earn from.',
      'Ваш сбор 5% за новых клиентов падает до 2.5% — а место в топе приносит больше новых клиентов.',
      "Yangi mijoz uchun 5% to'lov 2.5% ga tushadi — tepadagi o'rin esa ko'proq yangi mijoz keltiradi.");
  static String vipSavedSoFar(String som) => _t(
      'VIP has saved you $som in fees so far',
      'VIP уже сэкономил вам $som на сборах',
      'VIP sizga hozirgacha $som to\'lov tejadi');
  static String get vipPerkLowerFeeTitle =>
      _t('Lower commission', 'Ниже комиссия', 'Past komissiya');
  static String get vipPerkLowerFeeSub => _t(
      'Half the fee on every booking',
      'Вдвое меньше сбора за каждую запись',
      "Har bir yozuvda to'lov yarmiga kam");
  static String get vipPerkBoostsTitle => _t(
      '5 free boosts a month', '5 бустов в месяц', 'Oyiga 5 ta bepul boost');
  static String get vipPerkBoostsSub => _t(
      'Visibility fuel, bundled into VIP',
      'Топливо видимости — в составе VIP',
      "Ko'rinish yoqilg'isi — VIP tarkibida");

  // ── Flat commission tiers (wallet) ──
  static String get tierStandardTitle =>
      _t('Standard rate', 'Стандарт', 'Standart');
  static String get tierStandardSub => _t('5% on every booking',
      '5% с каждой записи', 'Har bir yozuvdan 5%');
  static String get tierVipProTitle => _t('VIP (Pro)', 'VIP (Pro)', 'VIP (Pro)');
  static String get tierVipProSub => _t('Half price — 2.5% per booking',
      'Вдвое меньше — 2.5% за запись', 'Yarim narx — 2.5%');
  static String get tierWalkinTitle =>
      _t('Your walk-ins', 'Ваши без записи', 'Navbatsizlar');
  static String get tierWalkinSub => _t('Off-app clients — always free',
      'Клиенты вне приложения — бесплатно', 'Ilovadan tashqari — bepul');

  // ── Dashboard: VIP savings + earn-VIP milestone ──
  static String get vipSavedTitle =>
      _t('VIP is paying off', 'VIP окупается', "VIP o'zini oqlamoqda");
  static String vipSavedThisMonth(String som) => _t(
      'You saved $som in fees this month',
      'Вы сэкономили $som на сборах в этом месяце',
      "Bu oy $som to'lov tejadingiz");
  static String get milestoneTitle =>
      _t('Earn VIP pricing', 'Заработайте цену VIP', "VIP narxini oling");
  static String milestoneProgress(int n, int goal) => _t(
      '$n / $goal bookings this month',
      '$n / $goal записей в этом месяце',
      'Bu oy $n / $goal yozuv');
  static String milestoneSub(int goal) => _t(
      "The busier you get, the more VIP's half-price fee saves you",
      'Чем больше записей, тем больше экономит VIP',
      "Qancha ko'p yozuv bo'lsa, VIP shuncha ko'p tejaydi");
  static String get milestoneReachedTitle =>
      _t("You've earned VIP pricing 🎉", 'Вы заработали цену VIP 🎉',
          "VIP narxini ishlab oldingiz 🎉");
  static String get milestoneReachedSub => _t(
      'Lock in 2.5% — VIP pays off at your volume',
      'Зафиксируйте 2.5% — VIP окупается при вашем объёме',
      "2.5% ni mahkamlang — VIP hajmingizda o'zini oqlaydi");

  // ── Analytics (VIP perk) ──
  static String get navAnalytics => _t('Analytics', 'Аналитика', 'Tahlil');
  static String get analyticsTitle =>
      _t('Your services', 'Ваши услуги', 'Xizmatlaringiz');
  static String get analyticsSub => _t('Which cuts earn you the most',
      'Что приносит больше дохода', "Qaysi xizmat ko'proq daromad keltiradi");
  static String get analyticsEmpty => _t(
      'Complete a few bookings to see your breakdown',
      'Завершите несколько записей, чтобы увидеть разбивку',
      "Tahlilni ko'rish uchun bir nechta yozuvni yakunlang");
  static String analyticsBookingsCount(int n) =>
      _t('$n bookings', '$n записей', '$n yozuv');
  static String get analyticsTotalLabel =>
      _t('This month', 'В этом месяце', 'Bu oy');
  static String get analyticsLockedTitle => _t('Analytics is a VIP perk',
      'Аналитика — привилегия VIP', 'Tahlil — VIP imkoniyati');
  static String get analyticsLockedSub => _t(
      'Go VIP to see which services earn you the most',
      'Перейдите на VIP, чтобы видеть прибыльность услуг',
      "Xizmatlar foydasini ko'rish uchun VIP oling");
  static String get analyticsUnlock =>
      _t('Unlock with VIP', 'Открыть с VIP', 'VIP bilan ochish');
}
