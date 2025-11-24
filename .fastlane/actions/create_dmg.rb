module Fastlane
  module Actions
    module SharedValues
      DMG_PATH = :DMG_PATH
    end

    class CreateDmgAction < Action
      def self.run(params)
        app_path = params[:app_path]
        dmg_name = params[:dmg_name]
        output_dir = params[:output_directory] || "."
        background_image = params[:background_image]
        
        UI.message("Creating DMG for #{app_path}")
        
        # 验证 app 路径
        unless File.exist?(app_path)
          UI.user_error!("App not found at: #{app_path}")
        end
        
        # 创建临时目录
        temp_dir = File.join(output_dir, "temp_dmg")
        FileUtils.mkdir_p(temp_dir)
        
        begin
          # 复制 app 到临时目录
          app_name = File.basename(app_path)
          dest_app_path = File.join(temp_dir, app_name)
          FileUtils.cp_r(app_path, dest_app_path)
          
          # 创建 Applications 符号链接
          FileUtils.ln_s("/Applications", File.join(temp_dir, "Applications"))
          
          # 复制背景图片（如果存在）
          if background_image && File.exist?(background_image)
            FileUtils.cp(background_image, File.join(temp_dir, ".background.png"))
          end
          
          # 创建 DMG
          dmg_path = File.join(output_dir, dmg_name)
          volname = File.basename(app_name, ".app")
          
          # 删除已存在的 DMG
          FileUtils.rm_f(dmg_path)
          
          # 使用 hdiutil 创建 DMG
          sh("hdiutil create -volname '#{volname}' -srcfolder '#{temp_dir}' -ov -format UDZO -imagekey zlib-level=9 '#{dmg_path}'")
          
          UI.success("DMG created successfully: #{dmg_path}")
          
          # 设置返回值
          Actions.lane_context[SharedValues::DMG_PATH] = dmg_path
          
          return dmg_path
        ensure
          # 清理临时文件
          FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
        end
      end

      def self.description
        "Create a DMG file from an app bundle"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :app_path,
            description: "Path to the .app bundle",
            verify_block: proc do |value|
              UI.user_error!("No app_path given") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :dmg_name,
            description: "Name of the output DMG file",
            verify_block: proc do |value|
              UI.user_error!("No dmg_name given") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :output_directory,
            description: "Directory where the DMG will be created",
            default_value: "."
          ),
          FastlaneCore::ConfigItem.new(
            key: :background_image,
            description: "Path to background image for DMG",
            optional: true
          )
        ]
      end

      def self.output
        [
          ['DMG_PATH', 'Path to the created DMG file']
        ]
      end

      def self.authors
        ["Vibeviewer"]
      end

      def self.is_supported?(platform)
        platform == :mac
      end
    end
  end
end

