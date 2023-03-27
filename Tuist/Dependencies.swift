import ProjectDescription

let packages: [Package] = [
  .package(url: "https://github.com/Saik0s/AppDevUtils.git", from: "0.2.1"),
  .package(url: "https://github.com/krzysztofzablocki/Inject.git", .branch("main")),
  .package(url: "https://github.com/dmrschmidt/DSWaveformImage.git", from: "11.0.0"),
  // .package(url: "https://github.com/jasudev/LottieUI.git", .branch("main")),
  .package(url: "https://github.com/AudioKit/AudioKit.git", from: "5.6.0"),
  .package(url: "https://github.com/ggerganov/whisper.spm", from: "1.2.1"),
  .package(url: "https://github.com/yannickl/DynamicColor.git", from: "5.0.1"),
  .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "0.52.0"),
  // .package(url: "https://github.com/darrarski/swift-composable-presentation.git", from: "0.16.0"),
]

let dependencies = Dependencies(
  swiftPackageManager: SwiftPackageManagerDependencies(
    packages,
    targetSettings: [
      "whisper": [
        "OTHER_CFLAGS": "-O3 -DNDEBUG -DGGML_USE_ACCELERATE $(inherited)",
      ],
    ]
  ),
  platforms: [.iOS]
)
