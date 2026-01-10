import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flymfrontend/core/theme/app_theme.dart';
import 'package:flymfrontend/core/di/service_locator.dart';
import 'package:flymfrontend/models/chat_message_model.dart';
import 'package:flymfrontend/providers/auth_provider.dart';
import 'package:flymfrontend/screens/chat/video_call_screen.dart';
import 'package:flymfrontend/services/api/im_service.dart';
import 'package:flymfrontend/services/chat/chat_service.dart';
import 'package:flymfrontend/services/chat/conversation_crypto.dart';

/// 仿微信聊天界面
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.conversationTitle = '王心研 · 主治医师',
    this.avatarUrl,
    this.roomId,
    this.targetUserId,
  });

  final String conversationTitle;
  final String? avatarUrl;

  final String? roomId;

  final String? targetUserId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _dateFormatter = DateFormat('MM月dd日 HH:mm');
  String? _currentUserId;
  String? _targetUserId;
  String? _roomId;
  late List<_UiMessage> _messages;
  bool _isLoading = false;

  late final ChatService _chatService;
  late final ImService _imService;
  ConversationCrypto? _crypto;

  @override
  void initState() {
    super.initState();
    _chatService = ServiceLocator().getChatService();
    _imService = ServiceLocator().getImService();
    _roomId = widget.roomId;
    _targetUserId = widget.targetUserId;

    if (_roomId != null && _targetUserId != null) {
      _initRealChat();
    } else {
      _currentUserId = 'patient_demo';
      _targetUserId ??= 'doctor_001';
      _messages = _buildMockMessages();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _chatService.unsubscribe('personal_chat');
    if (_roomId != null) {
      _chatService.unsubscribe('room_${_roomId!}');
    }
    super.dispose();
  }

  List<_UiMessage> _buildMockMessages() {
    final now = DateTime.now();
    final myId = _currentUserId ?? 'patient_demo';
    final doctorId = _targetUserId ?? 'doctor_001';
    return [
      _UiMessage(
        fromUserId: doctorId,
        toUserId: myId,
        content: '您好，我是王心研医生，请问哪里不舒服？',
        timestamp:
            now.subtract(const Duration(minutes: 18)).millisecondsSinceEpoch,
      ),
      _UiMessage(
        fromUserId: myId,
        toUserId: doctorId,
        content: '最近一直咳嗽，晚上更严重一些。',
        timestamp:
            now.subtract(const Duration(minutes: 17)).millisecondsSinceEpoch,
      ),
      _UiMessage(
        fromUserId: doctorId,
        toUserId: myId,
        content: '有发烧或者胸闷的情况吗？',
        timestamp:
            now.subtract(const Duration(minutes: 15)).millisecondsSinceEpoch,
      ),
      _UiMessage(
        fromUserId: myId,
        toUserId: doctorId,
        content: '偶尔会有轻微发烧，最高 37.8°。',
        timestamp:
            now.subtract(const Duration(minutes: 14)).millisecondsSinceEpoch,
      ),
      _UiMessage(
        fromUserId: doctorId,
        toUserId: myId,
        content: '好的，我先了解一下您的既往病史。',
        timestamp:
            now.subtract(const Duration(minutes: 12)).millisecondsSinceEpoch,
      ),
    ];
  }

  Future<void> _initRealChat() async {
    final auth = context.read<AuthProvider>();
    _currentUserId = auth.user?.id;
    if (_currentUserId == null) {
      _currentUserId = 'patient_demo';
    }
    _targetUserId ??= widget.targetUserId;
    _roomId ??= widget.roomId;
    if (_roomId == null || _targetUserId == null) {
      _messages = _buildMockMessages();
      return;
    }

    setState(() {
      _isLoading = true;
      _messages = [];
    });

    try {
      final keyResult = await _imService.getConversationKey(_roomId!);
      if (keyResult.success && keyResult.data != null) {
        _crypto = ConversationCrypto.fromBase64Key(keyResult.data!);
      }
    } catch (_) {}

    try {
      final historyResult = await _imService.getPrivateHistory(
        targetUserId: _targetUserId!,
        roomId: _roomId!,
        limit: 100,
      );
      if (historyResult.success && historyResult.data != null) {
        final items = historyResult.data!;
        final uiList = <_UiMessage>[];
        for (final item in items) {
          var text = item.content;
          if (_crypto != null) {
            try {
              text = await _crypto!.decryptContent(item.content);
            } catch (_) {}
          }
          uiList.add(
            _UiMessage(
              fromUserId: item.fromUserId ?? '',
              toUserId: item.toUserId,
              content: text,
              timestamp: item.timestamp,
            ),
          );
        }
        if (mounted) {
          setState(() {
            _messages = uiList;
          });
          _scrollToBottom();
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    await _chatService.connect();

    if (_roomId != null) {
      _chatService.subscribe(
        destination: ChatService.roomTopic(_roomId!),
        subscriptionId: 'room_${_roomId!}',
        onMessage: _handleIncomingMessage,
      );
    }
    _chatService.subscribe(
      destination: ChatService.personalChatQueue,
      subscriptionId: 'personal_chat',
      onMessage: _handleIncomingMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildPinnedNotice(),
          _buildQuickActions(),
          Expanded(child: _buildMessageList()),
          const Divider(height: 1, thickness: 1),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0.5,
      centerTitle: false,
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFB2D7FF),
            backgroundImage:
                widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                    ? NetworkImage(widget.avatarUrl!)
                    : null,
            child:
                widget.avatarUrl == null
                    ? const Text(
                      '王',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.conversationTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '在线 · 平均 2 分钟回复',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: '语音通话',
          icon: const Icon(Icons.call_outlined),
          onPressed: () {},
        ),
        IconButton(
          tooltip: '视频问诊',
          icon: const Icon(Icons.video_call_outlined),
          onPressed: () {
            if (_roomId == null || _targetUserId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('当前会话暂不支持视频通话')),
              );
              return;
            }
            final remoteId = int.tryParse(_targetUserId!);
            if (remoteId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('对方用户ID无效，无法发起视频通话')),
              );
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VideoCallScreen(
                  remoteUserId: remoteId,
                  roomId: _roomId!,
                  title: widget.conversationTitle,
                ),
              ),
            );
          },
        ),
        IconButton(
          tooltip: '更多',
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildPinnedNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFFFF8E7),
      child: Row(
        children: const [
          Icon(Icons.campaign_outlined, color: Color(0xFFFA6400), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '图文问诊请保持手机畅通，如需语音/视频请预约时间。',
              style: TextStyle(fontSize: 13, color: Color(0xFF8C4B00)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickActionItem(Icons.image_outlined, '病历/检查单'),
      _QuickActionItem(Icons.note_alt_outlined, '常用语'),
      _QuickActionItem(Icons.assignment_outlined, '开处方'),
      _QuickActionItem(Icons.more_horiz, '更多'),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:
            actions
                .map(
                  (action) => Expanded(
                    child: _QuickActionButton(
                      icon: action.icon,
                      label: action.label,
                      onTap: () {},
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildMessageList() {
    return Container(
      color: const Color(0xFFEDEDED),
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isMine = message.isFrom(_currentUserId);
              final showTime = _shouldShowTimeSeparator(index);

              return Column(
                children: [
                  if (showTime) _buildTimeChip(message.timestamp),
                  Align(
                    alignment:
                        isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment:
                            isMine
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMine) ...[
                            _buildAvatar('王'),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: _ChatBubble(
                              content: message.content,
                              isMine: isMine,
                            ),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 8),
                            _buildAvatar('我', isMine: true),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (isMine)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 48),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '已送达',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (_isLoading)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _shouldShowTimeSeparator(int index) {
    if (index == 0) return true;
    final current = _messages[index].timestamp;
    final previous = _messages[index - 1].timestamp;
    if (current == null || previous == null) return false;
    final duration = Duration(milliseconds: current - previous);
    return duration.inMinutes >= 5;
  }

  Widget _buildTimeChip(int? timestamp) {
    final timeText =
        timestamp != null
            ? _dateFormatter.format(
              DateTime.fromMillisecondsSinceEpoch(timestamp),
            )
            : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          timeText,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildAvatar(String text, {bool isMine = false}) {
    return CircleAvatar(
      radius: 18,
      backgroundColor:
          isMine ? const Color(0xFF95EC69) : const Color(0xFFE0E0E0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isMine ? Colors.white : AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.keyboard_voice_outlined),
              onPressed: () {},
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 40,
                  maxHeight: 120,
                ),
                child: Scrollbar(
                  child: TextField(
                    controller: _inputController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: '发送消息',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      fillColor: const Color(0xFFF6F6F6),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {},
            ),
            FilledButton(
              onPressed: _handleSendMessage,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF07C160),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 38),
              ),
              child: const Text('发送'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_roomId != null && _targetUserId != null && _crypto != null) {
      () async {
        final plain = text;
        String cipher = plain;
        try {
          cipher = await _crypto!.encryptContent(plain);
        } catch (_) {}

        final msg = ChatMessageModel(
          type: 'CHAT',
          toUserId: _targetUserId,
          roomId: _roomId,
          content: cipher,
          timestamp: now,
        );

        await _chatService.sendMessage(
          destination: '/app/chat.send',
          message: msg,
        );

        if (!mounted) return;
        setState(() {
          _messages.add(
            _UiMessage(
              fromUserId: _currentUserId ?? '',
              toUserId: _targetUserId,
              content: plain,
              timestamp: now,
            ),
          );
        });
        _scrollToBottom();
      }();
    } else {
      final uiMsg = _UiMessage(
        fromUserId: _currentUserId ?? 'patient_demo',
        toUserId: _targetUserId ?? 'doctor_001',
        content: text,
        timestamp: now,
      );
      setState(() {
        _messages.add(uiMsg);
      });
      _scrollToBottom();
    }

    _inputController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleIncomingMessage(ChatMessageModel message) async {
    if (_roomId != null && message.roomId != null && message.roomId != _roomId) {
      return;
    }
    var text = message.content;
    if (_crypto != null) {
      try {
        text = await _crypto!.decryptContent(message.content);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _messages.add(
        _UiMessage(
          fromUserId: message.fromUserId ?? '',
          toUserId: message.toUserId,
          content: text,
          timestamp: message.timestamp,
        ),
      );
    });
    _scrollToBottom();
  }
}

class _UiMessage {
  _UiMessage({
    required this.fromUserId,
    this.toUserId,
    required this.content,
    this.timestamp,
  });

  final String fromUserId;
  final String? toUserId;
  final String content;
  final int? timestamp;

  bool isFrom(String? userId) {
    if (userId == null) return false;
    return fromUserId == userId;
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.content, required this.isMine});

  final String content;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMine ? const Color(0xFF95EC69) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMine ? 18 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 15,
          color: isMine ? Colors.black87 : AppTheme.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
