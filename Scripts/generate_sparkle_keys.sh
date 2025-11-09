#!/bin/bash
set -e

# Sparkle 密钥生成脚本
# 这个脚本会生成 ED25519 密钥对用于 Sparkle 更新签名

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KEYS_DIR="$PROJECT_ROOT/Scripts/sparkle_keys"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔑 生成 Sparkle 更新密钥对...${NC}"

# 创建密钥目录
mkdir -p "$KEYS_DIR"

# 检查是否已存在密钥
if [ -f "$KEYS_DIR/eddsa_private_key.pem" ]; then
    echo -e "${YELLOW}⚠️  密钥已存在: $KEYS_DIR/eddsa_private_key.pem${NC}"
    read -p "是否重新生成？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✅ 使用现有密钥${NC}"
        exit 0
    fi
    rm -f "$KEYS_DIR/eddsa_private_key.pem" "$KEYS_DIR/eddsa_public_key.pem"
fi

# 方法1: 尝试使用 Sparkle 工具（如果可用）
if command -v generate_keys >/dev/null 2>&1; then
    echo -e "${BLUE}📦 使用 Sparkle generate_keys 工具...${NC}"
    cd "$KEYS_DIR"
    generate_keys
elif [ -f "$PROJECT_ROOT/Scripts/sparkle/bin/generate_keys" ]; then
    echo -e "${BLUE}📦 使用本地 Sparkle 工具...${NC}"
    cd "$KEYS_DIR"
    "$PROJECT_ROOT/Scripts/sparkle/bin/generate_keys"
else
    # 方法2: 使用 openssl 生成 ED25519 密钥
    echo -e "${BLUE}📦 使用 openssl 生成 ED25519 密钥...${NC}"
    
    # 检查 openssl 版本（需要支持 ED25519）
    if ! openssl version | grep -q "OpenSSL"; then
        echo -e "${RED}❌ 错误: 需要 openssl 支持 ED25519${NC}"
        echo -e "${YELLOW}💡 提示: 请安装 Sparkle 工具或更新 openssl${NC}"
        echo -e "${YELLOW}   下载地址: https://github.com/sparkle-project/Sparkle/releases${NC}"
        exit 1
    fi
    
    cd "$KEYS_DIR"
    
    # 生成私钥
    openssl genpkey -algorithm ED25519 -out eddsa_private_key.pem 2>/dev/null || {
        echo -e "${RED}❌ 错误: openssl 不支持 ED25519${NC}"
        echo -e "${YELLOW}💡 请手动下载 Sparkle 工具:${NC}"
        echo -e "${YELLOW}   https://github.com/sparkle-project/Sparkle/releases${NC}"
        echo -e "${YELLOW}   然后运行: ./bin/generate_keys${NC}"
        exit 1
    }
    
    # 提取公钥（Sparkle 格式）
    # Sparkle 需要的是 base64 编码的原始公钥
    openssl pkey -in eddsa_private_key.pem -pubout -outform DER 2>/dev/null | \
        tail -c +13 | base64 > eddsa_public_key.pem || {
        echo -e "${YELLOW}⚠️  无法自动提取公钥，请手动处理${NC}"
    }
fi

# 检查密钥是否生成成功
if [ ! -f "$KEYS_DIR/eddsa_private_key.pem" ]; then
    echo -e "${RED}❌ 密钥生成失败${NC}"
    exit 1
fi

# 读取公钥内容
if [ -f "$KEYS_DIR/eddsa_public_key.pem" ]; then
    PUBLIC_KEY=$(cat "$KEYS_DIR/eddsa_public_key.pem" | tr -d '\n')
    echo -e "${GREEN}✅ 密钥生成成功！${NC}"
    echo ""
    echo -e "${BLUE}📋 公钥内容:${NC}"
    echo -e "${YELLOW}$PUBLIC_KEY${NC}"
    echo ""
    echo -e "${BLUE}📝 下一步:${NC}"
    echo -e "1. 将公钥添加到 Project.swift 的 SUPublicEDSAKey 配置中"
    echo -e "2. 私钥文件: ${KEYS_DIR}/eddsa_private_key.pem (${RED}不要提交到仓库${NC})"
    echo -e "3. 公钥文件: ${KEYS_DIR}/eddsa_public_key.pem"
else
    echo -e "${YELLOW}⚠️  私钥已生成，但需要手动提取公钥${NC}"
    echo -e "${YELLOW}   请参考 Sparkle 文档或使用 Sparkle 工具${NC}"
fi

# 添加到 .gitignore
GITIGNORE="$PROJECT_ROOT/.gitignore"
if [ -f "$GITIGNORE" ]; then
    if ! grep -q "sparkle_keys/eddsa_private_key.pem" "$GITIGNORE"; then
        echo "" >> "$GITIGNORE"
        echo "# Sparkle 私钥（不要提交）" >> "$GITIGNORE"
        echo "Scripts/sparkle_keys/eddsa_private_key.pem" >> "$GITIGNORE"
        echo -e "${GREEN}✅ 已添加到 .gitignore${NC}"
    fi
else
    echo "Scripts/sparkle_keys/eddsa_private_key.pem" > "$GITIGNORE"
    echo -e "${GREEN}✅ 已创建 .gitignore${NC}"
fi

