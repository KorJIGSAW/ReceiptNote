//
//  ReciptNoteApp.swift
//  ReciptNote
//
//  Created by hansung on 6/6/25.
//

import SwiftUI

@main
struct ReciptNoteApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
