//
//  BudgetView.swift
//  ExpenseTracker
//
//  Created by Praveen Dhankhar on 29/04/25.
//

import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) var context
    @Query var budgets: [Budget]
    @Query var expenses: [Expense]
    
    @State private var isShowingAddBudget = false
    @State private var budgetToEdit: Budget?
    
    var activeBudgets: [Budget] {
        budgets.filter { $0.isActive() }
    }
    
    var inactiveBudgets: [Budget] {
        budgets.filter { !$0.isActive() }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if activeBudgets.isEmpty && inactiveBudgets.isEmpty {
                    ContentUnavailableView(label: {
                        Label("No Budgets", systemImage: "indianrupeesign.circle")
                    }, description: {
                        Text("Start adding budgets to track your spending goals.")
                    }, actions: {
                        Button("Add Budget") { isShowingAddBudget = true }
                    })
                } else {
                    if !activeBudgets.isEmpty {
                        Section("Active Budgets") {
                            ForEach(activeBudgets) { budget in
                                BudgetCell(budget: budget, expenses: expenses)
                                    .onTapGesture {
                                        budgetToEdit = budget
                                    }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    context.delete(activeBudgets[index])
                                }
                            }
                        }
                    }
                    
                    if !inactiveBudgets.isEmpty {
                        Section("Past Budgets") {
                            ForEach(inactiveBudgets) { budget in
                                BudgetCell(budget: budget, expenses: expenses)
                                    .onTapGesture {
                                        budgetToEdit = budget
                                    }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    context.delete(inactiveBudgets[index])
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Budgets")
            .toolbar {
                Button("Add Budget", systemImage: "plus") {
                    isShowingAddBudget = true
                }
            }
            .sheet(isPresented: $isShowingAddBudget) {
                AddBudgetSheet()
            }
            .sheet(item: $budgetToEdit) { budget in
                EditBudgetSheet(budget: budget)
            }
        }
    }
}

struct BudgetCell: View {
    let budget: Budget
    let expenses: [Expense]
    
    var progressColor: Color {
        let percentage = budget.getProgressPercentage(expenses: expenses)
        if percentage < 0.5 {
            return .green
        } else if percentage < 0.9 {
            return .yellow
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(budget.categoryEnum.rawValue, systemImage: budget.categoryEnum.icon)
                    .font(.headline)
                
                Spacer()
                
                Text(budget.amount, format: .currency(code: "INR"))
                    .fontWeight(.bold)
            }
            
            Text("\(budget.period.rawValue) • \(formatDateRange(start: budget.startDate, end: budget.getEndDate()))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: budget.getProgressPercentage(expenses: expenses))
                .tint(progressColor)
            
            HStack {
                Text("Spent: \(budget.currentPeriodSpent(expenses: expenses), format: .currency(code: "INR"))")
                    .font(.caption)
                
                Spacer()
                
                let remaining = budget.getRemainingAmount(expenses: expenses)
                Text("Remaining: \(remaining, format: .currency(code: "INR"))")
                    .font(.caption)
                    .foregroundColor(remaining < 0 ? .red : .green)
            }
        }
        .padding(.vertical, 4)
    }
    
    func formatDateRange(start: Date, end: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        return "\(dateFormatter.string(from: start)) - \(dateFormatter.string(from: end))"
    }
}

struct AddBudgetSheet: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: ExpenseCategory = .other
    @State private var amount: Double = 0
    @State private var selectedPeriod: Budget.BudgetPeriod = .monthly
    @State private var startDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .foregroundColor(Color(category.color))
                            .tag(category)
                    }
                }
                
                TextField("Budget Amount", value: $amount, format: .currency(code: "INR"))
                    .keyboardType(.decimalPad)
                
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(Budget.BudgetPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newBudget = Budget(
                            category: selectedCategory,
                            amount: amount,
                            period: selectedPeriod,
                            startDate: startDate
                        )
                        context.insert(newBudget)
                        dismiss()
                    }
                    .disabled(amount <= 0)
                }
            }
        }
    }
}

struct EditBudgetSheet: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @Bindable var budget: Budget
    
    @State private var selectedCategory: ExpenseCategory
    @State private var selectedPeriod: Budget.BudgetPeriod
    
    init(budget: Budget) {
        self.budget = budget
        self._selectedCategory = State(initialValue: budget.categoryEnum)
        self._selectedPeriod = State(initialValue: budget.period)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .foregroundColor(Color(category.color))
                            .tag(category)
                    }
                }
                .onChange(of: selectedCategory) { _, newValue in
                    budget.categoryEnum = newValue
                }
                
                TextField("Budget Amount", value: $budget.amount, format: .currency(code: "INR"))
                    .keyboardType(.decimalPad)
                
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(Budget.BudgetPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .onChange(of: selectedPeriod) { _, newValue in
                    budget.period = newValue
                }
                
                DatePicker("Start Date", selection: $budget.startDate, displayedComponents: .date)
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
