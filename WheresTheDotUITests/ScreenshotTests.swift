//
//  ScreenshotTests.swift
//  WheresTheDotUITests
//
//  Captures App Store screenshots across themes and screens.
//  Run via: scripts/take_screenshots.sh
//
//  To run a single test manually in Xcode, set these scheme arguments:
//    -screenshotMode
//    -screenshotTheme <neon|forest|ocean|cosmos>
//

import XCTest

final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    // MARK: - Main Menu

    func test01_MainMenuNeon() {
        launch(theme: "neon")
        snapshot("01_main_menu_neon")
    }

    func test02_MainMenuCosmos() {
        launch(theme: "cosmos")
        snapshot("02_main_menu_cosmos")
    }

    // MARK: - Gameplay

    func test03_Gameplay() {
        launch(theme: "neon")
        app.buttons["btn_classic_mode"].tap()
        // Wait for SpriteKit scene to load and first dot to appear
        wait(seconds: 3)
        snapshot("03_gameplay")
    }

    func test04_ArcadeMode() {
        launch(theme: "neon")
        // Arcade Mode button is shown when arcadeModeEnabled Remote Config is true (default)
        let arcadeButton = app.buttons["btn_arcade_mode"]
        guard arcadeButton.waitForExistence(timeout: 3) else { return }
        arcadeButton.tap()
        wait(seconds: 3)
        snapshot("04_arcade_gameplay")
    }

    // MARK: - Themes

    func test05_Themes() {
        launch(theme: "cosmos")
        app.buttons["btn_themes"].tap()
        wait(seconds: 1)
        snapshot("05_themes")
    }

    // MARK: - Settings

    func test06_Settings() {
        launch(theme: "neon")
        app.buttons["btn_options"].tap()
        wait(seconds: 0.5)
        snapshot("06_settings")
    }

    // MARK: - Helpers

    private func launch(theme: String) {
        app.launchArguments = ["-screenshotMode", "-screenshotTheme", theme]
        app.launch()
        // Wait for main menu to be fully visible (uses accessibilityIdentifier — locale-independent)
        _ = app.buttons["btn_classic_mode"].waitForExistence(timeout: 5)
    }

    private func snapshot(_ name: String) {
        let screenshot = app.screenshot()
        // XCTAttachment is the correct way to save screenshots from XCUITests.
        // The attachment is saved inside the .xcresult bundle on the host Mac.
        // take_screenshots.sh extracts them using xcresulttool after each test run.
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func wait(seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
