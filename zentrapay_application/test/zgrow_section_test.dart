// Tests for the ZGrow tab ("Grow" bottom-nav tab). The screen orchestrates
// six repositories; setUp seeds each of them so ensureLoaded() short-circuits
// before any network I/O, letting the suite assert on pure rendering and the
// toggle / "See more" interactions without a backend. A final test deliberately
// clears the caches again to exercise the loading path.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbanking_data.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrow_data.dart';
import 'package:zentrapay_application/features/zgrow/widgets/challenges_all_screen.dart';
import 'package:zentrapay_application/features/zgrow/widgets/rewards_all_screen.dart';
import 'package:zentrapay_application/features/zgrow/widgets/tutorials_all_screen.dart';
import 'package:zentrapay_application/features/zgrow/widgets/zgrow_hero_card.dart';
import 'package:zentrapay_application/features/zgrow/zgrow_screen.dart';

Challenge _challenge(String id, {String? title}) => Challenge(
  id: id,
  title: title ?? 'Challenge $id',
  description: 'Steady saving habits, rewarded daily.',
  category: 'Savings',
  challengeType: 'AMOUNT',
  durationDays: 7,
  isActive: true,
  progressPercentage: 0,
  startDate: '',
  endDate: '',
  targets: <Map<String, dynamic>>[
    {'rewardType': 'POINTS', 'rewardValue': 250, 'targetAmount': 100.0},
  ],
);

UserChallenge _enrollment(String id, Challenge challenge) => UserChallenge(
  id: id,
  userId: 'user-1',
  challenge: challenge,
  status: 'IN_PROGRESS',
  currentAmount: 40,
  targetAmount: 100,
  progressPercentage: 40,
  startedAt: '',
  endsAt: '',
  completedAt: '',
  challengeProgressLogs: const [],
);

