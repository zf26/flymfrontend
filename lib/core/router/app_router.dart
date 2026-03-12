import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flymfrontend/config/app_constants.dart';
import 'package:flymfrontend/core/router/route_guard.dart';
import 'package:flymfrontend/screens/splash/splash_screen.dart';
import 'package:flymfrontend/screens/login/login_screen.dart';
import 'package:flymfrontend/screens/home/home_screen.dart';
import 'package:flymfrontend/screens/consultation/consultation_list_screen.dart';
import 'package:flymfrontend/screens/consultation/consultation_detail_screen.dart';
import 'package:flymfrontend/screens/consultation/create_consultation_screen.dart';
import 'package:flymfrontend/screens/consultation/symptom_input_screen.dart';
import 'package:flymfrontend/screens/consultation/recommendation_screen.dart';
import 'package:flymfrontend/models/consultation_recommendation_model.dart';
import 'package:flymfrontend/screens/doctor/doctor_list_screen.dart';
import 'package:flymfrontend/screens/profile/profile_screen.dart';
import 'package:flymfrontend/screens/profile/personal_info_screen.dart';
import 'package:flymfrontend/screens/settings/settings_screen.dart';
import 'package:flymfrontend/screens/chat/chat_screen.dart';
import 'package:flymfrontend/screens/chat/chat_contacts_screen.dart';

/// 路由配置
class AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: AppConstants.routeSplash,
      redirect: (context, state) {
        return RouteGuard.getRedirectLocation(state);
      },
      routes: [
        GoRoute(
          path: AppConstants.routeSplash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppConstants.routeLogin,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppConstants.routeHome,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppConstants.routeConsultation,
          name: 'consultation',
          builder: (context, state) => const ConsultationListScreen(),
        ),
        GoRoute(
          path: '${AppConstants.routeConsultationDetail}/:id',
          name: 'consultation_detail',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return ConsultationDetailScreen(consultationId: id);
          },
        ),
        GoRoute(
          path: AppConstants.routeCreateConsultation,
          name: 'create_consultation',
          builder: (context, state) {
            final doctorId = state.uri.queryParameters['doctorId'];
            return CreateConsultationScreen(doctorId: doctorId);
          },
        ),
        GoRoute(
          path: AppConstants.routeSymptomInput,
          name: 'symptom_input',
          builder: (context, state) => SymptomInputScreen(showAppBar: true),
        ),
        GoRoute(
          path: AppConstants.routeConsultationRecommendation,
          name: 'consultation_recommendation',
          builder: (context, state) {
            final recommendation = state.extra as ConsultationRecommendation?;
            if (recommendation == null) {
              return const Scaffold(body: Center(child: Text('参数错误')));
            }
            return RecommendationScreen(recommendation: recommendation);
          },
        ),
        GoRoute(
          path: AppConstants.routeDoctorList,
          name: 'doctor_list',
          builder: (context, state) => const DoctorListScreen(),
        ),
        GoRoute(
          path: AppConstants.routeProfile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppConstants.routePersonalInfo,
          name: 'personal_info',
          builder: (context, state) => const PersonalInfoScreen(),
        ),
        GoRoute(
          path: AppConstants.routeSettings,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppConstants.routeChatContacts,
          name: 'chat_contacts',
          builder: (context, state) => const ChatContactsScreen(),
        ),
        GoRoute(
          path: AppConstants.routeChat,
          name: 'chat',
          builder: (context, state) {
            final title = state.uri.queryParameters['title'];
            final avatar = state.uri.queryParameters['avatar'];
            final roomId = state.uri.queryParameters['roomId'];
            final targetUserId = state.uri.queryParameters['targetUserId'];
            return ChatScreen(
              conversationTitle: title ?? '王心研 · 主治医师',
              avatarUrl: avatar,
              roomId: roomId,
              targetUserId: targetUserId,
            );
          },
        ),
      ],
      errorBuilder:
          (context, state) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('页面未找到: ${state.uri}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go(AppConstants.routeHome),
                    child: const Text('返回首页'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  static final GoRouter router = createRouter();
}
