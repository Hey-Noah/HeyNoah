
// SharedServices.swift
import Combine

class SharedServices: ObservableObject {
    @Published var speechService = SpeechService()
    @Published var notificationService = NotificationService()
}

