import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID = UUID()
    var date: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
    var exercises: [Exercise] = []

    var exerciseArray: [Exercise] {
        exercises.sorted { $0.name < $1.name }
    }

    var totalVolume: Double {
        exercises.reduce(0) { $0 + $1.volume }
    }

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = date
    }
}

@Model
final class Exercise: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var weight: Double = 0
    var sets: Int = 0
    var reps: Int = 0
    var date: Date?
    var workout: Workout?

    var volume: Double {
        weight * Double(sets) * Double(reps)
    }

    init(name: String, weight: Double, sets: Int, reps: Int, date: Date? = Date()) {
        self.id = UUID()
        self.name = name
        self.weight = weight
        self.sets = sets
        self.reps = reps
        self.date = date
    }
}

struct ExerciseType {
    static let common = [
        "ベンチプレス",
        "スクワット",
        "デッドリフト",
        "ショルダープレス",
        "バーベルロウ",
        "チンアップ",
        "ダンベルカール",
        "トライセプスディップス",
        "レッグプレス",
        "ダンベルフライ",
        "バーベルカール",
        "レッグレイズ",
        "カーフレイズ",
        "ラットプルダウン",
        "その他"
    ]
}
