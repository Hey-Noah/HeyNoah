// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject var settingsManager = SettingsManager()
    @StateObject var services = SharedServices() // Added services instance
    @State var isLoading: Bool = true
    @State var isPanelCollapsed: Bool = true
    @State var viewKey: UUID = UUID() // Added viewKey instance

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Requesting Permissions...")
                        .padding()
                        .onAppear {
                            print("ContentView appeared - requesting permissions")
                            services.speechService.requestAllPermissions { granted in
                                DispatchQueue.main.async {
                                    print("Permissions granted: \(granted)")
                                    if granted {
                                        isLoading = false
                                    } else {
                                        print("Permissions were not granted.")
                                    }
                                }
                            }
                        }
                } else {
                    VStack {
                        TranscriptionView(settingsManager: settingsManager)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(settingsManager.isDarkMode ? Color.black : Color.white)
                            .cornerRadius(16)
                            .clipped()
                            .onAppear {
                                updateColorScheme()
                            }
                        if !isPanelCollapsed {
                            SettingsView(settingsManager: settingsManager, isPanelCollapsed: $isPanelCollapsed)
                                .frame(maxWidth: .infinity)
                                .background(settingsManager.isDarkMode ? Color.black : Color.white)
                                .cornerRadius(16)
                                .shadow(radius: 10)
                                .transition(.move(edge: .bottom))
                                .padding()
                                .onAppear {
                                    updateColorScheme()
                                }
                        }
                    }
                    .background(settingsManager.isDarkMode ? Color.black : Color.white)
                    .onAppear {
                        updateColorScheme()
                    }
                }
                Button(action: {
                    print("Toggling settings panel visibility")
                    isPanelCollapsed.toggle()
                }) {
                    Image(systemName: "gear")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .padding()
                }
            }
            .background(settingsManager.isDarkMode ? Color.black : Color.white)
            .onAppear {
                updateColorScheme()
            }
        }
    }

    private func updateColorScheme() {
        let newColorScheme: UIUserInterfaceStyle = settingsManager.isDarkMode ? .dark : .light
        print("Updating color scheme to: \(newColorScheme == .dark ? "Dark Mode" : "Light Mode")")
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.overrideUserInterfaceStyle = newColorScheme
        }
    }

    private func gracefullyReinitializeView() {
        // Add guardrails to prevent runtime exceptions during rotation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("Gracefully reinitializing view")
            services.speechService.stopAudioEngineSafely()  // Stop the audio engine before reinitializing the view
            viewKey = UUID()  // Trigger a reinitialization of the view with a new key
        }
    }

    private func startSpeechService() {
        print("Starting speech service transcription")
        services.speechService.startTranscription { result, error in
            if let error = error {
                print("Error starting transcription: \(error.localizedDescription)")
            } else if let result = result {
                print("Transcription result: \(result)")
            }
        }
    }

    private func stopSpeechServiceBeforeNavigation() {
        print("Stopping speech service before navigation")
        services.speechService.stopAudioEngineSafely()
    }

    private func restartSpeechServiceWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("Restarting speech service with delay")
            services.speechService.stopAudioEngineSafely()  // Ensure the engine is stopped before starting again
            startSpeechService()
        }
    }
}
