// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Binding var isDarkMode: Bool
    @Binding var fontSize: CGFloat
    @Binding var customName: String

    var body: some View {
        VStack {
            Slider(value: $fontSize, in: 16...64, step: 1)
                .padding()
            HStack {
                Toggle(isOn: $isDarkMode) {
                    Text("Dark Mode")
                }
                .padding()
                Spacer()
            }
            TextField("Custom Name", text: $customName)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .onAppear {
            let newColorScheme: UIUserInterfaceStyle = isDarkMode ? .dark : .light
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.first?.overrideUserInterfaceStyle = newColorScheme
            }
        }
    }
}
