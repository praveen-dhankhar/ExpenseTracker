//
//  ExportService.swift
//  ExpenseTracker
//
//  Created by Praveen Dhankhar on 29/04/25.
//

import Foundation
import SwiftUI

class ExportService {
    enum ExportFormat {
        case csv
        case json
    }
    
    static func exportExpenses(_ expenses: [Expense], format: ExportFormat) -> URL? {
        let fileName = "ExpenseTracker_\(Date().formatted(date: .numeric, time: .omitted))"
        
        switch format {
        case .csv:
            return exportToCSV(expenses, fileName: "\(fileName).csv")
        case .json:
            return exportToJSON(expenses, fileName: "\(fileName).json")
        }
    }
    
    private static func exportToCSV(_ expenses: [Expense], fileName: String) -> URL? {
        var csvString = "ID,Name,Date,Amount,Category\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        for expense in expenses {
            // Properly escape fields for CSV
            let escapedName = escape(expense.name)
            let formattedDate = dateFormatter.string(from: expense.date)
            
            let line = "\(expense.id.uuidString),\(escapedName),\(formattedDate),\(expense.value),\(expense.expenseCategory.rawValue)\n"
            csvString.append(line)
        }
        
        return saveToFile(csvString, fileName: fileName)
    }
    
    private static func exportToJSON(_ expenses: [Expense], fileName: String) -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let expenseArray = expenses.map { expense -> [String: Any] in
            return [
                "id": expense.id.uuidString,
                "name": expense.name,
                "date": dateFormatter.string(from: expense.date),
                "amount": expense.value,
                "category": expense.expenseCategory.rawValue
            ]
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: expenseArray, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return saveToFile(jsonString, fileName: fileName)
            }
        } catch {
            print("Error creating JSON: \(error)")
        }
        
        return nil
    }
    
    private static func saveToFile(_ content: String, fileName: String) -> URL? {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving file: \(error)")
            return nil
        }
    }
    
    // Helper function to escape CSV fields
    private static func escape(_ field: String) -> String {
        let containsComma = field.contains(",")
        let containsQuote = field.contains("\"")
        let containsNewline = field.contains("\n")
        
        if containsComma || containsQuote || containsNewline {
            // Replace quotes with double quotes for escaping
            let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedField)\""
        }
        
        return field
    }
}

// Extension for sharing functionality
extension View {
    func shareSheet(
        isPresented: Binding<Bool>,
        fileURL: URL?,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        background(
            ShareSheet(isPresented: isPresented, fileURL: fileURL, onDismiss: onDismiss)
                .opacity(0)
        )
    }
}

// UIViewControllerRepresentable to show UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let fileURL: URL?
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented, let fileURL = fileURL {
            let activityViewController = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            activityViewController.completionWithItemsHandler = { _, _, _, _ in
                isPresented = false
                onDismiss()
            }
            
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = uiViewController.view
                popover.sourceRect = CGRect(x: uiViewController.view.bounds.midX,
                                          y: uiViewController.view.bounds.midY,
                                          width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            uiViewController.present(activityViewController, animated: true)
        }
    }
}
