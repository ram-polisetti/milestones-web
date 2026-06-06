import SwiftUI

enum TaskViewMode {
    case list
    case kanban
}

struct TaskBoardView: View {
    @EnvironmentObject private var store: MilestonesStore
    let projectID: UUID
    let milestoneID: UUID
    @State private var viewMode: TaskViewMode = .list
    @State private var quickTitle = ""
    @State private var editingTask: MilestoneTask?
    @FocusState private var quickEntryFocused: Bool

    private var milestone: Milestone? {
        store.milestone(projectID: projectID, milestoneID: milestoneID)
    }

    var body: some View {
        Group {
            if let milestone {
                VStack(spacing: 0) {
                    if viewMode == .list {
                        TaskList(
                            milestone: milestone,
                            onEdit: { editingTask = $0 },
                            onToggle: toggle,
                            onDelete: delete
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
                    QuickTaskBar(text: $quickTitle, focused: $quickEntryFocused, submit: addQuickTask)
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
                        Button {
                            quickEntryFocused = true
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                    }
                }
                .sheet(item: $editingTask) { task in
                    TaskEditor(task: task) { updated in
                        store.updateTask(projectID: projectID, milestoneID: milestoneID, task: updated)
                    }
                }
            }
        }
    }

    private func addQuickTask() {
        let trimmed = quickTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addTask(projectID: projectID, milestoneID: milestoneID, title: trimmed)
        quickTitle = ""
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
}

struct TaskList: View {
    let milestone: Milestone
    let onEdit: (MilestoneTask) -> Void
    let onToggle: (MilestoneTask) -> Void
    let onDelete: (MilestoneTask) -> Void

    var body: some View {
        List {
            ForEach(TaskStage.allCases, id: \.self) { stage in
                let tasks = milestone.tasks.filter { $0.stage == stage }
                if !tasks.isEmpty {
                    Section(stage.rawValue) {
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
                            .swipeActions(edge: .leading) {
                                Button(task.stage == .done ? "Reopen" : "Done", systemImage: "checkmark") {
                                    onToggle(task)
                                }
                                .tint(task.stage == .done ? .gray : .green)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct TaskListRow: View {
    let task: MilestoneTask
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: task.stage == .done ? "checkmark.circle.fill" : "circle.fill")
                    .foregroundStyle(task.stage.color)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .strikethrough(task.stage == .done)
                    .foregroundStyle(task.stage == .done ? .secondary : .primary)

                HStack(spacing: 5) {
                    if let dueDate = task.dueDate {
                        MetadataPill(
                            text: dueDate.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar",
                            color: dueDate < .now && task.stage != .done ? .red : .secondary
                        )
                    }
                    if task.priority != .none {
                        MetadataPill(
                            text: task.priority.rawValue,
                            systemImage: task.priority.symbol,
                            color: task.priority.color
                        )
                    }
                    ForEach(task.tags, id: \.self) { tag in
                        MetadataPill(text: tag, systemImage: "sparkles", color: .blue)
                    }
                }
            }
        }
        .padding(.vertical, 3)
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
                if task.priority != .none {
                    MetadataPill(text: task.priority.rawValue, systemImage: task.priority.symbol, color: task.priority.color)
                }
                ForEach(task.tags, id: \.self) { tag in
                    MetadataPill(text: tag, systemImage: "sparkles", color: .blue)
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 13))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct QuickTaskBar: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    let submit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("Add a new task…", text: $text)
                .focused(focused)
                .submitLabel(.send)
                .onSubmit(submit)
            Button(action: submit) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(12)
        .background(.bar)
    }
}
