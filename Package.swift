// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RememberCore",
    platforms: [.macOS(.v13)],
    products: [.library(name: "RememberCore", targets: ["RememberCore"])],
    targets: [
        .target(
            name: "RememberCore",
            path: "Remember/Services",
            exclude: ["CommunicationLinks.swift", "NotificationCoordinator.swift"],
            sources: ["BirthdayCalculator.swift", "ReminderPlanner.swift"]
        ),
        .testTarget(name: "RememberCoreTests", dependencies: ["RememberCore"], path: "RememberTests")
    ]
)
