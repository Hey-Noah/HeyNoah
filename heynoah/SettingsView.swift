import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                (settingsManager.isDarkMode ? Color.black : Color.white)
                    .edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack {
                        Text("Font Size")
                            .font(.system(size: settingsManager.fontSize))
                            .foregroundColor(settingsManager.isDarkMode ? .white : .black)
                            .padding(.bottom, 4)
                        Slider(value: $settingsManager.fontSize, in: 32...(UIDevice.current.userInterfaceIdiom == .phone ? 128 : 256), step: 2)
                            .padding()
                        HStack {
                            Toggle(isOn: $settingsManager.isDarkMode) {
                                Text("Dark Mode")
                                    .foregroundColor(settingsManager.isDarkMode ? .white : .black)
                            }
                            .padding()
                            Spacer()
                        }
                        HStack {
                            Toggle(isOn: $settingsManager.isKidModeEnabled) {
                                Text("Kid Mode 🌈🏁")
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
                            .frame(maxWidth: geometry.size.width * 0.9)
                    }
                    .padding()
                    .frame(maxWidth: geometry.size.width * 0.9)
                    .background(settingsManager.isDarkMode ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
                    .cornerRadius(16)
                    .onAppear {
                        updateColorScheme()
                    }
                }
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
