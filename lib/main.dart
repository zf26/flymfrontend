import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flymfrontend/config/app_environment.dart';
import 'package:flymfrontend/core/di/service_locator.dart';
import 'package:flymfrontend/core/router/app_router.dart';
import 'package:flymfrontend/core/theme/app_theme.dart';
import 'package:flymfrontend/providers/auth_provider.dart';
import 'package:flymfrontend/providers/consultation_provider.dart';
import 'package:flymfrontend/providers/doctor_provider.dart';
import 'package:flymfrontend/providers/settings_provider.dart';
import 'package:flymfrontend/providers/chat_provider.dart';
import 'package:flymfrontend/core/cache/cache_manager.dart';
import 'package:flymfrontend/config/app_config.dart';
import 'package:flymfrontend/utils/storage_util.dart';
import 'package:flymfrontend/utils/logger_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化环境配置
  AppEnvironmentConfig.setEnvironment(
    kDebugMode ? AppEnvironment.development : AppEnvironment.production,
  );

  // 初始化本地存储
  await StorageUtil.init();

  // 初始化依赖注入容器
  ServiceLocator().initialize();

  // 清理过期缓存
  final cacheManager = CacheManager();
  final autoCleanCache =
      StorageUtil.getBool(AppConfig.keyAutoCleanCache) ?? true;
  if (autoCleanCache) {
    await cacheManager.cleanExpiredCache();
  }

  // 全局异常捕获
  FlutterError.onError = (FlutterErrorDetails details) {
    LoggerUtil.e('Flutter错误', details.exception, details.stack);
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  // 异步异常捕获
  PlatformDispatcher.instance.onError = (error, stack) {
    LoggerUtil.e('平台异常', error, stack);
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final serviceLocator = ServiceLocator();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          // 在 provider 创建后立即初始化本地用户信息（从 Storage 中恢复）
          create: (_) {
            final authProvider = AuthProvider(serviceLocator.getAuthService());
            // 异步初始化用户信息（不阻塞 UI）
            authProvider.initUser();
            return authProvider;
          },
        ),
        ChangeNotifierProvider(
          create:
              (_) =>
                  ConsultationProvider(serviceLocator.getConsultationService()),
        ),
        ChangeNotifierProvider(
          create: (_) => DoctorProvider(serviceLocator.getDoctorService()),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(serviceLocator.getImService()),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812), // 设计稿尺寸
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            title: '远程医疗问诊',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
