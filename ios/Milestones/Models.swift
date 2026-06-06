import Foundation
import SwiftUI

enum TaskStage: String, Codable, CaseIterable, Identifiable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case done = "Done"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .todo: .gray
        case .inProgress: .blue
        case .done: .green
        }
    }
}

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .none: .secondary
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }

    var symbol: String {
        switch self {
        case .none: "minus"
        case .low: "arrow.down"
        case .medium: "equal"
        case .high: "exclamationmark.3"
        }
    }
}

enum TaskRecurrence: String, Codable, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { rawValue }
}

struct MilestoneTask: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var notes = ""
    var stage: TaskStage = .todo
    var priority: TaskPriority = .none
    var dueDate: Date?
    var tags: [String] = []
    var recurrence: TaskRecurrence?
    var createdAt = Date()
}

struct Milestone: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var status: String
    var statusColor: String
    var isActive = false
    var isArchived = false
    var tasks: [MilestoneTask] = []

    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        let points = tasks.reduce(0.0) { result, task in
            switch task.stage {
            case .done: result + 1
            case .inProgress: result + 0.5
            case .todo: result
            }
        }
        return points / Double(tasks.count)
    }
}

struct Project: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var symbol: String
    var color: String
    var status: String
    var isArchived = false
    var backlog: [MilestoneTask] = []
    var milestones: [Milestone] = []

    var activeMilestone: Milestone? {
        milestones.first(where: { $0.isActive && !$0.isArchived })
            ?? milestones.first(where: { !$0.isArchived })
    }
}

struct AppData: Codable {
    var projects: [Project]
    var inbox: [MilestoneTask]
    var tags: [String]
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    var hexString: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return "#159EF2"
        }
        return String(
            format: "#%02X%02X%02X",
            Int((red * 255).rounded()),
            Int((green * 255).rounded()),
            Int((blue * 255).rounded())
        )
    }
}
