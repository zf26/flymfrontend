import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flymfrontend/core/theme/app_theme.dart';
import 'package:flymfrontend/services/chat/webrtc_signaling_service.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    super.key,
    required this.remoteUserId,
    required this.roomId,
    this.title,
  });

  final int remoteUserId;
  final String roomId;
  final String? title;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  WebRtcSignalingService? _signaling;
  WebRtcCallState _callState = WebRtcCallState.idle;
  String? _error;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _signaling = WebRtcSignalingService(
      remoteUserId: widget.remoteUserId,
      roomId: widget.roomId,
      enableVideo: true,
      onLocalStream: (stream) {
        if (!mounted) return;
        setState(() {
          _localRenderer.srcObject = stream;
        });
      },
      onRemoteStream: (stream) {
        if (!mounted) return;
        setState(() {
          _remoteRenderer.srcObject = stream;
        });
      },
      onCallStateChange: (state) {
        if (!mounted) return;
        setState(() {
          _callState = state;
        });
      },
      onError: (msg) {
        if (!mounted) return;
        setState(() {
          _error = msg;
          _callState = WebRtcCallState.error;
        });
      },
    );

    try {
      await _signaling!.connect();
      if (!mounted) return;
      setState(() {
        _initialized = true;
      });
      await _signaling!.startCall();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _callState = WebRtcCallState.error;
      });
    }
  }

  @override
  void dispose() {
    () async {
      try {
        await _signaling?.dispose();
      } catch (_) {}
    }();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? '视频问诊'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _buildRemoteVideo(),
                  ),
                  Positioned(
                    right: 16,
                    top: 16,
                    width: 120,
                    height: 180,
                    child: _buildLocalPreview(),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: _buildStatus(),
                  ),
                  if (_error != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 80,
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteVideo() {
    if (!_initialized ||
        _callState == WebRtcCallState.connecting ||
        _callState == WebRtcCallState.ringing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_remoteRenderer.srcObject == null) {
      return const Center(
        child: Text(
          '等待对方接通...',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }
    return RTCVideoView(
      _remoteRenderer,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }

  Widget _buildLocalPreview() {
    if (_localRenderer.srcObject == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white70),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: RTCVideoView(
        _localRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        mirror: true,
      ),
    );
  }

  Widget _buildStatus() {
    String text;
    switch (_callState) {
      case WebRtcCallState.idle:
        text = '等待开始通话';
        break;
      case WebRtcCallState.connecting:
        text = '正在建立连接...';
        break;
      case WebRtcCallState.ringing:
        text = '等待对方接听...';
        break;
      case WebRtcCallState.inCall:
        text = '通话中';
        break;
      case WebRtcCallState.ended:
        text = '通话已结束';
        break;
      case WebRtcCallState.error:
        text = '通话异常';
        break;
    }
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(width: 56),
          InkWell(
            onTap: () async {
              try {
                await _signaling?.hangUp();
              } catch (_) {}
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }
}
