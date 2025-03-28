//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by Praveen Dhankhar on 24/03/25.
//

import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    
//    var container: ModelContainer = {
//        let schema = Schema([Expense.self])
//        let container = try! ModelContainer(for: schema, configurations: [])
//        return container
//    }()
//    
//    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        //.modelContainer(container)
        .modelContainer(for: [Expense.self])
    }
}
