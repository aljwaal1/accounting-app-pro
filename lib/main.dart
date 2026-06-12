import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/store_service.dart';
import 'widgets/ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StoreService.instance.load();
  runApp(const AccountingDesktopApp());
}

class AccountingDesktopApp extends StatelessWidget {
  const AccountingDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المحاسب الاحترافي V2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: bg,
        fontFamily: null,
      ),
      home: const Directionality(textDirection: TextDirection.rtl, child: HomeScreen()),
    );
  }
}
