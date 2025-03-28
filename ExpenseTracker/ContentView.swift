import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Environment(\.modelContext) var Context
    @State private var isShowingItemSheet = false
    @State private var expenseToEdit: Expense?
    @State private var refreshID = UUID() // ✅ Used to force refresh
    @State private var sortingOption: SortingOption = .dateDescending
    
    enum SortingOption: String, CaseIterable {
        case dateAscending = "Oldest"
        case dateDescending = "Newest"
        case amountAscending = "Low to High"
        case amountDescending = "High to Low"
    }
    
    @Query var expenses: [Expense]
    
    init() {
        _expenses = Query(sort: \Expense.date, order: .reverse) // Default sorting
       
    }
    
    var sortedExpenses: [Expense] {
        switch sortingOption {
        case .dateAscending:
            return expenses.sorted { $0.date < $1.date }
        case .dateDescending:
            return expenses.sorted { $0.date > $1.date }
        case .amountAscending:
            return expenses.sorted { $0.value < $1.value }
        case .amountDescending:
            return expenses.sorted { $0.value > $1.value }
        }
    }
    
    var body: some View {
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
                    .padding(.leading)
                    
                    Spacer()
                }
                .padding(.top, 5)
                
                List {
                    ForEach(sortedExpenses, id: \.self) { expense in
                        ExpenseCell(expense: expense)
                            .onTapGesture {
                                expenseToEdit = expense
                            }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            Context.delete(expenses[index])
                        }
                        refreshID = UUID() // ✅ Ensure UI refreshes after deletion
                    }
                }
                .id(refreshID) // ✅ Force refresh when ID changes
                .navigationTitle("Expenses")
                .navigationBarTitleDisplayMode(.large)
                .sheet(isPresented: $isShowingItemSheet) { AddExpenseSheet() }
                .sheet(item: $expenseToEdit) { expense in
                    UpdateExpenseSheet(expense: expense)
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
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}


struct ExpenseCell: View {
    let expense : Expense
    
    var body: some View {
        HStack{
            Text(expense.date, format: .dateTime.month(.abbreviated).day())
                .frame(width: 70, alignment: .leading)
            Text(expense.name)
            Spacer()
            Text(expense.value, format: .currency(code: "INR"))
                
        }
    }
}

struct AddExpenseSheet: View {
    
    @Environment(\.modelContext) var Context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var date: Date = .now
    @State private var value: Double = 0.00
    
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Expense Name", text: $name)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("Value", value: $value, format: .currency(code: "INR"))
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Save") {
                        let expense = Expense(name: name, date: date, value: value)
                        Context.insert(expense)
                        
                                            
                        dismiss()
                    }
                }
            }
        }
    }
}
struct UpdateExpenseSheet: View {
    
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var expense: Expense
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Expense Name", text: $expense.name)
                DatePicker("Date", selection: $expense.date, displayedComponents: .date)
                TextField("Value", value: $expense.value, format: .currency(code: "INR"))
                    .keyboardType(.decimalPad)
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
