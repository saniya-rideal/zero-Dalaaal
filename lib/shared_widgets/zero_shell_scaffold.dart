import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'maintenance_banner.dart';
import 'network_status_banner.dart';
import 'zero_bottom_dock.dart';
import 'zero_bottom_nav_bar.dart';
import 'zero_drawer.dart';

class ZeroShellScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ZeroShellScaffold({super.key, required this.navigationShell});

  @override
  State<ZeroShellScaffold> createState() => _ZeroShellScaffoldState();
}

class _ZeroShellScaffoldState extends State<ZeroShellScaffold> with SingleTickerProviderStateMixin {
  bool _isMarginExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1.0, // Initially expanded as in screenshots
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMarginDock() {
    setState(() {
      _isMarginExpanded = !_isMarginExpanded;
      if (_isMarginExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  String _getActiveRoute() {
    switch (widget.navigationShell.currentIndex) {
      case 0:
        return '/quotes';
      case 1:
        return '/deals';
      case 2:
        return '/net-deals';
      case 3:
        return '/history';
      default:
        return '/quotes';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      drawer: ZeroDrawer(activeRoute: _getActiveRoute()),
      body: Column(
        children: [
          // Persistent Maintenance Banner & Network Offline Banner
          const MaintenanceBanner(),
          const NetworkStatusBanner(),

          // Main Active Screen View
          Expanded(child: widget.navigationShell),

          // Slide-Down / Slide-Up Animated 10-Metric Bottom Account Margin Dock
          GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null) {
                if (details.primaryDelta! > 6 && _isMarginExpanded) {
                  _toggleMarginDock();
                } else if (details.primaryDelta! < -6 && !_isMarginExpanded) {
                  _toggleMarginDock();
                }
              }
            },
            child: SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1.0,
              child: const ZeroBottomDock(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: ZeroBottomNavBar(
          currentIndex: currentIndex,
          isExpanded: _isMarginExpanded,
          onCenterToggle: _toggleMarginDock,
          onTabSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}
