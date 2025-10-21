## Vibeviewer

[English](README.md) | 简体中文

![Swift](https://img.shields.io/badge/Swift-5.10-orange?logo=swift)
![Xcode](https://img.shields.io/badge/Xcode-15.4%2B-blue?logo=xcode)
![macOS](https://img.shields.io/badge/macOS-14%2B-black?logo=apple)
![License](https://img.shields.io/badge/License-MIT-green)
![Release](https://img.shields.io/badge/Release-DMG-purple)

![Preview](Images/image.png)

**标签**: `swift`, `swiftui`, `xcode`, `tuist`, `macos`, `menu-bar`, `release`

一个开源的 macOS 菜单栏应用，用来在系统状态栏中快速查看与分享「工作区/团队」的使用与支出概览，并提供登录、设置、自动刷新与分享能力。项目采用模块化的 Swift Package 架构与纯 SwiftUI MV（非 MVVM）范式，专注于清晰的边界与可替换性。

### 亮点特性
- **菜单栏概览**：点击弹窗查看关键指标与最近活动：
  - **计费总览**、**免费额度**（如存在）与 **按需额度**（如存在）
  - **总消耗金额（Total Credits Usage）**，支持数值过渡动画
  - **请求对比（今日 vs 昨日）** 与 **使用事件流水**
  - 顶部快捷操作：**打开 Dashboard**、**退出登录**
- **登录与设置**：独立的登录与设置窗口，支持持久化凭据与应用偏好。
- **自动刷新**：基于屏幕电源/活跃状态的智能刷新策略，节能且及时。
- **模块化架构**：Core ← Model ← API ← Feature 单向依赖，DTO→Domain 映射仅在 API 层完成。
- **分享组件**：内置字体与图形资源，便捷生成分享视图。

### 注意
- 项目目前仅基于**团队账号**进行开发测试，对于个人会员账号以及 free 版本账号还未经测试，欢迎提交适配与优化。
- 项目基于模块化分层原则，虽然目前支持 Cursor 作为数据源，对其他相同类型 App 来说，理论上只要实现了数据层的对应方法，即可无缝适配，欢迎 PR。
- 应用目前没有 Logo，欢迎设计大佬贡献一个 Logo。

> 品牌与数据来源仅用于演示。项目不会向 UI 层暴露具体的网络实现，遵循「服务协议 + 默认实现」的封装原则。

---

## 架构与目录结构

项目采用 Workspace + 多个 Swift Packages 的分层设计（单向依赖：Core ← Model ← API ← Feature）：

```
Vibeviewer/
├─ Vibeviewer.xcworkspace           # 打开此工作区进行开发
├─ Vibeviewer/                      # App 外壳（很薄，仅入口）
├─ Packages/
│  ├─ VibeviewerCore/               # Core：工具/扩展/通用服务（不依赖业务层）
│  ├─ VibeviewerModel/              # Model：纯领域实体（值类型/Sendable）
│  ├─ VibeviewerAPI/                # API：网络/IO + DTO→Domain 映射（对外仅暴露服务协议）
│  ├─ VibeviewerAppEnvironment/     # 环境注入与跨特性服务入口
│  ├─ VibeviewerStorage/            # 存储（设置、凭据等）
│  ├─ VibeviewerLoginUI/            # Feature：登录相关 UI
│  ├─ VibeviewerMenuUI/             # Feature：菜单栏弹窗 UI（主界面）
│  ├─ VibeviewerSettingsUI/         # Feature：设置界面 UI
│  └─ VibeviewerShareUI/            # Feature：分享组件与资源
└─ Scripts/ & Makefile              # Tuist 生成、清理、打包 DMG 的脚本
```

关键原则与约束（强烈建议在提交前阅读 `./.cursor/rules/architecture.mdc`）：
- **分层与职责**：
  - Core/Shared → 工具与扩展
  - Model → 纯数据/领域实体
  - API/Service → 网络/IO/三方编排以及 DTO→Domain 映射
  - Feature/UI → SwiftUI 视图与交互，仅依赖服务协议和领域模型
- **依赖方向**：仅允许自上而下（Core ← Model ← API ← Feature），严禁反向依赖。
- **可替换性**：API 层仅暴露服务协议与默认实现；UI 通过 `@Environment` 注入，不直接引用网络库。
- **SwiftUI MV 模式**：
  - 使用 `@State`/`@Observable`/`@Environment`/`@Binding` 管理状态
  - 异步副作用使用 `.task`/`.onChange`，自动随视图生命周期取消
  - 不引入默认的 ViewModel 层（避免 MVVM 依赖）

---

## 开发环境

- macOS 14.0+
- Xcode 15.4+（`SWIFT_VERSION = 5.10`）
- Tuist（项目生成与管理）

安装 Tuist（若未安装）：

```bash
brew tap tuist/tuist && brew install tuist
```

---

## 快速开始

1) 生成 Xcode 工作区：

```bash
make generate
# 或者
Scripts/generate.sh
```

2) 打开工作区并运行：

```bash
open Vibeviewer.xcworkspace
# 在 Xcode 中选择 scheme：Vibeviewer，目标：My Mac（macOS），直接 Run
```

3) 命令行构建/打包（可选）：

```bash
make build     # Release 构建（macOS 平台）
make dmg       # 生成 DMG 安装包
make release   # 清理 → 生成 → 构建 → 打包全流程
```

---

## 运行与调试

- 初次运行会在菜单栏显示图标与关键指标，点击打开弹窗查看详细信息。
- 登录与设置窗口通过依赖注入的窗口管理服务打开（参见 `VibeviewerApp.swift` 中的 `.environment(...)`）。
- 自动刷新服务将在应用启动与屏幕状态变化时调度执行。

---

## 测试

各模块包含独立的 Swift Package 测试目标。可在 Xcode 的 Test navigator 直接运行，或使用命令行分别在各包下执行：

```bash
swift test --package-path Packages/VibeviewerCore
swift test --package-path Packages/VibeviewerModel
swift test --package-path Packages/VibeviewerAPI
swift test --package-path Packages/VibeviewerAppEnvironment
swift test --package-path Packages/VibeviewerStorage
swift test --package-path Packages/VibeviewerLoginUI
swift test --package-path Packages/VibeviewerMenuUI
swift test --package-path Packages/VibeviewerSettingsUI
swift test --package-path Packages/VibeviewerShareUI
```

> 提示：若新增/调整包结构，请先执行 `make generate` 以确保工作区最新。

---

## 贡献指南

欢迎 Issue 与 PR！为保持一致性与可维护性，请遵循以下约定：

1) 分支与提交
- 建议使用形如 `feat/short-topic`、`fix/short-topic` 的分支命名。
- 提交信息尽量遵循 Conventional Commits（如 `feat: add dashboard refresh service`）。

2) 架构约定
- 变更前阅读 `./.cursor/rules/architecture.mdc` 与本 README 的分层说明。
- 新增类型放置到对应层中：UI/Service/Model/Core，每个文件仅承载一个主要类型。
- API 层仅暴露「服务协议 + 默认实现」，DTO 仅在 API 内部，UI 层只能看到领域实体。

