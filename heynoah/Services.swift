import Foundation
import UserNotifications
import Combine
import Speech
import AVFoundation
import AVFAudio
import Combine

class SharedServices: ObservableObject {
    @Published var speechService = SpeechService()
    @Published var notificationService = NotificationService()
    @Published var settingsManager = SettingsManager() // Added settingsManager to SharedServices
}


class SettingsManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var fontSize: CGFloat = 64
    @Published var customName: String = "Noah"
}


class NotificationService: ObservableObject {
    private let notificationCenter = UNUserNotificationCenter.current()
    private var hasRequestedAuthorization = false
    private var lastNotificationTime: Date?
    private let notificationCooldown: TimeInterval = 5.0 // Cooldown period to avoid duplicate notifications

    func isNotificationPending(identifier: String, completion: @escaping (Bool) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            let isPending = requests.contains { $0.identifier == identifier }
            DispatchQueue.main.async {
                print("Checked if notification is pending: \(isPending)")
                completion(isPending)
            }
        }
    }

    func requestNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        guard !hasRequestedAuthorization else {
            // If already requested, check current settings
            notificationCenter.getNotificationSettings { settings in
                let granted = settings.authorizationStatus == .authorized
                DispatchQueue.main.async {
                    print("Notification settings checked - authorization granted: \(granted)")
                    completion(granted)
                }
            }
            return
        }

        print("Requesting notification authorization")
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error requesting notification authorization: \(error.localizedDescription)")
                }
                if granted {
                    print("Notification authorization granted")
                } else {
                    print("Notification authorization denied")
                }
                self?.hasRequestedAuthorization = true
                completion(granted)
            }
        }
    }

    func sendLocalNotification(title: String, identifier: String) {
        let currentTime = Date()
        if let lastTime = lastNotificationTime, currentTime.timeIntervalSince(lastTime) < notificationCooldown {
            print("Notification skipped due to cooldown period")
            return
        }
        lastNotificationTime = currentTime

        requestNotificationAuthorization { [weak self] granted in
            guard granted else {
                print("Notification permission not granted. Cannot send notification.")
                return
            }
            print("Sending local notification: \(title)")
            let content = UNMutableNotificationContent()
            content.title = title
            content.sound = .default
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
            self?.notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to add notification request: \(error.localizedDescription)")
                } else {
                    print("Notification request added successfully")
                }
            }
        }
    }
}



