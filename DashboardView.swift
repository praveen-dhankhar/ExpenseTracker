//
//  DashboardView.swift
//  ExpenseTracker
//
//  Created by Praveen Dhankhar on 29/04/25.
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) var context
    @Query var expenses: [Expense]

    @State private var timeRange: TimeRange = .month

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
    }

    var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()

        switch timeRange {
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return expenses.filter { $0.date >= startOfWeek }
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return expenses.filter { $0.date >= startOfMonth }
        case .year:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return expenses.filter { $0.date >= startOfYear }
        case .all:
            return expenses
        }
    }

    var totalSpending: Double {
        filteredExpenses.reduce(0) { $0 + $1.value }
    }

    var categorySpending: [CategorySpending] {
        var result: [String: Double] = [:]
        for expense in filteredExpenses {
            let category = expense.expenseCategory.rawValue
            result[category, default: 0] += expense.value
        }
        return result.map { CategorySpending(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    var dailySpending: [DailySpending] {
        let calendar = Calendar.current
        var result: [Date: Double] = [:]
        for expense in filteredExpenses {
            let day = calendar.startOfDay(for: expense.date)
            result[day, default: 0] += expense.value
        }
        return result.map { DailySpending(date: $0.key, amount: $0.value) }
            .sorted { $0.date < $1.date }
    }

    struct CategorySpending: Identifiable {
        let id = UUID()
        let category: String
        let amount: Double
    }

    struct DailySpending: Identifiable {
        let id = UUID()
        let date: Date
        let amount: Double
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TimeRangePicker(timeRange: $timeRange)
                    SpendingSummary(total: totalSpending)
                    CategoryChart(data: categorySpending)
                    DailySpendingChart(data: dailySpending)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct TimeRangePicker: View {
    @Binding var timeRange: DashboardView.TimeRange

    var body: some View {
        Picker("Time Range", selection: $timeRange) {
            ForEach(DashboardView.TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

struct SpendingSummary: View {
    var total: Double

    var body: some View {
        VStack(alignment: .leading) {
            Text("Total Spending")
                .font(.headline)
            Text("₹\(String(format: "%.2f", total))")
                .font(.largeTitle)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CategoryChart: View {
    var data: [DashboardView.CategorySpending]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Spending by Category")
                .font(.headline)
            Chart(data) { item in
                BarMark(
                    x: .value("Category", item.category),
                    y: .value("Amount", item.amount)
                )
            }
            .frame(height: 200)
        }
    }
}

struct DailySpendingChart: View {
    var data: [DashboardView.DailySpending]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Daily Spending")
                .font(.headline)
            Chart(data) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Amount", item.amount)
                )
            }
            .frame(height: 200)
        }
    }
}
