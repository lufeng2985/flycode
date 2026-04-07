import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flycode/l10n/app_localizations.dart';
import 'package:flycode/pages/home_page.dart';
import 'package:flycode/providers/global_event_provider.dart';
import 'package:flycode/providers/home_page_provider.dart';
import 'package:flycode/service/api/models/global_event.dart';
import 'package:flycode/theme/app_theme.dart';

class _FakeGlobalEventListener extends GlobalEventListener {
  @override
  Stream<GlobalEvent> build() async* {}
}

Widget _buildHomePageHarness(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const MyHomePage(title: '会话'),
    ),
  );
}

void main() {
  testWidgets(
    'home page shows sanitized load error instead of raw exception text',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          globalEventListenerProvider.overrideWith(
            _FakeGlobalEventListener.new,
          ),
          homePagePresentationStateProvider.overrideWith(
            (ref) => const HomePagePresentationState(
              sessionId: null,
              isPending: false,
              selectedSession: null,
              permissionRequest: null,
              questionRequest: null,
              bodyMode: HomePageBodyMode.error,
              hasAnySessions: false,
              showChatInput: false,
              showQuestionOverlay: false,
              canShowCommandPanel: false,
              loadError: null,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildHomePageHarness(container));
      await tester.pump();

      expect(find.text('加载项目失败，请检查服务器配置。'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('Stack'), findsNothing);
    },
  );
}
