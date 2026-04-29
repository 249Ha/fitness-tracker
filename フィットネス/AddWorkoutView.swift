import SwiftUI
import SwiftData

struct AddWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool

    @State private var exercises: [ExerciseInput] = [ExerciseInput()]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        dateHeader
                        exerciseList
                        addExerciseButton
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))

                saveBar
            }
            .navigationTitle("ワークアウトを記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { isPresented = false }
                }
            }
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundStyle(.blue)
            Text(Date().formatted(.dateTime.year().month().day().weekday(.wide).hour().minute()))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        ForEach(Array(exercises.enumerated()), id: \.element.id) { index, _ in
            ExerciseInputCard(
                exercise: $exercises[index],
                number: index + 1,
                canDelete: exercises.count > 1,
                onDelete: { exercises.remove(at: index) }
            )
        }
    }

    // MARK: - Add Exercise Button

    private var addExerciseButton: some View {
        Button(action: { withAnimation { exercises.append(ExerciseInput()) } }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("種目を追加")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.blue)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color.blue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Save Bar

    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 16) {
                let validCount = exercises.filter { !$0.name.isEmpty }.count
                Text("\(validCount)種目")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: saveWorkout) {
                    Text("保存する")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(validCount > 0 ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .disabled(validCount == 0)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial)
    }

    private func saveWorkout() {
        let validExercises = exercises.filter { !$0.name.isEmpty }
        guard !validExercises.isEmpty else { return }

        let newWorkout = Workout(date: Date())
        for input in validExercises {
            let exercise = Exercise(
                name: input.name,
                weight: input.weight,
                sets: input.sets,
                reps: input.reps,
                date: Date()
            )
            newWorkout.exercises.append(exercise)
        }
        modelContext.insert(newWorkout)
        isPresented = false
    }
}

// MARK: - Exercise Input Card

struct ExerciseInputCard: View {
    @Binding var exercise: ExerciseInput
    let number: Int
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("種目 \(number)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                Spacer()
                if canDelete {
                    Button(action: { withAnimation { onDelete() } }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.7))
                    }
                }
            }

            Picker("種目を選択", selection: $exercise.name) {
                Text("選択してください").tag("")
                ForEach(ExerciseType.common, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("重量 (kg)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Button(action: { if exercise.weight >= 2.5 { exercise.weight -= 2.5 } }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.blue.opacity(0.7))
                        }
                        Text("\(exercise.weight, specifier: "%.1f")")
                            .font(.body)
                            .fontWeight(.semibold)
                            .frame(width: 56)
                        Button(action: { exercise.weight += 2.5 }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("セット")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Button(action: { if exercise.sets > 1 { exercise.sets -= 1 } }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.blue.opacity(0.7))
                        }
                        Text("\(exercise.sets)")
                            .font(.body)
                            .fontWeight(.semibold)
                            .frame(width: 28)
                        Button(action: { if exercise.sets < 20 { exercise.sets += 1 } }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("回数")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Button(action: { if exercise.reps > 1 { exercise.reps -= 1 } }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.blue.opacity(0.7))
                        }
                        Text("\(exercise.reps)")
                            .font(.body)
                            .fontWeight(.semibold)
                            .frame(width: 28)
                        Button(action: { if exercise.reps < 50 { exercise.reps += 1 } }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            if !exercise.name.isEmpty {
                HStack {
                    Text("ボリューム:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(exercise.weight * Double(exercise.sets) * Double(exercise.reps), specifier: "%.0f") kg")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }
}

// MARK: - Exercise Input Model

struct ExerciseInput: Identifiable {
    let id = UUID()
    var name: String = ""
    var weight: Double = 60.0
    var sets: Int = 3
    var reps: Int = 10
}
