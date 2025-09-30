import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:writeright/new/ui/view_model/profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Call initialize method once when the widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsViewModel = Provider.of<ProfileViewModel>(
        context,
        listen: false,
      );
      settingsViewModel.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ProfileViewModel>(context);

    if (store.isProfileLoading || store.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (store.isProfileError) {
      return Scaffold(body: Center(child: const Text('載入個人檔案失敗')));
    }

    final name = store.user!.name;
    final level = store.user!.level;
    final exp = store.user!.exp;
    final expMax = store.expMax;
    final xpProgress = store.xpProgress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('個人檔案'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back button icon
          onPressed: () {
            context.go('/home'); // Navigate to the home page
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[350],
              child: const Icon(Icons.person, size: 60, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Username
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Level and XP Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lv. $level',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$exp / $expMax XP',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: xpProgress,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
            const SizedBox(height: 32),

            // List of items
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: const Text('帳戶'),
                    onTap: () => context.go('/account'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('設定'),
                    onTap: () => context.go('/settings'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('關於'),
                    onTap: () => context.go('/about'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
