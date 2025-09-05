import SwiftUI

@main
struct FilmManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1400, minHeight: 800)
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
    }
}

extension Notification.Name {
    static let saveAll = Notification.Name("saveAll")
}