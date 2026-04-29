import SwiftUI
import Charts

struct ProgressChartView: View {
    let workouts: [Workout]
    @State private var selectedExercise = "ベンチプレス"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    exercisePicker
                    chartSection
                    statsCards
                    recordList
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("進捗")
        }
    }

    private var progressData: [ProgressPoint] {
        var result: [ProgressPoint] = []
        for workout in workouts {
            for exercise in workout.exerciseArray where exercise.name == selectedExercise {
                result.append(ProgressPoint(date: exercise.date ?? workout.date, weight: exercise.weight))
            }
        }
        return result.sorted { $0.date < $1.date }
    }

    // MARK: - Exercise Picker

    private var exercisePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(usedExerciseNames, id: \.self) { name in
                    Button(action: { withAnimation { selectedExercise = name } }) {
                        Text(name)
                            .font(.caption)
                            .fontWeight(selectedExercise == name ? .bold : .regular)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedExercise == name ? Color.blue : Color(.systemBackground))
                            .foregroundStyle(selectedExercise == name ? .white : .primary)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
                    }
                }
            }
        }
    }

    private var usedExerciseNames: [String] {
        var names: [String] = []
        var seen = Set<String>()
        for workout in workouts {
            for exercise in workout.exercises {
                if !seen.contains(exercise.name) {
                    seen.insert(exercise.name)
                    names.append(exercise.name)
                }
            }
        }
        if names.isEmpty {
            return ExerciseType.common
        }
        return names
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("重量推移")
                .font(.headline)

            if progressData.count >= 2 {
                Chart(progressData) { point in
                    LineMark(
                        x: .value("日付", point.date),
                        y: .value("重量", point.weight)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    AreaMark(
                        x: .value("日付", point.date),
                        y: .value("重量", point.weight)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("日付", point.date),
                        y: .value("重量", point.weight)
                    )
                    .foregroundStyle(Color.blue)
                    .symbolSize(30)
                }
                .chartYAxisLabel("kg")
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 220)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            } else if progressData.count == 1 {
                VStack(spacing: 8) {
                    Text("\(progressData[0].weight, specifier: "%.1f") kg")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.blue)
                    Text(progressData[0].date.formatted(.dateTime.month().day()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("データが2つ以上でグラフを表示します")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("この種目のデータはまだありません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
        }
    }

    // MARK: - Stats Cards

    private var statsCards: some View {
        HStack(spacing: 12) {
            let maxWeight = progressData.map(\.weight).max() ?? 0
            let latestWeight = progressData.last?.weight ?? 0
            let previousWeight = progressData.dropLast().last?.weight
            let change = previousWeight.map { latestWeight - $0 }

            VStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.orange)
                Text("\(maxWeight, specifier: "%.1f")")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("自己ベスト (kg)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

            VStack(spacing: 4) {
                Image(systemName: "number")
                    .foregroundStyle(.blue)
                Text("\(progressData.count)")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("記録回数")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

            VStack(spacing: 4) {
                Image(systemName: change ?? 0 >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundStyle(change ?? 0 >= 0 ? .green : .red)
                if let change = change {
                    Text(String(format: "%+.1f", change))
                        .font(.title3)
                        .fontWeight(.bold)
                } else {
                    Text("-")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("前回比 (kg)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }

    // MARK: - Record List

    private var recordList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !progressData.isEmpty {
                Text("記録一覧")
                    .font(.headline)

                let maxWeight = progressData.map(\.weight).max() ?? 0

                ForEach(progressData.reversed()) { point in
                    HStack {
                        Text(point.date.formatted(.dateTime.month().day()))
                            .font(.subheadline)
                        Spacer()
                        Text("\(point.weight, specifier: "%.1f") kg")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        if point.weight == maxWeight {
                            Image(systemName: "trophy.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
                }
            }
        }
    }
}

// MARK: - Progress Data Point

struct ProgressPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}
