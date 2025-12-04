import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flymfrontend/core/theme/app_theme.dart';
import 'package:flymfrontend/models/chat_message_model.dart';

/// 仿微信聊天界面
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.conversationTitle = '王心研 · 主治医师',
    this.avatarUrl,
  });

  final String conversationTitle;
  final String? avatarUrl;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _dateFormatter = DateFormat('MM月dd日 HH:mm');
  final String _currentUserId = 'patient_demo';
  final String _doctorUserId = 'doctor_001';
  late final List<ChatMessageModel> _messages;

  @override
  void initState() {
    super.initState();
    _messages = _buildMockMessages();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<ChatMessageModel> _buildMockMessages() {
    final now = DateTime.now();
    return [
      ChatMessageModel(
        id: '1',
        fromUserId: _doctorUserId,
        toUserId: _currentUserId,
        content: '您好，我是王心研医生，请问哪里不舒服？',
        timestamp:
            now.subtract(const Duration(minutes: 18)).millisecondsSinceEpoch,
      ),
      ChatMessageModel(
        id: '2',
        fromUserId: _currentUserId,
        toUserId: _doctorUserId,
        content: '最近一直咳嗽，晚上更严重一些。',
        timestamp:
            now.subtract(const Duration(minutes: 17)).millisecondsSinceEpoch,
      ),
      ChatMessageModel(
        id: '3',
        fromUserId: _doctorUserId,
        toUserId: _currentUserId,
        content: '有发烧或者胸闷的情况吗？',
        timestamp:
            now.subtract(const Duration(minutes: 15)).millisecondsSinceEpoch,
      ),
      ChatMessageModel(
        id: '4',
        fromUserId: _currentUserId,
        toUserId: _doctorUserId,
        content: '偶尔会有轻微发烧，最高 37.8°。',
        timestamp:
            now.subtract(const Duration(minutes: 14)).millisecondsSinceEpoch,
      ),
      ChatMessageModel(
        id: '5',
        fromUserId: _doctorUserId,
        toUserId: _currentUserId,
        content: '好的，我先了解一下您的既往病史。',
        timestamp:
            now.subtract(const Duration(minutes: 12)).millisecondsSinceEpoch,
      ),
    ];
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
          onPressed: () {},
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
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final isMine = message.isFromCurrentUser(_currentUserId);
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

    final message = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromUserId: _currentUserId,
      toUserId: _doctorUserId,
      content: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _messages.add(message);
    });

    _inputController.clear();
    _scrollToBottom();
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
