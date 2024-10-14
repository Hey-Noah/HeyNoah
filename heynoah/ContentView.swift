
// ContentView.swift
import SwiftUI

struct ContentView: View {
    @State var isDarkMode: Bool = false
    @State var fontSize: CGFloat = 64
    @State var customName: String = "Noah"
    @StateObject var services = SharedServices()
    @State var isLoading: Bool = true
    @State var isPanelCollapsed: Bool = true
    @State var viewKey: UUID = UUID()  // Used to reinitialize the view

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView("Requesting Permissions...")
                        .padding()
                } else {
                    VStack(spacing: 0) {
                        TranscriptionView(fontSize: $fontSize, customName: $customName, speechService: services.speechService, notificationService: services.notificationService)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(isDarkMode ? Color.black : Color.white)
                            .cornerRadius(16)
                            .clipped()
                            .padding(.top, geometry.safeAreaInsets.top)
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                        if !isPanelCollapsed {
                            SettingsView(isDarkMode: $isDarkMode, fontSize: $fontSize, customName: $customName, isPanelCollapsed: $isPanelCollapsed)
                                .frame(maxWidth: .infinity)
                                .background(isDarkMode ? Color.black : Color.white)
                                .cornerRadius(16)
                                .shadow(radius: 10)
                                .transition(.move(edge: .bottom))
                                .padding()
                        }
                    }
                    Button(action: {
                        withAnimation {
                            isPanelCollapsed.toggle()
                        }
                    }) {
                        Image(systemName: "gear")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .padding()
                    }
                    .padding()
                }
            }
            .background(isDarkMode ? Color.black : Color.white)
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                services.speechService.requestAllPermissions { granted in
                    DispatchQueue.main.async {
                        isLoading = !granted
                    }
                }
                updateColorScheme()
            }
            .id(viewKey)  // Reinitialize view using this key
            .onRotate { _ in
                gracefullyReinitializeView()
            }
        }
    }

    private func updateColorScheme() {
        let newColorScheme: UIUserInterfaceStyle = isDarkMode ? .dark : .light
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.overrideUserInterfaceStyle = newColorScheme
        }
    }

    private func gracefullyReinitializeView() {
        // Add guardrails to prevent runtime exceptions during rotation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            services.speechService.stopAudioEngineSafely()  // Stop the audio engine before reinitializing the view
            viewKey = UUID()  // Trigger a reinitialization of the view with a new key
        }
    }
}
