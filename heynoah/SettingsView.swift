// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Binding var isDarkMode: Bool
    @Binding var fontSize: CGFloat
    @Binding var customName: String
    @Binding var isPanelCollapsed: Bool

    var body: some View {
        VStack {
            Text("Font Size")
                .foregroundColor(isDarkMode ? .white : .black)
                .padding(.bottom, 4)
            Slider(value: $fontSize, in: 32...128, step: 2)
                .padding()
            HStack {
                Toggle(isOn: $isDarkMode) {
                    Text("Dark Mode")
                        .foregroundColor(isDarkMode ? .white : .black)
                }
                .padding()
                Spacer()
            }
            TextField("Enter Custom Name", text: $customName)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button(action: {
                withAnimation {
                    isPanelCollapsed = true
                }
            }) {
                Text("Hide Settings")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding()
        }
        .background(isDarkMode ? Color.black : Color.white)
        .cornerRadius(16)
        .onAppear {
            updateColorScheme()
        }
    }

    private func updateColorScheme() {
        let newColorScheme: UIUserInterfaceStyle = isDarkMode ? .dark : .light
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.overrideUserInterfaceStyle = newColorScheme
        }
    }
}
