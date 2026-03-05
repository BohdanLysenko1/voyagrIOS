import SwiftUI

enum SmartAlertType {
    case streakAtRisk(routineName: String)
    case packingNeeded(tripName: String, itemsLeft: Int, daysUntil: Int)
    case budgetWarning(tripName: String, percentUsed: Int)
    case overdueChecklist(tripName: String, overdueCount: Int)
    case lowReadiness(tripName: String, readinessPercent: Int, daysUntil: Int)
    case noTasksToday

    var icon: String {
        switch self {
        case .streakAtRisk: return "flame.fill"
        case .packingNeeded: return "bag.fill"
        case .budgetWarning: return "creditcard.fill"
        case .overdueChecklist: return "exclamationmark.triangle.fill"
        case .lowReadiness: return "gauge.with.dots.needle.33percent"
        case .noTasksToday: return "plus.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .streakAtRisk: return .orange
        case .packingNeeded: return .blue
        case .budgetWarning: return .red
        case .overdueChecklist: return .red
        case .lowReadiness: return .orange
        case .noTasksToday: return .green
        }
    }

    var title: String {
        switch self {
        case .streakAtRisk(let name):
            return "\(name) streak at risk!"
        case .packingNeeded(let name, let items, let days):
            return "Pack \(items) items for \(name) (\(days)d)"
        case .budgetWarning(let name, let percent):
            return "\(name) budget \(percent)% spent"
        case .overdueChecklist(let name, let count):
            return "\(count) overdue task\(count == 1 ? "" : "s") for \(name)"
        case .lowReadiness(let name, let percent, let days):
            return "\(name) only \(percent)% ready (\(days)d left)"
        case .noTasksToday:
            return "Plan your day — no tasks yet!"
        }
    }

    var priority: Int {
        switch self {
        case .streakAtRisk: return 1
        case .overdueChecklist: return 2
        case .budgetWarning: return 3
        case .lowReadiness: return 4
        case .packingNeeded: return 5
        case .noTasksToday: return 6
        }
    }
}

struct SmartAlertRow: View {

    let alert: SmartAlertType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.icon)
                .font(.system(size: 16))
                .foregroundStyle(alert.iconColor)
                .frame(width: 32, height: 32)
                .background(alert.iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(alert.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct SmartAlertsSection: View {

    let alerts: [SmartAlertType]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("Needs Attention")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            let sortedAlerts = Array(alerts.sorted { $0.priority < $1.priority }.prefix(4))

            VStack(spacing: 0) {
                ForEach(Array(sortedAlerts.enumerated()), id: \.offset) { index, alert in
                    SmartAlertRow(alert: alert)

                    if index < sortedAlerts.count - 1 {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
        }
        .padding(AppTheme.cardPadding)
        .cardStyle()
    }
}
