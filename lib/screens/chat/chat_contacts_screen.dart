import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flymfrontend/config/app_constants.dart';
import 'package:flymfrontend/core/theme/app_theme.dart';
import 'package:flymfrontend/providers/chat_provider.dart';
import 'package:flymfrontend/providers/auth_provider.dart';
import 'package:flymfrontend/models/conversation_model.dart';

/// 聊天联系人列表
/// 包含主治医生与平台服务两类联系人，点击后进入聊天页面
class ChatContactsScreen extends StatefulWidget {
  const ChatContactsScreen({super.key});

  @override
  State<ChatContactsScreen> createState() => _ChatContactsScreenState();
}

class _ChatContactsScreenState extends State<ChatContactsScreen> {
  @override
  void initState() {
    super.initState();
    // 加载会话列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('联系人'),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go(AppConstants.routeHome);
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ChatProvider>().refreshConversations();
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    chatProvider.errorMessage!,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      chatProvider.loadConversations();
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (chatProvider.conversations.isEmpty) {
            return const Center(
              child: Text(
                '暂无会话',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => chatProvider.refreshConversations(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chatProvider.conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 0, indent: 72),
              itemBuilder: (context, index) {
                final conversation = chatProvider.conversations[index];
                return _ConversationTile(conversation: conversation);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final ConversationModel conversation;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final currentUserId = int.tryParse(auth.user?.id ?? '0') ?? 0;
    final otherUserId = conversation.getOtherUserId(currentUserId);

    // 获取对方用户信息（这里简化处理，实际应该从用户服务获取）
    final displayName = conversation.otherUserName ?? '用户 $otherUserId';
    final displayRole = conversation.otherUserRole ?? '医生';
    final lastMsg = conversation.lastMessage ?? '暂无消息';
    final lastTime = conversation.lastMessageTime ?? '';

    return ListTile(
      onTap: () => _openChat(context, conversation, currentUserId),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFFB2D7FF),
        backgroundImage:
            conversation.otherUserAvatar != null &&
                    conversation.otherUserAvatar!.isNotEmpty
                ? NetworkImage(conversation.otherUserAvatar!)
                : null,
        child:
            conversation.otherUserAvatar == null
                ? Text(
                  displayName.isNotEmpty ? displayName[0] : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
                : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Text(
            lastTime,
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
              displayRole,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lastMsg,
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
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.unreadCount > 99
                    ? '99+'
                    : '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (conversation.conversationType != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                conversation.isPrivate ? '私聊' : '群聊',
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

  void _openChat(
    BuildContext context,
    ConversationModel conversation,
    int currentUserId,
  ) {
    final otherUserId = conversation.getOtherUserId(currentUserId);
    final displayName = conversation.otherUserName ?? '用户 $otherUserId';

    final params = {
      'title': displayName,
      'roomId': conversation.roomId ?? '',
      'targetUserId': otherUserId?.toString() ?? '',
    };

    if (conversation.otherUserAvatar != null) {
      params['avatar'] = conversation.otherUserAvatar!;
    }

    final uri = Uri(path: AppConstants.routeChat, queryParameters: params);
    context.push(uri.toString()).then((_) {
      // 返回时清除未读数
      if (conversation.roomId != null) {
        context.read<ChatProvider>().clearUnreadCount(conversation.roomId!);
      }
    });
  }
}
