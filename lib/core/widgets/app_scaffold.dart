import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Scaffold con sfondo a gradiente (light) o pieno scuro (dark).
/// Lo Scaffold interno è trasparente per lasciar vedere lo sfondo.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final decoration = isDark
        ? const BoxDecoration(color: AppTokens.darkBg)
        : const BoxDecoration(gradient: AppTokens.lightBgGradient);

    return Container(
      decoration: decoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
