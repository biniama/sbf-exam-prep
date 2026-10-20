import XCTest
@testable import SBFTrainer

/// Guards the bundled question catalogue and illustrations.
@MainActor
final class DataIntegrityTests: XCTestCase {
    private var store: QuestionStore { .shared }

    func testCatalogueLoads() {
        XCTAssertNil(store.loadError)
        XCTAssertEqual(store.allQuestions.count, 466)
        XCTAssertEqual(store.sections.count, 3)
    }

    func testIdsAreUnique() {
        let ids = store.allQuestions.map(\.uniqueId)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testEveryQuestionHasFourAnswersAndAValidKey() {
        for q in store.allQuestions {
            XCTAssertEqual(Set(q.options.keys), ["A", "B", "C", "D"], q.uniqueId)
            XCTAssertNotNil(q.options[q.correctOption], q.uniqueId)
            XCTAssertFalse(q.germanText.isEmpty, q.uniqueId)
            for (key, option) in q.options {
                XCTAssertFalse(option.german.isEmpty, "\(q.uniqueId) \(key)")
            }
        }
    }

    func testEveryIllustrationExists() {
        for q in store.allQuestions where q.hasImage {
            let urls = q.imageURLs
            XCTAssertFalse(urls.isEmpty, "\(q.uniqueId) has no image")
            for url in urls {
                XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "\(q.uniqueId): \(url.lastPathComponent)")
                XCTAssertNotNil(UIImage(contentsOfFile: url.path), "\(q.uniqueId) image does not decode")
            }
        }
        for q in store.allQuestions where !q.hasImage {
            XCTAssertTrue(q.imageURLs.isEmpty, "\(q.uniqueId) is not an image question but references one")
        }
    }

    func testNoOrphanedIllustrations() throws {
        let assets = try XCTUnwrap(Bundle.main.url(forResource: "assets", withExtension: nil))
        let files = FileManager.default.enumerator(at: assets, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "png" }
            .map { $0.deletingPathExtension().lastPathComponent } ?? []
        let referenced = Set(store.allQuestions.flatMap { q in q.imageURLs.map { $0.deletingPathExtension().lastPathComponent } })
        XCTAssertEqual(Set(files), referenced)
    }

    func testEveryQuestionHasAGermanCategory() {
        for q in store.allQuestions {
            XCTAssertNotNil(q.categoryDE, q.uniqueId)
        }
    }

    func testSoundPatternsAreValid() {
        let withPattern = store.allQuestions.compactMap(\.soundPattern)
        XCTAssertGreaterThanOrEqual(withPattern.count, 15)
        for pattern in withPattern {
            XCTAssertTrue(pattern.allSatisfy { ".- ".contains($0) }, pattern)
            XCTAssertFalse(pattern.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    func testEveryQuestionHasExplanationsInBothLanguages() {
        for q in store.allQuestions {
            XCTAssertFalse(q.explanationDE?.isEmpty ?? true, "\(q.uniqueId) German explanation missing")
            XCTAssertFalse(q.explanationEN?.isEmpty ?? true, "\(q.uniqueId) English explanation missing")
        }
    }

    func testDisplayOptionsKeepExactlyOneCorrectAnswer() {
        for q in store.allQuestions {
            let options = q.displayOptions
            XCTAssertEqual(options.map(\.key), ["A", "B", "C", "D"])
            XCTAssertEqual(options.filter(\.isCorrect).count, 1, q.uniqueId)
            XCTAssertEqual(options.first(where: \.isCorrect)?.value, q.options[q.correctOption])
        }
        // The official catalogue always lists the correct answer first; browsing must not.
        let correctIsA = store.allQuestions.filter { $0.displayOptions.first?.isCorrect == true }.count
        XCTAssertLessThan(correctIsA, store.allQuestions.count / 2)
    }

    func testGermanLocalisationIsBundled() {
        let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: "de")
        let strings = path.flatMap { NSDictionary(contentsOfFile: $0) as? [String: String] } ?? [:]
        XCTAssertGreaterThan(strings.count, 150)
        XCTAssertEqual(strings["Browse"], "Fragen")
        XCTAssertEqual(strings["Settings"], "Einstellungen")
    }
}
