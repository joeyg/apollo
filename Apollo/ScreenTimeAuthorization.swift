//
//  ScreenTimeAuthorization.swift
//  Apollo
//
//  Created by Joe Gasiorek on 9/15/25.
//


import Foundation
import FamilyControls

@MainActor
enum ScreenTimeAuthorization {
    static func requestAuthorization() async throws {
        // Request authorization for the current device user (non-family setup)
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }

    static var authorizationStatus: AuthorizationStatus {
        AuthorizationCenter.shared.authorizationStatus
    }
}
