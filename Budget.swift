//
//  Budget.swift
//  ExpenseTracker
//
//  Created by Praveen Dhankhar on 29/04/25.
//

import Foundation
import SwiftData

@Model
class Budget: Identifiable {
    var id: UUID = UUID()
    var category: String
    var amount: Double
    var period: BudgetPeriod
    var startDate: Date
    
    enum BudgetPeriod: String, CaseIterable, Codable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
    
    init(category: ExpenseCategory = .other, amount: Double, period: BudgetPeriod, startDate: Date = Date()) {
        self.category = category.rawValue
        self.amount = amount
        self.period = period
        self.startDate = startDate
    }
    
    var categoryEnum: ExpenseCategory {
        get {
            return ExpenseCategory(rawValue: category) ?? .other
        }
        set {
            category = newValue.rawValue
        }
    }
    
    func getEndDate() -> Date {
        let calendar = Calendar.current
        switch period {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startDate)!
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startDate)!
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: startDate)!
        }
    }
    
    func isActive() -> Bool {
        let now = Date()
        return now >= startDate && now <= getEndDate()
    }
    
    func currentPeriodSpent(expenses: [Expense]) -> Double {
        let filteredExpenses = expenses.filter { expense in
            expense.expenseCategory.rawValue == category &&
            expense.date >= startDate &&
            expense.date <= getEndDate()
        }
        
        return filteredExpenses.reduce(0) { $0 + $1.value }
    }
    
    func getRemainingAmount(expenses: [Expense]) -> Double {
        let spent = currentPeriodSpent(expenses: expenses)
        return amount - spent
    }
    
    func getProgressPercentage(expenses: [Expense]) -> Double {
        let spent = currentPeriodSpent(expenses: expenses)
        return min(spent / amount, 1.0)
    }
}
