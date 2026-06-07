import SwiftUI

enum TaskViewMode: String {
    case list
    case kanban
}

struct TaskBoardView: View {
    @EnvironmentObject private var store: MilestonesStore
    let projectID: UUID
    let milestoneID: UUID
    @AppStorage("taskViewMode") private var storedViewMode = TaskViewMode.list.rawValue
    @State private var quickTitle = ""
    @State private var quickNotes = ""
    @State private var quickTags: Set<String> = []
    @State private var quickPriority: TaskPriority = .none
    @State private var quickStage: TaskStage = .todo
    @State private var quickDueDate: Date?
    @State private var quickRecurrence: TaskRecurrence?
    @State private var showDueDatePicker = false
    @State private var showDescription = false
    @State private var showComposerHelp = false
    @State private var editingTask: MilestoneTask?
    @State private var composerActivated = false
    @FocusState private var quickEntryFocused: Bool

    private var milestone: Milestone? {
        store.milestone(projectID: projectID, milestoneID: milestoneID)
    }

    private var viewMode: TaskViewMode {
        get { TaskViewMode(rawValue: storedViewMode) ?? .list }
        nonmutating set { storedViewMode = newValue.rawValue }
    }

    var body: some View {
        Group {
            if let milestone {
                ZStack(alignment: .bottom) {
                    if viewMode == .list {
                        TaskList(
                            milestone: milestone,
                            onEdit: { editingTask = $0 },
                            onToggle: toggle,
                            onDelete: delete,
                            onAdd: beginTask
                        )
                    } else {
                        KanbanView(
                            milestone: milestone,
                            onEdit: { editingTask = $0 },
                            onToggle: toggle,
                            onMove: move,
                            onDelete: delete
                        )
                    }
                    TaskComposer(
                        text: $quickTitle,
                        notes: $quickNotes,
                        selectedTags: $quickTags,
                        priority: $quickPriority,
                        stage: $quickStage,
                        dueDate: $quickDueDate,
                        recurrence: $quickRecurrence,
                        showDescription: $showDescription,
                        showDueDatePicker: $showDueDatePicker,
                        isActivated: $composerActivated,
                        focused: $quickEntryFocused,
                        availableTags: store.tags,
                        submit: addQuickTask
                    )
                    .zIndex(1)
                }
                .navigationTitle(milestone.title)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            withAnimation(.snappy) {
                                viewMode = viewMode == .list ? .kanban : .list
                            }
                        } label: {
                            Image(systemName: viewMode == .list ? "rectangle.split.3x1" : "list.bullet")
                        }
                        .accessibilityLabel(viewMode == .list ? "Show Kanban board" : "Show task list")
                        Button {
                            showComposerHelp = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                    }
                }
                .sheet(item: $editingTask) { task in
                    TaskEditor(task: task) { updated in
                        store.updateTask(projectID: projectID, milestoneID: milestoneID, task: updated)
                    }
                }
                .sheet(isPresented: $showDueDatePicker) {
                    DueDatePickerSheet(date: $quickDueDate)
                }
                .alert("Quick task controls", isPresented: $showComposerHelp) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Add tags, a due date, description, recurrence, status, and priority before sending the task.")
                }
            }
        }
    }

    private func addQuickTask() {
        let trimmed = quickTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addTask(
            projectID: projectID,
            milestoneID: milestoneID,
            title: trimmed,
            notes: quickNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            stage: quickStage,
            tags: Array(quickTags),
            priority: quickPriority,
            dueDate: quickDueDate,
            recurrence: quickRecurrence
        )
        quickTitle = ""
        quickNotes = ""
        quickTags = []
        quickPriority = .none
        quickStage = .todo
        quickDueDate = nil
        quickRecurrence = nil
        showDescription = false
    }

    private func toggle(_ task: MilestoneTask) {
        store.moveTask(
            projectID: projectID,
            milestoneID: milestoneID,
            taskID: task.id,
            to: task.stage == .done ? .todo : .done
        )
    }

    private func move(_ taskID: UUID, _ stage: TaskStage) {
        store.moveTask(projectID: projectID, milestoneID: milestoneID, taskID: taskID, to: stage)
    }

    private func delete(_ task: MilestoneTask) {
        store.deleteTask(projectID: projectID, milestoneID: milestoneID, taskID: task.id)
    }

    private func beginTask(in stage: TaskStage) {
        quickStage = stage
        withAnimation(.easeInOut(duration: 0.18)) {
            composerActivated = true
        }
        quickEntryFocused = true
    }
}

