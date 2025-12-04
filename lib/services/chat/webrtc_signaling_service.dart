import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'package:flymfrontend/config/app_config.dart';
import 'package:flymfrontend/config/app_environment.dart';
import 'package:flymfrontend/utils/logger_util.dart';
import 'package:flymfrontend/utils/storage_util.dart';

/// WebRTC 呼叫状态
enum WebRtcCallState { idle, connecting, ringing, inCall, ended, error }

/// WebRTC + STOMP 信令服务
///
/// 该服务封装了以下职责：
/// - 获取本地音视频流并创建 PeerConnection
/// - 建立 STOMP 连接并订阅信令通道
/// - 发送 / 处理 offer、answer、ICE candidate
/// - 对外暴露流和状态回调，方便 UI 层使用
class WebRtcSignalingService {
  WebRtcSignalingService({
    required this.remoteUserId,
    required this.roomId,
    this.enableVideo = true,
    this.customWsUrl,
    this.onLocalStream,
    this.onRemoteStream,
    this.onCallStateChange,
    this.onError,
  });

  final int remoteUserId;
  final String roomId;
  final bool enableVideo;
  final String? customWsUrl;
  final void Function(MediaStream? stream)? onLocalStream;
  final void Function(MediaStream? stream)? onRemoteStream;
  final void Function(WebRtcCallState state)? onCallStateChange;
  final void Function(String error)? onError;

  static const _signalDestination = '/app/webrtc.signal';
  static const _userQueueDestination = '/user/queue/webrtc';

  StompClient? _stomp;
  Completer<void>? _stompReadyCompleter;
  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  WebRtcCallState _callState = WebRtcCallState.idle;
  bool _hasSubscribed = false;

  WebRtcCallState get callState => _callState;
  bool get isConnected => _stomp?.connected == true;

  /// 建立 STOMP & WebRTC 连接
  Future<void> connect() async {
    await _ensurePeerConnection();
    await _ensureStompConnection();
  }

  /// 发起呼叫，创建 offer 并发送
  Future<void> startCall() async {
    if (_peerConnection == null) {
      await _ensurePeerConnection();
    }
    await _ensureStompConnection();

    _setCallState(WebRtcCallState.connecting);
    try {
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      _sendSignal({
        'type': 'offer',
        'toUserId': remoteUserId,
        'roomId': roomId,
        'sdp': offer.sdp,
      });
    } catch (e, s) {
      LoggerUtil.e('WebRTC: Failed to create offer', e, s);
      _notifyError('Failed to create offer: $e');
    }
  }

  /// 关闭当前呼叫并清理资源
  Future<void> hangUp({bool notifyRemote = true}) async {
    try {
      if (notifyRemote && isConnected) {
        _sendSignal({
          'type': 'leave',
          'toUserId': remoteUserId,
          'roomId': roomId,
        });
      }
      await _disposePeerConnection();
      _setCallState(WebRtcCallState.ended);
    } catch (e, s) {
      LoggerUtil.e('WebRTC: Hang up failed', e, s);
    }
  }

  /// 彻底断开（STOMP + WebRTC）
  Future<void> dispose() async {
    await hangUp(notifyRemote: false);
    if (_stomp != null) {
      try {
        _stomp!.deactivate();
      } catch (e, s) {
        LoggerUtil.e('WebRTC: STOMP deactivate error', e, s);
      }
      _stomp = null;
      _hasSubscribed = false;
    }
    _stompReadyCompleter = null;
    _setCallState(WebRtcCallState.idle);
  }

  Future<void> _ensureStompConnection() async {
    if (_stomp?.connected == true) {
      return;
    }

    final token = await StorageUtil.getString(AppConfig.keyToken);

    final wsUrl = customWsUrl ?? _resolveWsUrl();
    _stompReadyCompleter = Completer<void>();

    final connectHeaders = <String, String>{};
    if (token != null && token.isNotEmpty) {
      connectHeaders['Authorization'] = 'Bearer $token';
    }

    _stomp = StompClient(
      config: StompConfig(
        url: wsUrl,
        stompConnectHeaders: connectHeaders,
        webSocketConnectHeaders: connectHeaders,
        onConnect: (frame) {
          LoggerUtil.i('WebRTC: STOMP connected');
          _onStompConnected(frame);
          if (_stompReadyCompleter?.isCompleted == false) {
            _stompReadyCompleter?.complete();
          }
        },
        reconnectDelay: const Duration(seconds: 5),
        onStompError: (frame) {
          LoggerUtil.e('WebRTC: STOMP error ${frame.body}');
          _notifyError(frame.body ?? 'Unknown STOMP error');
        },
        onWebSocketError: (error) {
          LoggerUtil.e('WebRTC: WebSocket error', error);
          _notifyError('WebSocket error: $error');
        },
      ),
    );

    _stomp!.activate();
    await _stompReadyCompleter!.future;
  }

