# Release 流程指南

本文档描述了 Vibeviewer 项目的完整 Release 流程，包括构建、签名和上传。

## 前置要求

1. **GitHub CLI**
   ```bash
   brew install gh
   gh auth login
   ```

## 快速开始

### 方法 1: 使用自动化脚本（推荐）

```bash
# 自动检测版本并执行完整流程
./Scripts/release.sh

# 指定版本号
./Scripts/release.sh 1.1.9

# 跳过构建（使用已有 DMG）
./Scripts/release.sh --skip-build 1.1.9

# 跳过上传（仅本地操作）
./Scripts/release.sh --skip-upload 1.1.9
```

### 方法 2: 使用 Makefile

```bash
# 构建 DMG
make release

# 然后手动执行后续步骤
```

### 方法 3: 手动步骤

1. **更新版本号**
   - 编辑 `Project.swift`，更新 `appVersion` 常量

2. **构建和创建 DMG**
   ```bash
   make release
   # 或
   Scripts/create_dmg.sh --version 1.1.9
   ```

3. **创建 Git Tag**
   ```bash
   git tag -a v1.1.9 -m "Release version 1.1.9"
   git push origin v1.1.9
   ```

4. **创建 GitHub Release**
   ```bash
   gh release create v1.1.9 \
     --title "Version 1.1.9" \
     --notes "Release notes here" \
     Vibeviewer-1.1.9.dmg
   ```

## 详细流程说明

### 1. 版本号管理

版本号在 `Project.swift` 中统一管理：
- `appVersion`: 统一版本号配置（如 "1.1.9"）
- `MARKETING_VERSION`: 显示版本号（从 appVersion 读取）
- `CURRENT_PROJECT_VERSION`: 构建版本号（从 appVersion 读取）
- `CFBundleShortVersionString`: Info.plist 中的版本号（从 appVersion 读取）
- `CFBundleVersion`: Info.plist 中的构建号（从 appVersion 读取）

### 2. 构建流程

`Scripts/create_dmg.sh` 脚本会：
1. 清理之前的构建产物
2. 构建 Release 版本应用
3. 验证应用版本信息和代码签名
4. 创建 DMG 安装包

### 3. GitHub Release

使用 GitHub CLI 创建 Release：
- 自动生成变更日志（基于 Git commits）
- 上传 DMG 文件
- 创建 Release 页面

## 故障排查

### 问题 1: GitHub Release 创建失败

**可能原因**:
- GitHub CLI 未认证
- Tag 已存在
- 网络问题

**解决方案**:
```bash
# 重新认证
gh auth login

# 删除现有 Tag/Release
git tag -d v1.1.9
git push origin :refs/tags/v1.1.9
gh release delete v1.1.9
```

### 问题 2: 构建失败

**解决方案**:
1. 检查 Xcode 是否正确安装
2. 运行 `make clear` 清理构建缓存
3. 检查 `Project.swift` 中的版本号配置

## 最佳实践

1. **版本号**: 遵循语义化版本（Semantic Versioning）
2. **变更日志**: 在 Release Notes 中清晰描述更新内容
3. **测试**: 发布前在本地测试 DMG 安装
4. **文档**: 重大更新时更新 README 和文档

## 相关文件

- `Scripts/release.sh` - 完整的自动化 Release 脚本
- `Scripts/create_dmg.sh` - DMG 创建脚本
- `Project.swift` - 版本号配置
- `Makefile` - 构建命令

## 参考链接

- [GitHub CLI 文档](https://cli.github.com/manual/)
- [语义化版本](https://semver.org/)
