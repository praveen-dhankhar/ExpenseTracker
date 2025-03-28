//
//  Expense.swift
//  ExpenseTracker
//
//  Created by Praveen Dhankhar on 24/03/25.
//
import Foundation
import SwiftData

@Model
class Expense: Identifiable {
    var id: UUID = UUID()
    var name: String
    var date: Date
    var value: Double  
    
    init(name: String, date: Date, value: Double) {
        self.name = name
        self.date = date
        self.value = value
    }
}