struct TaskList: View {
    let milestone: Milestone
    let onEdit: (MilestoneTask) -> Void
    let onToggle: (MilestoneTask) -> Void
    let onDelete: (MilestoneTask) -> Void
    let onAdd: (TaskStage) -> Void

    var body: some View {
        List {
            ForEach(TaskStage.allCases, id: \.self) { stage in
                let tasks = milestone.tasks.filter { $0.stage == stage }
                Section {
                    ForEach(tasks) { task in
                        TaskListRow(task: task) {
                            onToggle(task)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { onEdit(task) }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                onDelete(task)
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button("Edit", systemImage: "pencil") {
                                onEdit(task)
                            }
                            .tint(.purple)
                            Button(task.stage == .done ? "Reopen" : "Done", systemImage: "checkmark") {
                                onToggle(task)
                            }
                            .tint(task.stage == .done ? .orange : .green)
                        }
                    }

                    Button {
                        onAdd(stage)
                    } label: {
                        Label("Add Task", systemImage: "plus")
                            .font(.body)
                            .foregroundStyle(stage.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 0, leading: 38, bottom: 0, trailing: 16))
                    .listRowSeparator(.hidden)
                } header: {
                    TaskSectionHeader(stage: stage, count: tasks.count)
                }
            }
        }
        .listStyle(.plain)
        .background(Color(uiColor: .systemBackground))
        .contentMargins(.bottom, 76, for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
    }
}

struct TaskSectionHeader: View {
    let stage: TaskStage
    let count: Int

    var body: some View {
        HStack(spacing: 7) {
            Text(stage.rawValue)
                .font(.title3.weight(.bold))
                .foregroundStyle(stage.color)
                .textCase(nil)
            Text(count, format: .number)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 4)
    }
}

struct TaskListRow: View {
    @EnvironmentObject private var store: MilestonesStore
    let task: MilestoneTask
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .strokeBorder(completionColor, lineWidth: 1.8)
                    if task.stage == .done {
                        Circle()
                            .fill(completionColor)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    } else if task.stage == .inProgress {
                        Circle()
                            .fill(completionColor.opacity(0.18))
                            .padding(3.5)
                    }
                }
                .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .padding(.top, 1)
            .accessibilityLabel(task.stage == .done ? "Mark incomplete" : "Mark complete")

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.stage == .done)
                    .foregroundStyle(task.stage == .done ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !task.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(task.notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if hasMetadata {
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            if let dueDate = task.dueDate {
                                ReminderDetail(
                                    text: dueDate.dueDateLabel,
                                    systemImage: "calendar",
                                    color: dueDate.isOverdue && task.stage != .done ? .red : .secondary
                                )
                            }
                            if task.priority != .none {
                                ReminderDetail(
                                    text: task.priority.rawValue,
                                    systemImage: "flag.fill",
                                    color: task.priority.color
                                )
                            }
                            if let recurrence = task.recurrence {
                                ReminderDetail(text: recurrence.rawValue, systemImage: "repeat", color: .purple)
                            }
                            ForEach(task.tags, id: \.self) { tag in
                                ReminderDetail(text: tag, systemImage: store.tagIcon(for: tag), color: .blue)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .padding(.vertical, 6)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .listRowSeparatorTint(Color(uiColor: .separator).opacity(0.55))
        .alignmentGuide(.listRowSeparatorLeading) { _ in 50 }
        .accessibilityElement(children: .combine)
    }

    private var completionColor: Color {
        switch task.stage {
        case .todo: .gray
        case .inProgress, .done: .blue
        }
    }

    private var hasMetadata: Bool {
        task.dueDate != nil
            || task.priority != .none
            || task.recurrence != nil
            || !task.tags.isEmpty
    }
}

struct ReminderDetail: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(color)
            .fixedSize()
    }
}

