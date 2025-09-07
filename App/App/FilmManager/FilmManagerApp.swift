import SwiftUI

@main
struct FilmManagerApp: App {
    @StateObject private var sharedFilmManager = FilmManager()
    
    var body: some Scene {
        // Main application window
        WindowGroup("Film Manager") {
            ContentView()
                .frame(minWidth: 1400, minHeight: 800)
                .environmentObject(sharedFilmManager)
        }
        .commands {
            CommandGroup(replacing: .saveItem) {
                Button("Save All") {
                    NotificationCenter.default.post(name: .saveAll, object: nil)
                }
                .keyboardShortcut("s")
            }
        }
        .windowResizability(.contentSize)
        
        // Video playback window - always on top
        WindowGroup("Video Playback", id: "video-playback") {
            VideoPlaybackWindow(filmManager: sharedFilmManager)
                .frame(minWidth: 480, minHeight: 320)
        }
        .windowLevel(.floating)
        .defaultSize(width: 640, height: 360)
        .windowResizability(.contentSize)
        .defaultPosition(.topTrailing)
    }
}

extension Notification.Name {
    static let saveAll = Notification.Name("saveAll")
}