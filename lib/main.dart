import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'views/main_page.dart'; 
import 'views/intro_page.dart'; // NEW Import
import 'viewmodels/transaction_viewmodel.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize Database Service (registers adapters and opens boxes)
  await DatabaseService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionViewModel()),
      ],
      child: MaterialApp(
        title: 'Payment Tracker',
        theme: AppTheme.lightTheme,
        home: DatabaseService().hasSeenIntro() ? const MainPage() : const IntroPage(), 
      ),
    );
  }
}
