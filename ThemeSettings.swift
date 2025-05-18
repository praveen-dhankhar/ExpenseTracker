//
//  ThemeSettings.swift
//  ExpenseTracker
//
//  Created by Praveen Dhankhar on 29/04/25.
//


import SwiftUI

// Theme enum to handle the different appearance modes
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil // System default
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    var iconName: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
}

// Class to manage theme settings
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme {
        didSet {
            // Save to UserDefaults when changed
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        }
    }
    
    init() {
        // Read theme from UserDefaults or use system default
        let savedTheme = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.system.rawValue
        currentTheme = AppTheme(rawValue: savedTheme) ?? .system
    }
}

// View to select theme
struct ThemeSettingsView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    ForEach(AppTheme.allCases) { theme in
                        Button {
                            themeManager.currentTheme = theme
                        } label: {
                            HStack {
                                Label(theme.rawValue, systemImage: theme.iconName)
                                
                                Spacer()
                                
                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Appearance")
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
