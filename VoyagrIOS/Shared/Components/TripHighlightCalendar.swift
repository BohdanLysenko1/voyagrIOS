import SwiftUI

/// A monthly calendar grid that highlights trip and event date ranges.
struct TripHighlightCalendar: View {
    @Binding var selectedDate: Date
    let trips: [Trip]
    let events: [Event]
    let tasks: [DailyTask]

    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = Calendar.current.shortWeekdaySymbols
    private let cellHeight: CGFloat = 46

    var body: some View {
        VStack(spacing: 8) {
            monthHeader
            weekdayHeader
            daysGrid
        }
        .padding(.horizontal)
        .onAppear {
            displayedMonth = calendar.startOfMonth(for: selectedDate)
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    shiftMonth(by: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text(displayedMonth.formatted(.dateTime.year().month(.wide)))
                .font(.headline)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    shiftMonth(by: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Days Grid

    private var daysGrid: some View {
        let weeks = weeksInMonth()
        return VStack(spacing: 2) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                weekRow(week)
            }
        }
    }

    private func weekRow(_ week: [Date?]) -> some View {
        GeometryReader { geo in
            let colWidth = geo.size.width / 7

            // Draw trip bands (bottom layer)
            ForEach(highlightSegments(in: week, for: .trip), id: \.id) { segment in
                segmentShape(segment: segment, colWidth: colWidth)
            }

            // Draw event bands (stacked above trips if overlapping)
            ForEach(highlightSegments(in: week, for: .event), id: \.id) { segment in
                segmentShape(segment: segment, colWidth: colWidth)
            }

            // Day cells on top
            HStack(spacing: 0) {
                ForEach(Array(week.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(for: date)
                    } else {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .frame(height: cellHeight)
    }

    private func segmentShape(segment: HighlightSegment, colWidth: CGFloat) -> some View {
        let x = CGFloat(segment.startCol) * colWidth
        let w = CGFloat(segment.endCol - segment.startCol + 1) * colWidth

        return UnevenRoundedRectangle(
            topLeadingRadius: segment.isStart ? 6 : 0,
            bottomLeadingRadius: segment.isStart ? 6 : 0,
            bottomTrailingRadius: segment.isEnd ? 6 : 0,
            topTrailingRadius: segment.isEnd ? 6 : 0
        )
        .fill(segment.color.opacity(0.25))
        .frame(width: w, height: cellHeight - 4)
        .position(x: x + w / 2, y: cellHeight / 2)
    }

    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let dots = dateDots(for: date)

        return Button {
            selectedDate = date
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(.blue)
                        .frame(width: 36, height: 36)
                } else if isToday {
                    Circle()
                        .strokeBorder(.blue, lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                }

                VStack(spacing: 1) {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.subheadline)
                        .fontWeight(isToday || isSelected ? .bold : .regular)
                        .foregroundStyle(isSelected ? .white : isToday ? .blue : .primary)

                    if !dots.isEmpty && !isSelected {
                        HStack(spacing: 2) {
                            ForEach(dots, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 4, height: 4)
                            }
                        }
                    } else {
                        Color.clear.frame(width: 4, height: 4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: cellHeight)
        }
        .buttonStyle(.plain)
    }

    /// Returns dot colors for a date: purple for single-day events, green for tasks.
    private func dateDots(for date: Date) -> [Color] {
        let day = calendar.startOfDay(for: date)
        var dots: [Color] = []

        let hasEvent = events.contains { event in
            let eventDay = calendar.startOfDay(for: event.date)
            if let endDate = event.endDate {
                let endDay = calendar.startOfDay(for: endDate)
                return eventDay == endDay && eventDay == day
            }
            return eventDay == day
        }
        if hasEvent { dots.append(.purple) }

        let hasTask = tasks.contains { calendar.isDate($0.date, inSameDayAs: date) }
        if hasTask { dots.append(.green) }

        return dots
    }

    // MARK: - Highlight Segments

    private enum HighlightKind {
        case trip, event
    }

    private struct HighlightSegment: Identifiable {
        let id: String
        let startCol: Int
        let endCol: Int
        let isStart: Bool
        let isEnd: Bool
        let color: Color
    }

    /// A date range used for highlight calculation.
    private struct DateRange {
        let start: Date
        let end: Date
    }

    private func highlightSegments(in week: [Date?], for kind: HighlightKind) -> [HighlightSegment] {
        let ranges: [DateRange]
        let color: Color

        switch kind {
        case .trip:
            ranges = trips.map { DateRange(start: $0.startDate, end: $0.endDate) }
            color = .blue
        case .event:
            // Only highlight events that span multiple days
            ranges = events.compactMap { event in
                guard let endDate = event.endDate else { return nil }
                let startDay = calendar.startOfDay(for: event.date)
                let endDay = calendar.startOfDay(for: endDate)
                guard startDay != endDay else { return nil }
                return DateRange(start: event.date, end: endDate)
            }
            color = .purple
        }

        guard !ranges.isEmpty else { return [] }
        return buildSegments(in: week, ranges: ranges, color: color, prefix: kind == .trip ? "t" : "e")
    }

    private func buildSegments(in week: [Date?], ranges: [DateRange], color: Color, prefix: String) -> [HighlightSegment] {
        var segments: [HighlightSegment] = []
        var col = 0

        while col < 7 {
            guard let date = week[col], isInAnyRange(date, ranges: ranges) else {
                col += 1
                continue
            }

            let segStart = col
            let segIsStart = isRangeStart(date, ranges: ranges)

            while col < 6, let nextDate = week[col + 1], isInAnyRange(nextDate, ranges: ranges) {
                col += 1
            }

            let segEnd = col
            let segIsEnd = week[segEnd].map { isRangeEnd($0, ranges: ranges) } ?? false

            segments.append(HighlightSegment(
                id: "\(prefix)-\(segStart)-\(segEnd)",
                startCol: segStart,
                endCol: segEnd,
                isStart: segIsStart,
                isEnd: segIsEnd,
                color: color
            ))
            col += 1
        }

        return segments
    }

    private func isInAnyRange(_ date: Date, ranges: [DateRange]) -> Bool {
        let day = calendar.startOfDay(for: date)
        return ranges.contains {
            day >= calendar.startOfDay(for: $0.start) && day <= calendar.startOfDay(for: $0.end)
        }
    }

    private func isRangeStart(_ date: Date, ranges: [DateRange]) -> Bool {
        let day = calendar.startOfDay(for: date)
        return ranges.contains { calendar.startOfDay(for: $0.start) == day }
    }

    private func isRangeEnd(_ date: Date, ranges: [DateRange]) -> Bool {
        let day = calendar.startOfDay(for: date)
        return ranges.contains { calendar.startOfDay(for: $0.end) == day }
    }

    // MARK: - Date Calculations

    private func shiftMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
            // Auto-select today if navigating to current month, otherwise the 1st
            if calendar.isDate(newMonth, equalTo: Date(), toGranularity: .month) {
                selectedDate = Date()
            } else {
                selectedDate = newMonth
            }
        }
    }

    private func weeksInMonth() -> [[Date?]] {
        let monthStart = calendar.startOfMonth(for: displayedMonth)
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7

        var weeks: [[Date?]] = []
        var currentWeek: [Date?] = Array(repeating: nil, count: offset)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                currentWeek.append(date)
                if currentWeek.count == 7 {
                    weeks.append(currentWeek)
                    currentWeek = []
                }
            }
        }

        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                currentWeek.append(nil)
            }
            weeks.append(currentWeek)
        }

        return weeks
    }
}

// MARK: - Calendar Extension

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
