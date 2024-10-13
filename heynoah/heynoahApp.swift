import SwiftUI
import UIKit
import Speech
import UserNotifications

@main
struct HeyNoahApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class SharedServices: ObservableObject {
    @Published var speechService = SpeechService()
    @Published var notificationService = NotificationService()
}

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
                        VStack {
                            Slider(value: $fontSize, in: 16...64, step: 1)
                                .padding()
                            HStack {
                                Toggle(isOn: $isDarkMode) {
                                    Text("Dark Mode")
                                }
                                .padding()
                                .onChange(of: isDarkMode) { value in
                                    let newColorScheme: UIUserInterfaceStyle = value ? .dark : .light
                                    UIApplication.shared.windows.first?.overrideUserInterfaceStyle = newColorScheme
                                }
                                Spacer()
                            }
                            TextField("Custom Name", text: $customName)
                                .padding()
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
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

struct TranscriptionView: UIViewControllerRepresentable {
    @Binding var fontSize: CGFloat
    @Binding var customName: String
    @ObservedObject var speechService: SpeechService
    @ObservedObject var notificationService: NotificationService

    func makeUIViewController(context: Context) -> TranscriptionViewController {
        let controller = TranscriptionViewController(speechService: speechService, notificationService: notificationService)
        controller.fontSize = fontSize
        controller.customName = customName
        return controller
    }

    func updateUIViewController(_ uiViewController: TranscriptionViewController, context: Context) {
        uiViewController.updateFontSize(fontSize)
        uiViewController.customName = customName
    }
}

class TranscriptionViewController: UIViewController {
    private let transcriptionLabel = UILabel()
    var fontSize: CGFloat = 32
    var customName: String = "Noah"
    private var speechService: SpeechService
    private var notificationService: NotificationService

    init(speechService: SpeechService, notificationService: NotificationService) {
        self.speechService = speechService
        self.notificationService = notificationService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad called")
        setupTranscriptionLabel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.speechService.startTranscription { [weak self] transcription, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Transcription error: \(error.localizedDescription)")
                        self?.transcriptionLabel.text = "Error: \(error.localizedDescription)"
                        return
                    }
                    if let transcription = transcription {
                        print("Transcription: \(transcription)")
                        self?.transcriptionLabel.text = transcription
                        if transcription.localizedCaseInsensitiveContains(self?.customName ?? "Noah") && !(self?.notificationService.isNotificationPending(identifier: "NoahNotification") ?? false) {
                            self?.notificationService.sendNotification(title: "Someone is speaking to you, \(self?.customName ?? "Noah")!", identifier: "NoahNotification")
                        }
                    }
                }
            }
        }
    }

    private func setupTranscriptionLabel() {
        print("Setting up transcription label")
        transcriptionLabel.frame = view.bounds
        transcriptionLabel.font = UIFont.systemFont(ofSize: fontSize)
        transcriptionLabel.textAlignment = .center
        transcriptionLabel.numberOfLines = 0
        transcriptionLabel.text = "Listening..."
        view.addSubview(transcriptionLabel)
    }

    func updateFontSize(_ size: CGFloat) {
        transcriptionLabel.font = UIFont.systemFont(ofSize: size)
    }
}

class SpeechService: NSObject, SFSpeechRecognizerDelegate, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var request = SFSpeechAudioBufferRecognitionRequest()
    private var recognitionTask: SFSpeechRecognitionTask?

    func requestAllPermissions(completion: @escaping (Bool) -> Void) {
        print("Requesting all permissions")
        requestMicrophoneAccess { microphoneGranted in
            guard microphoneGranted else {
                print("Microphone access not granted")
                completion(false)
                return
            }
            self.requestSpeechAuthorization { speechAuthorized in
                guard speechAuthorized else {
                    print("Speech authorization not granted")
                    completion(false)
                    return
                }
                print("All permissions granted")
                completion(true)
            }
        }
    }

    func requestMicrophoneAccess(completion: @escaping (Bool) -> Void) {
        print("Requesting microphone access")
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("Microphone access granted")
                } else {
                    print("Microphone access denied")
                }
                completion(granted)
            }
        }
    }

    func requestSpeechAuthorization(completion: @escaping (Bool) -> Void) {
        print("Requesting speech authorization")
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                    completion(true)
                default:
                    print("Speech recognition not authorized")
                    completion(false)
                }
            }
        }
    }

    func startTranscription(completion: @escaping (String?, Error?) -> Void) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer not available")
            completion(nil, NSError(domain: "SpeechService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"]))
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            print("Configuring audio session")
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session configured successfully")
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
            completion(nil, error)
            return
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode

        recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                print("Recognition task error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            if let result = result {
                print("Recognition task result: \(result.bestTranscription.formattedString)")
                completion(result.bestTranscription.formattedString, nil)
                if result.isFinal {
                    inputNode.removeTap(onBus: 0)
                    self.audioEngine.stop()
                    self.request.endAudio()
                }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }

        do {
            print("Preparing and starting audio engine")
            try audioEngine.prepare()
            try audioEngine.start()
            print("Audio engine started successfully")
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
            completion(nil, error)
        }
    }
}

class NotificationService: ObservableObject {
    func isNotificationPending(identifier: String) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var isPending = false
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            isPending = requests.contains { $0.identifier == identifier }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 1)
        return isPending
    }

    func requestNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        print("Requesting notification authorization")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error requesting notification authorization: \(error.localizedDescription)")
                }
                if granted {
                    print("Notification authorization granted")
                } else {
                    print("Notification authorization denied")
                }
                completion(granted)
            }
        }
    }

    func sendNotification(title: String, identifier: String) {
        print("Sending notification: \(title)")
        let content = UNMutableNotificationContent()
        content.title = title
        content.sound = .default
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to add notification request: \(error.localizedDescription)")
            } else {
                print("Notification request added successfully")
            }
        }
    }
}

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("App launched")
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Notification will present: \(notification.request.content.title)")
        completionHandler([.alert, .sound])
    }
}
