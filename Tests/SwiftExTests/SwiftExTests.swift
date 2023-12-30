import XCTest
@testable import SwiftEx

final class SwiftExTests: XCTestCase {
    func testNormalizedDenormalized() throws {
        let x: Double = 5
        let range: ClosedRange<Double> = -10...10
        let taper: Double = 0.1
        let delta: Double = 1e-7 // Float.ulpOfOne = 1.1920929e-07
        
        let norm = x.normalized(from: range, taper: taper, aroundCenter: true)
        let y = norm.denormalized(to: range, taper: taper, aroundCenter: true)
        
        XCTAssert(abs(x - y) < delta)
    }
    
    func testDenormalizedNormalized() throws {
        let x: Double = 0.1
        let range: ClosedRange<Double> = 20...20000
        let taper: Double = 0.03
        let delta: Double = 1e-7 // Float.ulpOfOne = 1.1920929e-07
        
        let denorm = x.denormalized(to: range, taper: taper)
        let y = denorm.normalized(from: range, taper: taper)
        
        XCTAssert(abs(x - y) < delta)
    }
}
