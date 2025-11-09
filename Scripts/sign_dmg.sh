#!/bin/bash
set -e

# DMG 签名脚本（用于 Sparkle 更新）
# 用法: ./Scripts/sign_dmg.sh <DMG_FILE> [VERSION]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KEYS_DIR="$PROJECT_ROOT/Scripts/sparkle_keys"
PRIVATE_KEY="$KEYS_DIR/eddsa_private_key.pem"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查参数
if [ $# -lt 1 ]; then
    echo -e "${RED}❌ 错误: 需要指定 DMG 文件${NC}"
    echo -e "${YELLOW}用法: $0 <DMG_FILE> [VERSION]${NC}"
    exit 1
fi

DMG_FILE="$1"
VERSION="${2:-$(basename "$DMG_FILE" .dmg | sed 's/Vibeviewer-//')}"

# 检查 DMG 文件是否存在
if [ ! -f "$DMG_FILE" ]; then
    echo -e "${RED}❌ 错误: DMG 文件不存在: $DMG_FILE${NC}"
    exit 1
fi

# 检查私钥是否存在
if [ ! -f "$PRIVATE_KEY" ]; then
    echo -e "${RED}❌ 错误: 私钥文件不存在: $PRIVATE_KEY${NC}"
    echo -e "${YELLOW}💡 请先运行: ./Scripts/generate_sparkle_keys.sh${NC}"
    exit 1
fi

echo -e "${BLUE}🔐 签名 DMG 文件: $DMG_FILE${NC}"

# 方法1: 尝试使用 Sparkle 的 sign_update 工具
SIGNATURE=""
if command -v sign_update >/dev/null 2>&1; then
    echo -e "${BLUE}📦 使用 Sparkle sign_update 工具...${NC}"
    SIGNATURE=$(sign_update "$DMG_FILE" "$PRIVATE_KEY" 2>/dev/null || echo "")
elif [ -f "$PROJECT_ROOT/Scripts/sparkle/bin/sign_update" ]; then
    echo -e "${BLUE}📦 使用本地 Sparkle 工具...${NC}"
    SIGNATURE=$("$PROJECT_ROOT/Scripts/sparkle/bin/sign_update" "$DMG_FILE" "$PRIVATE_KEY" 2>/dev/null || echo "")
fi

# 如果签名失败，尝试使用 openssl
if [ -z "$SIGNATURE" ]; then
    echo -e "${YELLOW}⚠️  Sparkle 工具不可用，尝试使用 openssl...${NC}"
    
    # 计算 DMG 文件的 SHA256
    DMG_HASH=$(shasum -a 256 "$DMG_FILE" | cut -d' ' -f1)
    
    # 使用私钥签名哈希
    SIGNATURE=$(echo -n "$DMG_HASH" | openssl dgst -sha256 -sign "$PRIVATE_KEY" -binary | base64 | tr -d '\n' 2>/dev/null || echo "")
    
    if [ -z "$SIGNATURE" ]; then
        echo -e "${RED}❌ 签名失败${NC}"
        echo -e "${YELLOW}💡 请安装 Sparkle 工具:${NC}"
        echo -e "${YELLOW}   https://github.com/sparkle-project/Sparkle/releases${NC}"
        exit 1
    fi
fi

# 获取文件大小
FILE_SIZE=$(stat -f%z "$DMG_FILE" 2>/dev/null || stat -c%s "$DMG_FILE" 2>/dev/null)

echo -e "${GREEN}✅ 签名成功！${NC}"
echo ""
echo -e "${BLUE}📋 签名信息:${NC}"
echo -e "${YELLOW}版本: $VERSION${NC}"
echo -e "${YELLOW}文件大小: $FILE_SIZE 字节${NC}"
echo -e "${YELLOW}签名:${NC}"
echo -e "$SIGNATURE"
echo ""
echo -e "${BLUE}📝 下一步:${NC}"
echo -e "1. 将以下信息添加到 appcast.xml:"
echo -e "   - sparkle:version=\"$VERSION\""
echo -e "   - sparkle:shortVersionString=\"$VERSION\""
echo -e "   - length=\"$FILE_SIZE\""
echo -e "   - sparkle:dsaSignature=\"$SIGNATURE\""

# 保存签名到文件
SIGNATURE_FILE="$PROJECT_ROOT/Scripts/sparkle_keys/signature_${VERSION}.txt"
mkdir -p "$KEYS_DIR"
cat > "$SIGNATURE_FILE" << EOF
Version: $VERSION
File: $(basename "$DMG_FILE")
Size: $FILE_SIZE bytes
Signature: $SIGNATURE
EOF

echo -e "${GREEN}✅ 签名信息已保存到: $SIGNATURE_FILE${NC}"

