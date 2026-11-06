import 'package:barber_app/core/i18n/app_language.dart';
import 'package:barber_app/core/i18n/strings.dart';
import 'package:barber_app/core/theme/app_theme.dart';
import 'package:barber_app/data/app_state.dart';
import 'package:barber_app/data/mock_data.dart';
import 'package:barber_app/data/models/chat_message.dart';
import 'package:barber_app/presentation/screens/barber/barber_messages_screen.dart';
import 'package:barber_app/presentation/widgets/conversation_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<AppState> barber([Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    await initializeDateFormatting();
    final s = AppState.instance;
    await s.load();
    s.signInWithIdentity(
      id: 'b',
      fullName: 'Rustam Aliev',
      phone: '+998935550011',
      role: AppRole.barber,
      method: AuthMethod.telegram,
    );
    s.registerBarber(RegisteredBarber(
      firstName: 'Rustam',
      surname: 'Aliev',
      age: 27,
      phone: '+998935550011',
      shopId: MockData.demoShops.first.id,
    ));
    s.setLanguage(AppLanguage.en);
    Intl.defaultLocale = 'en';
    return s;
  }

  test('unread = messages from the other side since my last one', () {
    ChatMessage m(bool mine) => ChatMessage(text: 'x', mine: mine, at: DateTime.now());
    expect(unreadIn([]), 0);
    expect(unreadIn([m(true), m(false), m(false)]), 2);
    expect(unreadIn([m(false), m(true)]), 0);
  });

  test('replies keep their quote; only my own messages can be deleted', () async {
    final s = await barber();
    const client = 'Test Client';
    s.sendBarberChat(client, 'Are you free at 15:00?');
    final first = s.barberChatWith(client).last;
    s.sendBarberChat(client, 'Or 16:00', replyTo: first);
    final reply = s.barberChatWith(client).last;
    expect(reply.replyTo?.id, first.id);

    s.deleteBarberChatMessage(client, first.id);
    expect(s.barberChatWith(client).any((m) => m.id == first.id), isFalse);
    // The reply still shows what it answered.
    expect(s.barberChatWith(client).last.replyTo?.text, 'Are you free at 15:00?');
  });

  test('the other side shows as typing, then answers', () async {
    final s = await barber();
    const client = 'Typing Client';
    s.sendBarberChat(client, 'Hi');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(s.isTyping(client), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(s.isTyping(client), isFalse);
    expect(s.barberChatWith(client).last.mine, isFalse);
  });

  test('the schedule opens on the slots view by default', () async {
    final s = await barber();
    expect(s.scheduleSlotsView, isTrue);
  });

  testWidgets('barber list: active chats first, quiet clients in the strip',
      (t) async {
    final previous = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) previous?.call(d);
    };
    addTearDown(() => FlutterError.onError = previous);
    final s = await barber();
    final clients = s.barberClients;
    expect(clients.length, greaterThan(1));
    t.view.physicalSize = const Size(390, 1600);
    t.view.devicePixelRatio = 1.0;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });

    await t.pumpWidget(MaterialApp(
        theme: AppTheme.light, home: const BarberMessagesScreen()));
    await t.pump(const Duration(milliseconds: 600));

    // Every client with messages is a full thread row; the strip is there for
    // the rest; nobody reads "Tap to message" any more.
    final withMsgs =
        clients.where((b) => s.barberChatWith(b.clientName!).isNotEmpty).length;
    expect(find.byType(ChatThreadTile), findsNWidgets(withMsgs));
    if (withMsgs < clients.length) {
      expect(find.text(L.chatStartWith), findsOneWidget);
    }
    expect(find.text(L.tapToMessage), findsNothing);
  });
}