  Future<void> _ensurePeerConnection() async {
    if (_peerConnection != null) {
      return;
    }

    final configuration = AppConfig.webrtcPeerConnectionConfig;

    _peerConnection = await createPeerConnection(configuration);

    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video':
          enableVideo
              ? {
                'facingMode': 'user',
                'mandatory': {
                  'minWidth': '640',
                  'minHeight': '480',
                  'minFrameRate': '15',
                },
              }
              : false,
    });

    if (localStream != null) {
      for (final track in localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, localStream!);
      }
      onLocalStream?.call(localStream);
    }

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams.first;
        onRemoteStream?.call(remoteStream);
        _setCallState(WebRtcCallState.inCall);
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate == null) return;
      final candidateJson = jsonEncode({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
      _sendSignal({
        'type': 'candidate',
        'toUserId': remoteUserId,
        'roomId': roomId,
        'candidate': candidateJson,
      });
    };
  }

  void _onStompConnected(StompFrame frame) {
    if (_stomp == null || _hasSubscribed) {
      return;
    }
    _hasSubscribed = true;

    _stomp!.subscribe(
      destination: _userQueueDestination,
      callback: _handleStompMessage,
    );

    _stomp!.subscribe(
      destination: '/topic/webrtc.room.$roomId',
      callback: _handleStompMessage,
    );
  }

  Future<void> _handleSignalFromRemote(Map<String, dynamic> payload) async {
    final type = payload['type'] as String?;
    if (type == null) {
      return;
    }

    await _ensurePeerConnection();

    switch (type) {
      case 'offer':
        final sdp = payload['sdp'] as String?;
        if (sdp == null) return;

        _setCallState(WebRtcCallState.ringing);
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(sdp, 'offer'),
        );
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        _sendSignal({
          'type': 'answer',
          'toUserId': remoteUserId,
          'roomId': roomId,
          'sdp': answer.sdp,
        });
        break;
      case 'answer':
        final sdp = payload['sdp'] as String?;
        if (sdp == null) return;
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(sdp, 'answer'),
        );
        _setCallState(WebRtcCallState.inCall);
        break;
      case 'candidate':
        final candidateRaw = payload['candidate'];
        if (candidateRaw == null) return;
        Map<String, dynamic> candidateMap;
        if (candidateRaw is String) {
          candidateMap = jsonDecode(candidateRaw) as Map<String, dynamic>;
        } else {
          candidateMap = (candidateRaw as Map).cast<String, dynamic>();
        }
        final iceCandidate = RTCIceCandidate(
          candidateMap['candidate'] as String?,
          candidateMap['sdpMid'] as String?,
          candidateMap['sdpMLineIndex'] as int?,
        );
        await _peerConnection!.addCandidate(iceCandidate);
        break;
      case 'leave':
        await hangUp(notifyRemote: false);
        break;
      default:
        LoggerUtil.d('WebRTC: Unknown signal type $type');
        break;
    }
  }

  void _handleStompMessage(StompFrame frame) {
    if (frame.body == null) return;
    try {
      final data = jsonDecode(frame.body!);
      if (data is Map<String, dynamic>) {
        _handleSignalFromRemote(data);
      } else if (data is List && data.isNotEmpty) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            _handleSignalFromRemote(item);
          }
        }
      }
    } catch (e, s) {
      LoggerUtil.e('WebRTC: Failed to parse signal', e, s);
    }
  }

  void _sendSignal(Map<String, dynamic> payload) {
    if (_stomp == null || _stomp!.connected != true) {
      LoggerUtil.w('WebRTC: Cannot send signal, STOMP not ready');
      return;
    }
    final body = jsonEncode(payload);
    _stomp!.send(destination: _signalDestination, body: body);
  }

  String _resolveWsUrl() {
    final baseUrl =
        AppEnvironmentConfig.isDevelopment
            ? AppConfig.wsBaseUrlDev
            : AppConfig.wsBaseUrlProd;
    return '$baseUrl${AppConfig.wsStompEndpoint}';
  }

  void _setCallState(WebRtcCallState state) {
    if (_callState == state) return;
    _callState = state;
    onCallStateChange?.call(state);
  }

  Future<void> _disposePeerConnection() async {
    try {
      await _peerConnection?.close();
    } catch (_) {}
    _peerConnection = null;

    await localStream?.dispose();
    localStream = null;

    await remoteStream?.dispose();
    remoteStream = null;
  }

  void _notifyError(String message) {
    LoggerUtil.e('WebRTC: $message');
    _setCallState(WebRtcCallState.error);
    onError?.call(message);
  }
}