struct KanbanView: View {
    let milestone: Milestone
    let onEdit: (MilestoneTask) -> Void
    let onToggle: (MilestoneTask) -> Void
    let onMove: (UUID, TaskStage) -> Void
    let onDelete: (MilestoneTask) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(TaskStage.allCases) { stage in
                    KanbanColumn(
                        title: stage.rawValue,
                        stage: stage,
                        tasks: milestone.tasks.filter { $0.stage == stage },
                        onEdit: onEdit,
                        onToggle: onToggle,
                        onMove: onMove,
                        onDelete: onDelete
                    )
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .safeAreaPadding(.bottom, 76)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

struct KanbanColumn: View {
    let title: String
    let stage: TaskStage
    let tasks: [MilestoneTask]
    let onEdit: (MilestoneTask) -> Void
    let onToggle: (MilestoneTask) -> Void
    let onMove: (UUID, TaskStage) -> Void
    let onDelete: (MilestoneTask) -> Void
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(tasks.count, format: .number)
                    .font(.caption2)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }

            ForEach(tasks) { task in
                KanbanCard(task: task, onToggle: { onToggle(task) }, onDelete: { onDelete(task) })
                    .onTapGesture { onEdit(task) }
                    .draggable(task.id.uuidString)
            }

            if tasks.isEmpty {
                Text("Drop a task here")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .overlay {
                        RoundedRectangle(cornerRadius: 13)
                            .strokeBorder(.tertiary, style: StrokeStyle(lineWidth: 1, dash: [5]))
                    }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(width: 280, alignment: .top)
        .frame(minHeight: 180, alignment: .top)
        .background(isTargeted ? Color.blue.opacity(0.12) : Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(isTargeted ? Color.blue : .clear, lineWidth: 2)
        }
        .dropDestination(for: String.self) { items, _ in
            guard let rawID = items.first, let id = UUID(uuidString: rawID) else { return false }
            onMove(id, stage)
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }
}

struct KanbanCard: View {
    @EnvironmentObject private var store: MilestonesStore
    let task: MilestoneTask
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                Button(action: onToggle) {
                    Image(systemName: task.stage == .done ? "checkmark.circle.fill" : "circle.fill")
                        .foregroundStyle(task.stage.color)
                }
                .buttonStyle(.plain)
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(task.stage == .done)
                Spacer()
                Menu {
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 5) {
                if let dueDate = task.dueDate {
                    MetadataPill(
                        text: dueDate.dueDateLabel,
                        systemImage: "calendar",
                        color: dueDate.isOverdue && task.stage != .done ? .red : .secondary
                    )
                }
                if task.priority != .none {
                    MetadataPill(text: task.priority.rawValue, systemImage: task.priority.symbol, color: task.priority.color)
                }
                if let recurrence = task.recurrence {
                    MetadataPill(text: recurrence.rawValue, systemImage: "repeat", color: .purple)
                }
                ForEach(task.tags, id: \.self) { tag in
                    MetadataPill(text: tag, systemImage: store.tagIcon(for: tag), color: .blue)
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 13))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .accessibilityElement(children: .combine)
    }
}

struct TaskComposer: View {
    @EnvironmentObject private var store: MilestonesStore
    @Binding var text: String
    @Binding var notes: String
    @Binding var selectedTags: Set<String>
    @Binding var priority: TaskPriority
    @Binding var stage: TaskStage
    @Binding var dueDate: Date?
    @Binding var recurrence: TaskRecurrence?
    @Binding var showDescription: Bool
    @Binding var showDueDatePicker: Bool
    @Binding var isActivated: Bool
    var focused: FocusState<Bool>.Binding
    let availableTags: [String]
    let submit: () -> Void
    @State private var showOptions = false

