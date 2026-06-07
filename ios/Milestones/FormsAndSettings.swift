import SwiftUI
import UIKit

struct ProjectForm: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var symbol = "iphone"
    @State private var color = "#159EF2"
    @State private var iconKind = IconKind.symbols
    @State private var iconSearch = ""
    @State private var customEmoji = ""
    @State private var customSymbol = ""
    @State private var customColor = Color(hex: "#159EF2")
    let onSave: (String, String, String) -> Void

    private enum IconKind: String, CaseIterable, Identifiable {
        case symbols = "Symbols"
        case emoji = "Emoji"

        var id: String { rawValue }
    }

    private let symbols = [
        "iphone", "ipad", "laptopcomputer", "desktopcomputer", "applewatch", "visionpro",
        "globe", "network", "wifi", "antenna.radiowaves.left.and.right", "link", "server.rack",
        "folder.fill", "doc.fill", "book.closed.fill", "books.vertical.fill", "newspaper.fill", "note.text",
        "envelope.fill", "message.fill", "bubble.left.and.bubble.right.fill", "phone.fill", "video.fill", "mic.fill",
        "camera.fill", "photo.fill", "music.note", "headphones", "play.rectangle.fill", "film.fill",
        "paintbrush.fill", "pencil.and.outline", "scribble.variable", "wand.and.stars", "sparkles", "theatermasks.fill",
        "briefcase.fill", "building.2.fill", "chart.bar.fill", "chart.line.uptrend.xyaxis", "creditcard.fill", "dollarsign.circle.fill",
        "cart.fill", "bag.fill", "shippingbox.fill", "tag.fill", "gift.fill", "storefront.fill",
        "hammer.fill", "wrench.and.screwdriver.fill", "gearshape.fill", "cpu.fill", "terminal.fill", "curlybraces",
        "gamecontroller.fill", "puzzlepiece.fill", "dice.fill", "trophy.fill", "medal.fill", "flag.fill",
        "figure.run", "figure.strengthtraining.traditional", "bicycle", "soccerball", "basketball.fill", "tennis.racket",
        "airplane", "car.fill", "tram.fill", "ferry.fill", "map.fill", "location.fill",
        "house.fill", "bed.double.fill", "fork.knife", "cup.and.saucer.fill", "birthday.cake.fill", "leaf.fill",
        "heart.fill", "star.fill", "bolt.fill", "flame.fill", "lightbulb.fill", "target",
        "person.fill", "person.2.fill", "person.3.fill", "graduationcap.fill", "cross.case.fill", "pawprint.fill",
        "calendar", "clock.fill", "alarm.fill", "checkmark.circle.fill", "list.bullet.clipboard.fill", "rectangle.stack.fill"
    ]

    private let emojis = [
        "😀", "😎", "🤓", "🥳", "🤩", "🫡", "💡", "🔥", "✨", "⭐", "❤️", "🎯",
        "🚀", "✈️", "🚗", "🚲", "🏠", "🏢", "🏗️", "🗺️", "🌎", "🌱", "🌈", "☀️",
        "💻", "📱", "⌚", "🎮", "📷", "🎧", "🎙️", "🎬", "🎨", "✏️", "📚", "📰",
        "💼", "📊", "📈", "💰", "💳", "🛍️", "📦", "🏷️", "🔧", "⚙️", "🧪", "🔬",
        "✅", "📋", "📅", "⏰", "📌", "🔖", "🔐", "🔑", "🏆", "🥇", "🎁", "🎉",
        "🏃", "🏋️", "⚽", "🏀", "🎾", "⛳", "🍎", "☕", "🍽️", "🧘", "🩺", "💊",
        "👤", "👥", "🤝", "🧑‍💻", "🧑‍🎨", "🧑‍🚀", "🐶", "🐱", "🦊", "🦁", "🐼", "🦄"
    ]

    private let colors = [
        "#159EF2", "#0066CC", "#5856D6", "#7D5FFF", "#B31FC3", "#AF52DE",
        "#E91849", "#FF2D55", "#EF3032", "#FF453A", "#ED8508", "#FF9F0A",
        "#E4C342", "#FFD60A", "#19B957", "#30C968", "#34C759", "#00A98F",
        "#00C7BE", "#32ADE6", "#5AC8FA", "#8E8E93", "#6D6D72", "#2C2C2E"
    ]

    private var filteredSymbols: [String] {
        let query = iconSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return symbols }
        return symbols.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Project name", text: $title)
                }
                Section("Icon") {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: color).gradient)
                            .frame(width: 54, height: 54)
                            .overlay {
                                ProjectIcon(value: symbol)
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(title.isEmpty ? "Project preview" : title)
                                .font(.headline)
                            Text(UIImage(systemName: symbol) == nil ? "Emoji" : "SF Symbol")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Picker("Icon type", selection: $iconKind) {
                        ForEach(IconKind.allCases) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)

                    if iconKind == .symbols {
                        TextField("Search symbols", text: $iconSearch)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                                ForEach(filteredSymbols, id: \.self) { item in
                                    IconChoice(selected: symbol == item) {
                                        ProjectIcon(value: item)
                                    } action: {
                                        symbol = item
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .frame(height: 190)

                        HStack {
                            TextField("Any SF Symbol name", text: $customSymbol)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            Button("Use") {
                                let candidate = customSymbol.trimmingCharacters(in: .whitespacesAndNewlines)
                                if UIImage(systemName: candidate) != nil {
                                    symbol = candidate
                                }
                            }
                        }
                    } else {
                        TextField("Type or paste any emoji", text: $customEmoji)
                            .onChange(of: customEmoji) { _, value in
                                guard let emoji = value.first else { return }
                                symbol = String(emoji)
                            }

                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                                ForEach(emojis, id: \.self) { item in
                                    IconChoice(selected: symbol == item) {
                                        Text(item)
                                            .font(.title2)
                                    } action: {
                                        symbol = item
                                        customEmoji = item
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .frame(height: 190)
                    }
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(colors, id: \.self) { item in
                            Button {
                                color = item
                                customColor = Color(hex: item)
                            } label: {
                                Circle()
                                    .fill(Color(hex: item))
                                    .frame(width: 28, height: 28)
                                    .overlay {
                                        if color == item {
                                            Circle().stroke(.primary, lineWidth: 2).padding(-3)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    ColorPicker("Custom color", selection: $customColor, supportsOpacity: false)
                        .onChange(of: customColor) { _, value in
                            color = value.hexString
                        }
                }
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onSave(title.trimmingCharacters(in: .whitespaces), symbol, color)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct ProjectIcon: View {
    let value: String

    var body: some View {
        if UIImage(systemName: value) != nil {
            Image(systemName: value)
        } else {
            Text(value)
        }
    }
}

private struct IconChoice<Content: View>: View {
    let selected: Bool
    @ViewBuilder let content: () -> Content
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            content()
                .frame(width: 40, height: 40)
                .background(selected ? Color.accentColor.opacity(0.16) : Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    if selected {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.accentColor, lineWidth: 1.5)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

struct MilestoneForm: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var status = "In Progress"
    let onSave: (String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Milestone name", text: $title)
                Picker("Status", selection: $status) {
                    ForEach(["Draft", "Planning", "In Progress", "In Review", "Released"], id: \.self) {
                        Text($0)
                    }
                }
            }
            .navigationTitle("New Milestone")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onSave(title.trimmingCharacters(in: .whitespaces), status)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct MilestoneEditor: View {
    @EnvironmentObject private var store: MilestonesStore
    @Environment(\.dismiss) private var dismiss
    let projectID: UUID
    @State var milestone: Milestone

    var body: some View {
        NavigationStack {
            Form {
                Section("Milestone") {
                    TextField("Name", text: $milestone.title)
                    Picker("Status", selection: $milestone.status) {
                        ForEach(["Draft", "Planning", "In Progress", "In Review", "Released"], id: \.self) {
                            Text($0)
                        }
                    }
                    Toggle("Active Milestone", isOn: $milestone.isActive)
                }
            }
            .navigationTitle("Edit Milestone")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateMilestone(projectID: projectID, milestone: milestone)
                        dismiss()
                    }
                    .disabled(milestone.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct TaskEditor: View {
    @EnvironmentObject private var store: MilestonesStore
    @Environment(\.dismiss) private var dismiss
    @State var task: MilestoneTask
    @State private var hasDueDate: Bool
    let onSave: (MilestoneTask) -> Void

    init(task: MilestoneTask, onSave: @escaping (MilestoneTask) -> Void) {
        _task = State(initialValue: task)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $task.title)
                    TextField("Description", text: $task.notes, axis: .vertical)
                        .lineLimit(3...8)
                }
                Section("Status") {
                    Picker("Stage", selection: $task.stage) {
                        ForEach(TaskStage.allCases) { option in
                            Label {
                                Text(option.rawValue)
                            } icon: {
                                Image(systemName: option.menuSymbol)
                                    .foregroundStyle(option.color)
                            }
                            .tag(option)
                        }
                    }
                    Picker("Priority", selection: $task.priority) {
                        ForEach(TaskPriority.allCases) { option in
                            Label {
                                Text(option.rawValue)
                            } icon: {
                                Image(systemName: option.symbol)
                                    .foregroundStyle(option.color)
                            }
                            .tag(option)
                        }
                    }
                    Picker("Repeat", selection: $task.recurrence) {
                        Text("Never").tag(TaskRecurrence?.none)
                        ForEach(TaskRecurrence.allCases) { option in
                            Text(option.rawValue).tag(TaskRecurrence?.some(option))
                        }
                    }
                }
                Section("Due date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker(
                            "Due",
                            selection: Binding(
                                get: { task.dueDate ?? .now },
                                set: { task.dueDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                }
                Section("Tags") {
                    ForEach(store.tags, id: \.self) { tag in
                        Toggle(isOn: Binding(
                                get: { task.tags.contains(tag) },
                                set: { enabled in
                                    if enabled {
                                        if !task.tags.contains(tag) { task.tags.append(tag) }
                                    } else {
                                        task.tags.removeAll { $0 == tag }
                                    }
                                }
                            )) {
                                Label(tag, systemImage: store.tagIcon(for: tag))
                            }
                    }
                }
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !hasDueDate { task.dueDate = nil }
                        onSave(task)
                        dismiss()
                    }
                    .disabled(task.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

enum SmartListKind: Equatable {
    case today
    case upcoming
    case inbox

    var title: String {
        switch self {
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .inbox: "Inbox"
        }
    }
}

struct LocatedTask: Identifiable {
    let projectID: UUID
    let milestoneID: UUID
    let projectTitle: String
    let milestoneTitle: String
    let task: MilestoneTask
    var id: UUID { task.id }
}

struct SmartListView: View {
    @EnvironmentObject private var store: MilestonesStore
    let kind: SmartListKind
    @State private var quickTitle = ""
    @State private var editingInboxTask: MilestoneTask?
    @State private var editingLocatedTask: LocatedTask?

    private var locatedTasks: [LocatedTask] {
        let calendar = Calendar.current
        return store.projects.flatMap { project in
            project.milestones.flatMap { milestone in
                milestone.tasks.compactMap { task in
                    guard let dueDate = task.dueDate else { return nil }
                    let include: Bool
                    switch kind {
                    case .today:
                        include = calendar.isDateInToday(dueDate) || (dueDate < .now && task.stage != .done)
                    case .upcoming:
                        include = dueDate > .now && !calendar.isDateInToday(dueDate)
                    case .inbox:
                        include = false
                    }
                    return include ? LocatedTask(
                        projectID: project.id,
                        milestoneID: milestone.id,
                        projectTitle: project.title,
                        milestoneTitle: milestone.title,
                        task: task
                    ) : nil
                }
            }
        }
        .sorted { ($0.task.dueDate ?? .distantFuture) < ($1.task.dueDate ?? .distantFuture) }
    }

    var body: some View {
        List {
            if kind == .inbox {
                Section {
                    ForEach(store.data.inbox) { task in
                        TaskListRow(task: task) {
                            var updated = task
                            updated.stage = task.stage == .done ? .todo : .done
                            store.updateInboxTask(updated)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { editingInboxTask = task }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button("Edit", systemImage: "pencil") {
                                editingInboxTask = task
                            }
                            .tint(.purple)
                            Button(task.stage == .done ? "Reopen" : "Done", systemImage: "checkmark") {
                                var updated = task
                                updated.stage = task.stage == .done ? .todo : .done
                                store.updateInboxTask(updated)
                            }
                            .tint(task.stage == .done ? .orange : .green)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                store.deleteInboxTask(id: task.id)
                            }
                        }
                    }
                }
                if store.data.inbox.isEmpty {
                    ContentUnavailableView {
                        Label("Inbox Is Empty", systemImage: "tray")
                    } description: {
                        Text("Capture an idea below and organize it later.")
                    }
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(locatedTasks) { located in
                    Section("\(located.projectTitle) · \(located.milestoneTitle)") {
                        TaskListRow(task: located.task) {
                            store.moveTask(
                                projectID: located.projectID,
                                milestoneID: located.milestoneID,
                                taskID: located.task.id,
                                to: located.task.stage == .done ? .todo : .done
                            )
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { editingLocatedTask = located }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button("Edit", systemImage: "pencil") {
                                editingLocatedTask = located
                            }
                            .tint(.purple)
                            Button(located.task.stage == .done ? "Reopen" : "Done", systemImage: "checkmark") {
                                store.moveTask(
                                    projectID: located.projectID,
                                    milestoneID: located.milestoneID,
                                    taskID: located.task.id,
                                    to: located.task.stage == .done ? .todo : .done
                                )
                            }
                            .tint(located.task.stage == .done ? .orange : .green)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                store.deleteTask(
                                    projectID: located.projectID,
                                    milestoneID: located.milestoneID,
                                    taskID: located.task.id
                                )
                            }
                        }
                    }
                }
                if locatedTasks.isEmpty {
                    ContentUnavailableView {
                        Label(
                            kind == .today ? "Nothing Due Today" : "Nothing Upcoming",
                            systemImage: kind == .today ? "checkmark.circle" : "calendar"
                        )
                    } description: {
                        Text(kind == .today ? "You are all caught up." : "Tasks with future due dates will appear here.")
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(kind.title)
        .safeAreaInset(edge: .bottom) {
            if kind == .inbox {
                HStack {
                    TextField("Add to Inbox…", text: $quickTitle)
                        .submitLabel(.send)
                        .onSubmit(addInboxTask)
                    Button(action: addInboxTask) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                }
                .padding()
                .background(.bar)
            }
        }
        .sheet(item: $editingInboxTask) { task in
            TaskEditor(task: task) { store.updateInboxTask($0) }
        }
        .sheet(item: $editingLocatedTask) { located in
            TaskEditor(task: located.task) {
                store.updateTask(
                    projectID: located.projectID,
                    milestoneID: located.milestoneID,
                    task: $0
                )
            }
        }
    }

    private func addInboxTask() {
        let trimmed = quickTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addInboxTask(title: trimmed)
        quickTitle = ""
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: MilestonesStore
    @Environment(\.dismiss) private var dismiss
    @State private var newTag = ""
    @State private var newTagIcon = TagIcon.defaultValue
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    HStack {
                        Label("Tags", systemImage: "tag.fill")
                        Spacer()
                        Text(store.tags.count, format: .number)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("New tag", text: $newTag)
                        Menu {
                            ForEach(TagIcon.choices, id: \.self) { icon in
                                Button {
                                    newTagIcon = icon
                                } label: {
                                    Label(icon == newTagIcon ? "Selected" : "Use Icon", systemImage: icon)
                                }
                            }
                        } label: {
                            Image(systemName: newTagIcon)
                                .frame(width: 30, height: 30)
                        }
                        .accessibilityLabel("Choose hashtag icon")
                        Button("Add") {
                            let trimmed = newTag.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty { store.addTag(trimmed, icon: newTagIcon) }
                            newTag = ""
                            newTagIcon = TagIcon.defaultValue
                        }
                    }
                    ForEach(store.tags, id: \.self) { tag in
                        HStack {
                            Label(tag, systemImage: store.tagIcon(for: tag))
                            Spacer()
                            Button(role: .destructive) {
                                store.deleteTag(tag)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Storage") {
                    Label("Stored on this device", systemImage: "iphone")
                    Text("No account, cloud database, or iCloud entitlement is used.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Reset Sample Data", role: .destructive) {
                        confirmReset = true
                    }
                }

                Section {
                    Text("Milestones Local\nNative SwiftUI · Offline-first")
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Reset all local data?", isPresented: $confirmReset) {
                Button("Reset", role: .destructive) { store.reset() }
            }
        }
    }
}

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
    }
}

struct MetadataPill: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 5))
    }
}
