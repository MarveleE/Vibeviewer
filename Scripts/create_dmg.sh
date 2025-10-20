#!/bin/bash
set -e

# Configuration
APP_NAME="Vibeviewer"
VERSION="1.1.1"
CONFIGURATION="Release"
SCHEME="Vibeviewer"
WORKSPACE="Vibeviewer.xcworkspace"
BUILD_DIR="build"
TEMP_DIR="temp_dmg"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
BACKGROUND_IMAGE_NAME="dmg_background.png"

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
rm -f "${DMG_NAME}"

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

# Optional: Open the directory containing the DMG
if command -v open >/dev/null 2>&1; then
    echo -e "${BLUE}📂 Opening directory...${NC}"
    open .
fi