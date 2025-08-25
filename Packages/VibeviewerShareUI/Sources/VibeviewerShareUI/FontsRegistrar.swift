import CoreText
import Foundation

public enum FontsRegistrar {
    /// Registers all font files shipped in the module bundle under `Fonts/`.
    /// Safe to call multiple times; duplicates are ignored by CoreText.
    public static func registerAllFonts() {
        let bundle = Bundle.module
        let subdir = "Fonts"

        let otfURLs = bundle.urls(forResourcesWithExtension: "otf", subdirectory: subdir) ?? []
        let ttfURLs = bundle.urls(forResourcesWithExtension: "ttf", subdirectory: subdir) ?? []
        let urls = otfURLs + ttfURLs

        for url in urls {
            var error: Unmanaged<CFError>?
            // Use process scope so registration lives for the app lifecycle
            let ok = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            if !ok {
                // Ignore already-registered errors; other errors can be logged in debug
                #if DEBUG
                    if let err = error?.takeRetainedValue() {
                        let cfError = err as Error
                        // CFError domain kCTFontManagerErrorDomain code 305 means already registered
                        // We'll just print in debug builds
                        print(
                            "[FontsRegistrar] Font registration error for \(url.lastPathComponent): \(cfError)"
                        )
                    }
                #endif
            }
        }
    }
}
