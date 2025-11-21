import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flymfrontend/providers/settings_provider.dart';
import 'package:flymfrontend/config/app_config.dart';

/// 设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showClearCacheDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('清除缓存'),
            content: const Text('确定要清除所有缓存吗？此操作不可恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('清除'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      final provider = Provider.of<SettingsProvider>(context, listen: false);
      final success = await provider.clearAllCache();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success ? '缓存已清除' : '清除缓存失败')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设置'), elevation: 0),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 缓存设置卡片
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '缓存设置',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('启用缓存'),
                      subtitle: const Text('启用后可以提升应用性能'),
                      value: provider.cacheEnabled,
                      onChanged: (value) {
                        provider.setCacheEnabled(value);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('自动清理过期缓存'),
                      subtitle: const Text('自动清理过期的缓存数据'),
                      value: provider.autoCleanCache,
                      onChanged: (value) {
                        provider.setAutoCleanCache(value);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('缓存大小'),
                      subtitle:
                          provider.isLoadingCacheSize
                              ? const Text('计算中...')
                              : Text(provider.cacheSize),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          provider.refreshCacheSize();
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('清理过期缓存'),
                      subtitle: const Text('清理已过期的缓存数据'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await provider.cleanExpiredCache();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已清理过期缓存')),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text(
                        '清除所有缓存',
                        style: TextStyle(color: Colors.red),
                      ),
                      subtitle: const Text('清除所有缓存数据，此操作不可恢复'),
                      trailing: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      onTap: () => _showClearCacheDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 关于应用卡片
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '关于应用',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('应用名称'),
                      subtitle: Text(AppConfig.appName),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('版本号'),
                      subtitle: Text(AppConfig.appVersion),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('帮助中心'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 跳转到帮助中心
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('功能开发中')));
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('关于我们'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: AppConfig.appName,
                          applicationVersion: AppConfig.appVersion,
                          applicationIcon: Icon(
                            Icons.medical_services,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Text(
                                '远程医疗问诊移动端应用\n\n'
                                '为用户提供便捷的在线医疗咨询服务。',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
