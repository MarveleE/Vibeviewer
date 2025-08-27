.PHONY: generate clear build dmg release

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

release: clear generate build dmg
	@echo "🚀 Release build completed! DMG is ready for distribution."


