import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var fontSize: CGFloat = 64
    @Published var customName: String = "Noah"
}
