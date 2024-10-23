import SwiftUI

struct ContentView: View {
    @StateObject var settingsManager = SettingsManager()
    @StateObject var services = SharedServices() // Added services instance
    @State var isLoading: Bool = false
    @State var viewKey: UUID = UUID() // Added viewKey instance
    @State var showWelcomeScreen: Bool = !UserDefaults.standard.bool(forKey: "permissionsRequested") // Check if permissions were requested before

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    if showWelcomeScreen {
                        WelcomeScreen(showWelcomeScreen: $showWelcomeScreen)
                            .onDisappear {
                                requestPermissions()
                            }
                            .frame(width: min(geometry.size.width, 600), height: geometry.size.height) // Limit maximum width to 600
                            .background(settingsManager.isDarkMode ? Color.black : Color.white)
                            .edgesIgnoringSafeArea(.all)
                            .frame(maxWidth: .infinity, alignment: .center) // Center the content
                    } else if isLoading {
                        ProgressView("Requesting Permissions...")
                            .padding()
                            .background(settingsManager.isDarkMode ? Color.black : Color.white)
                            .foregroundColor(settingsManager.isDarkMode ? Color.white : Color.black)
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // Center the content
                    } else {
                        VStack {
                            TranscriptionView(settingsManager: settingsManager, speechService: services.speechService, notificationService: services.notificationService)
                                .frame(maxWidth: min(geometry.size.width, 800), maxHeight: .infinity) // Limit maximum width to 800
                                .background(settingsManager.isDarkMode ? Color.black : Color.white)
                                .cornerRadius(16)
                                .clipped()
                                .onAppear {
                                    updateColorScheme()
                                }

                            Spacer()

                            NavigationLink(destination: SettingsView(settingsManager: settingsManager)) {
                                Image(systemName: "gear")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .padding()
                                    .foregroundColor(settingsManager.isDarkMode ? Color.white : Color.black)
                            }
                            .padding(.bottom, 20)
                        }
                        .frame(maxWidth: min(geometry.size.width, 800), maxHeight: geometry.size.height) // Limit maximum width to 800
                        .background(settingsManager.isDarkMode ? Color.black : Color.white)
                        .onAppear {
                            updateColorScheme()
                        }
                        .edgesIgnoringSafeArea(.all)
                        .frame(maxWidth: .infinity, alignment: .center) // Center the content
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(settingsManager.isDarkMode ? Color.black : Color.white)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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

    private func requestPermissions() {
        isLoading = true
        services.speechService.requestAllPermissions { granted in
            DispatchQueue.main.async {
                print("Permissions granted: \(granted)")
                if granted {
                    isLoading = false
                    UserDefaults.standard.set(true, forKey: "permissionsRequested") // Save that permissions were requested
                } else {
                    print("Permissions were not granted.")
                    isLoading = false
                }
            }
        }
    }

    private func startSpeechService() {
        print("Starting speech service transcription")
        services.speechService.startTranscription { result, error in
            if let error = error {
                print("Error starting transcription: \(error.localizedDescription)")
                isLoading = false
            } else if let result = result {
                print("Transcription result: \(result)")
                isLoading = false
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
