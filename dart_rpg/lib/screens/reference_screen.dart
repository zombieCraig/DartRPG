import 'package:flutter/material.dart';
import 'moves_screen.dart';
import 'oracles_screen.dart';
import 'assets_screen.dart';
import 'truths_screen.dart';

/// A screen that consolidates Moves, Oracles, Assets, and Truths into sub-tabs.
class ReferenceScreen extends StatefulWidget {
  /// Which sub-tab to show initially: 0=Moves, 1=Oracles, 2=Assets, 3=Truths
  final int initialSubTabIndex;

  const ReferenceScreen({
    super.key,
    this.initialSubTabIndex = 0,
  });

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialSubTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.sports_martial_arts), text: 'Moves'),
            Tab(icon: Icon(Icons.casino), text: 'Oracles'),
            Tab(icon: Icon(Icons.card_membership), text: 'Assets'),
            Tab(icon: Icon(Icons.public), text: 'Truths'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              MovesScreen(),
              OraclesScreen(),
              AssetsScreen(),
              TruthsScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
