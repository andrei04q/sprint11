import XCTest

class Image_FeedUITests: XCTestCase {
    private let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func testAuth() throws {
        XCTAssertTrue(app.buttons["Войти"].waitForExistence(timeout: 5))
        app.buttons["Войти"].tap()
        
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 9))
        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 5))
        loginTextField.tap()
        loginTextField.typeText("XXXXXXXXX")
        
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5))
        
        // -- MARK: Пришлось реализовать через копипаст, т.к.
        // -- MARK: при стандартной реализации вводилось только 4 символа
        passwordTextField.tap()
        let pasteboard = UIPasteboard.general
        pasteboard.string = "XXXXXXXXXXX"
        passwordTextField.tap()
        passwordTextField.tap()
        passwordTextField.tap()
        XCUIApplication().menuItems["Paste"].firstMatch.tap()
        
        webView.buttons["Login"].tap()
        
        let tablesQuery = app.tables.firstMatch
        XCTAssertTrue(tablesQuery.waitForExistence(timeout: 9))
        
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 9))
    }

    func testFeed() throws {
        let tablesQuery = app.tables
        let firstCell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssert(firstCell.waitForExistence(timeout: 5))
        
        firstCell.swipeUp()
        
        let topCell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        let likeButton = topCell.buttons["like button"]
        likeButton.tap()
        
        likeButton.tap()
        
        topCell.tap()
        
        let fullImage = app.scrollViews.images.element(boundBy: 0)
        XCTAssert(fullImage.waitForExistence(timeout: 7))
        
        fullImage.pinch(withScale: 3, velocity: 1)
        
        fullImage.pinch(withScale: 0.5, velocity: -1)
        
        let backButton = app.buttons["backButton"]
        backButton.tap()
        
        XCTAssert(firstCell.waitForExistence(timeout: 2))
    }

    
    func testProfile() throws {
        let tablesQuery = app.tables.firstMatch
        XCTAssertTrue(tablesQuery.waitForExistence(timeout: 9))
        
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 9))
        
        app.tabBars.buttons.element(boundBy: 1).tap()
        
        let nameLabel = app.staticTexts["profileNameLabel"]
        XCTAssertTrue(nameLabel.waitForExistence(timeout: 5))
        
        let loginLabel = app.staticTexts["profileLoginLabel"]
        XCTAssertTrue(loginLabel.waitForExistence(timeout: 5))
        
        let logoutButton = app.buttons["logoutButton"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 5))
        logoutButton.tap()
        
        let alert = app.alerts["Пока, пока!"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.scrollViews.otherElements.buttons["Да"].tap()
        
        let loginButton = app.buttons["Войти"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 9))
    }
}
