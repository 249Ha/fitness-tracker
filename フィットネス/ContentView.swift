import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var showAddWorkout = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            homeTab
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(0)

            ProgressChartView(workouts: workouts)
                .tabItem {
                    Label("進捗", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)

            HistoryView(workouts: workouts, onDelete: deleteWorkout)
                .tabItem {
                    Label("履歴", systemImage: "calendar")
                }
                .tag(2)
        }
        .tint(.blue)
        .sheet(isPresented: $showAddWorkout) {
            AddWorkoutView(isPresented: $showAddWorkout)
        }
    }

    // MARK: - Home Tab

    private var homeTab: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statsRow
                    todaySection
                    if !workouts.isEmpty {
                        recentSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("フィットトラッカー")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddWorkout = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "合計",
                value: "\(workouts.count)",
                unit: "回",
                icon: "flame.fill",
                color: .orange
            )
            StatCard(
                title: "今週",
                value: "\(thisWeekCount)",
                unit: "回",
                icon: "calendar",
                color: .blue
            )
            StatCard(
                title: "連続",
                value: "\(currentStreak)",
                unit: "日",
                icon: "bolt.fill",
                color: .green
            )
        }
    }

    private var thisWeekCount: Int {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else {
            return 0
        }
        return workouts.filter { $0.date >= startOfWeek }.count
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        if !workouts.contains(where: { calendar.isDate($0.date, inSameDayAs: checkDate) }) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                return 0
            }
            checkDate = yesterday
        }

        while workouts.contains(where: { calendar.isDate($0.date, inSameDayAs: checkDate) }) {
            streak += 1
            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prevDay
        }

        return streak
    }

    // MARK: - Today Section

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本日のワークアウト")
                .font(.headline)

            if let todayWorkout = workouts.first(where: { Calendar.current.isDateInToday($0.date) }) {
                VStack(spacing: 0) {
                    ForEach(Array(todayWorkout.exerciseArray.enumerated()), id: \.element.id) { index, exercise in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("\(exercise.sets)セット × \(exercise.reps)回")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(exercise.weight, specifier: "%.1f") kg")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)

                        if index < todayWorkout.exerciseArray.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("まだ記録がありません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button(action: { showAddWorkout = true }) {
                        Label("ワークアウトを記録", systemImage: "plus")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
        }
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近の記録")
                .font(.headline)

            ForEach(workouts.prefix(5)) { workout in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(workout.date.formatted(.dateTime.month().day().weekday(.wide)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(workout.exercises.count)種目")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }

                    ForEach(workout.exerciseArray) { exercise in
                        HStack {
                            Text(exercise.name)
                                .font(.caption)
                            Spacer()
                            Text("\(exercise.weight, specifier: "%.1f")kg × \(exercise.sets)s × \(exercise.reps)r")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
            }
        }
    }

    private func deleteWorkout(_ workout: Workout) {
        modelContext.delete(workout)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Workout.self, Exercise.self], inMemory: true)
}
