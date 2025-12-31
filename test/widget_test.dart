import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bolt21/screens/home_screen.dart';
import 'package:bolt21/providers/wallet_provider.dart';
import 'package:bolt21/utils/theme.dart';

// Import TestWalletProvider from home_screen_test
import 'widget/home_screen_test.dart' show TestWalletProvider;

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    final testProvider = TestWalletProvider();

    await tester.pumpWidget(
      MaterialApp(
        theme: Bolt21Theme.darkTheme,
        home: ChangeNotifierProvider<WalletProvider>.value(
          value: testProvider,
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Wait for BalanceCard timer
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // Home screen should show key elements
    expect(find.text('Total Balance'), findsOneWidget);
  });
}
