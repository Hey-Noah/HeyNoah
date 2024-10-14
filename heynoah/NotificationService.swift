
// NotificationService.swift
import Foundation
import UserNotifications
import Combine

class NotificationService: ObservableObject {
    private let notificationCenter = UNUserNotificationCenter.current()
    private var hasRequestedAuthorization = false

    func isNotificationPending(identifier: String, completion: @escaping (Bool) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            let isPending = requests.contains { $0.identifier == identifier }
            DispatchQueue.main.async {
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
                    completion(granted)
                }
            }
            return
        }

        print("Requesting notification authorization")
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
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
        requestNotificationAuthorization { [weak self] granted in
            guard granted else {
                print("Notification permission not granted. Cannot send notification.")
                return
            }
            print("Sending local notification: \(title)")
            let content = UNMutableNotificationContent()
            content.title = title
            content.sound = .default
            content.badge = NSNumber(value: 1)
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
