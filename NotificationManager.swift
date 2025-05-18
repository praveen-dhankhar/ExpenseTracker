//
//  NotificationManager.swift
//  ExpenseTracker
//
//  Created by Praveen Dhankhar on 28/03/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    // ✅ Request Notification Permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            } else if granted {
                print("Notification permission granted ✅")
            } else {
                print("Notification permission denied ❌")
            }
        }
    }

    // ✅ Schedule a Daily Expense Reminder
    func scheduleDailyExpenseReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Expense Reminder"
        content.body = "Don't forget to track your expenses today!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 20 // Reminder at 8 PM

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyExpenseReminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily expense reminder: \(error.localizedDescription)")
            } else {
                print("Daily expense reminder scheduled ✅")
            }
        }
    }

    func checkBudgetLimit(expenses: [Expense], monthlyBudget: Double) {
        let totalSpent = getTotalExpenses(expenses: expenses)
        
        if totalSpent > monthlyBudget {
            sendNotification(title: "Budget Exceeded!", message: "You have exceeded your budget of \(monthlyBudget)")
        }
    }

    private func sendNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func getTotalExpenses(expenses: [Expense]) -> Double {
        return expenses.reduce(0) { $0 + $1.value }
    }
}
