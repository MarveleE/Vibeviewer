#!/bin/bash
set -e

# 更新 appcast.xml 脚本
# 用法: ./Scripts/update_appcast.sh <VERSION> <DMG_FILE> [RELEASE_NOTES_URL]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APPCAST_FILE="$PROJECT_ROOT/appcast.xml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查参数
if [ $# -lt 2 ]; then
    echo -e "${RED}❌ 错误: 需要指定版本号和 DMG 文件${NC}"
    echo -e "${YELLOW}用法: $0 <VERSION> <DMG_FILE> [RELEASE_NOTES_URL]${NC}"
    echo -e "${YELLOW}示例: $0 1.1.6 Vibeviewer-1.1.6.dmg${NC}"
    exit 1
fi

VERSION="$1"
DMG_FILE="$2"
RELEASE_NOTES_URL="${3:-https://github.com/MarveleE/Vibeviewer/releases/tag/v${VERSION}}"

# 检查 DMG 文件是否存在
if [ ! -f "$DMG_FILE" ]; then
    echo -e "${RED}❌ 错误: DMG 文件不存在: $DMG_FILE${NC}"
    exit 1
fi

# 检查 appcast.xml 是否存在
if [ ! -f "$APPCAST_FILE" ]; then
    echo -e "${RED}❌ 错误: appcast.xml 不存在: $APPCAST_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}📝 更新 appcast.xml...${NC}"

# 获取文件大小
FILE_SIZE=$(stat -f%z "$DMG_FILE" 2>/dev/null || stat -c%s "$DMG_FILE" 2>/dev/null)

# 获取签名（使用唯一来源 seed_base64.txt）
echo -e "${BLUE}🔐 计算 DMG 签名（seed_base64）...${NC}"
SEED_KEY_FILE="$PROJECT_ROOT/Scripts/sparkle_keys/seed_base64.txt"
if [ ! -f "$SEED_KEY_FILE" ]; then
    echo -e "${RED}❌ 错误: 未找到 seed 私钥: $SEED_KEY_FILE${NC}"
    exit 1
fi

# 查找 sign_update 工具
if command -v sign_update >/dev/null 2>&1; then
    SIGN_UPDATE_TOOL="sign_update"
elif [ -f "/opt/homebrew/Caskroom/sparkle/2.8.0/bin/sign_update" ]; then
    SIGN_UPDATE_TOOL="/opt/homebrew/Caskroom/sparkle/2.8.0/bin/sign_update"
elif [ -f "/usr/local/Caskroom/sparkle/2.8.0/bin/sign_update" ]; then
    SIGN_UPDATE_TOOL="/usr/local/Caskroom/sparkle/2.8.0/bin/sign_update"
else
    echo -e "${RED}❌ 错误: 找不到 sign_update 工具${NC}"
    exit 1
fi

SIGNATURE=$("$SIGN_UPDATE_TOOL" --ed-key-file "$SEED_KEY_FILE" -p "$DMG_FILE" 2>/dev/null | tr -d '\n\r ')
if [ -z "$SIGNATURE" ] || [ ${#SIGNATURE} -lt 60 ]; then
    echo -e "${RED}❌ 签名计算失败${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 签名计算成功${NC}"

# 获取当前日期（RFC 822 格式）
PUB_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

# 创建新的 item XML
NEW_ITEM=$(cat <<EOF
        <item>
            <title>Version ${VERSION}</title>
            <sparkle:releaseNotesLink>${RELEASE_NOTES_URL}</sparkle:releaseNotesLink>
            <pubDate>${PUB_DATE}</pubDate>
            <enclosure url="https://github.com/MarveleE/Vibeviewer/releases/download/v${VERSION}/Vibeviewer-${VERSION}.dmg"
                       sparkle:version="${VERSION}"
                       sparkle:shortVersionString="${VERSION}"
                       length="${FILE_SIZE}"
                       type="application/octet-stream"
                       sparkle:edSignature="${SIGNATURE}"/>
        </item>
EOF
)

# 备份原文件
cp "$APPCAST_FILE" "${APPCAST_FILE}.backup"

# 在 channel 标签内，第一个 item 之前插入新 item
# 使用 Python 来处理 XML（更可靠）
python3 <<PYTHON_SCRIPT
import xml.etree.ElementTree as ET
import sys
from datetime import datetime

try:
    tree = ET.parse("$APPCAST_FILE")
    root = tree.getroot()
    
    # 找到 channel
    channel = root.find('.//channel')
    if channel is None:
        print("错误: 找不到 channel 元素", file=sys.stderr)
        sys.exit(1)
    
    # 创建新的 item
    new_item = ET.fromstring('''$NEW_ITEM''')
    
    # 找到第一个 item（如果有）
    first_item = channel.find('item')
    if first_item is not None:
        # 在第一个 item 之前插入
        channel.insert(list(channel).index(first_item), new_item)
    else:
        # 如果没有 item，直接添加
        channel.append(new_item)
    
    # 保存
    tree.write("$APPCAST_FILE", encoding='utf-8', xml_declaration=True)
    print("✅ appcast.xml 已更新")
except Exception as e:
    print(f"错误: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ appcast.xml 更新成功！${NC}"
    echo -e "${BLUE}📋 更新内容:${NC}"
    echo -e "  版本: ${VERSION}"
    echo -e "  文件大小: ${FILE_SIZE} 字节"
    echo -e "  签名: ${SIGNATURE:0:50}..."
    echo ""
    echo -e "${YELLOW}⚠️  请检查 appcast.xml 内容是否正确${NC}"
    echo -e "${YELLOW}   备份文件: ${APPCAST_FILE}.backup${NC}"
else
    echo -e "${RED}❌ 更新失败，已恢复备份${NC}"
    mv "${APPCAST_FILE}.backup" "$APPCAST_FILE"
    exit 1
fi

