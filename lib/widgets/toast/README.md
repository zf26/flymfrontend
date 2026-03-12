# 液态玻璃效果提示组件使用指南

## 功能特点

✨ **从顶部弹出** - 距离顶部有安全距离，不会被刘海屏遮挡
✨ **液态玻璃效果** - 使用 BackdropFilter 实现毛玻璃模糊效果
✨ **丝滑动画** - 600ms 的缓动动画，流畅自然
✨ **手势关闭** - 支持向上滑动快速关闭
✨ **自动消失** - 默认 3 秒后自动消失
✨ **防止重复** - 新提示会自动替换旧提示

## 使用方法

### 1. 导入组件

```dart
import 'package:flymfrontend/widgets/toast/glassmorphism_toast.dart';
```

### 2. 显示不同类型的提示

#### 成功提示（绿色）
```dart
GlassmorphismToast.showSuccess(context, '登录成功');
```

#### 错误提示（红色）
```dart
GlassmorphismToast.showError(context, '登录失败，请检查账号密码');
```

#### 警告提示（橙色）
```dart
GlassmorphismToast.showWarning(context, '请输入手机号');
```

#### 信息提示（蓝色）
```dart
GlassmorphismToast.showInfo(context, '验证码已发送到您的手机');
```

### 3. 自定义显示时长

```dart
GlassmorphismToast.showSuccess(
  context,
  '操作成功',
  duration: const Duration(seconds: 5), // 显示 5 秒
);
```

## 设计细节

### 视觉效果
- **毛玻璃模糊**: sigmaX: 12, sigmaY: 12
- **渐变背景**: 白色半透明渐变 (0.25 → 0.15)
- **边框**: 白色半透明边框 (opacity: 0.3)
- **阴影**: 柔和的底部阴影
- **圆角**: 16px 圆角

### 动画效果
- **进入动画**: 600ms，使用 easeOutCubic 曲线
- **退出动画**: 600ms，使用 easeInCubic 曲线
- **淡入淡出**: 前 50% 时间淡入，后 50% 时间淡出

### 交互方式
1. **自动消失**: 默认 3 秒后自动消失
2. **点击关闭**: 点击右侧 × 按钮关闭
3. **滑动关闭**: 向上快速滑动关闭（速度 > 300）

## 在其他页面使用

### 示例 1: 表单验证
```dart
if (phoneNumber.isEmpty) {
  GlassmorphismToast.showWarning(context, '请输入手机号');
  return;
}
```

### 示例 2: API 请求结果
```dart
final result = await apiService.submitData(data);
if (result.success) {
  GlassmorphismToast.showSuccess(context, '提交成功');
} else {
  GlassmorphismToast.showError(context, result.message);
}
```

### 示例 3: 网络状态
```dart
if (!hasNetwork) {
  GlassmorphismToast.showWarning(context, '网络连接已断开');
}
```

## 替换旧的 SnackBar

### 旧代码
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('登录成功'),
    backgroundColor: Colors.green,
    behavior: SnackBarBehavior.floating,
  ),
);
```

### 新代码
```dart
GlassmorphismToast.showSuccess(context, '登录成功');
```

## 注意事项

1. **Context 要求**: 需要在有 Overlay 的 context 中使用
2. **自动替换**: 新提示会自动替换正在显示的旧提示
3. **安全区域**: 自动适配刘海屏和状态栏
4. **文本长度**: 最多显示 3 行，超出部分会显示省略号

## 技术实现

- 使用 `OverlayEntry` 实现全局浮层
- 使用 `BackdropFilter` 实现毛玻璃效果
- 使用 `AnimationController` 控制动画
- 使用 `GestureDetector` 处理滑动手势
- 使用 `SafeArea` 适配不同设备

## 性能优化

- 单例模式，同时只显示一个提示
- 动画结束后自动释放资源
- 使用 `mounted` 检查避免内存泄漏

