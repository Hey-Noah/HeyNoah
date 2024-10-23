import SwiftUI

struct WelcomeScreen: View {
    @Binding var showWelcomeScreen: Bool

    var body: some View {
        VStack(spacing: 20) {
            // App Icon Image
            Image("Image") // Replace "AppIcon" with the actual name of your image asset
                .resizable()
                .frame(width: iconSize().width, height: iconSize().height)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.top, 40)

            // Welcome Message
            Text("Welcome to Hey Noah!")
                .font(.system(size: fontSize(for: .title)))
                .fontWeight(.bold)
                .padding(.top)
                .multilineTextAlignment(textAlignment())

            // Thank You Message
            Text("Thank you for downloading Hey Noah! We are excited to have you on board.")
                .font(.system(size: fontSize(for: .body)))
                .multilineTextAlignment(textAlignment())
                .padding(.horizontal)

            // Introduction Bullet Points
            VStack(alignment: textAlignment() == .center ? .center : .leading, spacing: 10) {
                Text("• Privacy-conscious live transcription app.")
                    .font(.system(size: fontSize(for: .body)))
                Text("• Great for reading what people in the room are saying in real time.")
                    .font(.system(size: fontSize(for: .body)))
                Text("• Customizable features: font size, dark mode, and kid mode.")
                    .font(.system(size: fontSize(for: .body)))
                Text("• Notifications when your chosen name is heard (default: Noah).")
                    .font(.system(size: fontSize(for: .body)))
            }
            .padding(.horizontal)

            // Playful Suggestion About Customization
            Text("Not named Noah? No worries! You can change it by tapping the \(Image(systemName: "gear")) icon.")
                .font(.system(size: fontSize(for: .body)))
                .multilineTextAlignment(textAlignment())
                .padding(.horizontal)

            // Get Started Button
            Button(action: {
                showWelcomeScreen = false
            }) {
                Text("Get Started")
                    .font(.system(size: fontSize(for: .headline)))
                    .padding()
                    .frame(maxWidth: 300) // Set a sensible max width for larger screens
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.3))
        .edgesIgnoringSafeArea(.all) // Ensures the view takes up the full screen
        .onChange(of: UIScreen.main.bounds.size) { _, _ in }
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
