#!/bin/bash
set -e

# 生成 Sparkle appcast.xml 脚本
# 用法: ./Scripts/generate_appcast.sh <VERSION> <DMG_URL> [RELEASE_NOTES_URL]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 参数
VERSION="${1:-}"
DMG_URL="${2:-}"
RELEASE_NOTES_URL="${3:-}"
OUTPUT_FILE="${4:-appcast.xml}"

if [ -z "$VERSION" ] || [ -z "$DMG_URL" ]; then
    echo -e "${RED}❌ 错误: 需要版本号和 DMG URL${NC}"
    echo "用法: $0 <VERSION> <DMG_URL> [RELEASE_NOTES_URL] [OUTPUT_FILE]"
    echo "示例: $0 1.1.11 https://github.com/.../Vibeviewer-1.1.11.dmg"
    exit 1
fi

# 获取当前日期（RFC 822 格式）
PUB_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

# 如果没有提供 Release Notes URL，使用 GitHub Release 页面
if [ -z "$RELEASE_NOTES_URL" ]; then
    RELEASE_NOTES_URL="https://github.com/MarveleE/Vibeviewer/releases/tag/v${VERSION}"
fi

# 生成 appcast.xml
echo -e "${BLUE}📝 生成 appcast.xml...${NC}"

cat > "$OUTPUT_FILE" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>Vibeviewer</title>
        <link>https://github.com/MarveleE/Vibeviewer</link>
        <description>Vibeviewer App Updates</description>
        <language>en</language>
        <item>
            <title>Version ${VERSION}</title>
            <pubDate>${PUB_DATE}</pubDate>
            <sparkle:version>${VERSION}</sparkle:version>
            <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
            <enclosure url="${DMG_URL}" 
                       sparkle:version="${VERSION}" 
                       sparkle:shortVersionString="${VERSION}"
                       type="application/octet-stream"
                       length="0"/>
            <sparkle:releaseNotesLink>${RELEASE_NOTES_URL}</sparkle:releaseNotesLink>
        </item>
    </channel>
</rss>
EOF

echo -e "${GREEN}✅ appcast.xml 已生成: ${OUTPUT_FILE}${NC}"
echo -e "${BLUE}   版本: ${VERSION}${NC}"
echo -e "${BLUE}   DMG URL: ${DMG_URL}${NC}"

