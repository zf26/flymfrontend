import 'dart:ui';
import 'package:flutter/material.dart';

/// 液态玻璃效果的顶部提示组件
class GlassmorphismToast {
  static OverlayEntry? _currentOverlay;
  static _ToastWidgetState? _currentState;
  static bool _isShowing = false;

  /// 显示成功提示
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(
      context,
      message,
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF4CAF50),
      duration: duration,
    );
  }

  /// 显示错误提示
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message,
      icon: Icons.error_rounded,
      iconColor: const Color(0xFFE53935),
      duration: duration,
    );
  }

  /// 显示警告提示
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message,
      icon: Icons.warning_rounded,
      iconColor: const Color(0xFFFFA726),
      duration: duration,
    );
  }

  /// 显示信息提示
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message,
      icon: Icons.info_rounded,
      iconColor: const Color(0xFF42A5F5),
      duration: duration,
    );
  }

  /// 核心显示方法
  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color iconColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    // 如果已经有提示在显示，先移除
    if (_isShowing) {
      _hide();
    }

    _isShowing = true;
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        icon: icon,
        iconColor: iconColor,
        onDismiss: _hideImmediately,
        onStateCreated: (state) => _currentState = state,
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);

    // 自动隐藏（带动画）
    Future.delayed(duration, () {
      if (_isShowing) {
        _hide();
      }
    });
  }

  /// 隐藏提示（带动画）
  static Future<void> _hide() async {
    if (_currentState != null) {
      await _currentState!._dismiss();
    } else {
      _hideImmediately();
    }
  }

  /// 立即隐藏提示（无动画）
  static void _hideImmediately() {
    _currentOverlay?.remove();
    _currentOverlay = null;
    _currentState = null;
    _isShowing = false;
  }
}

/// Toast 组件
class _ToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onDismiss;
  final Function(_ToastWidgetState) onStateCreated;

  const _ToastWidget({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.onDismiss,
    required this.onStateCreated,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // 通知父组件 state 已创建
    widget.onStateCreated(this);
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // 滑动动画（从上方滑入，向上滑出）
    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInQuart,
    );

    // 淡入淡出动画
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        reverseCurve: Curves.easeInQuad,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -80 * (1 - _slideAnimation.value) + topPadding),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                // 向上滑动关闭
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -300) {
                  _dismiss();
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // 图标
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.iconColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.iconColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 消息文本
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 关闭按钮
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

