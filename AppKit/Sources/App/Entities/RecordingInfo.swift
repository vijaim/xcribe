import AppDevUtils
import Foundation
import IdentifiedCollections
import Dependencies

// MARK: - RecordingInfo

public struct RecordingInfo: Identifiable, Hashable, Then, Codable {
  public var id: String { fileName }

  public var fileName: String
  public var title = ""
  public var date: Date
  public var duration: TimeInterval
  public var editedText: String?
  public var transcriptionHistory: IdentifiedArrayOf<Transcription> = []

  public var text: String { editedText ?? lastTranscription?.text ?? "" }
  public var lastTranscription: Transcription? { transcriptionHistory.last }
  public var isTranscribed: Bool { lastTranscription?.status.isDone == true }
  public var isTranscribing: Bool {
    switch lastTranscription?.status {
    case .loading, .progress:
      return true
    default:
      return false
    }
  }

  // FIXME: This is a hack
  public var fileURL: URL {
    @Dependency(\.storage) var storage
    return storage.audioFileURLWithName(fileName)
  }
}

#if DEBUG

  extension RecordingInfo {
    static let mock = RecordingInfo(
      fileName: "mock.wav",
      title: "Random thoughts",
      date: Date(),
      duration: 10,
      editedText: "Mock text",
      transcriptionHistory: [.mock1]
    )

    static let fixtures: [RecordingInfo] = [
      RecordingInfo(
        fileName: "groceryList.wav",
        title: "Grocery List",
        date: Date(),
        duration: 15,
        editedText: "Milk, eggs, bread, tomatoes, onions, cereal, chicken, ground beef, pasta, apples, and orange juice.",
        transcriptionHistory: [.mock1]
      ),
      RecordingInfo(
        fileName: "meetingRecap.wav",
        title: "Meeting Recap",
        date: Date(),
        duration: 25,
        editedText: "Discussed new marketing strategy, assigned tasks to team members, follow-up meeting scheduled for next week. Bob to send updated report by Wednesday.",
        transcriptionHistory: [.mock1]
      ),
      RecordingInfo(
        fileName: "weekendPlans.wav",
        title: "Weekend Plans",
        date: Date(),
        duration: 20,
        editedText: "Saturday morning, 10 AM - Yoga class. Afternoon - Lunch with Sarah at that new Italian place. Evening - Movie night at home. Sunday - Finish reading that book and start planning for the next road trip.",
        transcriptionHistory: [.mock1]
      ),
      RecordingInfo(
        fileName: "birthdayPartyIdeas.wav",
        title: "Birthday Party Ideas",
        date: Date(),
        duration: 18,
        editedText: "Theme: Superheroes. Decorations: balloons, banners, and confetti. Food: pizza, chips, and ice cream. Activities: face painting, games, and a piñata.",
        transcriptionHistory: [.mock1]
      ),
      RecordingInfo(
        fileName: "gymWorkoutRoutine.wav",
        title: "Gym Workout Routine",
        date: Date(),
        duration: 22,
        editedText: "Warm-up: 5 minutes on the treadmill. Strength training: 3 sets of 10 squats, lunges, and push-ups. Cardio: 20 minutes on the elliptical. Cool down: stretching and deep breathing exercises.",
        transcriptionHistory: [.mock1]
      ),
      RecordingInfo(
        fileName: "bookRecommendations.wav",
        title: "Book Recommendations",
        date: Date(),
        duration: 17,
        editedText: "Educated by Tara Westover, Atomic Habits by James Clear, Sapiens by Yuval Noah Harari, and The Nightingale by Kristin Hannah.",
        transcriptionHistory: [.mock1]
      ),
      RecordingInfo(
        fileName: "websiteIdeas.wav",
        title: "Website Ideas",
        date: Date(),
        duration: 19,
        editedText: "Online art gallery showcasing local artists, subscription-based meal planning service, educational platform for creative writing, and a marketplace for handmade crafts.",
        transcriptionHistory: [.mock1]
      ),
      RecordingInfo(
        fileName: "carMaintenanceReminders.wav",
        title: "Car Maintenance Reminders",
        date: Date(),
        duration: 14,
        editedText: "Check oil levels and tire pressure, schedule appointment for oil change, replace wiper blades, and inspect brake pads.",
        transcriptionHistory: [.mock1]
      ),
      RecordingInfo(
        fileName: "newRecipeIdeas.wav",
        title: "New Recipe Ideas",
        date: Date(),
        duration: 16,
        editedText: "Vegetarian stir-fry with tofu, spaghetti carbonara, Moroccan-style chicken with couscous, and homemade sushi rolls.",
        transcriptionHistory: [.mock1]
      ),
      RecordingInfo(
        fileName: "podcastEpisodeList.wav",
        title: "Podcast Episode List",
        date: Date(),
        duration: 21,
        editedText: "1. How to Build a Successful Startup, 2. Exploring the Depths of Space, 3. The History of Coffee, 4. Mindfulness and Meditation Techniques, and 5. The Future of Renewable Energy.",
        transcriptionHistory: [.mock1]
      ),
    ]
  }
#endif
