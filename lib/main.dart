import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/erp_home_screen.dart';
import 'services/store.dart';
import 'services/erp_store.dart';
import 'widgets/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.instance.load();
  await ErpStore.instance.load();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const HesabatiErpApp());
}

class HesabatiErpApp extends StatelessWidget {
  const HesabatiErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حساباتي ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: gold,
          error: coral,
        ),
        fontFamilyFallback: const ['Arial','Tahoma'],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: darkText,
          elevation: 0,
          scrolledUnderElevation: .5,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(color: darkText, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: line)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 17),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryDark,
            side: const BorderSide(color: line),
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 17),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 1.3)),
          labelStyle: const TextStyle(color: softText, fontWeight: FontWeight.w700, fontSize: 12),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: primaryLight,
          labelTextStyle: WidgetStateProperty.resolveWith((s)=>TextStyle(color:s.contains(WidgetState.selected)?primaryDark:softText,fontWeight:FontWeight.w900,fontSize:10)),
          iconTheme: WidgetStateProperty.resolveWith((s)=>IconThemeData(color:s.contains(WidgetState.selected)?primary:softText,size:22)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          titleTextStyle: const TextStyle(color: darkText, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white,surfaceTintColor: Colors.transparent,showDragHandle:true),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: darkText,
          contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        dividerColor: line,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: ErpHomeScreen(),
      ),
    );
  }
}
