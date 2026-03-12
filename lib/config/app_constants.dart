/// 应用常量
class AppConstants {
  // 路由名称
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeHome = '/home';
  static const String routeConsultation = '/consultation';
  static const String routeConsultationDetail = '/consultation/detail';
  static const String routeCreateConsultation = '/consultation/create';
  static const String routeSymptomInput = '/symptom-input';
  static const String routeConsultationRecommendation =
      '/consultation-recommendation';
  static const String routeDoctorList = '/doctor/list';
  static const String routeDoctorDetail = '/doctor/detail';
  static const String routeProfile = '/profile';
  static const String routeSettings = '/settings';
  static const String routeChatContacts = '/chat/contacts';
  static const String routeChat = '/chat';
  static const String routePersonalInfo = '/profile/personal-info';

  // 问诊状态
  static const String consultationStatusPending = 'pending'; // 待接诊
  static const String consultationStatusInProgress = 'in_progress'; // 进行中
  static const String consultationStatusCompleted = 'completed'; // 已完成
  static const String consultationStatusCancelled = 'cancelled'; // 已取消
}