Tutorial _tutorial(int id) => Tutorial(
  id: id,
  title: 'Lesson $id',
  type: 'VIDEO',
  description: 'Learn the basics.',
  videoUrl: '',
  thumbnailUrl: '',
  durationSeconds: 60,
  isActive: true,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Reward _reward(int id) => Reward(
  rewardId: id,
  rewardType: 'POINTS',
  title: 'Reward $id',
  description: 'Keep your streak going.',
  worth: 100,
  currencyCode: 'GHS',
  isActive: true,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Future<void> _pump(WidgetTester t) async {
  await t.pumpWidget(const MaterialApp(home: Scaffold(body: ZGrowScreen())));
  await t.pumpAndSettle();
}

/// Scrolls the whole tab down and back up so every section — including the
/// ones below the fold — goes through layout and paint.
Future<void> _scroll(WidgetTester t) async {
  final Finder root = find.byType(CustomScrollView).first;
  for (var i = 0; i < 8; i++) {
    await t.drag(root, const Offset(0, -300));
    await t.pumpAndSettle();
  }
  for (var i = 0; i < 8; i++) {
    await t.drag(root, const Offset(0, 300));
    await t.pumpAndSettle();
  }
}

void main() {
  // The repositories build their Dio client lazily through ApiClient, which
  // reads BASE_URL from dotenv — mirror main() by loading it first.
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:2000');
  });

  setUp(() {
    ChallengesRepository.instance.setData([
      for (var i = 0; i < 5; i++)
        _challenge('c$i', title: 'Challenge ${i + 1}'),
    ]);
    UserChallengesRepository.instance.setData([
      _enrollment('e1', _challenge('accepted-1', title: 'Accepted one')),
      _enrollment('e2', _challenge('accepted-2', title: 'Accepted two')),
    ]);
    TutorialsRepository.instance.setData(
      TutorialsList(tutorials: [for (var i = 0; i < 5; i++) _tutorial(i)]),
    );
    RewardsRepository.instance.setData(
      RewardsList(rewards: [for (var i = 0; i < 5; i++) _reward(i)]),
    );
    BankAccountsRepository.instance.setData(
      const BankAccountsSnapshot(primary: null, accounts: []),
    );
    BankingInsightsRepository.instance.setData(
      BankingInsights(
        monthlySpend: '0',
        monthlyIncome: '0',
        topCategories: const [],
      ),
    );
  });

  testWidgets('renders every section from cached data and scrolls', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Your Overall Savings'), findsOneWidget);
    expect(find.text('Gamified Savings'), findsOneWidget);
    // Quick actions: the financial tools section is gone, Save Goal lives here.
    expect(find.text('Emergency'), findsOneWidget);
    expect(find.text('Pay Loans'), findsOneWidget);
    expect(find.text('Save Goal'), findsOneWidget);
    expect(find.text('Financial Tools'), findsNothing);
    expect(find.text('Rewards'), findsOneWidget);
    expect(find.text('Tutorials'), findsOneWidget);
    expect(find.text('Budget Planner'), findsNothing);
    expect(find.text('Debt Tracker'), findsNothing);
    // The two groups stay hidden while the toggle is off.
    expect(find.text('All Challenges'), findsNothing);
    expect(find.text('Accepted Challenges'), findsNothing);

    await _scroll(tester);
    expect(find.text('Your Overall Savings'), findsOneWidget);
  });

  testWidgets('the gamified switch reveals both challenge groups', (
    tester,
  ) async {
    await _pump(tester);

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('All Challenges'), findsOneWidget);
    expect(find.text('Accepted Challenges'), findsOneWidget);
    // Inline cards render for both groups (3 capped + 2 accepted).
    expect(find.text('Accept Challenge'), findsNWidgets(3));
    expect(find.text('Decline'), findsNWidgets(2));
    // 5 catalog challenges exceed the inline cap of 3, so the "All" group
    // gets a "See more" link; the 2 accepted enrollments do not. Scope to the
    // group heading so this doesn't pick up the Rewards/Tutorials links.
    final Finder seeMore = find.descendant(
      of: find
          .ancestor(of: find.text('All Challenges'), matching: find.byType(Row))
          .first,
      matching: find.text('See more'),
    );
    expect(seeMore, findsOneWidget);

    await tester.ensureVisible(seeMore);
    await tester.tap(seeMore);
    await tester.pumpAndSettle();

    expect(find.byType(ChallengesAllScreen), findsOneWidget);
    // The ListView only builds visible rows, so verify the full list by
    // title: the first card is on screen, and the last one is reachable by
    // scrolling (i.e. all 5 catalog challenges render, not just the inline
    // cap of 3).
    final Finder list = find.descendant(
      of: find.byType(ChallengesAllScreen),
      matching: find.byType(Scrollable),
    );
    expect(
      find.descendant(
        of: find.byType(ChallengesAllScreen),
        matching: find.text('Challenge 1'),
      ),
      findsOneWidget,
    );
    await tester.drag(list, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(ChallengesAllScreen),
        matching: find.text('Challenge 5'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders "See more" for rewards and tutorials over the cap', (
    tester,
  ) async {
    await _pump(tester);

    // 5 rewards > 4 inline cap, so the Rewards link appears and opens the
    // full list with every reward.
    final Finder rewardsSeeMore = find.descendant(
      of: find
          .ancestor(of: find.text('Rewards'), matching: find.byType(Row))
          .first,
      matching: find.text('See more'),
    );
    expect(rewardsSeeMore, findsOneWidget);
    await tester.ensureVisible(rewardsSeeMore);
    await tester.tap(rewardsSeeMore);
    await tester.pumpAndSettle();
    expect(find.byType(RewardsAllScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    // Same contract for tutorials (5 seeded, 4 inline).
    final Finder tutorialsSeeMore = find.descendant(
      of: find
          .ancestor(of: find.text('Tutorials'), matching: find.byType(Row))
          .first,
      matching: find.text('See more'),
    );
    expect(tutorialsSeeMore, findsOneWidget);
    await tester.ensureVisible(tutorialsSeeMore);
    await tester.tap(tutorialsSeeMore);
    await tester.pumpAndSettle();
    expect(find.byType(TutorialsAllScreen), findsOneWidget);
  });

  testWidgets('the hero visibility toggle masks the saved amount', (
    tester,
  ) async {
    await _pump(tester);

    // The hero shows the GHS-prefixed figure; rewards tiles use their own
    // currency codes, so scope to the hero card.
    final Finder hero = find.byType(ZGrowHeroCard);
    expect(
      find.descendant(of: hero, matching: find.textContaining('GHS')),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: hero, matching: find.byIcon(Icons.visibility_off)),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: hero, matching: find.text('___.__')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: hero, matching: find.textContaining('GHS')),
      findsNothing,
    );

    await tester.tap(
      find.descendant(of: hero, matching: find.byIcon(Icons.visibility)),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: hero, matching: find.textContaining('GHS')),
      findsOneWidget,
    );
  });

  testWidgets('renders and scrolls on a small phone viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester);
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('All Challenges'), findsOneWidget);

    await _scroll(tester);
  });

  testWidgets('renders static sections when the caches are empty', (
    tester,
  ) async {
    ChallengesRepository.instance.clear();
    UserChallengesRepository.instance.clear();
    TutorialsRepository.instance.clear();
    RewardsRepository.instance.clear();
    BankAccountsRepository.instance.clear();
    BankingInsightsRepository.instance.clear();

    await _pump(tester);

    // The hero and static sections still render while data loads or fails;
    // a failed fetch must not surface as an unhandled exception.
    expect(find.text('Your Overall Savings'), findsOneWidget);
    expect(find.text('Pay Loans'), findsOneWidget);
  });
}
