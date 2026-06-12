import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/store.dart';
import 'widgets/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.instance.load();
  runApp(const SmartAccountingApp());
}

class SmartAccountingApp extends StatelessWidget {
  const SmartAccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المحاسب الذكي V3',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: darkText,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomeScreen(),
      ),
    );
  }
}
