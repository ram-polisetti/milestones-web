import SwiftUI

struct ProjectForm: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var symbol = "iphone"
    @State private var color = "#159EF2"
    let onSave: (String, String, String) -> Void

    private let symbols = ["iphone", "globe", "book.closed.fill", "envelope.fill", "mic.fill", "gamecontroller.fill"]
    private let colors = ["#159EF2", "#B31FC3", "#ED8508", "#E91849", "#EF3032", "#19B957"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Project name", text: $title)
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                        ForEach(symbols, id: \.self) { item in
                            Button {
                                symbol = item
                            } label: {
                                Image(systemName: item)
                                    .frame(width: 38, height: 38)
                                    .background(symbol == item ? Color.blue.opacity(0.15) : .clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 9))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section("Color") {
                    HStack {
                        ForEach(colors, id: \.self) { item in
                            Button {
                                color = item
                            } label: {
                                Circle()
                                    .fill(Color(hex: item))
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if color == item {
                                            Circle().stroke(.primary, lineWidth: 2).padding(-3)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
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
        .presentationDetents([.medium, .large])
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
                        ForEach(TaskStage.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Priority", selection: $task.priority) {
                        ForEach(TaskPriority.allCases) { Text($0.rawValue).tag($0) }
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
                        Toggle(tag, isOn: Binding(
                            get: { task.tags.contains(tag) },
                            set: { enabled in
                                if enabled {
                                    if !task.tags.contains(tag) { task.tags.append(tag) }
                                } else {
                                    task.tags.removeAll { $0 == tag }
                                }
                            }
                        ))
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
                    }
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
                    }
                }
            }
        }
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
                        Button("Add") {
                            let trimmed = newTag.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty { store.addTag(trimmed) }
                            newTag = ""
                        }
                    }
                    ForEach(store.tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
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
