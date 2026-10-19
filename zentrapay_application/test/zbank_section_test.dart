import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/features/zbanking/widgets/other_bank_accounts_strip.dart';

/// Builds a linked bank account for the strip/header tests.
BankAccounts _account({
  required String userBankId,
  String bankName = 'GCB Bank',
  double balance = 100.0,
  String lastDigits = '4821',
  String currencyCode = 'GHS',
  String? linkLabel,
  bool isPrimary = false,
}) => BankAccounts(
  userBankId: userBankId,
  bankId: 'bank-$userBankId',
  bankName: bankName,
  bankCode: 'GCB',
  balance: balance,
  lastDigits: lastDigits,
  countryCode: 'GH',
  currencyCode: currencyCode,
  linkLabel: linkLabel,
  isPrimary: isPrimary,
);

void main() {
  group('BankAccounts model', () {
    test('parses the backend DTO, including the `primary` wire name', () {
      final account = BankAccounts.fromJson({
        'userBankId': 'link-1',
        'userId': 'user-1',
        'bankId': 'catalog-9',
        'bankName': 'Ecobank Ghana',
        'bankCode': 'ECO',
        'balance': 1240.5,
        'lastDigits': '4821',
        'countryCode': 'GH',
        'currencyCode': 'GHS',
        'linkLabel': 'Salary',
        'primary': true,
        'connectionStatus': 'active',
        'linkedAt': '2026-01-02T10:00:00',
      });

      expect(account.userBankId, 'link-1');
      expect(account.isPrimary, isTrue);
      // The link label is the user-facing name when present.
      expect(account.displayName, 'Salary');
      expect(account.maskedNumber, '•••• •••• •••• 4821');
      expect(account.formattedBalance, 'GHS 1240.50');
      expect(account.linkedAt.year, 2026);
    });

    test('falls back to the bank name when there is no link label', () {
      final account = _account(userBankId: 'l1', bankName: 'Fidelity Bank');
      expect(account.displayName, 'Fidelity Bank');
    });

    test('copyWith flips isPrimary without touching other fields', () {
      final original = _account(userBankId: 'l1', balance: 42);
      final promoted = original.copyWith(isPrimary: true);
      expect(promoted.isPrimary, isTrue);
      expect(promoted.balance, 42);
      expect(promoted.userBankId, 'l1');
    });
  });

  group('BankAccountsSnapshot', () {
    test('parses primary and accounts, and excludes primary from `others`', () {
      final snapshot = BankAccountsSnapshot.fromJson({
        'primary': {
          'userBankId': 'link-p',
          'bankId': 'b1',
          'bankName': 'GCB Bank',
          'balance': 1000,
          'lastDigits': '1111',
          'currencyCode': 'GHS',
          'primary': true,
        },
        'accounts': [
          {
            'userBankId': 'link-p',
            'bankId': 'b1',
            'bankName': 'GCB Bank',
            'balance': 1000,
            'lastDigits': '1111',
            'currencyCode': 'GHS',
            'primary': true,
          },
          {
            'userBankId': 'link-a',
            'bankId': 'b2',
            'bankName': 'Ecobank',
            'balance': 250,
            'lastDigits': '2222',
            'currencyCode': 'GHS',
          },
        ],
      });

      expect(snapshot.primary?.userBankId, 'link-p');
      expect(snapshot.accounts, hasLength(2));
      // The header already shows the primary, so the strip must not repeat it.
      expect(snapshot.others, hasLength(1));
      expect(snapshot.others.single.userBankId, 'link-a');
      expect(snapshot.totalBalance, 1250);
    });

    test('tolerates a missing primary and empty account list', () {
      final snapshot = BankAccountsSnapshot.fromJson({'accounts': []});
      expect(snapshot.primary, isNull);
      expect(snapshot.accounts, isEmpty);
      expect(snapshot.others, isEmpty);
      expect(snapshot.totalBalance, 0);
    });
  });

  group('OtherBankAccountsStrip', () {
    testWidgets(
      'renders one card per non-primary account, horizontally scrollable',
      (tester) async {
        final others = [
          _account(
            userBankId: 'a1',
            bankName: 'Ecobank Ghana',
            lastDigits: '1111',
          ),
          _account(
            userBankId: 'a2',
            bankName: 'Fidelity Bank',
            lastDigits: '2222',
          ),
          _account(
            userBankId: 'a3',
            bankName: 'Stanbic Bank',
            lastDigits: '3333',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: OtherBankAccountsStrip(accounts: others)),
          ),
        );

        // Every linked non-primary account is represented.
        for (final name in ['Ecobank Ghana', 'Fidelity Bank', 'Stanbic Bank']) {
          expect(find.text(name), findsOneWidget);
        }

        // The strip itself must be horizontally scrollable.
        final listFinder = find.byType(ListView);
        expect(listFinder, findsOneWidget);
        final listView = tester.widget<ListView>(listFinder);
        expect(listView.scrollDirection, Axis.horizontal);

        // No overflow at this width — the key regression from the old stacked UI.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('empty account list still renders without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OtherBankAccountsStrip(accounts: [])),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
