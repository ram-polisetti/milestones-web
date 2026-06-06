import SwiftUI

struct MilestoneListView: View {
    @EnvironmentObject private var store: MilestonesStore
    let projectID: UUID
    @Binding var selection: UUID?
    @State private var showForm = false
    @State private var showProjectEditor = false

    private var project: Project? { store.project(id: projectID) }

    var body: some View {
        Group {
            if let project {
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
                        ForEach(project.milestones.filter { !$0.isArchived }) { milestone in
                            MilestoneRow(milestone: milestone)
                                .tag(milestone.id)
                                .contextMenu {
                                    Button("Archive", systemImage: "archivebox") {
                                        store.archiveMilestone(projectID: projectID, milestoneID: milestone.id)
                                    }
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        store.deleteMilestone(projectID: projectID, milestoneID: milestone.id)
                                        if selection == milestone.id { selection = nil }
                                    }
                                }
                        }
                    }
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
                .safeAreaInset(edge: .bottom) {
                    Button {
                        showForm = true
                    } label: {
                        Label("New Milestone", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(Capsule())
                    .padding()
                    .background(.bar)
                }
                .sheet(isPresented: $showForm) {
                    MilestoneForm { title, status in
                        selection = store.addMilestone(projectID: projectID, title: title, status: status)
                    }
                }
                .sheet(isPresented: $showProjectEditor) {
                    ProjectEditor(project: project)
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

    var body: some View {
        List {
            if let project = store.project(id: projectID) {
                Section("To Do") {
                    ForEach(project.backlog) { task in
                        TaskListRow(task: task) {}
                    }
                }
            }
        }
        .navigationTitle("Backlog")
    }
}
