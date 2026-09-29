import SwiftUI
import SwiftData

// MARK: - App entry

@main
struct ExpenseTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Category.self, Expense.self])
    }
}

// MARK: - Models

@Model
final class Category {
    var name: String
    var icon: String          // SF Symbol name
    var colorHex: String
    var monthlyBudget: Double // 0 = no budget

    // Deleting a category keeps its expenses (they become "Uncategorized")
    @Relationship(deleteRule: .nullify, inverse: \Expense.category)
    var expenses: [Expense] = []

    init(name: String, icon: String, colorHex: String, monthlyBudget: Double = 0) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.monthlyBudget = monthlyBudget
    }

    var color: Color { Color(hex: colorHex) }

    var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var spentThisMonth: Double {
        expenses
            .filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
}

@Model
final class Expense {
    var title: String
    var amount: Double
    var date: Date
    var note: String
    var category: Category?

    init(title: String, amount: Double, date: Date = .now, note: String = "", category: Category? = nil) {
        self.title = title
        self.amount = amount
        self.date = date
        self.note = note
        self.category = category
    }
}

// MARK: - Helpers

let currencySymbol = "Rs"

extension Double {
    /// e.g. "Rs 3,000" or "Rs 1,250.50"
    var money: String {
        let number = formatted(.number.precision(.fractionLength(0...2)))
        return "\(currencySymbol) \(number)"
    }
}

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

// MARK: - Root tabs + first-launch seeding

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var categories: [Category]

    var body: some View {
        TabView {
            ExpenseListView()
                .tabItem { Label("Expenses", systemImage: "list.bullet.rectangle") }

            CategoryListView()
                .tabItem { Label("Categories", systemImage: "square.grid.2x2") }

            SummaryView()
                .tabItem { Label("Summary", systemImage: "chart.pie") }
        }
        .task { seedIfNeeded() }
    }

    private func seedIfNeeded() {
        guard categories.isEmpty else { return }
        let defaults: [(String, String, String)] = [
            ("Food", "fork.knife", "#F59E0B"),
            ("Transport", "car.fill", "#3B82F6"),
            ("Shopping", "bag.fill", "#EC4899"),
            ("Bills", "doc.text.fill", "#EF4444"),
            ("Health", "cross.case.fill", "#10B981"),
            ("Entertainment", "gamecontroller.fill", "#8B5CF6")
        ]
        for (name, icon, hex) in defaults {
            context.insert(Category(name: name, icon: icon, colorHex: hex))
        }
    }
}
