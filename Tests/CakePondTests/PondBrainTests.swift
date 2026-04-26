import XCTest
@testable import CakePond

final class PondBrainTests: XCTestCase {
    func testKoiGenerationIsStableAndCounted() {
        let koi = PondBrain.koi(count: 6)
        XCTAssertEqual(koi.count, 6)
        XCTAssertEqual(koi[0].id, 0)
        XCTAssertEqual(koi[5].radius, 72)
        XCTAssertGreaterThan(koi[2].speed, koi[0].speed)
    }

    func testBubblesStayInsideNormalizedHorizontalRange() {
        let bubbles = PondBrain.bubbles(count: 64)
        XCTAssertEqual(bubbles.count, 64)
        XCTAssertTrue(bubbles.allSatisfy { $0.x >= 0.08 && $0.x <= 0.91 })
        XCTAssertTrue(bubbles.allSatisfy { $0.size >= 4 && $0.size <= 21 })
    }

    func testComplimentsEscalateWithInteraction() {
        XCTAssertTrue(PondBrain.compliment(for: 0).contains("Tap"))
        XCTAssertTrue(PondBrain.compliment(for: 5).contains("overclocked"))
        XCTAssertTrue(PondBrain.compliment(for: 20).contains("senior sparkle engineer"))
    }
}
