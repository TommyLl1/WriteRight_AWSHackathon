import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:writeright/new/ui/view_model/setting.dart';
import 'package:provider/provider.dart';
import 'package:writeright/new/utils/logger.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _titleTapCount = 0;
  bool _showDeveloperSettings = false;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<SettingsViewModel>(context, listen: false);
    // Initialize settings when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsStore = Provider.of<SettingsViewModel>(context);
    AppLogger.debug("hasUnsavedChanges: ${settingsStore.hasUnsavedChanges}");
    return PopScope(
      canPop: !settingsStore.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && settingsStore.hasUnsavedChanges) {
          final shouldLeave = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('尚有未儲存的設定'),
              content: const Text('你有尚未儲存的更改，確定要離開嗎？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('離開'),
                ),
              ],
            ),
          );
          if (shouldLeave == true && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onTap: () {
              setState(() {
                _titleTapCount++;
                if (_titleTapCount >= 7) {
                  _showDeveloperSettings = true;
                  _titleTapCount = 0;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('開發者設定已啟用')));
                }
              });
            },
            child: const Text('設定'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // Back button icon
            onPressed: () async {
              if (settingsStore.hasUnsavedChanges) {
                final shouldLeave = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('尚有未儲存的設定'),
                    content: const Text('你有尚未儲存的更改，確定要離開嗎？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('離開'),
                      ),
                    ],
                  ),
                );
                if (shouldLeave == true) {
                  if (mounted) {
                    context.go('/profile');
                  }
                }
              } else {
                context.go('/profile'); // Navigate back to the profile page
              }
            },
          ),
          actions: [
            if (settingsStore.hasUnsavedChanges)
              IconButton(
                icon: Icon(
                  Icons.save,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                tooltip: '儲存設定',
                onPressed: settingsStore.isSaving
                    ? null
                    : () async {
                        await settingsStore.saveSettings();
                        if (!mounted) {
                          return; // Check if widget is still mounted
                        }
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('設定已儲存')));
                      },
              )
            else
              IconButton(
                icon: const Icon(Icons.save_outlined),
                tooltip: '儲存設定',
                onPressed: null,
              ),
          ],
        ),
        body: settingsStore.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wrong Word Library Section
                    Text(
                      '錯字庫',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Wrong Word Badge Setting
                    Card(
                      child: SwitchListTile(
                        title: const Text('顯示錯字數量徽章'),
                        subtitle: const Text('在應用程式中顯示錯字計數徽章'),
                        value: settingsStore.showWrongCountBadge,
                        onChanged: settingsStore.isSaving
                            ? null
                            : (bool value) {
                                settingsStore.updateDictionarySetting(
                                  'showWrongCountBadge',
                                  value,
                                );
                              },
                        secondary: const Icon(Icons.badge),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Language & Theme Section
                    Text(
                      '外觀設定',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Theme Setting (hidden for now)
                    Card(
                      child: ListTile(
                        title: const Text('主題'),
                        subtitle: Text(
                          _getThemeDisplayName(settingsStore.theme),
                        ),
                        leading: const Icon(Icons.palette),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        enabled: false, // Hide/disable theme selection
                        onTap: null,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Additional settings sections
                    Text(
                      '其他設定',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notification settings placeholder
                    Card(
                      child: ListTile(
                        title: const Text('通知設定'),
                        subtitle: const Text('管理應用程式通知'),
                        leading: const Icon(Icons.notifications),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // TODO: Navigate to notification settings
                        },
                      ),
                    ),

                    // Show refresh button if there's an error
                    if (settingsStore.settings == null &&
                        !settingsStore.isLoading)
                      Card(
                        child: ListTile(
                          title: const Text('重新載入設定'),
                          subtitle: const Text('點擊重新從伺服器載入設定'),
                          leading: const Icon(Icons.refresh),
                          onTap: () {
                            settingsStore.refresh();
                          },
                        ),
                      ),

                    // Developer settings section (hidden by default)
                    if (_showDeveloperSettings) ...[
                      const SizedBox(height: 32),
                      Text(
                        '開發者設定',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Staging endpoint setting
                      Card(
                        child: SwitchListTile(
                          title: const Text('使用測試伺服器'),
                          subtitle: const Text('切換到測試環境的 API 端點 (需要重新啟動應用程式)'),
                          value: settingsStore.useStagingEndpoint,
                          onChanged: (bool value) {
                            settingsStore.updateStagingEndpoint(value);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? '已切換到測試伺服器，請重新啟動應用程式以確保所有功能正常運作'
                                      : '已切換到正式伺服器，請重新啟動應用程式以確保所有功能正常運作',
                                ),
                                duration: const Duration(seconds: 5),
                                action: SnackBarAction(
                                  label: '關閉',
                                  onPressed: () {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).hideCurrentSnackBar();
                                  },
                                ),
                              ),
                            );
                          },
                          secondary: const Icon(Icons.dns),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  String _getThemeDisplayName(String? theme) {
    switch (theme) {
      case 'light':
        return '淺色主題';
      case 'dark':
        return '深色主題';
      case 'system':
        return '跟隨系統';
      default:
        return '淺色主題';
    }
  }
}
