import 'package:flutter/material.dart';
import '../views/main_page.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      "icon": Icons.wallet, // Replaced business_center with wallet for "Payment" theme
      "title": "Welcome Tolu!", // Placeholder, maybe redundant if we don't have name
      "headline": "Track Your\nPayments",
      "subtitle": "Tell us who you are to get customized tracking settings.",
      "color": AppTheme.primary,
    },
    {
      "icon": Icons.pie_chart_outline,
      "title": "Smart Insights",
      "headline": "Visualize\nYour Income",
      "subtitle": "Automatically categorizes your payments so you see where money comes from.",
      "color": AppTheme.accent,
    },
    {
      "icon": Icons.lock_outline,
      "title": "Private & Secure",
      "headline": "Data Stays\nOn Device",
      "subtitle": "We process everything locally. Your bank statement never leaves this phone.",
      "color": AppTheme.primaryDark,
    },
  ];

  void _onFinish() async {
    await DatabaseService().markIntroSeen();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Split: Dark Gradient Background
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)], // Dark Indigo -> Lighter Indigo
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon Container (Glassmorphism effect)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Icon(
                        slide['icon'], 
                        size: 80, 
                        color: Colors.white
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Split: White Content
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: SingleChildScrollView( // Added scroll for safety
                child: Container(
                  constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 3/7), // Ensure min height
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      // Progress Indicator (Small Pill)
                      Row(
                        children: List.generate(
                          _slides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            width: _currentPage == index ? 32 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? AppTheme.primary : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Typography
                      Text(
                        slide['headline'], 
                        style: const TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                          color: AppTheme.textMain,
                          // fontFamily: 'Inter', // Removed hardcoded string
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        slide['subtitle'],
                        style: const TextStyle(
                          fontSize: 16, 
                          color: AppTheme.textSub,
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 32), // Replaced generic Spacer with SizedBox for scroll safety
                      
                      // Navigation Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (_currentPage < _slides.length - 1) {
                                _currentPage++;
                              } else {
                                _onFinish();
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentPage == _slides.length - 1 ? "Get Started" : "Continue",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
