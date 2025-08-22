//
//  ModalPresentKit.swift
//  sunoAi
//
//  Created by Groot on 2025/5/29.
//

import ObjectiveC
import SwiftEntryKit
import SwiftUI
import UIKit

// MARK: - 弹窗信息模型

/// 弹窗信息模型（简化版）
public struct ModalInfo {
    /// 弹窗唯一标识符
    public let id: String
    /// 弹窗位置
    public let position: ModalPresentKit.Position
    /// 弹窗窗口层级
    public let windowLevel: CGFloat

    /// 初始化弹窗信息
    /// - Parameters:
    ///   - id: 弹窗唯一标识符
    ///   - position: 弹窗位置
    ///   - windowLevel: 弹窗窗口层级
    public init(id: String, position: ModalPresentKit.Position, windowLevel: CGFloat) {
        self.id = id
        self.position = position
        self.windowLevel = windowLevel
    }
}

// MARK: - 弹窗注册表

/// 轻量级弹窗注册表
@MainActor
class ModalRegistry {
    /// 弹窗存储字典 - Key: 弹窗ID, Value: 弹窗信息
    private var modals: [String: ModalInfo] = [:]

    /// 注册弹窗
    /// - Parameters:
    ///   - id: 弹窗ID
    ///   - position: 弹窗位置
    ///   - windowLevel: 弹窗窗口层级
    func register(id: String, position: ModalPresentKit.Position, windowLevel: CGFloat) {
        let modalInfo = ModalInfo(id: id, position: position, windowLevel: windowLevel)
        modals[id] = modalInfo
    }

    /// 注销弹窗
    /// - Parameter id: 弹窗ID
    func unregister(id: String) {
        modals.removeValue(forKey: id)
    }

    /// 根据位置查找弹窗ID列表
    /// - Parameter position: 弹窗位置
    /// - Returns: 匹配的弹窗ID数组
    func findByPosition(_ position: ModalPresentKit.Position) -> [String] {
        return modals.values
            .filter { $0.position == position }
            .map { $0.id }
    }

    /// 根据ID查找弹窗信息
    /// - Parameter id: 弹窗ID
    /// - Returns: 弹窗信息，如果不存在则返回nil
    func findById(_ id: String) -> ModalInfo? {
        return modals[id]
    }

    /// 清空所有弹窗记录
    func clear() {
        modals.removeAll()
    }

    /// 获取所有弹窗ID
    /// - Returns: 所有弹窗ID数组
    func allIds() -> [String] {
        return Array(modals.keys)
    }

    /// 获取所有弹窗信息
    /// - Returns: 所有弹窗信息数组
    func allModals() -> [ModalInfo] {
        return Array(modals.values)
    }

    /// 获取弹窗总数
    /// - Returns: 弹窗总数
    func count() -> Int {
        return modals.count
    }

    /// 获取当前最高的窗口层级
    /// - Returns: 最高的windowLevel，如果没有modal则返回nil
    func getHighestWindowLevel() -> CGFloat? {
        guard !modals.isEmpty else { return nil }
        return modals.values.map { $0.windowLevel }.max()
    }
}

/// 弹窗展示管理工具
@MainActor
public class ModalPresentKit {

    // MARK: - 私有属性

    /// 弹窗注册表实例
    private let registry = ModalRegistry()

    /// 弹窗位置枚举
    public enum Position {
        /// 底部弹窗
        case bottom
        /// 中心弹窗
        case center
        /// 顶部通知
        case top

        /// 转换为EKAttributes的position
        fileprivate var ekPosition: EKAttributes.Position {
            switch self {
            case .bottom: return .bottom
            case .center: return .center
            case .top: return .top
            }
        }

        func transition(insert: Bool) -> EKAttributes.Animation {
            switch self {
            case .bottom: return .init(translate: .init(duration: 0.2))
            case .center:
                return .init(
                    translate: nil,
                    scale: .init(from: insert ? 0.9 : 1, to: insert ? 1 : 0.9, duration: 0.2),
                    fade: .init(from: insert ? 0 : 1, to: insert ? 1 : 0, duration: 0.2))
            case .top: return .init(translate: .init(duration: 0.3))
            }
        }
    }

