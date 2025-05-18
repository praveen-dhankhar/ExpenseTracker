//
//  SettingsView.swift
//  ExpenseTracker
//
//  Created by Praveen Dhankhar on 29/04/25.
//


import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var themeManager = ThemeManager()
    @State private var isShowingThemeSettings = false
    @State private var isShowingExportOptions = false
    @State private var defaultCurrency = "INR"
    @Environment(\.modelContext) private var context
    
    @Query private var expenses: [Expense]
    
    // Currency options (could be expanded)
    let currencyOptions = ["INR", "USD", "EUR", "GBP", "JPY", "AUD"]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Button {
                        isShowingThemeSettings = true
                    } label: {
                        HStack {
                            Label("Theme", systemImage: themeManager.currentTheme.iconName)
                            Spacer()
                            Text(themeManager.currentTheme.rawValue)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                
                Section("Preferences") {
                    Picker("Default Currency", selection: $defaultCurrency) {
                        ForEach(currencyOptions, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    .onChange(of: defaultCurrency) {
                        UserDefaults.standard.set(defaultCurrency, forKey: "defaultCurrency")
                    }
                }
                
                Section("Data") {
                    Button {
                        isShowingExportOptions = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        // Show delete confirmation
                        deleteAllExpenses()
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $isShowingThemeSettings) {
                ThemeSettingsView(themeManager: themeManager)
            }
            .actionSheet(isPresented: $isShowingExportOptions) {
                ActionSheet(
                    title: Text("Export Data"),
                    message: Text("Choose export format"),
                    buttons: [
                        .default(Text("CSV")) {
                            exportToCSV()
                        },
                        .default(Text("JSON")) {
                            exportToJSON()
                        },
                        .cancel()
                    ]
                )
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .onAppear {
            // Load saved currency preference
            defaultCurrency = UserDefaults.standard.string(forKey: "defaultCurrency") ?? "INR"
        }
    }
    
    private func deleteAllExpenses() {
        for expense in expenses {
            context.delete(expense)
        }
        
        // Also delete all budgets
        let descriptor = FetchDescriptor<Budget>()
        if let budgets = try? context.fetch(descriptor) {
            for budget in budgets {
                context.delete(budget)
            }
        }
    }
    
    private func exportToCSV() {
        var csvString = "ID,Name,Date,Amount,Category\n"
        
        for expense in expenses {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            
            let formattedDate = dateFormatter.string(from: expense.date)
            let line = "\(expense.id.uuidString),\(expense.name),\(formattedDate),\(expense.value),\(expense.expenseCategory.rawValue)\n"
            csvString.append(line)
        }
        
        // In a real app, we would save this to a file and share it
        print("CSV Export: \(csvString)")
        
        // Show success alert or share sheet in a real app
    }
    
    private func exportToJSON() {
        let expenseArray = expenses.map { expense -> [String: Any] in
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            
            return [
                "id": expense.id.uuidString,
                "name": expense.name,
                "date": dateFormatter.string(from: expense.date),
                "amount": expense.value,
                "category": expense.expenseCategory.rawValue
            ]
        }
        
        // In a real app, we would convert this to proper JSON and share it
        print("JSON Export: \(expenseArray)")
        
        // Show success alert or share sheet in a real app
    }
}