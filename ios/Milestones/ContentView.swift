import SwiftUI

enum SidebarSelection: Hashable {
    case today
    case upcoming
    case inbox
    case project(UUID)
}

struct ContentView: View {
    @EnvironmentObject private var store: MilestonesStore
    @State private var sidebarSelection: SidebarSelection? = .project(MilestonesStore.sampleData().projects[0].id)
    @State private var selectedProjectID: UUID?
    @State private var selectedMilestoneID: UUID?
    @State private var showProjectForm = false
    @State private var showSettings = false
    @State private var searchText = ""

    private var selectedProject: Project? {
        store.project(id: selectedProjectID)
    }

    var body: some View {
        NavigationSplitView {
            ProjectSidebar(
                selection: $sidebarSelection,
                searchText: $searchText,
                showProjectForm: $showProjectForm,
                showSettings: $showSettings
            )
            .navigationSplitViewColumnWidth(min: 260, ideal: 300)
        } content: {
            contentColumn
                .navigationSplitViewColumnWidth(min: 310, ideal: 360)
        } detail: {
            detailColumn
        }
        .onAppear {
            if selectedProjectID == nil {
                selectedProjectID = store.projects.first?.id
                sidebarSelection = selectedProjectID.map(SidebarSelection.project)
                selectedMilestoneID = store.project(id: selectedProjectID)?.activeMilestone?.id
            }
        }
        .onChange(of: sidebarSelection) { _, selection in
            guard case let .project(id) = selection else {
                selectedProjectID = nil
                selectedMilestoneID = nil
                return
            }
            selectedProjectID = id
            selectedMilestoneID = store.project(id: id)?.activeMilestone?.id
        }
        .sheet(isPresented: $showProjectForm) {
            ProjectForm { title, symbol, color in
                let id = store.addProject(title: title, symbol: symbol, color: color)
                sidebarSelection = .project(id)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    @ViewBuilder
    private var contentColumn: some View {
        switch sidebarSelection {
        case .today:
            SmartListView(kind: .today)
        case .upcoming:
            SmartListView(kind: .upcoming)
        case .inbox:
            SmartListView(kind: .inbox)
        case .project:
            if let project = selectedProject {
                MilestoneListView(projectID: project.id, selection: $selectedMilestoneID)
            } else {
                ContentUnavailableView("Select a project", systemImage: "rectangle.stack")
            }
        case nil:
            ContentUnavailableView("Select a list", systemImage: "sidebar.left")
        }
    }

    @ViewBuilder
    private var detailColumn: some View {
        if let projectID = selectedProjectID,
           let milestoneID = selectedMilestoneID,
           store.milestone(projectID: projectID, milestoneID: milestoneID) != nil {
            TaskBoardView(projectID: projectID, milestoneID: milestoneID)
        } else if case .project = sidebarSelection {
            ContentUnavailableView("Select a milestone", systemImage: "flag")
        } else {
            ContentUnavailableView("Tasks", systemImage: "checklist")
        }
    }
}

struct ProjectSidebar: View {
    @EnvironmentObject private var store: MilestonesStore
    @Binding var selection: SidebarSelection?
    @Binding var searchText: String
    @Binding var showProjectForm: Bool
    @Binding var showSettings: Bool
    @FocusState private var searchFocused: Bool

    private var projects: [Project] {
        guard !searchText.isEmpty else { return store.projects }
        return store.projects.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List(selection: $selection) {
            Section {
                Label("Today", systemImage: "star.fill")
                    .foregroundStyle(.primary)
                    .tag(SidebarSelection.today)
                Label("Upcoming", systemImage: "calendar")
                    .tag(SidebarSelection.upcoming)
                Label("Inbox", systemImage: "tray")
                    .tag(SidebarSelection.inbox)
            }

            Section {
                ForEach(projects) { project in
                    ProjectRow(project: project)
                        .tag(SidebarSelection.project(project.id))
                        .contextMenu {
                            Button("Archive", systemImage: "archivebox") {
                                store.archiveProject(id: project.id)
                            }
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                store.deleteProject(id: project.id)
                            }
                        }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            projectBottomControls
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                ASCIIBrandMark(size: 36)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showProjectForm = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New project")
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                }
                .accessibilityLabel("Settings")
            }
        }
    }

    private var projectBottomControls: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.medium))
                TextField("Search", text: $searchText)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        searchFocused = false
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color(uiColor: .systemBackground), in: Capsule())
            .shadow(color: .black.opacity(0.13), radius: 20, y: 9)

            Button {
                showProjectForm = true
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.accentColor, in: Circle())
            }
            .buttonStyle(.plain)
            .shadow(color: .black.opacity(0.15), radius: 14, y: 7)
            .accessibilityLabel("New Project")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct ProjectRow: View {
    let project: Project

    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: project.color).gradient)
                ProjectIcon(value: project.symbol)
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(project.title)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    StatusPill(text: project.status, color: .orange)
                }
                if let active = project.activeMilestone {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text(active.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Text(active.progress, format: .percent.precision(.fractionLength(0)))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: active.progress)
                        .tint(.blue)
                } else {
                    Text("No active milestone")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .padding(.vertical, 3)
    }
}
