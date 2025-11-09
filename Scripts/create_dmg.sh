#!/bin/bash
set -e

# Configuration
APP_NAME="Vibeviewer"
CONFIGURATION="Release"
SCHEME="Vibeviewer"
WORKSPACE="Vibeviewer.xcworkspace"
BUILD_DIR="build"
TEMP_DIR="temp_dmg"
BACKGROUND_IMAGE_NAME="dmg_background.png"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Parse command line arguments
VERSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --version|-v)
            VERSION="$2"
            shift 2
            ;;
        --help|-h)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --version, -v <版本>     指定版本号（默认从应用 Info.plist 读取）"
            echo "  --help, -h               显示此帮助信息"
            echo ""
            echo "示例:"
            echo "  $0                       # 仅创建 DMG"
            echo "  $0 -v 1.1.9              # 指定版本创建 DMG"
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            echo "使用 --help 查看帮助信息"
            exit 1
            ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting DMG creation process for ${APP_NAME}...${NC}"

# Clean up previous builds
echo -e "${YELLOW}📦 Cleaning up previous builds...${NC}"
rm -rf "${BUILD_DIR}"
rm -rf "${TEMP_DIR}"
# Note: DMG_NAME will be set after version detection, so we clean up old DMGs separately
rm -f "${APP_NAME}"-*.dmg

# Build the app
echo -e "${BLUE}🔨 Building ${APP_NAME} in ${CONFIGURATION} configuration...${NC}"
xcodebuild -workspace "${WORKSPACE}" \
           -scheme "${SCHEME}" \
           -configuration "${CONFIGURATION}" \
           -derivedDataPath "${BUILD_DIR}" \
           -destination "platform=macOS" \
           -skipMacroValidation \
           clean build

# Find the built app
APP_PATH=$(find "${BUILD_DIR}" -name "${APP_NAME}.app" -type d | head -1)
if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ Error: Could not find ${APP_NAME}.app in build output${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found app at: ${APP_PATH}${NC}"

# 验证 app 的版本信息和代码签名
echo -e "${BLUE}🔍 验证 app 信息...${NC}"
INFO_PLIST="${APP_PATH}/Contents/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    APP_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || echo "")
    APP_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" 2>/dev/null || echo "")
    echo -e "   版本: ${APP_VERSION}"
    echo -e "   Build: ${APP_BUILD}"
    
    # 检查代码签名
    if codesign -dv "${APP_PATH}" 2>&1 | grep -q "code object is not signed"; then
        echo -e "${YELLOW}⚠️  警告: App 未签名或签名无效${NC}"
    else
        SIGNING_IDENTITY=$(codesign -dv "${APP_PATH}" 2>&1 | grep "Authority=" | head -1 | sed 's/.*Authority=\(.*\)/\1/' || echo "未知")
        echo -e "   签名: ${SIGNING_IDENTITY}"
        
        # 检查签名是否有效
        if ! codesign --verify --verbose "${APP_PATH}" 2>&1 | grep -q "valid on disk"; then
            echo -e "${YELLOW}⚠️  警告: 代码签名验证失败${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  警告: 找不到 Info.plist${NC}"
fi

# Get version from Project.swift first (single source of truth), then from built app
if [ -z "$VERSION" ]; then
    # 优先从 Project.swift 读取版本号（统一版本号配置）
    if [ -f "${PROJECT_ROOT}/Project.swift" ]; then
        VERSION=$(grep -E '^let appVersion\s*=' "${PROJECT_ROOT}/Project.swift" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/' | head -1)
    fi
    
    # Fallback: 从构建后的应用读取版本号
    if [ -z "$VERSION" ]; then
        INFO_PLIST="${APP_PATH}/Contents/Info.plist"
        if [ -f "$INFO_PLIST" ]; then
            VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || echo "")
        fi
    fi
    
    # Final fallback
    if [ -z "$VERSION" ]; then
        echo -e "${YELLOW}⚠️  无法自动获取版本号，使用默认值 1.1.8${NC}"
        echo -e "${YELLOW}   提示: 使用 --version 参数指定版本号${NC}"
        VERSION="1.1.8"
    fi
fi

DMG_NAME="${APP_NAME}-${VERSION}.dmg"
echo -e "${BLUE}📦 版本: ${VERSION}${NC}"
echo -e "${BLUE}📦 DMG 文件名: ${DMG_NAME}${NC}"

# Create temporary directory for DMG contents
echo -e "${YELLOW}📁 Creating DMG contents...${NC}"
mkdir -p "${TEMP_DIR}"
cp -R "${APP_PATH}" "${TEMP_DIR}/"

# Create Applications symlink
ln -s /Applications "${TEMP_DIR}/Applications"

# Create a simple background image if it doesn't exist
if [ ! -f "${BACKGROUND_IMAGE_NAME}" ]; then
    echo -e "${YELLOW}🎨 Creating background image...${NC}"
    # Create a simple background using ImageMagick if available, otherwise skip
    if command -v convert >/dev/null 2>&1; then
        convert -size 600x400 xc:white \
                -fill '#f0f0f0' -draw 'rectangle 0,0 600,400' \
                -fill black -pointsize 20 -gravity center \
                -annotate +0-100 "Drag ${APP_NAME} to Applications" \
                "${BACKGROUND_IMAGE_NAME}"
    fi
fi

# Copy background image if it exists
if [ -f "${BACKGROUND_IMAGE_NAME}" ]; then
    cp "${BACKGROUND_IMAGE_NAME}" "${TEMP_DIR}/.background.png"
fi

# Create DMG
echo -e "${BLUE}💽 Creating DMG file...${NC}"
hdiutil create -volname "${APP_NAME}" \
               -srcfolder "${TEMP_DIR}" \
               -ov \
               -format UDZO \
               -imagekey zlib-level=9 \
               "${DMG_NAME}"

# Clean up temporary files
echo -e "${YELLOW}🧹 Cleaning up temporary files...${NC}"
rm -rf "${TEMP_DIR}"
rm -rf "${BUILD_DIR}"

# Get DMG size
DMG_SIZE=$(du -h "${DMG_NAME}" | cut -f1)

echo -e "${GREEN}🎉 DMG creation completed successfully!${NC}"
echo -e "${GREEN}📦 Output: ${DMG_NAME} (${DMG_SIZE})${NC}"
echo -e "${GREEN}📍 Location: $(pwd)/${DMG_NAME}${NC}"
echo ""
echo -e "${BLUE}📋 下一步:${NC}"
echo -e "1. 在 GitHub 上创建 Release (tag: v${VERSION})"
echo -e "2. 上传 DMG 文件: ${DMG_NAME}"
echo -e "3. 填写 Release Notes"

# Optional: Open the directory containing the DMG
if command -v open >/dev/null 2>&1; then
    echo ""
    echo -e "${BLUE}📂 Opening directory...${NC}"
    open .
fi