    private var hasDraftDetails: Bool {
        showDescription
            || !selectedTags.isEmpty
            || priority != .none
            || dueDate != nil
            || recurrence != nil
            || stage != .todo
    }

    private var isExpanded: Bool {
        isActivated
            || focused.wrappedValue
            || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || hasDraftDetails
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                if !isActivated {
                    Image(systemName: "plus")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                }
                TextField("Add a new task…", text: $text, axis: .vertical)
                    .lineLimit(3)
                    .focused(focused)
                    .submitLabel(.send)
                    .onSubmit(submitTask)
            }

            if showDescription {
                Divider()
                TextField("Description (optional)", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
                    .font(.subheadline)
            }

            if showOptions {
                ComposerMetadata(
                    tags: Array(selectedTags).sorted(),
                    priority: priority,
                    stage: stage,
                    dueDate: dueDate,
                    recurrence: recurrence
                )
            }

            if showOptions {
                HStack(spacing: 8) {
                    Menu {
                        if availableTags.isEmpty {
                            Text("Create tags in Settings")
                        } else {
                            ForEach(availableTags, id: \.self) { tag in
                                Button {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                } label: {
                                    Label {
                                        Text(tag)
                                    } icon: {
                                        Image(systemName: selectedTags.contains(tag) ? "checkmark.circle.fill" : store.tagIcon(for: tag))
                                            .foregroundStyle(selectedTags.contains(tag) ? .blue : .secondary)
                                    }
                                }
                            }
                        }
                    } label: {
                        ComposerButton(systemImage: "number", active: !selectedTags.isEmpty)
                    }
                    .accessibilityLabel("Tags")

                    Button {
                        showDueDatePicker = true
                    } label: {
                        ComposerButton(systemImage: "calendar", active: dueDate != nil)
                    }
                    .accessibilityLabel("Due date")

                    Button {
                        withAnimation(.snappy) { showDescription.toggle() }
                    } label: {
                        ComposerButton(systemImage: "text.alignleft", active: showDescription || !notes.isEmpty)
                    }
                    .accessibilityLabel("Description")

                    Menu {
                        Button("No recurrence") { recurrence = nil }
                        ForEach(TaskRecurrence.allCases) { option in
                            Button {
                                recurrence = option
                            } label: {
                                Label(option.rawValue, systemImage: recurrence == option ? "checkmark" : "repeat")
                            }
                        }
                    } label: {
                        ComposerButton(systemImage: "repeat", active: recurrence != nil)
                    }
                    .accessibilityLabel("Recurrence")

                    Menu {
                        Section("Status") {
                            ForEach(TaskStage.allCases) { option in
                                Button {
                                    stage = option
                                } label: {
                                    Label {
                                        Text(option.rawValue)
                                    } icon: {
                                        Image(systemName: stage == option ? "checkmark.circle.fill" : option.menuSymbol)
                                            .foregroundStyle(option.color)
                                    }
                                }
                            }
                        }
                        Section("Priority") {
                            ForEach(TaskPriority.allCases) { option in
                                Button {
                                    priority = option
                                } label: {
                                    Label {
                                        Text(option.rawValue)
                                    } icon: {
                                        Image(systemName: priority == option ? "checkmark.circle.fill" : option.symbol)
                                            .foregroundStyle(option.color)
                                    }
                                }
                            }
                        }
                    } label: {
                        ComposerButton(systemImage: "flag", active: priority != .none || stage != .todo)
                    }
                    .accessibilityLabel("Status and priority")

                    Spacer()

                    Button {
                        focused.wrappedValue = false
                    } label: {
                        ComposerButton(systemImage: "keyboard.chevron.compact.down", active: false)
                    }
                    .accessibilityLabel("Dismiss keyboard")

                    Button(action: submitTask) {
                        Image(systemName: "arrow.up")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(.blue, in: Circle())
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                    .accessibilityLabel("Add task")
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, isExpanded ? 14 : 13)
        .padding(.vertical, isExpanded ? 14 : 12)
        .background(
            isExpanded ? AnyShapeStyle(.thickMaterial) : AnyShapeStyle(Color(uiColor: .systemBackground)),
            in: isExpanded ? AnyShape(RoundedRectangle(cornerRadius: 22)) : AnyShape(Capsule())
        )
        .overlay {
            if isExpanded {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
            }
        }
        .shadow(color: .black.opacity(isExpanded ? 0.12 : 0.13), radius: isExpanded ? 18 : 20, y: isExpanded ? 8 : 9)
        .padding(.horizontal, isExpanded ? 16 : 26)
        .padding(.top, 9)
        .padding(.bottom, isExpanded ? 9 : 0)
        .background(.clear)
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(.snappy, value: isExpanded)
        .onChange(of: focused.wrappedValue) { _, isFocused in
            guard isFocused else { return }
            activateComposer()
        }
    }

    private func activateComposer() {
        guard !isActivated || !showOptions else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            isActivated = true
            showOptions = true
        }
    }

    private func submitTask() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        submit()
        focused.wrappedValue = false
        withAnimation(.easeInOut(duration: 0.25)) {
            showOptions = false
            isActivated = false
        }
    }
}

struct ComposerButton: View {
    let systemImage: String
    let active: Bool