    // MARK: - 单例
    public static let shared = ModalPresentKit()
    private init() {}

    // MARK: - 默认属性配置

    /// 获取默认属性配置
    /// - Parameter position: 弹窗位置
    /// - Returns: 配置好的属性
    public func defaultAttributes(for position: Position) -> EKAttributes {
        switch position {
        case .bottom:
            return bottomAttributes()
        case .center:
            return centerAttributes()
        case .top:
            return topAttributes()
        }
    }

    private func sharedAttributes(position: Position) -> EKAttributes {
        var attributes = EKAttributes()

        // 基础设置
        attributes.name = UUID().uuidString
        attributes.position = position.ekPosition
        attributes.displayDuration = .infinity
        attributes.entryBackground = .clear

        // 交互设置 - top 位置特殊配置
        if position == .top {
            attributes.screenInteraction = .forward  // 保持原屏幕可操作性
            attributes.entryInteraction = .absorbTouches
            attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)  // 允许滑动关闭
        } else {
            attributes.screenInteraction = .dismiss
            attributes.entryInteraction = .absorbTouches
            attributes.scroll = .disabled
        }

        // 显示设置
        attributes.entranceAnimation = position.transition(insert: true)
        attributes.exitAnimation = position.transition(insert: false)

        // 背景设置 - top 位置不添加背景遮罩
        if position == .top {
            attributes.screenBackground = .clear
        } else {
            attributes.screenBackground = .color(
                color: EKColor(UIColor.black.withAlphaComponent(0.5)))
        }

        // 忽略安全区域
        attributes.positionConstraints.safeArea = .overridden

