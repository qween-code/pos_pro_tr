import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/theme_constants.dart';

/// Desktop platformlar için Navigation Bar
class DesktopNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  
  const DesktopNavigationBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 2,
      leading: showBackButton && Get.previousRoute != ''
          ? Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Get.back(),
                  tooltip: 'Geri',
                ),
              ],
            )
          : null,
      title: Row(
        children: [
          if (showBackButton && Get.previousRoute != '')
            IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.white70),
              onPressed: () {
                // GetX doesn't have forward navigation, but we can track it
                if (Get.routing.previous != null) {
                  Get.toNamed(Get.routing.previous!);
                }
              },
              tooltip: 'İleri',
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Ana Menü Butonu
        IconButton(
          icon: const Icon(Icons.home, color: Colors.white70),
          onPressed: () => Get.offAllNamed('/home'),
          tooltip: 'Ana Sayfa',
        ),
        // Özel actions
        if (actions != null) ...actions!,
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Basit Navigation Helper
class NavigationHelper {
  static final List<String> _history = [];
  static int _currentIndex = -1;

  static void push(String route) {
    // Remove forward history if we're not at the end
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }
    _history.add(route);
    _currentIndex = _history.length - 1;
  }

  static bool canGoBack() => _currentIndex > 0;
  
  static bool canGoForward() => _currentIndex < _history.length - 1;

  static String? goBack() {
    if (canGoBack()) {
      _currentIndex--;
      return _history[_currentIndex];
    }
    return null;
  }

  static String? goForward() {
    if (canGoForward()) {
      _currentIndex++;
      return _history[_currentIndex];
    }
    return null;
  }

  static void clear() {
    _history.clear();
    _currentIndex = -1;
  }
}
