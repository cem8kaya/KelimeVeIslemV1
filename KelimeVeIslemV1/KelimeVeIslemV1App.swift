//
//  KelimeVeIslemV1App.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

import SwiftUI
import CoreData

@main
struct KelimeVeIslemV1App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
