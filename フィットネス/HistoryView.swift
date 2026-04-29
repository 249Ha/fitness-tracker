import SwiftUI

struct HistoryView: View {
    let workouts: [Workout]
    let onDelete: (Workout) -> Void
    @State private var workoutToDelete: Workout?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    emptyState
                } else {
                    workoutList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("履歴")
            .confirmationDialog(
                "このワークアウトを削除しますか？",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    if let workout = workoutToDelete {
                        withAnimation { onDelete(workout) }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("ワークアウト履歴がまだありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("ワークアウトを記録すると\nここに表示されます")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Workout List

    private var workoutList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(workouts) { workout in
                    workoutCard(workout)
                }
            }
            .padding()
        }
    }

    private func workoutCard(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.date.formatted(.dateTime.year().month().day().weekday(.wide)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(workout.date.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(workout.exercises.count)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                        Text("種目")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(workout.totalVolume, specifier: "%.0f")")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                        Text("kg")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            ForEach(workout.exerciseArray) { exercise in
                HStack {
                    Text(exercise.name)
                        .font(.caption)
                    Spacer()
                    Text("\(exercise.weight, specifier: "%.1f")kg")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("×")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text("\(exercise.sets)s × \(exercise.reps)r")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .contextMenu {
            Button(role: .destructive) {
                workoutToDelete = workout
                showDeleteConfirmation = true
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}
