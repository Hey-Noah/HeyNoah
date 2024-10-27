// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(settingsManager.isDarkMode ? .black : .white)
                    .animation(.easeInOut(duration: 0.3), value: settingsManager.isDarkMode)
                    .onChange(of: settingsManager.isDarkMode) { _ in updateColorScheme() }

                ScrollView {
                    VStack {
                        Spacer()

                        VStack(spacing: 20) {
                            Text("Font Size")
                                .font(.system(size: settingsManager.fontSize))
                                .foregroundColor(Color(settingsManager.isDarkMode ? .white : .black))
                                .animation(.easeInOut(duration: 0.3), value: settingsManager.isDarkMode)

                            Slider(value: $settingsManager.fontSize, in: 32...(UIDevice.current.userInterfaceIdiom == .phone ? 128 : 256), step: 2)
                                .padding(.horizontal)

                            HStack {
                                Toggle(isOn: $settingsManager.isDarkMode) {
                                    Text("Dark Mode")
                                        .foregroundColor(settingsManager.isDarkMode ? .white : .black)
                                        .animation(.easeInOut(duration: 0.3), value: settingsManager.isDarkMode)
                                }
                                .padding(.horizontal)
                                Spacer()
                            }

                            HStack {
                                Toggle(isOn: $settingsManager.isKidModeEnabled) {
                                    Text("Kid Mode 🌈🏁")
                                        .foregroundColor(settingsManager.isDarkMode ? .white : .black)
                                        .animation(.easeInOut(duration: 0.3), value: settingsManager.isDarkMode)
                                }
                                .padding(.horizontal)
                                Spacer()
                            }

                            HStack(alignment: .center) {
                                Text("Custom Name:")
                                    .foregroundColor(settingsManager.isDarkMode ? .white : .black)
                                    .animation(.easeInOut(duration: 0.3), value: settingsManager.isDarkMode)
                                TextField("Your name?", text: $settingsManager.customName)
                                    .font(.system(size: 24))
                                    .padding()
                                    .background(settingsManager.isDarkMode ? Color.gray.opacity(0.2) : Color.white)
                                    .cornerRadius(8)
                                    .foregroundColor(settingsManager.isDarkMode ? .white : .black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(settingsManager.isDarkMode ? Color.white.opacity(0.9) : Color.black.opacity(0.9), lineWidth: 2)
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: settingsManager.isDarkMode)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(Color(settingsManager.isDarkMode ? .black : .white).opacity(0.8))
                    .onChange(of: settingsManager.isDarkMode) { _ in updateColorScheme() }
                        .cornerRadius(16)
                        .animation(.easeInOut(duration: 0.3), value: settingsManager.isDarkMode)

                        Spacer()

                        Text("Made with ♥ in Silver Spring, MD")
                            .font(.footnote)
                            .foregroundColor(settingsManager.isDarkMode ? Color.white.opacity(0.3) : Color.black.opacity(0.3))
                            .padding(.top, 20)
                            .animation(.easeInOut(duration: 0.3), value: settingsManager.isDarkMode)
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                    .onAppear {
                        updateColorScheme()
                    }
                }
                .overlay(alignment: .bottom) {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "checkmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                                .foregroundColor(settingsManager.isDarkMode ? .white : .black)
                                .animation(.easeInOut(duration: 0.3), value: settingsManager.isDarkMode)
                        }
                        Spacer()
                        Image(systemName: "mic.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 30)
                            .foregroundColor(settingsManager.microphoneColor)
                            .animation(.easeInOut(duration: 1.0), value: settingsManager.microphoneColor)
                    }
                    .padding()
                    .background(settingsManager.isDarkMode ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
                    .ignoresSafeArea(edges: .bottom)
                    .animation(.easeInOut(duration: 0.3), value: settingsManager.isDarkMode)
                }
            }
            .navigationBarBackButtonHidden(true) // Hides the default back button
        }
    }

    private func updateColorScheme() {
        let newColorScheme: UIUserInterfaceStyle = settingsManager.isDarkMode ? .dark : .light
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.overrideUserInterfaceStyle = newColorScheme
        }
    }
}
