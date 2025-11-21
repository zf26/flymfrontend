import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flymfrontend/config/app_constants.dart';
import 'package:flymfrontend/providers/auth_provider.dart';

/// 格式化手机号（脱敏处理）
String _formatPhone(String? phone) {
  if (phone == null || phone.isEmpty) {
    return '未设置';
  }
  if (phone.length == 11) {
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }
  return phone;
}

/// 个人中心页
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认退出'),
            content: const Text('确定要退出登录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('退出'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (context.mounted) {
        // 退出登录后跳转到登录页
        context.go(AppConstants.routeLogin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          final phone = _formatPhone(user?.phone);
          final displayName = user?.name ?? '用户';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 用户信息卡片
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('手机号：$phone'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 功能菜单卡片
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.person_outline,
                        color: colorScheme.primary,
                      ),
                      title: const Text('个人信息'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 跳转到个人信息页面
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.medical_services_outlined,
                        color: colorScheme.primary,
                      ),
                      title: const Text('我的问诊'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.go(AppConstants.routeConsultation);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.health_and_safety_outlined,
                        color: colorScheme.primary,
                      ),
                      title: const Text('健康档案'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 跳转到健康档案页面
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 设置菜单卡片
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.settings_outlined,
                        color: colorScheme.primary,
                      ),
                      title: const Text('设置'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push(AppConstants.routeSettings);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.help_outline,
                        color: colorScheme.primary,
                      ),
                      title: const Text('帮助中心'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 跳转到帮助中心
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                      ),
                      title: const Text('关于我们'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 跳转到关于我们页面
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 退出登录按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => _handleLogout(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '退出登录',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
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
