import 'package:go_router/go_router.dart';
import 'package:flymfrontend/config/app_constants.dart';
import 'package:flymfrontend/core/di/service_locator.dart';

/// 路由守卫
class RouteGuard {
  /// 检查是否需要登录
  static bool checkAuth(GoRouterState state) {
    final authService = ServiceLocator().getAuthService();
    final isLoggedIn = authService.isLoggedIn();

    // 需要登录的路径列表
    final protectedRoutes = [
      AppConstants.routeHome,
      AppConstants.routeConsultation,
      AppConstants.routeProfile,
    ];

    final isProtectedRoute = protectedRoutes.any(
      (route) => state.uri.path.startsWith(route),
    );

    if (isProtectedRoute && !isLoggedIn) {
      return false; // 需要跳转到登录页
    }

    return true;
  }

  /// 获取重定向目标
  static String? getRedirectLocation(GoRouterState state) {
    final authService = ServiceLocator().getAuthService();
    final isLoggedIn = authService.isLoggedIn();

    // 如果已登录，访问登录页时重定向到首页
    if (state.uri.path == AppConstants.routeLogin && isLoggedIn) {
      return AppConstants.routeHome;
    }

    // 如果未登录，访问受保护页面时重定向到登录页
    final protectedRoutes = [
      AppConstants.routeHome,
      AppConstants.routeConsultation,
      AppConstants.routeProfile,
    ];

    final isProtectedRoute = protectedRoutes.any(
      (route) => state.uri.path.startsWith(route),
    );

    if (isProtectedRoute && !isLoggedIn) {
      return AppConstants.routeLogin;
    }

    return null; // 不需要重定向
  }
}
