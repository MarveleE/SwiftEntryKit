//
//  ModalPresentEnvironment.swift
//  sunoAi
//
//  Created by Groot on 2025/7/25.
//

import SwiftEntryKit
import SwiftUI

public struct ModalPresentEnvironment {
    let id: String
    let windowLevel: UIWindow.Level
    let position: ModalPresentKit.Position
    let attributes: EKAttributes
    // MARK: - TODO - 后面再完善
    var window: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap { $0.windows }
            .first {
                $0.windowLevel == windowLevel
                    && String(describing: type(of: $0)) != "UITextEffectsWindow"
            }
    }
    @MainActor
    func dismiss() {
        ModalPresentKit.shared.dismiss(type: .id(id))
    }
}

struct ModalPresentEnvironmentKey: EnvironmentKey {
    static let defaultValue: ModalPresentEnvironment = ModalPresentEnvironment(
        id: "", windowLevel: .normal, position: .top, attributes: EKAttributes())
}

extension EnvironmentValues {
    var modalPresentEnvironment: ModalPresentEnvironment {
        get { self[ModalPresentEnvironmentKey.self] }
        set { self[ModalPresentEnvironmentKey.self] = newValue }
    }
}
