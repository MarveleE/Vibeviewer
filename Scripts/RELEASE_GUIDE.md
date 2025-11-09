# Release 流程指南

本文档描述了 Vibeviewer 项目的完整 Release 流程，包括构建、签名、上传和 Sparkle 更新配置。

## 前置要求

1. **Sparkle 工具**
   ```bash
   brew install sparkle
   ```

2. **Sparkle 密钥**
   - 如果还没有密钥，运行：
     ```bash
     /opt/homebrew/Caskroom/sparkle/2.8.0/bin/generate_keys
     ```
   - 密钥会自动保存到 Keychain
   - 公钥需要添加到 `Project.swift` 的 `SUPublicEDSAKey` 配置中

3. **GitHub CLI**
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
./Scripts/release.sh 1.1.7

# 跳过构建（使用已有 DMG）
./Scripts/release.sh --skip-build 1.1.7

# 跳过上传（仅本地操作）
./Scripts/release.sh --skip-upload 1.1.7
```

### 方法 2: 使用 Makefile

```bash
# 构建 DMG（包含 Sparkle 配置）
make release

# 然后手动执行后续步骤
```

### 方法 3: 手动步骤

1. **更新版本号**
   - 编辑 `Project.swift`，更新 `MARKETING_VERSION` 和 `CFBundleShortVersionString`

2. **构建和创建 DMG**
   ```bash
   make release
   # 或
   Scripts/create_dmg.sh --version 1.1.7 --update-appcast
   ```

3. **创建 Git Tag**
   ```bash
   git tag -a v1.1.7 -m "Release version 1.1.7"
   git push origin v1.1.7
   ```

4. **创建 GitHub Release**
   ```bash
   gh release create v1.1.7 \
     --title "Version 1.1.7" \
     --notes "Release notes here" \
     Vibeviewer-1.1.7.dmg
   ```

5. **提交 appcast.xml**
   ```bash
   git add appcast.xml
   git commit -m "chore: 更新 appcast.xml 添加版本 1.1.7"
   git push
   ```

## 详细流程说明

### 1. 版本号管理

版本号在 `Project.swift` 中统一管理：
- `MARKETING_VERSION`: 显示版本号（如 1.1.7）
- `CURRENT_PROJECT_VERSION`: 构建版本号（通常与 MARKETING_VERSION 相同）
- `CFBundleShortVersionString`: Info.plist 中的版本号
- `CFBundleVersion`: Info.plist 中的构建号

### 2. 构建流程

`Scripts/create_dmg.sh` 脚本会：
1. 清理之前的构建产物
2. 构建 Release 版本应用
3. 验证应用版本信息和代码签名
4. 创建 DMG 安装包
5. 签名 DMG（Sparkle 必需）
6. 可选：更新 appcast.xml

### 3. Sparkle 签名

Sparkle 使用 EdDSA (Ed25519) 签名来验证更新包：

- **密钥存储**: Sparkle 2.8.0+ 使用 Keychain 存储密钥
- **签名工具**: `sign_update`（Sparkle 提供）
- **签名格式**: Base64 编码的 EdDSA 签名

签名脚本 (`Scripts/sign_dmg.sh`) 会自动：
1. 查找 `sign_update` 工具（系统 PATH 或 Homebrew 安装位置）
2. 尝试从 Keychain 读取密钥
3. 如果 Keychain 中没有，尝试使用私钥文件
4. 生成签名并保存到文件

### 4. appcast.xml 更新

`appcast.xml` 是 Sparkle 更新系统的配置文件，包含：
- 版本信息
- 下载 URL（GitHub Release）
- 文件大小
- EdDSA 签名
- 发布说明链接

`Scripts/update_appcast.sh` 会自动：
1. 获取 DMG 文件大小
2. 获取 EdDSA 签名
3. 生成新的 `<item>` 条目
4. 插入到 appcast.xml 的最前面（最新版本在顶部）

### 5. GitHub Release

使用 GitHub CLI 创建 Release：
- 自动生成变更日志（基于 Git commits）
- 上传 DMG 文件
- 创建 Release 页面

## 故障排查

### 问题 1: 找不到 sign_update 工具

**解决方案**:
```bash
brew install sparkle
# 或手动下载并解压到 Scripts/sparkle/
```

### 问题 2: 签名失败

**可能原因**:
- Keychain 中没有 Sparkle 密钥
- 私钥文件格式不正确

**解决方案**:
```bash
# 重新生成密钥到 Keychain
/opt/homebrew/Caskroom/sparkle/2.8.0/bin/generate_keys

# 或检查 Keychain 中的密钥
security find-generic-password -s "ed25519"
```

### 问题 3: appcast.xml 更新失败

**解决方案**:
1. 检查 Python 3 是否安装
2. 手动运行签名脚本获取签名
3. 手动编辑 appcast.xml

### 问题 4: GitHub Release 创建失败

**可能原因**:
- GitHub CLI 未认证
- Tag 已存在
- 网络问题

**解决方案**:
```bash
# 重新认证
gh auth login

# 删除现有 Tag/Release
git tag -d v1.1.7
git push origin :refs/tags/v1.1.7
gh release delete v1.1.7
```

## 最佳实践

1. **版本号**: 遵循语义化版本（Semantic Versioning）
2. **变更日志**: 在 Release Notes 中清晰描述更新内容
3. **测试**: 发布前在本地测试 DMG 安装和 Sparkle 更新
4. **备份**: 重要版本发布前备份 appcast.xml
5. **文档**: 重大更新时更新 README 和文档

## 相关文件

- `Scripts/release.sh` - 完整的自动化 Release 脚本
- `Scripts/create_dmg.sh` - DMG 创建脚本
- `Scripts/sign_dmg.sh` - DMG 签名脚本
- `Scripts/update_appcast.sh` - appcast.xml 更新脚本
- `appcast.xml` - Sparkle 更新配置文件
- `Project.swift` - 版本号配置
- `Makefile` - 构建命令

## 参考链接

- [Sparkle 文档](https://sparkle-project.org/documentation/)
- [GitHub CLI 文档](https://cli.github.com/manual/)
- [语义化版本](https://semver.org/)

