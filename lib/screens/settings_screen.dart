import 'package:flutter/material.dart';
import 'package:chat_app/services/theme_manager.dart';
import 'package:chat_app/widgets/background_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late PageController _pageController;
  // Start at a large number to allow scrolling left immediately
  final int _initialPage = 1000;

  @override
  void initState() {
    super.initState();
    // Precache images to avoid jank
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var theme in AppTheme.values) {
        precacheImage(
          AssetImage(ThemeManager().getBackgroundImage(theme)),
          context,
        );
      }
    });

    // Calculate initial page to be a multiple of length + current index
    // This ensures we start at the correct "slot" in the infinite scroll
    // 1000 is arbitrary, we find the nearest multiple of length <= 1000
    final int basePage = _initialPage - (_initialPage % AppTheme.values.length);
    final int startPage = basePage + ThemeManager().currentTheme.value.index;

    _pageController = PageController(
      viewportFraction: 0.6,
      initialPage: startPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final themeIndex = index % AppTheme.values.length;
    final newTheme = AppTheme.values[themeIndex];
    // Only update if different to avoid unnecessary rebuilds
    if (ThemeManager().currentTheme.value != newTheme) {
      ThemeManager().setTheme(newTheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 60),
            SizedBox(
              height: 400,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                // Infinite scroll simulation
                itemBuilder: (context, index) {
                  final themeIndex = index % AppTheme.values.length;
                  final theme = AppTheme.values[themeIndex];

                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                      } else {
                        // Initial state handling
                        final currentIndex = _pageController.initialPage;
                        if (index == currentIndex) {
                          value = 1.0;
                        } else {
                          value = 0.7; // Scale down others initially
                        }
                      }

                      return Center(
                        child: SizedBox(
                          height: Curves.easeOut.transform(value) * 350,
                          width: Curves.easeOut.transform(value) * 250,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        image: DecorationImage(
                          image: AssetImage(
                            ThemeManager().getBackgroundImage(theme),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
            ValueListenableBuilder<AppTheme>(
              valueListenable: ThemeManager().currentTheme,
              builder: (context, theme, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeManager().getThemeColor(theme),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    ThemeManager().getThemeName(theme),
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            const Text(
              'Theme',
              style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
