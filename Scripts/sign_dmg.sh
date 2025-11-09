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

# 方法1: 尝试使用 Sparkle 的 sign_update 工具（必需）
SIGNATURE=""
SIGN_ERROR=""
SIGN_UPDATE_TOOL=""

# 查找 sign_update 工具
if command -v sign_update >/dev/null 2>&1; then
    SIGN_UPDATE_TOOL="sign_update"
elif [ -f "$PROJECT_ROOT/Scripts/sparkle/bin/sign_update" ]; then
    SIGN_UPDATE_TOOL="$PROJECT_ROOT/Scripts/sparkle/bin/sign_update"
elif [ -f "/opt/homebrew/Caskroom/sparkle/2.8.0/bin/sign_update" ]; then
    SIGN_UPDATE_TOOL="/opt/homebrew/Caskroom/sparkle/2.8.0/bin/sign_update"
elif [ -f "/usr/local/Caskroom/sparkle/2.8.0/bin/sign_update" ]; then
    SIGN_UPDATE_TOOL="/usr/local/Caskroom/sparkle/2.8.0/bin/sign_update"
else
    # 尝试查找最新版本的 Sparkle
    SPARKLE_DIR=$(find /opt/homebrew/Caskroom/sparkle -name sign_update 2>/dev/null | head -1)
    if [ -n "$SPARKLE_DIR" ]; then
        SIGN_UPDATE_TOOL="$SPARKLE_DIR"
    else
        SPARKLE_DIR=$(find /usr/local/Caskroom/sparkle -name sign_update 2>/dev/null | head -1)
        if [ -n "$SPARKLE_DIR" ]; then
            SIGN_UPDATE_TOOL="$SPARKLE_DIR"
        fi
    fi
fi

if [ -n "$SIGN_UPDATE_TOOL" ]; then
    echo -e "${BLUE}📦 使用 Sparkle sign_update 工具: $SIGN_UPDATE_TOOL${NC}"
    
    # 尝试使用私钥文件签名
    if [ -f "$PRIVATE_KEY" ]; then
        SIGN_ERROR=$("$SIGN_UPDATE_TOOL" --ed-key-file "$PRIVATE_KEY" "$DMG_FILE" 2>&1 >/dev/null)
        SIGNATURE=$("$SIGN_UPDATE_TOOL" --ed-key-file "$PRIVATE_KEY" -p "$DMG_FILE" 2>/dev/null)
    else
        # 如果没有私钥文件，尝试从 Keychain 读取（Sparkle 2.8.0+）
        echo -e "${BLUE}📦 从 Keychain 读取密钥...${NC}"
        SIGN_ERROR=$("$SIGN_UPDATE_TOOL" "$DMG_FILE" 2>&1 >/dev/null)
        SIGNATURE=$("$SIGN_UPDATE_TOOL" -p "$DMG_FILE" 2>/dev/null)
    fi
    
    if [ $? -ne 0 ] || [ -z "$SIGNATURE" ]; then
        echo -e "${RED}❌ 签名失败: $SIGN_ERROR${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ 错误: 找不到 Sparkle sign_update 工具${NC}"
    echo -e "${YELLOW}💡 请下载并安装 Sparkle 工具:${NC}"
    echo -e "${YELLOW}   1. 下载: https://github.com/sparkle-project/Sparkle/releases${NC}"
    echo -e "${YELLOW}   2. 解压到: $PROJECT_ROOT/Scripts/sparkle/${NC}"
    echo -e "${YELLOW}   3. 或者安装到系统 PATH: brew install sparkle${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  注意: Sparkle 更新必须使用 sign_update 工具生成 EdDSA 签名${NC}"
    echo -e "${YELLOW}   不能使用 openssl 替代，因为格式不兼容${NC}"
    exit 1
fi

# 清理签名字符串（移除换行符和空格）
SIGNATURE=$(echo "$SIGNATURE" | tr -d '\n\r ')

# 验证签名格式（应该是 base64 编码的字符串，长度通常在 80-100 字符左右）
if [ -z "$SIGNATURE" ] || [ ${#SIGNATURE} -lt 20 ]; then
    echo -e "${RED}❌ 签名格式无效或为空${NC}"
    echo -e "${YELLOW}   签名长度: ${#SIGNATURE}${NC}"
    echo -e "${YELLOW}   签名内容: $SIGNATURE${NC}"
    exit 1
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
echo -e "   - sparkle:edSignature=\"$SIGNATURE\" (Ed25519 签名)"

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

