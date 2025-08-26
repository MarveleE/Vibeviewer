import Foundation
import SwiftUI
import VibeviewerModel

public extension AIModelBrands {
    /// 从 SPM 模块资源中加载图片；macOS 直接以文件 URL 读取 PDF/PNG，避免命名查找失败
    private func moduleImage(_ name: String) -> Image {
        #if canImport(AppKit)
        if let url = Bundle.module.url(forResource: name, withExtension: "pdf"),
           let nsImage = NSImage(contentsOf: url) {
            return Image(nsImage: nsImage)
        }
        if let url = Bundle.module.url(forResource: name, withExtension: "png"),
           let nsImage = NSImage(contentsOf: url) {
            return Image(nsImage: nsImage)
        }
        // 回退占位（确保界面不会空白）
        return Image(systemName: "app")
        #else
        if let url = Bundle.module.url(forResource: name, withExtension: "pdf"),
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        if let url = Bundle.module.url(forResource: name, withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        // 回退占位（确保界面不会空白）
        return Image(systemName: "app")
        #endif
    }

    var logo: Image {
        switch self {
        case .gpt:
            return moduleImage("gpt")
        case .claude:
            return moduleImage("claude")
        case .deepseek:
            return moduleImage("deepseek")
        case .gemini:
            return moduleImage("gemini")
        case .grok:
            return moduleImage("grok")
        case .kimi:
            return moduleImage("kimi")
        case .default:
            return moduleImage("cursor")
        }
    }
}