.PHONY: generate clear build dmg dmg-release release

generate:
	@Scripts/generate.sh

clear:
	@Scripts/clear.sh

build:
	@echo "🔨 Building Vibeviewer..."
	@xcodebuild -workspace Vibeviewer.xcworkspace -scheme Vibeviewer -configuration Release -destination "platform=macOS" -skipMacroValidation build

dmg:
	@echo "💽 Creating DMG package..."
	@Scripts/create_dmg.sh

dmg-release:
	@echo "💽 Creating DMG package..."
	@Scripts/create_dmg.sh

release: clear generate build dmg-release
	@echo "🚀 Release build completed! DMG is ready for distribution."
	@echo "📋 Next steps:"
	@echo "  1. Create GitHub Release (tag: v<VERSION>)"
	@echo "  2. Upload DMG file"
	@echo ""
	@echo "💡 提示: 使用 ./Scripts/release.sh 可以自动化整个流程"

release-full:
	@Scripts/release.sh


