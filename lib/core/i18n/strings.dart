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
      _t('Turbo Boost', 'Турбо-буст', 'Turbo Bust');
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
  static String get actBoost => _t('Boost', 'Буст', 'Bust');
  static String get topUpAddedToast =>
      _t('Credit topped up ✓', 'Кредит пополнен ✓', "Kredit to'ldirildi ✓");

  // ── Help & feedback ──
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
  static String get bookThisLook => _t(
      'Book this look', 'Записаться на этот образ', 'Shu uslubga yozilish');
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
  static String get photoPrivacy => _t(
      'Your photo is processed only for your preview.',
      'Фото обрабатывается только для превью.',
      "Surat faqat ko'rish uchun ishlanadi.");
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
  static String reviewsCount(int n) =>
      _t('$n reviews', '$n отзывов', '$n sharh');

  // ── Home quick actions ────────────────────────────────
  static String get quickBook => _t('Book a cut', 'Записаться', 'Yozilish');
  static String get quickBookSub =>
      _t('find your barber', 'найти барбера', 'barber topish');
  static String get quickAi => _t('AI try-on', 'AI-примерка', 'AI sinash');
  static String get quickAiSub =>
      _t('see your style', 'ваш новый образ', 'yangi uslub');
  static String get quickNear => _t('Near me', 'Рядом', 'Yaqinda');
  static String get quickNearSub =>
      _t('shops on map', 'на карте', 'xaritada');
  static String get quickCuts => _t('My cuts', 'Мои записи', 'Yozuvlarim');
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
  static String get barberTag => _t('BARBER', 'БАРБЕР', 'BARBER');
  static String get profileTab => _t('Profile', 'Профиль', 'Profil');
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
  static String get barberTag2 => _t('BARBER', 'БАРБЕР', 'BARBER');
  static String get shopTag => _t('SHOP', 'БАРБЕРШОП', 'BARBERSHOP');
  static String get reviewNeedsOne => _t('Rate the barber or the shop first ✍️',
      'Оцените барбера или барбершоп ✍️', 'Barber yoki barbershopni baholang ✍️');

  // ══ Barber wallet & tiered commission ════════════════════
  static String get walletTitle => _t('Wallet', 'Кошелёк', 'Hamyon');
  static String get walletBalanceLabel =>
      _t('Balance', 'Баланс', 'Balans');
  static String get walletVending => _t(
      'Load a little, get clients out. You only pay when Fade brings you a brand-new client.',
      'Пополните немного — получайте клиентов. Платите, только когда Fade приводит нового клиента.',
      "Ozgina soling — mijoz oling. Faqat Fade yangi mijoz keltirsa to'laysiz.");
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
      _t('Use a boost now', 'Использовать буст', 'Bustni ishlatish');
  static String boostedUntilTime(String t) => _t('Boosted until $t 🚀',
      'В топе до $t 🚀', '$t gacha tepada 🚀');
  static String get outOfUps => _t('Out of Ups — grab a pack below',
      'Нет Up — купите пакет ниже', 'Up tugadi — quyidan paket oling');
  static String get boostOnToast => _t("Boost on — you're at the top 🚀",
      'Буст включён — вы в топе 🚀', 'Bust yoqildi — tepadasiz 🚀');
  static String upsUnit(int n) => _t('$n Ups', '$n Up', '$n Up');
  static String perBoostLabel(String som) =>
      _t('$som / boost', '$som / буст', '$som / bust');
  static String get bestValue =>
      _t('Best value', 'Выгодно', 'Eng foydali');
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
  static String get barberLabel => _t('Barber', 'Барбер', 'Barber');
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
  static String get biSkip => _t('Skip', 'Пропустить', "O'tkazib yuborish");

  // ── Intro: how money & commissions work ──
  static String get biMoneyTitle => _t('How you get paid',
      'Как вы получаете деньги', 'Qanday pul olasiz');
  static String get biMoneySub => _t(
      'Simple and fair — you keep your price. Here is the whole deal.',
      'Просто и честно — цена остаётся вашей. Вот и всё.',
      "Sodda va halol — narx sizniki. Mana hammasi.");
  static String get biMoneyKeepTitle => _t('You keep 100% of your price',
      'Вы оставляете 100% цены', "Narxning 100% sizniki");
  static String get biMoneyKeepSub => _t(
      'Clients pay you directly for the cut. Fade never takes a slice of your work.',
      'Клиенты платят вам напрямую. Fade не берёт долю с вашей работы.',
      "Mijozlar to'g'ridan-to'g'ri sizga to'laydi. Fade ishingizdan ulush olmaydi.");
  static String get biMoneyCommTitle => _t('Just 5% on new clients we bring',
      'Всего 5% за новых клиентов', "Yangi mijoz uchun atigi 5%");
  static String get biMoneyCommSub => _t(
      "Only on their first visit. After that they're your regular — 0% forever.",
      'Только за первый визит. Потом это ваш постоянный — 0% навсегда.',
      "Faqat birinchi tashrifda. Keyin u doimiy — abadiy 0%.");
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
  static String get tabBoost => _t('Boost', 'Буст', 'Bust');
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
      'Your photo stays on your device — nothing is uploaded.',
      'Фото остаётся на устройстве — ничего не загружается.',
      "Surat qurilmangizda qoladi — hech narsa yuklanmaydi.");
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
}
