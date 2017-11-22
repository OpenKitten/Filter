import XCTest
@testable import Filter

class FilterTests: XCTestCase {
    func testExample() {
        let string = parse([UInt8]("age == 4 || age == 5 && age < 10 && age > 2".utf8))
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
