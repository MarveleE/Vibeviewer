.PHONY: generate clear dmg release

# 生成项目文件
generate:
	@Scripts/generate.sh

# 清理构建产物
clear:
	@Scripts/clear.sh

# 打包 Production 环境（构建 Release 版本并创建 DMG）
dmg: clear generate
	@echo "💽 Building Production version and creating DMG..."
	@export LC_ALL=en_US.UTF-8 && fastlane mac build_release_dmg || (echo "❌ DMG 创建失败" && exit 1)

# 完整 Release 流程：先打包 Production，然后执行 release 步骤（Git tag、GitHub Release）
release: dmg
	@echo "🚀 Starting release process..."
	@if [ -z "$$GITHUB_TOKEN" ]; then \
		echo "⚠️  警告: GITHUB_TOKEN 未设置，release lane 需要此环境变量"; \
		echo "   设置方法: export GITHUB_TOKEN=your_token"; \
		read -p "是否继续？(y/N): " -n 1 -r; \
		echo; \
		if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then exit 1; fi; \
	fi
	@export LC_ALL=en_US.UTF-8 && fastlane mac release_post_dmg || (echo "❌ Release 流程失败" && exit 1)


