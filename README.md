# 远程医疗问诊移动端

一个基于Flutter开发的远程医疗问诊移动端应用，采用现代化的工程化架构设计。

## 📋 项目特性

- 🏗️ **清晰的架构设计** - 分层架构，职责分离
- 🔒 **依赖注入** - 使用ServiceLocator实现依赖注入，便于测试和维护
- 🛡️ **统一异常处理** - 完善的异常处理机制，提供友好的错误提示
- 🔐 **路由守卫** - 自动权限验证和路由重定向
- 🌍 **环境配置** - 支持开发/生产环境切换
- 📝 **统一结果封装** - API响应统一封装，类型安全
- 📊 **日志系统** - 基于环境的日志管理
- 🎨 **主题配置** - 统一的UI主题管理

## 🏗️ 项目结构

```
lib/
├── config/                      # 配置层
│   ├── app_config.dart          # 应用配置（超时时间、分页等）
│   ├── app_constants.dart       # 应用常量（路由名称、状态等）
│   └── app_environment.dart     # 环境配置管理
├── core/                        # 核心功能层
│   ├── di/                      # 依赖注入
│   │   └── service_locator.dart # 服务定位器
│   ├── exception/               # 异常处理
│   │   ├── app_exception.dart   # 异常基类及子类
│   │   └── exception_handler.dart # 异常处理器
│   ├── interceptors/            # 网络拦截器
│   │   ├── auth_interceptor.dart    # 认证拦截器
│   │   └── logging_interceptor.dart # 日志拦截器
│   ├── result/                  # 结果封装
│   │   └── api_result.dart      # API统一返回结果
│   ├── router/                  # 路由配置
│   │   ├── app_router.dart      # 路由定义
│   │   └── route_guard.dart     # 路由守卫
│   └── theme/                   # 主题配置
│       └── app_theme.dart       # 应用主题
├── models/                      # 数据模型层
│   ├── user_model.dart          # 用户模型
│   ├── user_model.g.dart        # 用户模型（生成）
│   ├── consultation_model.dart  # 问诊模型
│   └── consultation_model.g.dart # 问诊模型（生成）
├── providers/                   # 状态管理层
│   ├── auth_provider.dart       # 认证状态管理
│   └── consultation_provider.dart # 问诊状态管理
├── screens/                     # 页面层
│   ├── splash/                  # 启动页
│   ├── login/                   # 登录页
│   ├── home/                    # 首页
│   ├── consultation/            # 问诊相关页面
│   └── profile/                 # 个人中心
├── services/                    # 服务层
│   └── api/                     # API服务
│       ├── api_service.dart     # API服务基类
│       ├── auth_service.dart    # 认证服务
│       └── consultation_service.dart # 问诊服务
├── utils/                       # 工具类
│   ├── storage_util.dart        # 本地存储工具
│   └── logger_util.dart         # 日志工具
└── widgets/                     # 公共组件
    └── common/                  # 通用组件
        ├── loading_widget.dart  # 加载组件
        ├── error_widget.dart    # 错误组件
        └── empty_widget.dart    # 空状态组件
```

## 🛠️ 技术栈

### 核心框架
- **Flutter**: 3.7.2+
- **Dart**: 3.7.2+

### 主要依赖
- **路由管理**: `go_router` ^14.6.2
- **状态管理**: `provider` ^6.1.2
- **网络请求**: `dio` ^5.7.0
- **本地存储**: `shared_preferences` ^2.3.3
- **JSON序列化**: `json_annotation` ^4.9.0 + `json_serializable` ^6.8.0
- **屏幕适配**: `flutter_screenutil` ^5.9.3
- **图片加载**: `cached_network_image` ^3.4.1
- **权限管理**: `permission_handler` ^11.3.1
- **图片选择器**: `image_picker` ^1.1.2
- **日志**: `logger` ^2.4.0
- **国际化**: `intl` ^0.19.0

## 🚀 快速开始

### 1. 环境要求

- Flutter SDK: 3.7.2 或更高版本
- Dart SDK: 3.7.2 或更高版本
- Android Studio / VS Code（推荐使用VS Code）
- 已配置Android/iOS开发环境

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 生成代码

运行以下命令生成JSON序列化代码：

```bash
flutter pub run build_runner build
```

如果需要监听文件变化自动生成，使用：

```bash
flutter pub run build_runner watch
```

### 4. 配置环境

#### 配置API地址

在 `lib/config/app_environment.dart` 中配置不同环境的API地址：

```dart
static String getApiBaseUrl() {
  switch (_environment) {
    case AppEnvironment.development:
      return 'https://dev-api.example.com'; // 开发环境
    case AppEnvironment.production:
      return 'https://api.example.com';     // 生产环境
  }
}
```

#### 环境切换

应用会自动根据构建模式切换环境：
- Debug模式 → 开发环境
- Release模式 → 生产环境

### 5. 运行项目

#### 移动端运行

```bash
# 运行在连接设备/模拟器上
flutter run

# 指定设备运行
flutter run -d <device-id>

# Release模式运行
flutter run --release
```

#### Web端运行

**重要**：由于Flutter Web默认使用CanvasKit渲染器（需要从Google CDN加载资源），在国内网络环境下可能无法正常加载。建议使用HTML渲染器：

```bash
# 使用HTML渲染器运行（推荐，避免CDN加载问题）
flutter run -d chrome --web-renderer html

# 或构建时指定HTML渲染器
flutter build web --web-renderer html

# 如果网络环境良好，也可以使用CanvasKit渲染器（性能更好）
flutter run -d chrome --web-renderer canvaskit
```

