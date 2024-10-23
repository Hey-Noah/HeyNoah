import SwiftUI

struct WelcomeScreen: View {
    @Binding var showWelcomeScreen: Bool
    @State private var isCheckboxChecked: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // App Icon Image and Welcome Message in the same container
            VStack(spacing: 10) {
                Image("Image") // Replace "AppIcon" with the actual name of your image asset
                    .resizable()
                    .frame(width: iconSize().width, height: iconSize().height)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.top, 40)

                Text("Welcome to Hey Noah!")
                    .font(.system(size: fontSize(for: .title)))
                    .fontWeight(.bold)
                    .padding(.top)
                    .multilineTextAlignment(textAlignment())
            }
            .padding(.horizontal)
            .padding(.top, 40) // Additional padding to handle iPhone notch

            // Thank You Message
            Text("Thank you for downloading Hey Noah! We are excited to have you on board.")
                .font(.system(size: fontSize(for: .body)))
                .multilineTextAlignment(textAlignment())
                .padding(.horizontal)

            // Introduction Bullet Points
            VStack(alignment: textAlignment() == .center ? .center : .leading, spacing: 10) {
                Text("🛡️ Privacy-conscious live transcription app.")
                    .font(.system(size: fontSize(for: .body)))
                Text("💬 Great for reading what people in the room are saying in real time.")
                    .font(.system(size: fontSize(for: .body)))
                Text("⚙️ Customizable features: font size, dark mode, and kid mode.")
                    .font(.system(size: fontSize(for: .body)))
                Text("🔔 Notifications when your chosen name is heard (default: Noah).")
                    .font(.system(size: fontSize(for: .body)))
            }
            .padding(.horizontal)

            // Playful Suggestion About Customization
            Text("Not named Noah? No worries! You can change it by tapping the \(Image(systemName: "gear")) icon.")
                .font(.system(size: fontSize(for: .body)))
                .multilineTextAlignment(textAlignment())
                .padding(.horizontal)

            Spacer()

            // Note and Checkbox
            VStack(alignment: .center, spacing: 20) {
                Text("Note: After pressing 'Get Started', you will be prompted for a few permissions required for the proper function of the app.")
                    .font(.system(size: fontSize(for: .headline)))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .fixedSize(horizontal: false, vertical: true) // Ensure the note wraps and is always visible

                HStack {
                    Button(action: {
                        isCheckboxChecked.toggle()
                    }) {
                        Image(systemName: isCheckboxChecked ? "checkmark.square.fill" : "square")
                            .font(.system(size: 64))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("Got it 👍")
                        .font(.system(size: 64))
                }
                .padding(.horizontal)
            }

            // Get Started Button
            Button(action: {
                showWelcomeScreen = false
            }) {
                Text("Get Started")
                    .font(.system(size: fontSize(for: .headline)))
                    .padding()
                    .frame(maxWidth: 300) // Set a sensible max width for larger screens
                    .background(isCheckboxChecked ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
            .disabled(!isCheckboxChecked)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.3))
        .edgesIgnoringSafeArea(.all) // Ensures the view takes up the full screen
    }

    private func fontSize(for style: FontStyle) -> CGFloat {
        switch style {
        case .title:
            return UIDevice.current.userInterfaceIdiom == .pad ? 40 : 30
        case .body:
            return UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16
        case .headline:
            return UIDevice.current.userInterfaceIdiom == .pad ? 28 : 18
        }
    }

    private func iconSize() -> CGSize {
        return UIDevice.current.userInterfaceIdiom == .pad ? CGSize(width: 150, height: 150) : CGSize(width: 100, height: 100)
    }

    private func textAlignment() -> TextAlignment {
        return UIDevice.current.userInterfaceIdiom == .pad ? .center : .leading
    }

    private enum FontStyle {
        case title, body, headline
    }
}
