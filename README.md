<div align="center">

<img src="ExpenseTracker/Assets.xcassets/AppIcon.appiconset/AppIcon_HK.png" width="120" alt="Hisaab Kitaab app icon" />

# Hisaab Kitaab

**A simple, offline expense tracker for iPhone, built with SwiftUI and SwiftData.**

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![UI](https://img.shields.io/badge/UI-SwiftUI-green)

</div>

---

## About

**Hisaab Kitaab** ("accounts and records") helps you keep track of everyday spending. Group your expenses into categories, set monthly budgets, and see where your money goes with a clean monthly breakdown. Amounts are shown in rupees (Rs), and everything is stored locally on your device, with no account and no internet needed.

## Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/42aa20b4-1c8e-4a5c-a3be-c80c775be9ea" width="230" alt="Expenses screen" />
  &nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/e185b877-2c3f-44a4-84d3-393ebd98de9e" width="230" alt="Categories screen" />
  &nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/2beed3bc-74a6-40d7-8935-23c153868b17" width="230" alt="Summary screen" />
</p>

## Features

**Expenses**
- Add, edit, and delete expenses with a title, amount, date, category, and optional note
- Search by title or note
- Filter the list by category
- Running total for whatever is currently shown

**Categories**
- Six starter categories on first launch: Food, Transport, Shopping, Bills, Health, and Entertainment
- Create your own with a custom icon and colour
- Optional monthly budget per category, with a progress bar that turns red when you go over
- Deleting a category keeps its expenses (they become "Uncategorized")

**Summary**
- Monthly total with a donut chart and a percentage breakdown by category
- Left and right arrows to browse previous months
- "This month" button to jump back to the current month

**Other**
- Fully offline, with data saved on the device using SwiftData

## Tech stack

| | |
|---|---|
| Language | Swift |
| UI | SwiftUI |
| Storage | SwiftData |
| Charts | Swift Charts |
| Minimum OS | iOS 17 |
| IDE | Xcode 15 or later |

## Getting started

1. **Clone the repo**
   ```bash
   git clone https://github.com/arsumziyan/hisaab-kitaab.git
   cd hisaab-kitaab
   ```
2. **Open the project**
   ```bash
   open ExpenseTracker.xcodeproj
   ```
3. **Pick an iPhone simulator** (iOS 17 or later) from the device menu at the top of Xcode.
4. **Run** with `Cmd + R`.

To run on a real iPhone, go to **Signing & Capabilities**, choose your own Team, and change the bundle identifier to something unique to you. Then plug in your phone, turn on Developer Mode, and press `Cmd + R`.

## Project structure

```
ExpenseTracker/
├── ExpenseTrackerApp.swift          # App entry point, data models, helpers, tab bar
├── ExpenseViews.swift               # Expense list, row, and add/edit form
├── CategoryAndSummaryViews.swift    # Category list and form, monthly summary and chart
└── Assets.xcassets                  # App icon and colours
```

## Customising

- **Currency symbol:** change `currencySymbol` near the top of `ExpenseTrackerApp.swift` (default is `"Rs"`).
- **Starter categories:** edit the `defaults` list in `RootView.seedIfNeeded()`.

## Roadmap

- [ ] Income tracking and balance
- [ ] Recurring expenses
- [ ] Export to CSV
- [ ] Month-by-month history chart
- [ ] iCloud sync

## Author

Built by **Arsum Ziyan** ([@arsumziyan](https://github.com/arsumziyan)).
