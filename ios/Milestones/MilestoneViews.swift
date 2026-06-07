import SwiftUI

struct MilestoneListView: View {
    @EnvironmentObject private var store: MilestonesStore
    let projectID: UUID
    @Binding var selection: UUID?
    @State private var showForm = false
    @State private var showProjectEditor = false
    @State private var editingMilestone: Milestone?

    private var project: Project? { store.project(id: projectID) }

    var body: some View {
        Group {
            if let project {
                ZStack(alignment: .bottom) {
                    List(selection: $selection) {
                        Section {
                            NavigationLink {
                                BacklogView(projectID: projectID)
                            } label: {
                                HStack {
                                    Label("Backlog", systemImage: "list.bullet.rectangle")
                                    Spacer()
                                    Text(project.backlog.count, format: .number)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Button {
                                showProjectEditor = true
                            } label: {
                                Label("Project Settings", systemImage: "gearshape")
                            }
                        }

                        Section("Milestones") {
                            let visibleMilestones = project.milestones.filter { !$0.isArchived }
                            ForEach(visibleMilestones) { milestone in
                                MilestoneRow(milestone: milestone)
                                    .tag(milestone.id)
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button("Edit", systemImage: "pencil") {
                                        editingMilestone = milestone
                                    }
                                    .tint(.purple)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button("Archive", systemImage: "archivebox") {
                                            store.archiveMilestone(projectID: projectID, milestoneID: milestone.id)
                                            if selection == milestone.id { selection = nil }
                                        }
                                        .tint(.orange)
                                        Button("Delete", systemImage: "trash", role: .destructive) {
                                            store.deleteMilestone(projectID: projectID, milestoneID: milestone.id)
                                            if selection == milestone.id { selection = nil }
                                        }
                                    }
                                    .contextMenu {
                                        Button("Edit", systemImage: "pencil") {
                                            editingMilestone = milestone
                                        }
                                        Button("Archive", systemImage: "archivebox") {
                                            store.archiveMilestone(projectID: projectID, milestoneID: milestone.id)
                                        }
                                        Button("Delete", systemImage: "trash", role: .destructive) {
                                            store.deleteMilestone(projectID: projectID, milestoneID: milestone.id)
                                            if selection == milestone.id { selection = nil }
                                        }
                                    }
                            }
                            if visibleMilestones.isEmpty {
                                ContentUnavailableView {
                                    Label("No Milestones", systemImage: "flag")
                                } description: {
                                    Text("Create a milestone to break this project into clear stages.")
                                } actions: {
                                    Button("New Milestone") { showForm = true }
                                        .buttonStyle(.borderedProminent)
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                    .contentMargins(.bottom, 88, for: .scrollContent)

                    Button {
                        showForm = true
                    } label: {
                        Label("New Milestone", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .shadow(color: .black.opacity(0.12), radius: 14, y: 7)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .zIndex(1)
                }
                .navigationTitle(project.title)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showForm = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showForm) {
                    MilestoneForm { title, status in
                        selection = store.addMilestone(projectID: projectID, title: title, status: status)
                    }
                }
                .sheet(isPresented: $showProjectEditor) {
                    ProjectEditor(project: project)
                }
                .sheet(item: $editingMilestone) { milestone in
                    MilestoneEditor(projectID: projectID, milestone: milestone)
                }
            }
        }
    }
}

struct MilestoneRow: View {
    let milestone: Milestone

    private var completed: Int {
        milestone.tasks.filter { $0.stage == .done }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                HStack(spacing: 7) {
                    if milestone.isActive {
                        Circle()
                            .fill(.green)
                            .frame(width: 9, height: 9)
                    }
                    Text(milestone.title)
                        .font(.headline)
                }
                Spacer()
                StatusPill(text: milestone.status, color: Color(hex: milestone.statusColor))
            }
            ProgressView(value: milestone.progress)
                .tint(.blue)
            HStack {
                Text("\(completed)/\(milestone.tasks.count) tasks completed")
                Spacer()
                Text(milestone.progress, format: .percent.precision(.fractionLength(0)))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
    }
}

struct ProjectEditor: View {
    @EnvironmentObject private var store: MilestonesStore
    @Environment(\.dismiss) private var dismiss
    @State var project: Project

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Name", text: $project.title)
                    TextField("SF Symbol", text: $project.symbol)
                    TextField("Hex color", text: $project.color)
                    TextField("Status", text: $project.status)
                }
                Section {
                    Button("Archive Project", role: .destructive) {
                        project.isArchived = true
                        store.updateProject(project)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Project Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateProject(project)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BacklogView: View {
    @EnvironmentObject private var store: MilestonesStore
    let projectID: UUID
    @State private var editingTask: MilestoneTask?

    var body: some View {
        List {
            if let project = store.project(id: projectID) {
                ForEach(TaskStage.allCases) { stage in
                    let tasks = project.backlog.filter { $0.stage == stage }
                    if !tasks.isEmpty {
                        Section(stage.rawValue) {
                            ForEach(tasks) { task in
                                TaskListRow(task: task) {
                                    store.moveBacklogTask(
                                        projectID: projectID,
                                        taskID: task.id,
                                        to: task.stage == .done ? .todo : .done
                                    )
                                }
                                .contentShape(Rectangle())
                                .onTapGesture { editingTask = task }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button("Edit", systemImage: "pencil") {
                                        editingTask = task
                                    }
                                    .tint(.purple)
                                    Button(task.stage == .done ? "Reopen" : "Done", systemImage: "checkmark") {
                                        store.moveBacklogTask(
                                            projectID: projectID,
                                            taskID: task.id,
                                            to: task.stage == .done ? .todo : .done
                                        )
                                    }
                                    .tint(task.stage == .done ? .orange : .green)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        store.deleteBacklogTask(projectID: projectID, taskID: task.id)
                                    }
                                }
                            }
                        }
                    }
                }
                if project.backlog.isEmpty {
                    ContentUnavailableView {
                        Label("Backlog Is Empty", systemImage: "tray")
                    } description: {
                        Text("Unscheduled tasks for this project will appear here.")
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Backlog")
        .sheet(item: $editingTask) { task in
            TaskEditor(task: task) {
                store.updateBacklogTask(projectID: projectID, task: $0)
            }
        }
    }
}
