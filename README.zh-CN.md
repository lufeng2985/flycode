# FlyCode

[English](./README.md) | [简体中文](./README.zh-CN.md)

FlyCode 是一个基于 Flutter 构建的移动端 `opencode` 客户端，用于连接 `opencode server`，并将项目浏览、会话管理和 AI 编码工作流带到 Android 与 iOS。

## 技术栈

- Flutter / Dart `^3.11.0`
- Riverpod + `riverpod_annotation`
- `go_router`
- `http`
- `shared_preferences`
- `sqflite`
- `json_serializable`

## 支持平台

当前项目主要面向移动端：

- Android
- iOS

## Features

- 支持连接 `opencode server`，可配置服务端地址，并支持可选认证
- 支持浏览项目，并快速进入新建或已有的编码会话
- 提供面向移动端优化的消息展示与输入交互，用于与编码 agent 对话
- 可在应用内查看权限请求、问题卡片、Todo、Diff 和会话上下文
- 支持模型配置、主题模式、语言和完成通知等个性化设置
- 提供本地状态持久化与移动端通知能力

## 项目结构

```text
lib/
  app.dart                    # 应用入口：路由、主题、国际化、全局事件
  main.dart                   # Flutter 启动入口
  router.dart                 # go_router 路由定义
  theme/                      # ThemeData 与 AppThemeTokens
  l10n/                       # 国际化资源与生成代码
  pages/                      # 页面层
  widgets/                    # 通用组件与业务组件
  providers/                  # Riverpod providers 与状态逻辑
  service/api/                # API client、接口封装与 API 模型
  database/                   # 本地数据库与 DAO
  models/                     # 应用内本地模型
test/                         # 单元测试与 Widget 测试
assets/                       # 字体、应用图标与静态资源
```

## 本地开发

### 环境要求

- Flutter SDK
- Dart SDK `^3.11.0`
- 目标平台对应的构建环境

### 安装依赖

```bash
flutter pub get
```

### 启动应用

```bash
flutter run
```

如果需要指定设备：

```bash
flutter devices
flutter run -d <device-id>
```

## 开发命令

### 代码格式化

```bash
dart format .
```

### 静态检查

```bash
flutter analyze
```

### 运行测试

```bash
flutter test
```

运行单个测试文件：

```bash
flutter test test/session_status_provider_test.dart
```

按测试名运行：

```bash
flutter test test/session_status_provider_test.dart --name="returns loading state"
```

### 代码生成

当你修改以下内容后，需要重新生成代码：

- `@riverpod` provider
- `json_serializable` 模型

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 推荐工作流

提交前建议执行：

```bash
dart format .
flutter analyze
flutter test
```

仓库约定：

- 不要手动修改 `*.g.dart`
- 新 provider 优先使用 `@riverpod`
- 页面层尽量只负责组装与 UI
- 业务逻辑尽量放入 provider
- 避免硬编码颜色、字体和间距，优先使用主题 token

## 主题与设计

项目通过 `ThemeData` 和 `ThemeExtension(AppThemeTokens)` 管理设计 token。

关键文件：

- `lib/app.dart`
- `lib/theme/app_theme.dart`
- `lib/theme/app_tokens.dart`
- `lib/theme/theme_mode_provider.dart`

设计建议：

- 先保证信息层级，再考虑视觉装饰
- 优先复用组件，避免一次性样式
- 颜色、字号、圆角和间距尽量通过 token 管理
- 同时考虑浅色和深色模式

当前视觉基线：

- 正文字体：Inter
- 标题字体：PlusJakartaSans
- 主色：`#8B5CF6`

## 配置说明

### 服务端配置

应用依赖一个可访问的 `opencode server`。当前连接测试会访问：

```text
/global/health
```

可配置字段：

- `baseUrl`
- `username`（可选）
- `password`（可选）

### 本地持久化

当前项目使用：

- `shared_preferences` 存储轻量级本地设置和引导状态
- `sqflite` 存储本地结构化数据

## 许可证与资源

- 字体资源位于 `assets/fonts/`
- 字体许可证文件位于 `assets/fonts/OFL.txt`
