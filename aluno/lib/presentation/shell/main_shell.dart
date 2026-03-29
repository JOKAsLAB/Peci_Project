import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const double _swipeVelocityThreshold = 520;
  static const double _swipeDistanceThreshold = 56;
  double _dragDistance = 0;

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _handleHorizontalSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldSwipeByVelocity = velocity.abs() >= _swipeVelocityThreshold;
    final shouldSwipeByDistance = _dragDistance.abs() >= _swipeDistanceThreshold;
    if (!shouldSwipeByVelocity && !shouldSwipeByDistance) {
      _dragDistance = 0;
      return;
    }

    final currentIndex = widget.navigationShell.currentIndex;
    if ((_dragDistance < 0 || velocity < 0) && currentIndex < 2) {
      _goBranch(currentIndex + 1);
    } else if ((_dragDistance > 0 || velocity > 0) && currentIndex > 0) {
      _goBranch(currentIndex - 1);
    }

    _dragDistance = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => _dragDistance = 0,
        onHorizontalDragUpdate: (details) => _dragDistance += details.delta.dx,
        onHorizontalDragEnd: _handleHorizontalSwipe,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        backgroundColor: AppTheme.surfaceSecondary,
        indicatorColor: AppTheme.brandAccent.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Cursos',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt),
            label: 'Prática',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}