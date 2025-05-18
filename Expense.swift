//
//  Expense.swift
//  ExpenseTracker
//
//  Created by Praveen Dhankhar on 24/03/25.
//
import Foundation
import SwiftData

// Define expense categories
enum ExpenseCategory: String, CaseIterable, Codable {
    case food = "Food"
    case transportation = "Transportation"
    case housing = "Housing"
    case utilities = "Utilities"
    case entertainment = "Entertainment"
    case health = "Health"
    case education = "Education"
    case shopping = "Shopping"
    case travel = "Travel"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .housing: return "house.fill"
        case .utilities: return "bolt.fill"
        case .entertainment: return "tv.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .shopping: return "cart.fill"
        case .travel: return "airplane"
        case .other: return "square.grid.2x2.fill"
        }
    }
    
    var color: String {
        switch self {
        case .food: return "green"
        case .transportation: return "blue"
        case .housing: return "brown"
        case .utilities: return "yellow"
        case .entertainment: return "purple"
        case .health: return "red"
        case .education: return "cyan"
        case .shopping: return "orange"
        case .travel: return "indigo"
        case .other: return "gray"
        }
    }
}

@Model
class Expense: Identifiable {
    var id: UUID = UUID()
    var name: String
    var date: Date
    var value: Double
    var category: String // Store as string for SwiftData compatibility
    
    init(name: String, date: Date, value: Double, category: ExpenseCategory = .other) {
        self.name = name
        self.date = date
        self.value = value
        self.category = category.rawValue
    }
    
    var expenseCategory: ExpenseCategory {
        get {
            return ExpenseCategory(rawValue: category) ?? .other
        }
        set {
            category = newValue.rawValue
        }
    }
}

