
// ContentView.swift
import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var isDarkMode: Bool = false
    @State var fontSize: CGFloat = 32
    @State var customName: String = "Noah"
    @StateObject var services = SharedServices()
    @State var isLoading: Bool = true
    @State var isPanelCollapsed: Bool = true

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Requesting Permissions...")
                    .padding()
            } else {
                TranscriptionView(fontSize: $fontSize, customName: $customName, speechService: services.speechService, notificationService: services.notificationService)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Button(action: {
                        withAnimation {
                            isPanelCollapsed.toggle()
                        }
                    }) {
                        Image(systemName: "gear")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    if !isPanelCollapsed {
                        SettingsView(isDarkMode: $isDarkMode, fontSize: $fontSize, customName: $customName)
                            .transition(.slide)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            services.speechService.requestAllPermissions { granted in
                DispatchQueue.main.async {
                    isLoading = !granted
                }
            }
        }
    }
}
