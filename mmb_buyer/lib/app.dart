import 'package:flutter/material.dart';
import 'package:mmb_core/mmb_core.dart';
import 'features/auth/buyer_register_screen.dart';
import 'features/buyer_shell.dart';

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MMB',
        debugShowCheckedModeBanner: false,
        theme: MmbTheme.light(),
        darkTheme: MmbTheme.dark(),
        themeMode: ThemeMode.system,
        home: AuthGate(
          role: UserRole.buyer,
          loginScreen: LoginScreen(
            title: 'Welcome back',
            subtitle: 'Buy electronics in bulk, direct from distributors',
            registerBuilder: (_) => const BuyerRegisterScreen(),
          ),
          homeBuilder: (_) => const BuyerShell(),
        ),
      );
}
