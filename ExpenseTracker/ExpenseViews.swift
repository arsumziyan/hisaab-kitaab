import SwiftUI
import SwiftData

// MARK: - Expense list

struct ExpenseListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var searchText = ""
    @State private var filterCategory: Category?
    @State private var showingAdd = false
    @State private var editing: Expense?

    private var filtered: [Expense] {
        expenses.filter { expense in
            let matchesSearch = searchText.isEmpty
                || expense.title.localizedCaseInsensitiveContains(searchText)
                || expense.note.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = filterCategory == nil || expense.category == filterCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !filtered.isEmpty {
                    Section {
                        HStack {
                            Text("Total")
                            Spacer()
                            Text(filtered.reduce(0) { $0 + $1.amount }.money)
                                .fontWeight(.semibold)
                        }
                    }
                }

                Section {
                    ForEach(filtered) { expense in
                        Button { editing = expense } label: {
                            ExpenseRow(expense: expense)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: delete)
                }
            }
            .overlay {
                if expenses.isEmpty {
                    ContentUnavailableView(
                        "No expenses yet",
                        systemImage: "creditcard",
                        description: Text("Tap + to add your first expense.")
                    )
                }
            }
            .navigationTitle("Expenses")
            .searchable(text: $searchText, prompt: "Search expenses")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("All categories") { filterCategory = nil }
                        ForEach(categories) { category in
                            Button {
                                filterCategory = category
                            } label: {
                                Label(category.name, systemImage: category.icon)
                            }
                        }
                    } label: {
                        Image(systemName: filterCategory == nil
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) { ExpenseFormView() }
            .sheet(item: $editing) { expense in ExpenseFormView(expense: expense) }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(filtered[index]) }
    }
}

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category?.icon ?? "questionmark.circle")
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(expense.category?.color ?? .gray, in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title).font(.body)
                Text("\(expense.category?.name ?? "Uncategorized") · \(expense.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(expense.amount.money)
                .fontWeight(.medium)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Add / edit form

struct ExpenseFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var categories: [Category]

    var expense: Expense?

    @State private var title = ""
    @State private var amountText = ""
    @State private var date = Date.now
    @State private var note = ""
    @State private var category: Category?

    private var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && (amount ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("What did you buy?", text: $title)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        Text("None").tag(Category?.none)
                        ForEach(categories) { category in
                            Label(category.name, systemImage: category.icon)
                                .tag(Category?.some(category))
                        }
                    }
                }

                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .navigationTitle(expense == nil ? "New Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let expense else { return }
        title = expense.title
        amountText = String(expense.amount)
        date = expense.date
        note = expense.note
        category = expense.category
    }

    private func save() {
        guard let amount else { return }
        let trimmed = title.trimmingCharacters(in: .whitespaces)

        if let expense {
            expense.title = trimmed
            expense.amount = amount
            expense.date = date
            expense.note = note
            expense.category = category
        } else {
            context.insert(Expense(title: trimmed, amount: amount, date: date, note: note, category: category))
        }
        dismiss()
    }
}

#Preview {
    ExpenseListView()
        .modelContainer(for: [Category.self, Expense.self], inMemory: true)
}
