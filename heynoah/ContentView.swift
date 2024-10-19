
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
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    if isLoading {
                        ProgressView("Requesting Permissions...")
                            .padding()
                    } else {
                        VStack(spacing: 0) {
                            TranscriptionView(fontSize: $fontSize, customName: $customName, services: services)
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
                            stopSpeechServiceBeforeNavigation()  // Stop the speech service before navigating
                            viewKey = UUID()  // Destroy the current view
                        }) {
                            NavigationLink(destination: SettingsView(isDarkMode: $isDarkMode, fontSize: $fontSize, customName: $customName, isPanelCollapsed: $isPanelCollapsed).onDisappear {
                                restartSpeechServiceWithDelay()
                            }) {
                                Image(systemName: "gear")
                                    .resizable()
                                    .frame(width: 36, height: 36)
                                    .padding()
                            }
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
                            if granted {
                                startSpeechService()
                            }
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
        .navigationViewStyle(StackNavigationViewStyle())
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

    private func startSpeechService() {
        services.speechService.startTranscription { result, error in
            if let error = error {
                print("Error starting transcription: \(error.localizedDescription)")
            } else if let result = result {
                print("Transcription result: \(result)")
            }
        }
    }

    private func stopSpeechServiceBeforeNavigation() {
        services.speechService.stopAudioEngineSafely()
    }

    private func restartSpeechServiceWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            services.speechService.stopAudioEngineSafely()  // Ensure the engine is stopped before starting again
            startSpeechService()
        }
    }
}
