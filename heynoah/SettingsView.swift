
// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Binding var isDarkMode: Bool
    @Binding var fontSize: CGFloat
    @Binding var customName: String
    @Binding var isPanelCollapsed: Bool
    @State private var useBluetoothMic: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            (isDarkMode ? Color.black : Color.white)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text("Font Size")
                    .font(.system(size: fontSize))
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
                    .background(isDarkMode ? Color.gray.opacity(0.2) : Color.white)
                    .cornerRadius(8)
                    .foregroundColor(isDarkMode ? .white : .black)
                Toggle(isOn: $useBluetoothMic) {
                    Text("Use Bluetooth Mic")
                        .foregroundColor(isDarkMode ? .white : .black)
                }
                .padding()
                
                .padding()
            }
            .padding()
            .onAppear {
                updateColorScheme()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ReinitializeContentView"))) { _ in
            DispatchQueue.main.async {
                let rootView = ContentView()
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController = UIHostingController(rootView: rootView)
                    window.makeKeyAndVisible()
                }
            }
        }
    }

    private func updateColorScheme() {
        let newColorScheme: UIUserInterfaceStyle = isDarkMode ? .dark : .light
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.overrideUserInterfaceStyle = newColorScheme
        }
    }
}
