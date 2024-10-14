import SwiftUI
import UIKit
import Speech
import UserNotifications

@main
struct HeyNoahApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
