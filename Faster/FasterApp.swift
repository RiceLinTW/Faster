//
//  FasterApp.swift
//  Faster
//
//  Created by Rice Lin on 3/30/25.
//

import SwiftUI
import SwiftData
import AppCore

@main
struct FasterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TimerModel.self,
            TimerRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TimerListView()
                .modelContainer(sharedModelContainer)
        }
    }
}
