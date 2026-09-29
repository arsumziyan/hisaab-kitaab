import SwiftUI
import SwiftData
import Charts

// MARK: - Category list

struct CategoryListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var showingAdd = false
    @State private var editing: Category?

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    Button { editing = category } label: {
                        CategoryRow(category: category)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(categories[index]) }
                }
            }
            .overlay {
                if categories.isEmpty {
                    ContentUnavailableView(
                        "No categories",
                        systemImage: "square.grid.2x2",
                        description: Text("Tap + to create one.")
                    )
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) { CategoryFormView() }
            .sheet(item: $editing) { category in CategoryFormView(category: category) }
        }
    }
}

struct CategoryRow: View {
    let category: Category

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(category.color, in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                    Text("\(category.expenses.count) expenses · \(category.totalSpent.money) total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(category.spentThisMonth.money).fontWeight(.medium)
                    Text("this month").font(.caption).foregroundStyle(.secondary)
                }
            }

            if category.monthlyBudget > 0 {
                let ratio = category.spentThisMonth / category.monthlyBudget
                ProgressView(value: min(ratio, 1))
                    .tint(ratio > 1 ? .red : category.color)
                Text("Budget: \(category.monthlyBudget.money)")
                    .font(.caption2)
                    .foregroundStyle(ratio > 1 ? .red : .secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Category form

struct CategoryFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var category: Category?

    @State private var name = ""
    @State private var icon = "cart.fill"
    @State private var colorHex = "#3B82F6"
    @State private var budgetText = ""

    private let icons = [
        "cart.fill", "fork.knife", "car.fill", "bag.fill", "doc.text.fill", "cross.case.fill",
        "gamecontroller.fill", "house.fill", "airplane", "book.fill", "gift.fill", "pawprint.fill",
        "graduationcap.fill", "wifi", "fuelpump.fill", "tshirt.fill"
    ]
    private let colors = [
        "#EF4444", "#F59E0B", "#10B981", "#3B82F6",
        "#8B5CF6", "#EC4899", "#14B8A6", "#6B7280"
    ]

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Groceries", text: $name)
                }

                Section("Monthly budget (optional)") {
                    TextField("0", text: $budgetText)
                        .keyboardType(.decimalPad)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 14) {
                        ForEach(icons, id: \.self) { symbol in
                            Image(systemName: symbol)
                                .frame(width: 40, height: 40)
                                .background(icon == symbol ? Color(hex: colorHex).opacity(0.25) : .clear,
                                            in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(icon == symbol ? Color(hex: colorHex) : .secondary)
                                .onTapGesture { icon = symbol }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 14) {
                        ForEach(colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 28, height: 28)
                                .overlay {
                                    if colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(category == nil ? "New Category" : "Edit Category")
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
        guard let category else { return }
        name = category.name
        icon = category.icon
        colorHex = category.colorHex
        budgetText = category.monthlyBudget > 0 ? String(category.monthlyBudget) : ""
    }

    private func save() {
        let budget = Double(budgetText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let trimmed = name.trimmingCharacters(in: .whitespaces)

        if let category {
            category.name = trimmed
            category.icon = icon
            category.colorHex = colorHex
            category.monthlyBudget = budget
        } else {
            context.insert(Category(name: trimmed, icon: icon, colorHex: colorHex, monthlyBudget: budget))
        }
        dismiss()
    }
}

// MARK: - Summary

private extension Date {
    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }
}

struct SummaryView: View {
    @Query private var expenses: [Expense]
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var selectedMonth = Date.now.startOfMonth
    @AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
    @State private var showingBudget = false

    private struct Slice: Identifiable {
        let id = UUID()
        let name: String
        let total: Double
        let color: Color
    }

    private var monthExpenses: [Expense] {
        expenses.filter {
            Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var monthTotal: Double { monthExpenses.reduce(0) { $0 + $1.amount } }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: .now, toGranularity: .month)
    }

    // Can go back as far as your oldest expense
    private var canGoBack: Bool {
        guard let earliest = expenses.map(\.date).min() else { return false }
        return selectedMonth > earliest.startOfMonth
    }

    // Can go forward up to the current month, or further if you have future-dated expenses
    private var canGoForward: Bool {
        let latest = expenses.map(\.date).max() ?? Date.now
        return selectedMonth < max(latest, Date.now).startOfMonth
    }

    private var slices: [Slice] {
        var result = categories.compactMap { category -> Slice? in
            let total = monthExpenses
                .filter { $0.category == category }
                .reduce(0) { $0 + $1.amount }
            return total > 0 ? Slice(name: category.name, total: total, color: category.color) : nil
        }
        let uncategorized = monthExpenses
            .filter { $0.category == nil }
            .reduce(0) { $0 + $1.amount }
        if uncategorized > 0 {
            result.append(Slice(name: "Uncategorized", total: uncategorized, color: .gray))
        }
        return result.sorted { $0.total > $1.total }
    }

    private var budgetColor: Color {
        guard monthlyBudget > 0 else { return .accentColor }
        let ratio = monthTotal / monthlyBudget
        if ratio > 1 { return .red }
        return ratio >= 0.8 ? .orange : .green
    }

    private var budgetCard: some View {
        Button { showingBudget = true } label: {
            if monthlyBudget > 0 {
                let remaining = monthlyBudget - monthTotal
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Monthly budget", systemImage: "target")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: min(monthTotal / monthlyBudget, 1))
                        .tint(budgetColor)
                    HStack {
                        Text("\(monthTotal.money) of \(monthlyBudget.money)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(remaining >= 0 ? "\(remaining.money) left" : "\((-remaining).money) over")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(remaining >= 0 ? Color.primary : Color.red)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "target")
                    Text("Set a monthly budget")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func changeMonth(by value: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            withAnimation { selectedMonth = next.startOfMonth }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Month header with previous / next arrows
                    HStack {
                        Button { changeMonth(by: -1) } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3.weight(.semibold))
                                .frame(width: 44, height: 44)
                        }
                        .disabled(!canGoBack)

                        Spacer()

                        VStack(spacing: 4) {
                            Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(monthTotal.money)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                            Text("\(monthExpenses.count) \(monthExpenses.count == 1 ? "expense" : "expenses")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button { changeMonth(by: 1) } label: {
                            Image(systemName: "chevron.right")
                                .font(.title3.weight(.semibold))
                                .frame(width: 44, height: 44)
                        }
                        .disabled(!canGoForward)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    budgetCard

                    if slices.isEmpty {
                        ContentUnavailableView(
                            "No expenses this month",
                            systemImage: "chart.pie",
                            description: Text("Use the arrows to look at other months.")
                        )
                    } else {
                        Chart(slices) { slice in
                            SectorMark(
                                angle: .value("Amount", slice.total),
                                innerRadius: .ratio(0.6),
                                angularInset: 2
                            )
                            .foregroundStyle(slice.color)
                            .cornerRadius(4)
                        }
                        .frame(height: 240)

                        VStack(spacing: 12) {
                            ForEach(slices) { slice in
                                HStack {
                                    Circle().fill(slice.color).frame(width: 10, height: 10)
                                    Text(slice.name)
                                    Spacer()
                                    Text(slice.total.money).fontWeight(.medium)
                                    Text("\(Int((slice.total / monthTotal * 100).rounded()))%")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 40, alignment: .trailing)
                                }
                            }
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .navigationTitle("Summary")
            .sheet(isPresented: $showingBudget) { BudgetEditView() }
            .toolbar {
                if !isCurrentMonth {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("This month") {
                            withAnimation { selectedMonth = Date.now.startOfMonth }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Monthly budget editor

struct BudgetEditView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
    @State private var text = ""

    private var value: Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. 50000", text: $text)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Monthly budget (\(currencySymbol))")
                } footer: {
                    Text("One budget for all categories combined. It applies to every month.")
                }

                if monthlyBudget > 0 {
                    Section {
                        Button("Remove budget", role: .destructive) {
                            monthlyBudget = 0
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Monthly Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        monthlyBudget = max(value ?? 0, 0)
                        dismiss()
                    }
                    .disabled(value == nil)
                }
            }
            .onAppear {
                if monthlyBudget > 0 {
                    text = monthlyBudget.formatted(.number.precision(.fractionLength(0...2)).grouping(.never))
                }
            }
        }
        .presentationDetents([.medium])
    }
}
