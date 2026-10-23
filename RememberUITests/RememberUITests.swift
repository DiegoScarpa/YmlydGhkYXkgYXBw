import XCTest

final class RememberUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSarahPersistsAndAppearsOnCalendar() throws {
        let app = XCUIApplication()
        app.launch()

        let addButton = app.buttons["home.addPerson"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10))
        addButton.tap()

        let nameField = app.textFields["person.fullName"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Sarah")
        app.buttons["person.save"].tap()

        func sarahIsVisible() -> Bool {
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS[c] %@", "Sarah"))
                .firstMatch.waitForExistence(timeout: 10)
        }

        XCTAssertTrue(sarahIsVisible())
        app.terminate()
        app.launch()
        XCTAssertTrue(sarahIsVisible())
        app.tabBars.buttons["Calendar"].tap()
        XCTAssertTrue(sarahIsVisible())
    }
}
