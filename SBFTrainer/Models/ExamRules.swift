import Foundation

/// Official ELWIS scoring for the multiple-choice part of the theory exam
/// (Bewertungsschlüssel, ELWIS, as of 31 Oct 2022).
///
/// Both licences: 7 basic questions (pass ≥ 5) + 23 licence-specific questions (pass ≥ 18).
/// SBF Binnen: 45 minutes.  SBF See: 60 minutes including a 9-question navigation task,
/// which this app does not simulate.
struct ExamRules: Equatable {
    let type: ExamType
    let basicCount = 7
    let basicPassMark = 5
    let specificCount = 23
    let specificPassMark = 18

    init(type: ExamType) {
        precondition(type == .binnen || type == .see, "Exam simulation exists for SBF Binnen and SBF See")
        self.type = type
    }

    var totalCount: Int { basicCount + specificCount }

    /// Time limit in minutes as in the official exam.
    var minutes: Int { type == .binnen ? 45 : 60 }

    /// The navigation task (9 written questions) is part of the SBF See exam but not of this app.
    var excludesNavigationTask: Bool { type == .see }

    func result(basicCorrect: Int, specificCorrect: Int) -> ExamResult {
        ExamResult(rules: self, basicCorrect: basicCorrect, specificCorrect: specificCorrect)
    }
}

struct ExamResult: Equatable {
    let rules: ExamRules
    let basicCorrect: Int
    let specificCorrect: Int

    var basicPassed: Bool { basicCorrect >= rules.basicPassMark }
    var specificPassed: Bool { specificCorrect >= rules.specificPassMark }
    /// Both parts are assessed separately; the exam is passed only if both are passed.
    var passed: Bool { basicPassed && specificPassed }
}