3) 开发自检清单
- `make generate` 能通过且工作区可成功打开
- `make build` 通过（或 Xcode Release 构建成功）
- 相关包的 `swift test` 通过
- 没有反向依赖或 UI 直接依赖网络实现

4) 提交 PR
- 在 PR 描述中简述变更动机、涉及模块与影响面
- 如涉及 UI，建议附带截图/录屏
- 小而聚焦的 PR 更容易被审阅与合并

---

## 常见问题（FAQ）

- Q: Xcode 打不开或 Targets 缺失？
  - A: 先运行 `make generate`（或 `Scripts/generate.sh`）重新生成工作区。

- Q: 提示找不到 Tuist 命令？
  - A: 参考上文用 Homebrew 安装 Tuist 后重试。

- Q: 构建失败提示 Swift 版本不匹配？
  - A: 请使用 Xcode 15.4+（Swift 5.10）。若升级后仍失败，执行清理脚本 `Scripts/clear.sh` 再 `make generate`。

---

## 许可证

本项目采用 MIT License 开源。详情参见 `LICENSE` 文件。

---

## 致谢

感谢所有为模块化 Swift 包架构、SwiftUI 生态与开发者工具做出贡献的社区成员。也感谢你对 Vibeviewer 的关注与改进！

UI 灵感来自 X 用户 @hi_caicai 的作品：[Minto: Vibe Coding Tracker](https://apps.apple.com/ca/app/minto-vibe-coding-tracker/id6749605275?mt=12)。


