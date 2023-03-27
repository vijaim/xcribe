import AppDevUtils
import Foundation

// MARK: - VoiceModel

struct VoiceModel: Equatable, Identifiable, Then {
  var modelType: VoiceModelType
  var isDownloading: Bool = false
  var downloadProgress: Double = 0

  var id: String { name }
  var name: String { modelType.fileName }
  var isDownloaded: Bool { downloadProgress >= 1 }
}

// MARK: - VoiceModelType

enum VoiceModelType: String, CaseIterable {
  case tinyEN = "tiny.en"
  case tiny
  case baseEN = "base.en"
  case base
  case smallEN = "small.en"
  case small
  case mediumEN = "medium.en"
  case medium
  case largeV1 = "large-v1"
  case large

  var fileName: String { "ggml-\(rawValue).bin" }

  var readableName: String {
    switch self {
    case .tinyEN: return "Tiny (English)"
    case .tiny: return "Tiny"
    case .baseEN: return "Base (English)"
    case .base: return "Base"
    case .smallEN: return "Small (English)"
    case .small: return "Small"
    case .mediumEN: return "Medium (English)"
    case .medium: return "Medium"
    case .largeV1: return "Large (v1)"
    case .large: return "Large"
    }
  }

  var sizeLabel: String {
    switch self {
    case .tinyEN, .tiny: return "75 MB"
    case .baseEN, .base: return "142 MB"
    case .smallEN, .small: return "466 MB"
    case .mediumEN, .medium: return "1.5 GB"
    case .largeV1, .large: return "2.9 GB"
    }
  }

  var memoryRequired: UInt64 {
    switch self {
    case .tinyEN, .tiny: return 125 * 1024 * 1024
    case .baseEN, .base: return 210 * 1024 * 1024
    case .smallEN, .small: return 600 * 1024 * 1024
    case .mediumEN, .medium: return 1700 * 1024 * 1024
    case .largeV1, .large: return 3300 * 1024 * 1024
    }
  }

  var remoteURL: URL {
    VoiceModelType.srcURL.appending(component: fileName)
  }

  var localURL: URL {
    switch self {
    case .tiny:
      return Files.App.Resources.ggmlTinyBin.url

    default:
      return VoiceModelType.localFolderURL.appending(component: fileName)
    }
  }

  private static var srcURL: URL {
    URL(staticString: "https://huggingface.co/datasets/ggerganov/whisper.cpp/resolve/main/")
  }

  static var localFolderURL: URL {
    try! FileManager.default
      .url(for: .documentationDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appending(path: "Models")
  }

  static var `default`: VoiceModelType { .tiny }
}
