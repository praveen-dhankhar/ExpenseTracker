//
//  SearchViewFilter.swift
//  ExpenseTracker
//
//  Created by Praveen Dhankhar on 29/04/25.
//

import SwiftUI
import SwiftData

struct SearchFilterView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var activeFilters: ExpenseFilters
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    Toggle("Enable Date Filter", isOn: $activeFilters.isDateFilterActive)
                    
                    if activeFilters.isDateFilterActive {
                        DatePicker("Start Date", selection: $activeFilters.startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $activeFilters.endDate, displayedComponents: .date)
                        
                        Button("Clear Date Filter") {
                            activeFilters.clearDateFilter()
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section("Amount Range") {
                    Toggle("Enable Amount Filter", isOn: $activeFilters.isAmountFilterActive)
                    
                    if activeFilters.isAmountFilterActive {
                        HStack {
                            Text("Min")
                            TextField("Minimum Amount", value: $activeFilters.minAmount, format: .currency(code: "INR"))
                                .keyboardType(.decimalPad)
                        }
                        
                        HStack {
                            Text("Max")
                            TextField("Maximum Amount", value: $activeFilters.maxAmount, format: .currency(code: "INR"))
                                .keyboardType(.decimalPad)
                        }
                        
                        Button("Clear Amount Filter") {
                            activeFilters.clearAmountFilter()
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section("Categories") {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Button {
                            toggleCategory(category)
                        } label: {
                            HStack {
                                Label(category.rawValue, systemImage: category.icon)
                                    .foregroundColor(Color(category.color))
                                
                                Spacer()
                                
                                if activeFilters.categories.contains(category.rawValue) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Button("Select All") {
                        activeFilters.categories = ExpenseCategory.allCases.map { $0.rawValue }
                    }
                    .foregroundColor(.blue)
                    
                    Button("Clear All") {
                        activeFilters.categories = []
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleCategory(_ category: ExpenseCategory) {
        if activeFilters.categories.contains(category.rawValue) {
            activeFilters.categories.removeAll { $0 == category.rawValue }
        } else {
            activeFilters.categories.append(category.rawValue)
        }
    }
}

struct ExpenseFilters {
    var searchText: String = ""
    var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    var endDate: Date = Date()
    var minAmount: Double = 0
    var maxAmount: Double = Double.greatestFiniteMagnitude
    var categories: [String] = ExpenseCategory.allCases.map { $0.rawValue }
    var isDateFilterActive: Bool = false
    var isAmountFilterActive: Bool = false
    
    mutating func clearDateFilter() {
        startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        endDate = Date()
        isDateFilterActive = false
    }
    
    mutating func clearAmountFilter() {
        minAmount = 0
        maxAmount = Double.greatestFiniteMagnitude
        isAmountFilterActive = false
    }
    
    mutating func resetAll() {
        searchText = ""
        clearDateFilter()
        clearAmountFilter()
        categories = ExpenseCategory.allCases.map { $0.rawValue }
    }
    
    var isAnyFilterActive: Bool {
        return !searchText.isEmpty || isDateFilterActive || isAmountFilterActive || categories.count != ExpenseCategory.allCases.count
    }
    
    func applyFilters(to expenses: [Expense]) -> [Expense] {
        return expenses.filter { expense in
            // Filter by search text
            let matchesSearch = searchText.isEmpty ||
                                expense.name.lowercased().contains(searchText.lowercased())
            
            // Filter by date range
            let matchesDate = !isDateFilterActive ||
                             (expense.date >= startDate && expense.date <= endDate)
            
            // Filter by amount range
            let matchesAmount = !isAmountFilterActive ||
                               (expense.value >= minAmount && expense.value <= maxAmount)
            
            // Filter by categories
            let matchesCategory = categories.contains(expense.expenseCategory.rawValue)
            
            return matchesSearch && matchesDate && matchesAmount && matchesCategory
        }
    }
}
