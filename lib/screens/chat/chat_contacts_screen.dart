import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flymfrontend/config/app_constants.dart';
import 'package:flymfrontend/core/theme/app_theme.dart';

/// 聊天联系人列表
/// 包含主治医生与平台服务两类联系人，点击后进入聊天页面
class ChatContactsScreen extends StatelessWidget {
  const ChatContactsScreen({super.key});

  static const List<_ChatContact> _doctorContacts = [
    _ChatContact(
      name: '王心研 · 主治医师',
      role: '呼吸内科  |  上海市第一人民医院',
      lastMessage: '好的，稍后我补充用药建议。',
      lastTime: '15:32',
      unreadCount: 2,
      badgeText: '图文问诊',
      color: Color(0xFFB2D7FF),
    ),
    _ChatContact(
      name: '丁可欣 · 主任医师',
      role: '儿科  |  上海儿童医学中心',
      lastMessage: '收到化验单了，我们电话沟通一下？',
      lastTime: '昨天',
      unreadCount: 0,
      badgeText: '复诊中',
      color: Color(0xFFFFC8C2),
    ),
    _ChatContact(
      name: '护理专员',
      role: '术后康复随访',
      lastMessage: '今天感觉怎么样？注意休息哦～',
      lastTime: '周二',
      unreadCount: 1,
      badgeText: '随访',
      color: Color(0xFFE4E3FF),
    ),
  ];

  static const List<_ChatContact> _serviceContacts = [
    _ChatContact(
      name: '健康小助手',
      role: '7×24 小时在线客服',
      lastMessage: '您好～本周会员权益礼包已更新，欢迎查收。',
      lastTime: '08:10',
      unreadCount: 3,
      badgeText: '会员',
      color: Color(0xFF95EC69),
    ),
    _ChatContact(
      name: '保险顾问',
      role: '保障方案咨询',
      lastMessage: '想了解你的意向预算，我们再优化一下方案。',
      lastTime: '昨天',
      unreadCount: 0,
      badgeText: '保障',
      color: Color(0xFFFFE19C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('联系人'),
          elevation: 0.5,
          bottom: const TabBar(tabs: [Tab(text: '医生团队'), Tab(text: '平台服务')]),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: () {},
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _ContactList(contacts: _doctorContacts),
            _ContactList(contacts: _serviceContacts),
          ],
        ),
      ),
    );
  }
}

class _ContactList extends StatelessWidget {
  const _ContactList({required this.contacts});

  final List<_ChatContact> contacts;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return const Center(
        child: Text('暂无联系人', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const Divider(height: 0, indent: 72),
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return _ContactTile(contact: contact);
      },
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact});

  final _ChatContact contact;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => _openChat(context, contact),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: contact.color,
        child: Text(
          contact.initial,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              contact.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Text(
            contact.lastTime,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.role,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              contact.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (contact.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                contact.unreadCount > 99 ? '99+' : '${contact.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (contact.badgeText != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                contact.badgeText!,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void _openChat(BuildContext context, _ChatContact contact) {
    final params = {'title': contact.name};
    final uri = Uri(path: AppConstants.routeChat, queryParameters: params);
    context.push(uri.toString());
  }
}

class _ChatContact {
  const _ChatContact({
    required this.name,
    required this.role,
    required this.lastMessage,
    required this.lastTime,
    this.unreadCount = 0,
    this.badgeText,
    this.color = const Color(0xFFB2D7FF),
  });

  final String name;
  final String role;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;
  final String? badgeText;
  final Color color;

  String get initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.substring(0, 1);
  }
}
