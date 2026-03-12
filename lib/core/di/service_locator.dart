import 'package:flymfrontend/services/api/api_service.dart';
import 'package:flymfrontend/services/api/auth_service.dart';
import 'package:flymfrontend/services/api/consultation_service.dart';
import 'package:flymfrontend/services/api/doctor_service.dart';
import 'package:flymfrontend/services/api/im_service.dart';
import 'package:flymfrontend/services/api/upload_service.dart';
import 'package:flymfrontend/services/api/symptom_analysis_service.dart';
import 'package:flymfrontend/services/chat/chat_service.dart';
import 'package:flymfrontend/providers/chat_provider.dart';

/// 服务定位器（简单的依赖注入容器）
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  /// 注册服务
  void register<T>(T service) {
    _services[T] = service;
  }

  /// 注册单例服务
  void registerSingleton<T>(T Function() factory) {
    if (!_services.containsKey(T)) {
      _services[T] = factory();
    }
  }

  /// 获取API服务
  ApiService getApiService() {
    if (!_services.containsKey(ApiService)) {
      throw Exception('ApiService not registered');
    }
    return _services[ApiService] as ApiService;
  }

  /// 获取认证服务
  AuthService getAuthService() {
    if (!_services.containsKey(AuthService)) {
      throw Exception('AuthService not registered');
    }
    return _services[AuthService] as AuthService;
  }

  /// 获取问诊服务
  ConsultationService getConsultationService() {
    if (!_services.containsKey(ConsultationService)) {
      throw Exception('ConsultationService not registered');
    }
    return _services[ConsultationService] as ConsultationService;
  }

  /// 获取医生服务
  DoctorService getDoctorService() {
    if (!_services.containsKey(DoctorService)) {
      throw Exception('DoctorService not registered');
    }
    return _services[DoctorService] as DoctorService;
  }

  /// 获取上传服务
  UploadService getUploadService() {
    if (!_services.containsKey(UploadService)) {
      throw Exception('UploadService not registered');
    }
    return _services[UploadService] as UploadService;
  }

  /// 获取 IM 服务
  ImService getImService() {
    if (!_services.containsKey(ImService)) {
      throw Exception('ImService not registered');
    }
    return _services[ImService] as ImService;
  }

  /// 获取聊天服务
  ChatService getChatService() {
    if (!_services.containsKey(ChatService)) {
      throw Exception('ChatService not registered');
    }
    return _services[ChatService] as ChatService;
  }

  /// 获取症状分析服务
  SymptomAnalysisService getSymptomAnalysisService() {
    if (!_services.containsKey(SymptomAnalysisService)) {
      throw Exception('SymptomAnalysisService not registered');
    }
    return _services[SymptomAnalysisService] as SymptomAnalysisService;
  }

  /// 获取聊天Provider
  ChatProvider getChatProvider() {
    if (!_services.containsKey(ChatProvider)) {
      throw Exception('ChatProvider not registered');
    }
    return _services[ChatProvider] as ChatProvider;
  }

  /// 初始化所有服务
  void initialize() {
    // 注册API服务
    registerSingleton<ApiService>(() => ApiService());
    register<AuthService>(AuthService(getApiService()));
    register<ConsultationService>(ConsultationService(getApiService()));
    register<DoctorService>(DoctorService(getApiService()));
    register<UploadService>(UploadService(getApiService()));
    register<ImService>(ImService(getApiService()));
    register<SymptomAnalysisService>(SymptomAnalysisService(getApiService()));
    // 注册聊天服务（单例）
    registerSingleton<ChatService>(() => ChatService());
    // 注册聊天Provider
    register<ChatProvider>(ChatProvider(getImService()));
  }
}