        return attributes
    }

    /// 创建底部弹出视图的属性
    private func bottomAttributes() -> EKAttributes {
        let attributes = sharedAttributes(position: .bottom)

        return attributes
    }
    /// 创建中心弹出视图的属性
    private func centerAttributes() -> EKAttributes {
        let attributes = sharedAttributes(position: .center)

        return attributes
    }

    /// 创建顶部弹出视图的属性
    private func topAttributes() -> EKAttributes {
        let attributes = sharedAttributes(position: .top)

        return attributes
    }

    // MARK: - 私有方法

    /// 生成唯一的弹窗ID
    /// - Returns: 格式为 "modal_{UUID前8位}_{时间戳}" 的唯一ID
    private func generateUniqueId() -> String {
        let uuidPrefix = UUID().uuidString.prefix(8)
        let timestamp = Int(Date().timeIntervalSince1970)
        return "modal_\(uuidPrefix)_\(timestamp)"
    }

    /// 计算新modal的windowLevel
    /// - Returns: 如果当前有modal正在显示，返回当前最高level+1，否则返回mainWindow+1
    private func calculateWindowLevel() -> (EKAttributes.WindowLevel, UIWindow.Level) {
        // 获取主窗口的level作为基础
        guard let mainWindowLevel = UIApplication.shared.windows.first?.windowLevel else {
            let level = UIWindow.Level.normal.rawValue + 1
            return (
                .custom(level: UIWindow.Level(rawValue: level)), UIWindow.Level(rawValue: level)
            )
        }

        // 从registry获取当前最高的windowLevel
        if let highestLevel = registry.getHighestWindowLevel() {
            let newLevel = highestLevel + 1
            return (
                .custom(level: UIWindow.Level(rawValue: newLevel)),
                UIWindow.Level(rawValue: newLevel)
            )
        }

        // 如果没有modal在显示，返回主窗口level+1
        let newLevel = mainWindowLevel.rawValue + 1
        return (
            .custom(level: UIWindow.Level(rawValue: newLevel)), UIWindow.Level(rawValue: newLevel)
        )
    }

    /// 创建并配置UIHostingController
    /// - Parameter view: SwiftUI视图
    /// - Returns: 配置好的UIHostingController
    private func createHostingController<Content: View>(
        for view: Content
    ) -> UIHostingController<
        Content
    > {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.backgroundColor = .clear

        // 支持iOS 16以上版本使用sizingOptions
        if #available(iOS 16.0, *) {
            hostingController.sizingOptions = [.intrinsicContentSize]
        }

        return hostingController
    }

    /// 统一的弹窗展示逻辑
    /// - Parameters:
    ///   - view: SwiftUI View
    ///   - id: 弹窗ID（可选）
    ///   - position: 弹窗位置
    ///   - customAttributes: 自定义属性
    ///   - autoDismissAfter: 自动关闭时间（仅用于通知）
    ///   - rollbackWindow: 返回窗口
    ///   - completion: 完成回调
    /// - Returns: 实际使用的弹窗ID
    private func displayModal<Content: View>(
        _ view: Content, id: String?, position: Position, customAttributes: EKAttributes?,
        autoDismissAfter duration: TimeInterval? = nil,
        rollbackWindow: SwiftEntryKit.RollbackWindow = .main, completion: (() -> Void)?
    ) -> ModalPresentEnvironment {
        // 生成或使用提供的ID
        let modalId = id ?? generateUniqueId()

        // 配置属性
        var attributes = customAttributes ?? defaultAttributes(for: position)
        attributes.name = modalId  // 设置SwiftEntryKit的name为modalId

        // 动态设置windowLevel - 如果有modal正在显示，则在当前最高level基础上+1
        let (windowLevel, levelValue) = calculateWindowLevel()
        attributes.windowLevel = windowLevel

        let environmentValue = ModalPresentEnvironment(
            id: modalId, windowLevel: levelValue, position: position, attributes: attributes)

        // 创建HostingController
        let hostingController = createHostingController(
            for: view.environment(\.modalPresentEnvironment, environmentValue))

        // 设置自动关闭时间（仅用于通知）
        if let duration = duration {
            attributes.displayDuration = .init(duration)
        }

        // 注册到注册表
        registry.register(id: modalId, position: position, windowLevel: levelValue.rawValue)

        // 设置生命周期事件以自动清理注册信息
        setupLifecycleEventsWithRegistry(
            &attributes, modalId: modalId, position: position, completion: completion)

        displayEntry(hostingController, using: attributes, rollbackWindow: rollbackWindow)

        return environmentValue
    }

    /// 私有方法：统一处理展示弹窗逻辑
    /// - Parameters:
    ///   - entry: 展示的内容(UIView或UIViewController)
    ///   - attributes: 展示属性
    ///   - rollbackWindow: 返回窗口
    private func displayEntry(
        _ entry: Any, using attributes: EKAttributes,
        rollbackWindow: SwiftEntryKit.RollbackWindow = .main
    ) {
        if let viewController = entry as? UIViewController {
            SwiftEntryKit.display(
                entry: viewController, using: attributes, rollbackWindow: rollbackWindow)
        } else if let view = entry as? UIView {
            SwiftEntryKit.display(entry: view, using: attributes, rollbackWindow: rollbackWindow)
        }
    }

    /// 设置属性的生命周期事件，并集成注册表
    /// - Parameters:
    ///   - attributes: 要设置的属性
    ///   - modalId: 弹窗ID
    ///   - position: 弹窗位置
    ///   - completion: 完成回调
    private func setupLifecycleEventsWithRegistry(
        _ attributes: inout EKAttributes, modalId: String, position: Position,
        completion: (() -> Void)? = nil
    ) {
        // 保存原有的回调
        let originalDidAppearAction = attributes.lifecycleEvents.didAppear
        let originalDidDisappearAction = attributes.lifecycleEvents.didDisappear
        let originalWillDisappear = attributes.lifecycleEvents.willDisappear

        // 设置didAppear回调
        attributes.lifecycleEvents.didAppear = {
            // 调用原有回调
            originalDidAppearAction?()
            // 调用新的completion
            completion?()
        }

        // 设置didDisappear回调以自动清理注册表
        attributes.lifecycleEvents.didDisappear = {
            // 调用原有回调
            originalDidDisappearAction?()
            // 从注册表中移除
            Task { @MainActor in
                self.registry.unregister(id: modalId)
            }
        }

        attributes.lifecycleEvents.willDisappear = {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            originalWillDisappear?()
        }
    }

    // MARK: - 展示方法

    /// 展示弹窗
    /// - Parameters:
    ///   - view: SwiftUI视图
    ///   - id: 弹窗唯一标识符（可选，不提供时自动生成）
    ///   - position: 弹窗位置
    ///   - customAttributes: 自定义属性（可选）
    ///   - rollbackWindow: 返回窗口
    ///   - completion: 完成回调
    /// - Returns: 实际使用的弹窗ID
    @discardableResult
    public func present<Content: View>(
        _ view: Content, id: String? = nil, position: Position = .bottom,
        customAttributes: EKAttributes? = nil, rollbackWindow: SwiftEntryKit.RollbackWindow = .main,
        completion: (() -> Void)? = nil
    ) -> ModalPresentEnvironment {
        let environment = displayModal(
            view, id: id, position: position, customAttributes: customAttributes,
            rollbackWindow: rollbackWindow, completion: completion)
        return environment
    }

    /// 展示顶部通知
    /// - Parameters:
    ///   - view: SwiftUI视图
    ///   - id: 弹窗唯一标识符（可选，不提供时自动生成）
    ///   - autoDismissAfter: 自动关闭时间（秒），传入 nil 表示不自动关闭
    ///   - customAttributes: 自定义属性（可选）
    ///   - completion: 完成回调
    /// - Returns: 实际使用的弹窗ID
    @discardableResult
    public func notification<Content: View>(
        _ view: Content, id: String? = nil, autoDismissAfter duration: TimeInterval? = nil,
        customAttributes: EKAttributes? = nil, completion: (() -> Void)? = nil
    ) -> ModalPresentEnvironment {
        let environment = displayModal(
            view, id: id, position: .top, customAttributes: customAttributes,
            autoDismissAfter: duration, completion: completion)
        return environment
    }

    // MARK: - 关闭方法

    /// 关闭当前显示的弹窗（兼容性方法）
    /// - Parameter completion: 完成回调
    public func dismiss(
        type: DismissType = .default, completion: SwiftEntryKit.DismissCompletionHandler? = nil
    ) {
        dismissModal(type: type, completion: completion)
    }

    // MARK: - 内部方法

    /// 统一的关闭逻辑
    private func dismissModal(
        type: DismissType, completion: SwiftEntryKit.DismissCompletionHandler? = nil
    ) {
        resignFirstResponder()

        switch type {
        case .id(let id):
            // 检查弹窗是否存在于注册表中
            guard registry.findById(id) != nil else {
                return  // 静默忽略不存在的ID
            }
            SwiftEntryKit.dismiss(.specific(entryName: id), with: completion)
            registry.unregister(id: id)

        case .position(let position):
            // 获取指定位置的所有弹窗ID
            let modalIds = registry.findByPosition(position)
            guard !modalIds.isEmpty else {
                return  // 静默忽略空位置
            }
            // 逐一关闭弹窗
            for modalId in modalIds {
                SwiftEntryKit.dismiss(.specific(entryName: modalId), with: completion)
                registry.unregister(id: modalId)
            }

        case .all:
            registry.clear()
            SwiftEntryKit.dismiss(.all, with: completion)
        case .default:
            SwiftEntryKit.dismiss(.displayed, with: completion)
        }
    }

    /// 辞去第一响应者状态，防止卡死
    private func resignFirstResponder() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// 关闭类型枚举
    public enum DismissType {
        /// 当前window的
        case `default`
        case id(String)
        case position(Position)
        case all
    }

    // MARK: - 查询方法（可选）

    /// 检查指定ID的弹窗是否正在显示
    /// - Parameter id: 弹窗ID
    /// - Returns: 是否正在显示
    public func isDisplaying(id: String) -> Bool {
        return registry.findById(id) != nil
    }

    /// 获取指定位置的弹窗数量
    /// - Parameter position: 弹窗位置
    /// - Returns: 弹窗数量
    public func modalCount(at position: Position) -> Int {
        return registry.findByPosition(position).count
    }

    /// 获取当前显示的所有弹窗信息
    /// - Returns: 弹窗信息数组
    public func displayedModals() -> [ModalInfo] {
        return registry.allModals()
    }
}
