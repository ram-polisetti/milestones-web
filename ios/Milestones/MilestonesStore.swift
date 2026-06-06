import Foundation
import Combine

@MainActor
final class MilestonesStore: ObservableObject {
    @Published private(set) var data: AppData

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent("milestones.json")
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let stored = try? Data(contentsOf: fileURL),
           let decoded = try? decoder.decode(AppData.self, from: stored) {
            data = decoded
        } else {
            data = Self.sampleData()
        }
    }

    var projects: [Project] { data.projects.filter { !$0.isArchived } }
    var archivedProjects: [Project] { data.projects.filter(\.isArchived) }
    var tags: [String] { data.tags }

    func project(id: UUID?) -> Project? {
        guard let id else { return nil }
        return data.projects.first { $0.id == id }
    }

    func milestone(projectID: UUID?, milestoneID: UUID?) -> Milestone? {
        guard let projectID, let milestoneID else { return nil }
        return project(id: projectID)?.milestones.first { $0.id == milestoneID }
    }

    func addProject(title: String, symbol: String, color: String) -> UUID {
        let project = Project(title: title, symbol: symbol, color: color, status: "Active")
        data.projects.append(project)
        save()
        return project.id
    }

    func updateProject(_ project: Project) {
        guard let index = data.projects.firstIndex(where: { $0.id == project.id }) else { return }
        data.projects[index] = project
        save()
    }

    func archiveProject(id: UUID) {
        mutateProject(id: id) { $0.isArchived = true }
    }

    func deleteProject(id: UUID) {
        data.projects.removeAll { $0.id == id }
        save()
    }

    func addMilestone(projectID: UUID, title: String, status: String) -> UUID {
        let milestone = Milestone(
            title: title,
            status: status,
            statusColor: Self.color(for: status),
            isActive: false
        )
        mutateProject(id: projectID) { project in
            if project.milestones.isEmpty { project.milestones.append(Milestone(
                id: milestone.id,
                title: milestone.title,
                status: milestone.status,
                statusColor: milestone.statusColor,
                isActive: true
            )) } else {
                project.milestones.append(milestone)
            }
        }
        return milestone.id
    }

    func updateMilestone(projectID: UUID, milestone: Milestone) {
        mutateProject(id: projectID) { project in
            guard let index = project.milestones.firstIndex(where: { $0.id == milestone.id }) else { return }
            if milestone.isActive {
                for itemIndex in project.milestones.indices {
                    project.milestones[itemIndex].isActive = false
                }
            }
            project.milestones[index] = milestone
        }
    }

    func archiveMilestone(projectID: UUID, milestoneID: UUID) {
        mutateMilestone(projectID: projectID, milestoneID: milestoneID) { $0.isArchived = true }
    }

    func deleteMilestone(projectID: UUID, milestoneID: UUID) {
        mutateProject(id: projectID) { project in
            project.milestones.removeAll { $0.id == milestoneID }
        }
    }

    func addTask(projectID: UUID, milestoneID: UUID, title: String, tags: [String] = [], priority: TaskPriority = .none, dueDate: Date? = nil) {
        let parsed = Self.parseQuickTask(title)
        let task = MilestoneTask(
            title: parsed.title,
            priority: parsed.priority ?? priority,
            dueDate: parsed.dueDate ?? dueDate,
            tags: Array(Set(tags + parsed.tags)).sorted()
        )
        mutateMilestone(projectID: projectID, milestoneID: milestoneID) {
            $0.tasks.insert(task, at: 0)
        }
    }

    func updateTask(projectID: UUID, milestoneID: UUID, task: MilestoneTask) {
        mutateMilestone(projectID: projectID, milestoneID: milestoneID) { milestone in
            guard let index = milestone.tasks.firstIndex(where: { $0.id == task.id }) else { return }
            milestone.tasks[index] = task
        }
    }

    func moveTask(projectID: UUID, milestoneID: UUID, taskID: UUID, to stage: TaskStage) {
        mutateMilestone(projectID: projectID, milestoneID: milestoneID) { milestone in
            guard let index = milestone.tasks.firstIndex(where: { $0.id == taskID }) else { return }
            milestone.tasks[index].stage = stage
        }
    }

    func deleteTask(projectID: UUID, milestoneID: UUID, taskID: UUID) {
        mutateMilestone(projectID: projectID, milestoneID: milestoneID) {
            $0.tasks.removeAll { $0.id == taskID }
        }
    }

    func addInboxTask(title: String) {
        let parsed = Self.parseQuickTask(title)
        data.inbox.insert(MilestoneTask(
            title: parsed.title,
            priority: parsed.priority ?? .none,
            dueDate: parsed.dueDate,
            tags: parsed.tags
        ), at: 0)
        save()
    }

    func updateInboxTask(_ task: MilestoneTask) {
        guard let index = data.inbox.firstIndex(where: { $0.id == task.id }) else { return }
        data.inbox[index] = task
        save()
    }

    func addTag(_ name: String) {
        guard !data.tags.contains(name) else { return }
        data.tags.append(name)
        data.tags.sort()
        save()
    }

    func deleteTag(_ name: String) {
        data.tags.removeAll { $0 == name }
        for projectIndex in data.projects.indices {
            for milestoneIndex in data.projects[projectIndex].milestones.indices {
                for taskIndex in data.projects[projectIndex].milestones[milestoneIndex].tasks.indices {
                    data.projects[projectIndex].milestones[milestoneIndex].tasks[taskIndex].tags.removeAll { $0 == name }
                }
            }
        }
        save()
    }

    func reset() {
        data = Self.sampleData()
        save()
    }

    func exportData() -> Data? {
        try? encoder.encode(data)
    }

    private func mutateProject(id: UUID, _ mutation: (inout Project) -> Void) {
        guard let index = data.projects.firstIndex(where: { $0.id == id }) else { return }
        mutation(&data.projects[index])
        save()
    }

    private func mutateMilestone(projectID: UUID, milestoneID: UUID, _ mutation: (inout Milestone) -> Void) {
        mutateProject(id: projectID) { project in
            guard let index = project.milestones.firstIndex(where: { $0.id == milestoneID }) else { return }
            mutation(&project.milestones[index])
        }
    }

    private func save() {
        guard let encoded = try? encoder.encode(data) else { return }
        try? encoded.write(to: fileURL, options: .atomic)
    }

    private static func color(for status: String) -> String {
        switch status {
        case "Released": "#30C968"
        case "In Review": "#E4C342"
        case "Planning": "#159EF2"
        case "Draft": "#9A9A9A"
        default: "#F08B55"
        }
    }

    private static func parseQuickTask(_ input: String) -> (title: String, tags: [String], dueDate: Date?, priority: TaskPriority?) {
        var titleParts: [String] = []
        var tags: [String] = []
        var dueDate: Date?
        var priority: TaskPriority?
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for part in input.split(separator: " ").map(String.init) {
            if part.hasPrefix("#"), part.count > 1 {
                tags.append(String(part.dropFirst()))
            } else if part.lowercased().hasPrefix("due:") {
                dueDate = formatter.date(from: String(part.dropFirst(4)))
            } else if part.lowercased().hasPrefix("priority:") {
                priority = TaskPriority(rawValue: String(part.dropFirst(9)).capitalized)
            } else {
                titleParts.append(part)
            }
        }
        let title = titleParts.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        return (title.isEmpty ? input : title, tags, dueDate, priority)
    }

    static func sampleData() -> AppData {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: .now)

        let storage = Milestone(
            title: "Local storage",
            status: "In Progress",
            statusColor: "#F08B55",
            isActive: true,
            tasks: [
                MilestoneTask(title: "Define local schema", stage: .done, priority: .medium, tags: ["Feature"]),
                MilestoneTask(title: "Write migration plan", stage: .done, tags: ["Feature"]),
                MilestoneTask(title: "Build import and export", stage: .inProgress, priority: .medium, tags: ["Feature"]),
                MilestoneTask(title: "Add offline queue", stage: .inProgress, priority: .medium, dueDate: tomorrow, tags: ["Feature"]),
                MilestoneTask(title: "Polish storage UI", stage: .inProgress, priority: .low, tags: ["Refactor"]),
                MilestoneTask(title: "Add settings toggle", priority: .low, tags: ["Feature"]),
                MilestoneTask(title: "Write telemetry events", priority: .medium, tags: ["Feature"]),
                MilestoneTask(title: "Design error states", priority: .high, dueDate: yesterday, tags: ["Bug"]),
                MilestoneTask(title: "Track storage metrics"),
                MilestoneTask(title: "Run release checklist", priority: .high),
            ]
        )

        return AppData(
            projects: [
                Project(
                    title: "iOS App",
                    symbol: "iphone",
                    color: "#159EF2",
                    status: "In Progress",
                    backlog: [
                        MilestoneTask(title: "Improve dark mode contrast", priority: .high, tags: ["Bug"]),
                        MilestoneTask(title: "Siri shortcuts", priority: .medium, tags: ["Feature"]),
                    ],
                    milestones: [
                        storage,
                        Milestone(title: "Onboarding revamp", status: "Released", statusColor: "#30C968", tasks: [
                            MilestoneTask(title: "Map first-run flow", stage: .done),
                            MilestoneTask(title: "Build welcome screen", stage: .done),
                            MilestoneTask(title: "Add sample project", stage: .done),
                            MilestoneTask(title: "Ship onboarding", stage: .done),
                        ]),
                        Milestone(title: "Paywall A/B test", status: "In Review", statusColor: "#E4C342", tasks: [
                            MilestoneTask(title: "Variant A", stage: .done),
                            MilestoneTask(title: "Variant B", stage: .done),
                            MilestoneTask(title: "Event tracking", stage: .done),
                            MilestoneTask(title: "Review results", stage: .inProgress),
                            MilestoneTask(title: "Choose winner"),
                        ]),
                        Milestone(title: "Home screen widgets", status: "Planning", statusColor: "#159EF2"),
                        Milestone(title: "Launch on Product Hunt", status: "Draft", statusColor: "#9A9A9A"),
                    ]
                ),
                Project(title: "Personal Website", symbol: "globe", color: "#B31FC3", status: "Active", milestones: [
                    Milestone(title: "Launch blog", status: "Active", statusColor: "#159EF2", isActive: true, tasks: [
                        MilestoneTask(title: "Choose publishing stack", stage: .inProgress, tags: ["Feature"]),
                        MilestoneTask(title: "Draft first article"),
                        MilestoneTask(title: "Design article template"),
                    ])
                ]),
                Project(title: "Side Project Book", symbol: "book.closed.fill", color: "#ED8508", status: "Idea", milestones: [
                    Milestone(title: "Write outline", status: "Idea", statusColor: "#E4C342", isActive: true, tasks: [
                        MilestoneTask(title: "Collect chapter ideas", stage: .inProgress)
                    ])
                ]),
                Project(title: "Newsletter", symbol: "envelope.fill", color: "#E91849", status: "Active"),
                Project(title: "Podcast", symbol: "mic.fill", color: "#EF3032", status: "In Progress"),
                Project(title: "Indie Game", symbol: "gamecontroller.fill", color: "#19B957", status: "Idea"),
            ],
            inbox: [
                MilestoneTask(title: "Review App Store screenshots", dueDate: .now, tags: ["Feature"]),
                MilestoneTask(title: "Reply to beta feedback", priority: .high),
            ],
            tags: ["Bug", "Feature", "Refactor"]
        )
    }
}
