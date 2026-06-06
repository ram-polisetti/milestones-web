import SwiftUI

@main
struct MilestonesApp: App {
    @StateObject private var store = MilestonesStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .tint(.blue)
        }
    }
}
