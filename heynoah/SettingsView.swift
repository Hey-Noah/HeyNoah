
// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var useBluetoothMic: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            (settingsManager.isDarkMode ? Color.black : Color.white)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text("Font Size")
                    .font(.system(size: settingsManager.fontSize))
                    .foregroundColor(settingsManager.isDarkMode ? .white : .black)
                    .padding(.bottom, 4)
                Slider(value: $settingsManager.fontSize, in: 32...128, step: 2)
                    .padding()
                HStack {
                    Toggle(isOn: $settingsManager.isDarkMode) {
                        Text("Dark Mode")
                            .foregroundColor(settingsManager.isDarkMode ? .white : .black)
                    }
                    .padding()
                    Spacer()
                }
                TextField("Enter Custom Name", text: $settingsManager.customName)
                    .padding()
                    .background(settingsManager.isDarkMode ? Color.gray.opacity(0.2) : Color.white)
                    .cornerRadius(8)
                    .foregroundColor(settingsManager.isDarkMode ? .white : .black)
                Toggle(isOn: $useBluetoothMic) {
                    Text("Use Bluetooth Mic")
                        .foregroundColor(settingsManager.isDarkMode ? .white : .black)
                }
                .padding()
                
                .padding()
            }
            .padding()
            .onAppear {
                updateColorScheme()
            }
        }
    }

    private func updateColorScheme() {
        let newColorScheme: UIUserInterfaceStyle = settingsManager.isDarkMode ? .dark : .light
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.overrideUserInterfaceStyle = newColorScheme
        }
    }
}
