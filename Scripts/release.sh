#!/bin/bash
set -e

# 完整的 Release 流程脚本
# 用法: ./Scripts/release.sh [VERSION] [--skip-build] [--skip-upload] [--skip-commit]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="Vibeviewer"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 解析参数
SKIP_BUILD=false
SKIP_UPLOAD=false
VERSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-upload)
            SKIP_UPLOAD=true
            shift
            ;;
        --version|-v)
            VERSION="$2"
            shift 2
            ;;
        --help|-h)
            echo "用法: $0 [选项] [VERSION]"
            echo ""
            echo "选项:"
            echo "  --version, -v <版本>   指定版本号（默认从 Project.swift 读取）"
            echo "  --skip-build           跳过构建步骤"
            echo "  --skip-upload           跳过上传到 GitHub Release"
            echo "  --help, -h              显示此帮助信息"
            echo ""
            echo "示例:"
            echo "  $0                      # 自动检测版本并完整流程"
            echo "  $0 1.1.7               # 指定版本号"
            echo "  $0 --skip-build 1.1.7   # 跳过构建（使用已有 DMG）"
            exit 0
            ;;
        *)
            if [ -z "$VERSION" ] && [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                VERSION="$1"
            else
                echo -e "${RED}❌ 未知选项: $1${NC}"
                echo "使用 --help 查看帮助信息"
                exit 1
            fi
            shift
            ;;
    esac
done

echo -e "${BLUE}🚀 开始 Release 流程...${NC}"
echo ""

# 1. 获取版本号（从 Project.swift 的统一版本号配置读取）
if [ -z "$VERSION" ]; then
    echo -e "${BLUE}📋 检测版本号...${NC}"
    # 优先从 appVersion 常量读取（统一版本号配置）
    VERSION=$(grep -E '^let appVersion\s*=' "$PROJECT_ROOT/Project.swift" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/' | head -1)
    
    # Fallback: 从 MARKETING_VERSION 读取
    if [ -z "$VERSION" ]; then
        VERSION=$(grep -E 'MARKETING_VERSION' "$PROJECT_ROOT/Project.swift" | head -1 | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')
    fi
    
    if [ -z "$VERSION" ]; then
        echo -e "${RED}❌ 无法自动检测版本号${NC}"
        echo -e "${YELLOW}   请使用 --version 参数指定版本号${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ 版本号: ${VERSION}${NC}"
echo ""

# 2. 检查 GitHub CLI
if ! command -v gh >/dev/null 2>&1; then
    echo -e "${RED}❌ 错误: 需要 GitHub CLI (gh)${NC}"
    echo -e "${YELLOW}   安装: brew install gh${NC}"
    exit 1
fi

# 4. 构建和创建 DMG
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
if [ "$SKIP_BUILD" = false ]; then
    echo -e "${BLUE}🔨 构建 Release 版本并创建 DMG...${NC}"
    "$SCRIPT_DIR/create_dmg.sh" --version "$VERSION" || {
        echo -e "${RED}❌ 构建失败${NC}"
        exit 1
    }
    echo ""
else
    echo -e "${YELLOW}⏭️  跳过构建步骤${NC}"
    if [ ! -f "$DMG_NAME" ]; then
        echo -e "${RED}❌ 错误: DMG 文件不存在: $DMG_NAME${NC}"
        exit 1
    fi
    echo ""
fi

# 5. 检查 Git 状态
echo -e "${BLUE}📋 检查 Git 状态...${NC}"
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️  有未提交的更改${NC}"
    git status --short
    echo ""
    read -p "是否继续？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 6. 创建 Git Tag
echo -e "${BLUE}🏷️  创建 Git Tag...${NC}"
if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Tag v${VERSION} 已存在${NC}"
    read -p "是否删除并重新创建？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -d "v${VERSION}" 2>/dev/null || true
        git push origin ":refs/tags/v${VERSION}" 2>/dev/null || true
    else
        echo -e "${YELLOW}⏭️  跳过 Tag 创建${NC}"
    fi
fi

if ! git rev-parse "v${VERSION}" >/dev/null 2>&1; then
    git tag -a "v${VERSION}" -m "Release version ${VERSION}"
    echo -e "${GREEN}✅ Tag v${VERSION} 已创建${NC}"
else
    echo -e "${YELLOW}⏭️  使用现有 Tag${NC}"
fi
echo ""

# 7. 创建 GitHub Release
if [ "$SKIP_UPLOAD" = false ]; then
    echo -e "${BLUE}📤 创建 GitHub Release...${NC}"
    
    # 检查 Release 是否已存在
    if gh release view "v${VERSION}" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Release v${VERSION} 已存在${NC}"
        read -p "是否删除并重新创建？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gh release delete "v${VERSION}" --yes 2>/dev/null || true
        else
            echo -e "${YELLOW}⏭️  跳过 Release 创建，直接上传 DMG${NC}"
            gh release upload "v${VERSION}" "$DMG_NAME" --clobber || {
                echo -e "${RED}❌ 上传失败${NC}"
                exit 1
            }
            echo -e "${GREEN}✅ DMG 已上传${NC}"
            echo ""
            SKIP_RELEASE_CREATE=true
        fi
    fi
    
    if [ "$SKIP_RELEASE_CREATE" != true ]; then
        # 获取变更日志
        PREV_TAG=$(git describe --tags --abbrev=0 HEAD~1 2>/dev/null || echo "")
        if [ -n "$PREV_TAG" ]; then
            CHANGELOG=$(git log "${PREV_TAG}..HEAD" --pretty=format:"- %s" | head -20)
        else
            CHANGELOG=$(git log --oneline -10 --pretty=format:"- %s")
        fi
        
        RELEASE_NOTES=$(cat <<EOF
## 更新内容

${CHANGELOG}

## 技术改进

- 版本更新至 ${VERSION}
- 优化自动更新机制
EOF
)
        
        # 创建 Release
        gh release create "v${VERSION}" \
            --title "Version ${VERSION}" \
            --notes "$RELEASE_NOTES" \
            "$DMG_NAME" || {
            echo -e "${RED}❌ Release 创建失败${NC}"
            exit 1
        }
        
        echo -e "${GREEN}✅ GitHub Release 已创建${NC}"
        echo -e "${BLUE}   URL: https://github.com/MarveleE/Vibeviewer/releases/tag/v${VERSION}${NC}"
    fi
    echo ""
else
    echo -e "${YELLOW}⏭️  跳过上传步骤${NC}"
    echo ""
fi

# 8. 推送 Tag
echo -e "${BLUE}📤 推送 Git Tag...${NC}"
git push origin "v${VERSION}" || {
    echo -e "${YELLOW}⚠️  Tag 推送失败或已存在${NC}"
}
echo ""

# 完成
echo -e "${GREEN}🎉 Release 流程完成！${NC}"
echo ""
echo -e "${BLUE}📋 总结:${NC}"
echo -e "  版本: ${VERSION}"
echo -e "  DMG: ${DMG_NAME}"
echo -e "  Release: https://github.com/MarveleE/Vibeviewer/releases/tag/v${VERSION}"
echo ""

