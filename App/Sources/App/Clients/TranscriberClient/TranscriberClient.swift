import AppDevUtils
import Combine
import ComposableArchitecture
import Dependencies
import Foundation
import os.log

typealias TranscriptionSegment = String
typealias FileName = String

// MARK: - TranscriptionProgress

enum TranscriptionProgress {
  case loadingModel
  case started
  case newSegment(TranscriptionSegment)
  case finished(String)
  case error(Error)
}

// MARK: - TranscriberState

enum TranscriberState: Equatable {
  case idle
  case loadingModel
  case modelLoaded
  case transcribing
  case finished
  case failed(EquatableErrorWrapper)
}

// MARK: - TranscriberError

enum TranscriberError: Error, CustomStringConvertible {
  case couldNotLocateModel
  case modelNotLoaded
  case notEnoughMemory(available: UInt64, required: UInt64)
  case cancelled
}

// MARK: - TranscriptionState

public struct TranscriptionState: Hashable {
  enum State: Hashable { case starting, loadingModel, transcribing }

  var state: State = .starting
  var segments: [TranscriptionSegment] = []
  var finalText: String = ""
}

// MARK: - TranscriberClient

struct TranscriberClient {
  var selectModel: @Sendable (_ model: VoiceModelType) -> Void
  var getSelectedModel: @Sendable () -> VoiceModelType

  var unloadSelectedModel: @Sendable () -> Void

  var transcribeAudio: @Sendable (_ audioURL: URL, _ language: VoiceLanguage) async throws -> String
  var transcriberState: @Sendable () -> TranscriberState

  var transcriptionStateStream: AnyPublisher<[FileName: TranscriptionState], Never>

  var getAvailableLanguages: @Sendable () -> [VoiceLanguage]
}

// MARK: DependencyKey

extension TranscriberClient: DependencyKey {
  static var selectedModel: VoiceModelType {
    get { UserDefaults.standard.selectedModelName.flatMap { VoiceModelType(rawValue: $0) } ?? .default }
    set { UserDefaults.standard.selectedModelName = newValue.rawValue }
  }

  static let liveValue: TranscriberClient = {
    let impl = TranscriberImpl()
    let transcriptionStatesSubject = CurrentValueSubject<[FileName: TranscriptionState], Never>([:])
    let state: CurrentValueSubject<TranscriberState, Never> = CurrentValueSubject(.idle)

    return TranscriberClient(
      selectModel: { model in
        selectedModel = model
      },

      getSelectedModel: {
        if !FileManager.default.fileExists(atPath: selectedModel.localURL.path) {
          selectedModel = .default
        }
        return selectedModel
      },

      unloadSelectedModel: {
        impl.unloadModel()
      },

      transcribeAudio: { audioURL, language in
        let fileName = audioURL.lastPathComponent
        log.verbose("Transcribing \(fileName)...")

        var transcriptionState: TranscriptionState {
          get { transcriptionStatesSubject.value[fileName] ?? TranscriptionState() }
          set { transcriptionStatesSubject.value[fileName] = newValue }
        }

        defer {
          transcriptionStatesSubject.value.removeValue(forKey: fileName)
        }

        transcriptionState.state = .loadingModel
        try await impl.loadModel(model: selectedModel)

        transcriptionState.state = .transcribing
        let text = try await impl.transcribeAudio(audioURL, language: language) { segment in
          transcriptionState.segments.append(segment)
        }

        return text
      },

      transcriberState: { state.value },

      transcriptionStateStream: transcriptionStatesSubject.eraseToAnyPublisher(),

      getAvailableLanguages: {
        [.auto] + WhisperContext.getAvailableLanguages().sorted { $0.name < $1.name }
      }
    )
  }()
}

// MARK: - TranscriberImpl

final class TranscriberImpl {
  private var whisperContext: WhisperContext?
  private var model: VoiceModelType?

  func loadModel(model: VoiceModelType) async throws {
    if whisperContext != nil && model == self.model {
      log.verbose("Model already loaded")
      return
    } else if whisperContext != nil {
      unloadModel()
    }

    let memory = freeMemory()
    log.info("Available memory: \(bytesToReadableString(bytes: availableMemory()))")
    log.info("Free memory: \(bytesToReadableString(bytes: memory))")

    guard memory > model.memoryRequired else {
      throw TranscriberError.notEnoughMemory(available: memory, required: model.memoryRequired)
    }

    self.model = model

    log.verbose("Loading model...")
    whisperContext = try WhisperContext.createContext(path: model.localURL.path)
    log.verbose("Loaded model \(model.fileName)")
  }

  func unloadModel() {
    log.verbose("Unloading model...")
    let tmpContext = whisperContext
    whisperContext = nil
    Task {
      await tmpContext?.unloadContext()
    }
  }

  /// Transcribes the audio file at the given URL.
  /// Model should be loaded
  func transcribeAudio(_ audioURL: URL, language: VoiceLanguage, newSegmentCallback: @escaping (String) -> Void) async throws -> String {
    guard let whisperContext else {
      throw TranscriberError.modelNotLoaded
    }

    log.verbose("Reading wave samples...")
    let data = try readAudioSamples(audioURL)

    log.verbose("Transcribing data...")
    try await whisperContext.fullTranscribe(samples: data, language: language, newSegmentCallback: newSegmentCallback)

    let text = await whisperContext.getTranscription()
    log.verbose("Done: \(text)")

    return text
  }

  private func readAudioSamples(_ url: URL) throws -> [Float] {
    try decodeWaveFile(url)
  }
}

extension TranscriberState {
  var isTranscribing: Bool {
    switch self {
    case .transcribing, .loadingModel:
      return true
    default:
      return false
    }
  }

  var isIdle: Bool {
    switch self {
    case .idle, .failed, .finished, .modelLoaded:
      return true
    default:
      return false
    }
  }

  var isModelLoaded: Bool {
    switch self {
    case .modelLoaded, .finished:
      return true
    default:
      return false
    }
  }
}

extension TranscriberError {
  var localizedDescription: String {
    switch self {
    case .couldNotLocateModel:
      return "Could not locate model"
    case .modelNotLoaded:
      return "Model not loaded"
    case let .notEnoughMemory(available, required):
      return "Not enough memory. Available: \(bytesToReadableString(bytes: available)), required: \(bytesToReadableString(bytes: required))"
    case .cancelled:
      return "Cancelled"
    }
  }

  var description: String {
    localizedDescription
  }
}

extension TranscriptionState {
  var isTranscribing: Bool {
    state == .starting || state == .loadingModel || state == .transcribing
  }
}

extension DependencyValues {
  var transcriber: TranscriberClient {
    get { self[TranscriberClient.self] }
    set { self[TranscriberClient.self] = newValue }
  }
}

func decodeWaveFile(_ url: URL) throws -> [Float] {
  let data = try Data(contentsOf: url)
  let floats = stride(from: 44, to: data.count, by: 2).map {
    data[$0 ..< $0 + 2].withUnsafeBytes {
      let short = Int16(littleEndian: $0.load(as: Int16.self))
      return max(-1.0, min(Float(short) / 32767.0, 1.0))
    }
  }
  return floats
}

private extension UserDefaults {
  var selectedModelName: String? {
    get { string(forKey: #function) }
    set { set(newValue, forKey: #function) }
  }
}
