// TranscriptionViewController.swift
import UIKit
import AVFoundation

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
        configureAudioSessionForBackground()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.speechService.startTranscription { [weak self] transcription, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let error = error {
                        print("Transcription error: \(error.localizedDescription)")
                        self.transcriptionLabel.text = "Error: \(error.localizedDescription)"
                        return
                    }
                    if let transcription = transcription {
                        print("Transcription: \(transcription)")
                        self.transcriptionLabel.text = transcription
                        if transcription.localizedCaseInsensitiveContains(self.customName) {
                            self.notificationService.isNotificationPending(identifier: "NoahNotification") { [weak self] isPending in
                                guard let self = self else { return }
                                if !isPending {
                                    self.notificationService.sendLocalNotification(title: "Someone is speaking to you, \(self.customName)!", identifier: "NoahNotification")
                                }
                            }
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

    private func configureAudioSessionForBackground() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            print("Audio session configured for background use")
        } catch {
            print("Failed to configure audio session for background: \(error.localizedDescription)")
        }
    }

    func updateFontSize(_ size: CGFloat) {
        transcriptionLabel.font = UIFont.systemFont(ofSize: size)
    }
}
