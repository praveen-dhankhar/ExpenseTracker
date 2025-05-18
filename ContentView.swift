import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Environment(\.modelContext) var context
    @State private var isShowingItemSheet = false
    @State private var expenseToEdit: Expense?
    @State private var refreshID = UUID()
    @State private var sortingOption: SortingOption = .dateDescending
    @State private var activeFilters = ExpenseFilters()
    @State private var isShowingFilterSheet = false
    @State private var searchText = ""
    @State private var selectedTab = 0
    
    enum SortingOption: String, CaseIterable {
        case dateAscending = "Oldest"
        case dateDescending = "Newest"
        case amountAscending = "Low to High"
        case amountDescending = "High to Low"
    }
    
    @Query var expenses: [Expense]
    
    init() {
        _expenses = Query(sort: \Expense.date, order: .reverse)
    }
    
    var sortedAndFilteredExpenses: [Expense] {
        // First apply filters
        let filteredExpenses = activeFilters.applyFilters(to: expenses)
        
        // Then apply sorting
        switch sortingOption {
        case .dateAscending:
            return filteredExpenses.sorted { $0.date < $1.date }
        case .dateDescending:
            return filteredExpenses.sorted { $0.date > $1.date }
        case .amountAscending:
            return filteredExpenses.sorted { $0.value < $1.value }
        case .amountDescending:
            return filteredExpenses.sorted { $0.value > $1.value }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Expense List Tab
            NavigationStack {
                VStack {
                    HStack {
                        Menu {
                            ForEach(SortingOption.allCases, id: \.self) { option in
                                Button {
                                    sortingOption = option
                                } label: {
                                    HStack {
                                        Text(option.rawValue)
                                        if sortingOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label(sortingOption.rawValue, systemImage: "arrow.up.arrow.down")
                                .font(.headline)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.0)))
                        }
                        
                        Spacer()
                        
                        Button {
                            isShowingFilterSheet = true
                        } label: {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle\(activeFilters.isAnyFilterActive ? ".fill" : "")")
                                .font(.headline)
                                .padding(8)
                                .foregroundColor(activeFilters.isAnyFilterActive ? .blue : .primary)
                        }
                    }
                    .padding(.horizontal)
                    
                    List {
                        ForEach(sortedAndFilteredExpenses, id: \.self) { expense in
                            ExpenseCell(expense: expense)
                                .onTapGesture {
                                    expenseToEdit = expense
                                }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                context.delete(sortedAndFilteredExpenses[index])
                            }
                            refreshID = UUID() // Ensure UI refreshes after deletion
                        }
                    }
                    .id(refreshID) // Force refresh when ID changes
                    .searchable(text: $searchText)
                    .onChange(of: searchText) { _, newValue in
                        activeFilters.searchText = newValue
                    }
                }
                .navigationTitle("Expenses")
                .navigationBarTitleDisplayMode(.large)
                .sheet(isPresented: $isShowingItemSheet) {
                    AddExpenseSheet()
                }
                .sheet(item: $expenseToEdit) { expense in
                    UpdateExpenseSheet(expense: expense)
                }
                .sheet(isPresented: $isShowingFilterSheet) {
                    SearchFilterView(activeFilters: $activeFilters)
                }
                .toolbar {
                    if !expenses.isEmpty {
                        Button("Add Expense", systemImage: "plus") {
                            isShowingItemSheet = true
                        }
                    }
                }
                .overlay {
                    if expenses.isEmpty {
                        ContentUnavailableView(label: {
                            Label("No Expenses", systemImage: "list.bullet.rectangle.portrait")
                        }, description: {
                            Text("Start adding your expenses to see your list.")
                        }, actions: {
                            Button("Add Expense") { isShowingItemSheet = true }
                        })
                        .offset(y: -60)
                    } else if sortedAndFilteredExpenses.isEmpty {
                        ContentUnavailableView(label: {
                            Label("No Matching Expenses", systemImage: "magnifyingglass")
                        }, description: {
                            Text("Try changing your search or filters.")
                        }, actions: {
                            Button("Clear Filters") {
                                activeFilters.resetAll()
                                searchText = ""
                            }
                        })
                        .offset(y: -60)
                    }
                }
            }
            .tabItem {
                Label("Expenses", systemImage: "list.bullet")
            }
            .tag(0)
            
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie")
                }
                .tag(1)
            
            // Budget Tab
            BudgetView()
                .tabItem {
                    Label("Budgets", systemImage: "indianrupeesign.circle")
                }
                .tag(2)
            
            //Setting tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
    }
}

struct ExpenseCell: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(expense.date, format: .dateTime.month(.abbreviated).day())
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                Label(expense.name, systemImage: expense.expenseCategory.icon)
                    .font(.headline)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(expense.value, format: .currency(code: "INR"))
                    .font(.headline)
                
                Text(expense.expenseCategory.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(expense.expenseCategory.color).opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddExpenseSheet: View {
    
    @Environment(\.modelContext) var Context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var date: Date = .now
    @State private var value: Double = 0.00
    @State private var selectedCategory: ExpenseCategory = .other
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Expense Name", text: $name)
                
                DatePicker("Date", selection: $date, displayedComponents: .date)
                
                TextField("Value", value: $value, format: .currency(code: "INR"))
                    .keyboardType(.decimalPad)
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .foregroundColor(Color(category.color))
                            .tag(category)
                    }
                }
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Save") {
                        let expense = Expense(name: name, date: date, value: value, category: selectedCategory)
                        Context.insert(expense)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct UpdateExpenseSheet: View {
    
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var expense: Expense
    @State private var selectedCategory: ExpenseCategory
    
    init(expense: Expense) {
        self.expense = expense
        self._selectedCategory = State(initialValue: expense.expenseCategory)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Expense Name", text: $expense.name)
                
                DatePicker("Date", selection: $expense.date, displayedComponents: .date)
                
                TextField("Value", value: $expense.value, format: .currency(code: "INR"))
                    .keyboardType(.decimalPad)
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .foregroundColor(Color(category.color))
                            .tag(category)
                    }
                }
                .onChange(of: selectedCategory) { _, newValue in
                    expense.expenseCategory = newValue
                }
            }
            .navigationTitle("Update Expense")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