    var body: some View {
        Image(systemName: systemImage)
            .font(.body.weight(.medium))
            .foregroundStyle(active ? .blue : .primary)
            .frame(width: 36, height: 36)
            .background(active ? Color.blue.opacity(0.12) : Color(uiColor: .systemGray5), in: Circle())
    }
}

struct ComposerMetadata: View {
    @EnvironmentObject private var store: MilestonesStore
    let tags: [String]
    let priority: TaskPriority
    let stage: TaskStage
    let dueDate: Date?
    let recurrence: TaskRecurrence?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                if let dueDate {
                    MetadataPill(text: dueDate.dueDateLabel, systemImage: "calendar", color: .blue)
                }
                if priority != .none {
                    MetadataPill(text: priority.rawValue, systemImage: priority.symbol, color: priority.color)
                }
                if stage != .todo {
                    MetadataPill(text: stage.rawValue, systemImage: "flag.fill", color: stage.color)
                }
                if let recurrence {
                    MetadataPill(text: recurrence.rawValue, systemImage: "repeat", color: .purple)
                }
                ForEach(tags, id: \.self) { tag in
                    MetadataPill(text: tag, systemImage: store.tagIcon(for: tag), color: .blue)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

struct DueDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date?
    @State private var selectedDay: Date
    @State private var selectedTime: Date
    @State private var isAllDay: Bool

    init(date: Binding<Date?>) {
        _date = date
        let initialDate = date.wrappedValue ?? Calendar.current.startOfDay(for: .now)
        _selectedDay = State(initialValue: initialDate)
        _selectedTime = State(initialValue: initialDate.hasDueTime ? initialDate : .now)
        _isAllDay = State(initialValue: !initialDate.hasDueTime)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "Date",
                    selection: $selectedDay,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)

                Section {
                    Toggle("All Day", isOn: $isAllDay)
                    if !isAllDay {
                        DatePicker(
                            "Time",
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                if date != nil {
                    Button("Remove Due Date", role: .destructive) {
                        date = nil
                        dismiss()
                    }
                }
            }
            .navigationTitle("Due Date")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if isAllDay {
                            date = Calendar.current.startOfDay(for: selectedDay)
                        } else {
                            date = Calendar.current.date(
                                bySettingHour: Calendar.current.component(.hour, from: selectedTime),
                                minute: Calendar.current.component(.minute, from: selectedTime),
                                second: 0,
                                of: selectedDay
                            )
                        }
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
