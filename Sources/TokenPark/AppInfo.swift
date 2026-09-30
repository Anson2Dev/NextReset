import Foundation
import AppKit

enum AppInfo {
    static let icon: NSImage = {
        guard let url=Bundle.main.url(forResource:"AppIcon",withExtension:"icns"),
              let image=NSImage(contentsOf:url) else { return NSImage() }
        return image
    }()
    static let name = "NextReset@TokenPark"
    static let version = "0.2.1"
    static let website = URL(string: "https://nextreset.tokenpark.org")!
    static let github = URL(string: "https://github.com/Anson2Dev/NextReset")!
    static let authorWebsite = URL(string: "https://anson.im")!
    static let authorEmail = URL(string: "mailto:anson@bestapp.us")!
}
