import SwiftUI

struct ContentView: View {
    @StateObject var settingsManager = SettingsManager()
    @StateObject var services = SharedServices()
    @State var isLoading: Bool = false
    @State var viewKey: UUID = UUID()
    @State var showWelcomeScreen: Bool = !UserDefaults.standard.bool(forKey: "permissionsRequested")

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    if showWelcomeScreen {
                        WelcomeScreen(showWelcomeScreen: $showWelcomeScreen)
                            .onDisappear {
                                requestPermissions()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(settingsManager.isDarkMode ? Color.black : Color.white)
                            .edgesIgnoringSafeArea(.all)
                    } else if isLoading {
                        ProgressView("Requesting Permissions...")
                            .padding()
                            .background(settingsManager.isDarkMode ? Color.black : Color.white)
                            .foregroundColor(settingsManager.isDarkMode ? Color.white : Color.black)
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(settingsManager.isDarkMode ? Color.black : Color.white)
                    } else {
                        VStack {
                            TranscriptionView(settingsManager: settingsManager, speechService: services.speechService, notificationService: services.notificationService)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(settingsManager.isDarkMode ? Color.black : Color.white)
                                .cornerRadius(16)
                                .clipped()
                                .onAppear {
                                    updateColorScheme()
                                }

                            Spacer()

                            HStack {
                                   Spacer()
                                   NavigationLink(destination: SettingsView(settingsManager: settingsManager)) {
                                       Image(systemName: "gear")
                                           .resizable()
                                           .frame(width: 30, height: 30) // Original size for consistency
                                           .padding()
                                           .foregroundColor(settingsManager.isDarkMode ? Color.white : Color.black)
                                   }
                                   Spacer()
                               }
                               .padding(.bottom, 40) // Add padding at the bottom to avoid the home swipe area
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(settingsManager.isDarkMode ? Color.black : Color.white)
                        .onAppear {
                            updateColorScheme()
                        }
                        .edgesIgnoringSafeArea(.all)
                    }
                }
                .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                .background(settingsManager.isDarkMode ? Color.black : Color.white)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Update color scheme on startup for multiplatform support
            updateColorScheme()
        }
    }

    private func updateColorScheme() {
        #if os(iOS)
        let newColorScheme: UIUserInterfaceStyle = settingsManager.isDarkMode ? .dark : .light
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.overrideUserInterfaceStyle = newColorScheme
        }
        #endif
    }

    private func requestPermissions() {
        isLoading = true
        services.speechService.requestAllPermissions { granted in
            DispatchQueue.main.async {
                if granted {
                    isLoading = false
                    UserDefaults.standard.set(true, forKey: "permissionsRequested")
                } else {
                    isLoading = false
                }
            }
        }
    }
}
