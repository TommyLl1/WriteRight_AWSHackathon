import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:writeright/new/ui/view_model/home.dart';
import '../widgets/profile_card.dart';
import '../widgets/navigator.dart';
import 'package:writeright/new/utils/logger.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    AppLogger.debug("HomePage initializing");
    // Call initialize method once when the widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
      homeViewModel.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeViewModel = Provider.of<HomeViewModel>(context);

    if (homeViewModel.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          homeViewModel.backgroundImage,

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                ProfileCard(
                  level: homeViewModel.user.level,
                  xpProgress: homeViewModel.xpProgress,
                  tasks: homeViewModel.tasks,
                  now: now,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      homeViewModel.characterWidget,
                      const SizedBox(height: 8),
                      const Text(
                        '海豚威威',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const NavigatorCard(),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 32),
                onPressed: () => context.go('/profile'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
