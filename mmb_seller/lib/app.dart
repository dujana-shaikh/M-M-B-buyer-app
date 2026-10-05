import 'package:flutter/material.dart';
import 'package:mmb_core/mmb_core.dart';
import 'features/auth/seller_register_screen.dart';
import 'features/seller_shell.dart';

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MMB Seller',
        debugShowCheckedModeBanner: false,
        theme: MmbTheme.light(),
        darkTheme: MmbTheme.dark(),
        themeMode: ThemeMode.system,
        home: AuthGate(
          role: UserRole.seller,
          loginScreen: LoginScreen(
            title: 'Distributor Login',
            subtitle: 'Post electronics for bulk sale',
            registerBuilder: (_) => const SellerRegisterScreen(),
          ),
          homeBuilder: (_) => const SellerShell(),
        ),
      );
}
