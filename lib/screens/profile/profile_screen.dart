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

/// 构建头像 Widget
Widget _buildAvatar(String? avatarUrl, ColorScheme colorScheme) {
  // 默认头像
  final defaultAvatar = CircleAvatar(
    radius: 30,
    backgroundColor: colorScheme.primary.withOpacity(0.1),
    child: Icon(Icons.person, size: 30, color: colorScheme.primary),
  );

  if (avatarUrl == null || avatarUrl.isEmpty) {
    return defaultAvatar;
  }

  // 使用 ClipOval + Image.network 来确保图片能正确显示
  return ClipOval(
    child: Image.network(
      avatarUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      cacheWidth: 120, // 缓存宽度，优化内存使用
      cacheHeight: 120, // 缓存高度，优化内存使用
      errorBuilder: (context, error, stackTrace) {
        debugPrint('头像加载失败: $error');
        return defaultAvatar;
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return CircleAvatar(
          radius: 30,
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          child: CircularProgressIndicator(
            value:
                loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        );
      },
    ),
  );
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
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.user;
            final phone = _formatPhone(user?.phone);
            final displayName = user?.name ?? '用户';
            final avatarUrl = user?.avatar;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // 用户信息卡片
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: _buildAvatar(avatarUrl, colorScheme),
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

                // 功能菜单和设置菜单卡片
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // 功能菜单
                      ListTile(
                        leading: Icon(
                          Icons.person_outline,
                          color: colorScheme.primary,
                        ),
                        title: const Text('个人信息'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.push(AppConstants.routePersonalInfo);
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
                          context.push(AppConstants.routeConsultation);
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
                      const Divider(height: 1),
                      // 设置菜单
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
                        leading: Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          '退出登录',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () => _handleLogout(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}