**渲染器说明**：
- **HTML渲染器**：不依赖外部CDN，兼容性好，适合国内网络环境
- **CanvasKit渲染器**：性能更好，但需要从Google CDN加载资源

## 📐 架构设计

### 分层架构

项目采用清晰的分层架构：

```
┌─────────────────────────────────┐
│         UI Layer (Screens)      │  ← 用户界面层
├─────────────────────────────────┤
│     State Layer (Providers)     │  ← 状态管理层
├─────────────────────────────────┤
│      Service Layer (API)        │  ← 服务层
├─────────────────────────────────┤
│      Data Layer (Models)        │  ← 数据模型层
└─────────────────────────────────┘
```

### 依赖注入

使用 `ServiceLocator` 实现依赖注入，所有服务在应用启动时统一注册：

```dart
// 在 main.dart 中初始化
ServiceLocator().initialize();

// 在需要的地方使用
final authService = ServiceLocator().getAuthService();
```

### 异常处理

统一的异常处理机制：

1. **异常类型**：
   - `NetworkException` - 网络异常
   - `ApiException` - API异常
   - `AuthException` - 认证异常
   - `BusinessException` - 业务异常
   - `ParseException` - 数据解析异常

2. **处理流程**：
   ```
   Service层 → ExceptionHandler → AppException → Provider层 → UI层
   ```

### 路由守卫

自动进行权限验证：

- 未登录用户访问受保护页面 → 自动跳转到登录页
- 已登录用户访问登录页 → 自动跳转到首页

### API结果封装

所有API响应使用 `ApiResult<T>` 统一封装：

```dart
final result = await authService.login(phone, password);
if (result.success) {
  // 处理成功逻辑
  final data = result.data;
} else {
  // 处理失败逻辑
  final message = result.message;
}
```

## ✨ 主要功能

### 已实现功能

- ✅ 用户登录/登出
- ✅ 问诊列表查看（支持分页）
- ✅ 问诊详情查看
- ✅ 创建问诊
- ✅ 医生列表（支持搜索和分页）
- ✅ 图片上传（支持多图上传）
- ✅ 路由管理和权限控制
- ✅ 状态管理（Provider） 
- ✅ 网络请求封装（Dio + 拦截器）
- ✅ 本地存储（SharedPreferences）
- ✅ 主题配置
- ✅ 全局异常捕获
- ✅ 日志系统（环境区分）
- ✅ 依赖注入
- ✅ 环境配置管理

### 待开发功能

- [ ] 医生详情
- [ ] 健康档案
- [ ] 设置页面
- [ ] 消息推送
- [ ] 数据缓存策略
- [ ] 离线模式支持

## 📝 代码规范

### 命名规范

- **文件命名**: 使用下划线命名，如 `user_model.dart`
- **类命名**: 使用大驼峰命名，如 `UserModel`
- **变量/方法命名**: 使用小驼峰命名，如 `userName`
- **常量命名**: 使用小驼峰命名，如 `appName`

### 代码组织

- 每个文件只包含一个主要类
- 使用 `part` 和 `part of` 组织相关文件
- 公共组件放在 `widgets` 目录
- 工具类放在 `utils` 目录

### 注释规范

- 使用 `///` 进行文档注释
- 关键业务逻辑添加注释说明
- TODO注释标记待完成功能

## 🔧 开发指南

### 添加新页面

1. 在 `screens` 目录创建页面文件
2. 在 `app_router.dart` 中添加路由
3. 如需权限控制，在 `route_guard.dart` 中配置

### 添加新API服务

1. 在 `services/api` 目录创建服务文件
2. 在 `service_locator.dart` 中注册服务
3. 创建对应的Provider（如需要）

### 添加新数据模型

1. 在 `models` 目录创建模型文件
2. 使用 `@JsonSerializable` 注解
3. 运行 `build_runner` 生成序列化代码

## 🐛 调试

### 查看日志

开发环境下，日志会自动输出到控制台。生产环境下，仅输出错误日志。

### 网络请求调试

开发环境下，所有网络请求和响应都会在控制台输出，包括：
- 请求URL和参数
- 响应状态码和数据
- 错误信息

## 📦 构建发布

### Android

```bash
# 构建APK
flutter build apk --release

# 构建App Bundle
flutter build appbundle --release
```

### iOS

```bash
# 构建iOS应用
flutter build ios --release
```

## ⚠️ 注意事项

1. **首次运行前**：
   - 确保已配置正确的API地址
   - 运行 `flutter pub get` 安装依赖
   - 运行 `build_runner` 生成代码

2. **资源文件**：
   - 图片资源放置在 `assets/images/` 目录
   - 图标资源放置在 `assets/icons/` 目录
   - 在 `pubspec.yaml` 中正确配置资源路径

3. **环境配置**：
   - 开发环境使用开发API地址
   - 生产环境使用生产API地址
   - 确保API地址末尾没有斜杠

4. **依赖管理**：
   - 定期更新依赖包版本
   - 使用 `flutter pub outdated` 检查过时的依赖
   - 重大版本更新前先在开发环境测试

## 📚 相关文档

- [Flutter官方文档](https://flutter.dev/docs)
- [Dart官方文档](https://dart.dev/guides)
- [go_router文档](https://pub.dev/packages/go_router)
- [Provider文档](https://pub.dev/packages/provider)
- [Dio文档](https://pub.dev/packages/dio)

## 📄 许可证

本项目采用私有许可证，仅供内部使用。

## 👥 贡献

欢迎提交Issue和Pull Request。

---

**注意**: 本项目严格按照软件工程规范开发，采用分层架构、依赖注入、统一异常处理等最佳实践，确保代码的可维护性和可扩展性。
