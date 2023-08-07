//
//  NetworkProtectionDebugMenu.swift
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AppKit
import Common
import Foundation

#if !NETWORK_PROTECTION

/// App store placedholder.  Should be replaced with the actual thing once we enable NetP in App Store builds.
///
@objc
final class NetworkProtectionDebugMenu: NSMenu {
    /// This is just present so we can remove this menu item in App Store builds.
    ///
    @IBOutlet weak var mainMenuItem: NSMenuItem?

    override func awakeFromNib() {
        // Hide the entire NetP debug menu when the feature is disabled:
        mainMenuItem?.removeFromParent()
    }
}

#else

import NetworkProtection

/// Controller for the Network Protection debug menu.
///
@available(macOS 11.4, *)
@objc
@MainActor
final class NetworkProtectionDebugMenu: NSMenu {

    override func awakeFromNib() {
        if #unavailable(macOS 11.4) {
            mainMenuItem?.removeFromParent()
        }
    }

    // MARK: - Outlets: Menus

    @IBOutlet weak var preferredServerMenu: NSMenu? {
        didSet {
            populateNetworkProtectionServerListMenuItems()
        }
    }

    @IBOutlet weak var registrationKeyValidityMenu: NSMenu? {
        didSet {
            populateNetworkProtectionRegistrationKeyValidityMenuItems()
        }
    }

    @IBOutlet weak var exclusionsMenu: NSMenu! {
        didSet {
            populateExclusionsMenuItems()
        }
    }

    // MARK: - Outlets: Menu Items

    /// This is just present so we can remove this menu item in App Store builds.
    ///
    @IBOutlet weak var mainMenuItem: NSMenuItem!
    @IBOutlet weak var registrationKeyValidityMenuSeparatorItem: NSMenuItem!
    @IBOutlet weak var registrationKeyValidityMenuItem: NSMenuItem!
    @IBOutlet weak var registrationKeyValidityAutomaticItem: NSMenuItem!
    @IBOutlet weak var preferredServerAutomaticItem: NSMenuItem!

    @IBOutlet weak var enableConnectOnDemandMenuItem: NSMenuItem!
    @IBOutlet weak var shouldEnforceRoutesMenuItem: NSMenuItem!
    @IBOutlet weak var shouldIncludeAllNetworksMenuItem: NSMenuItem!
    @IBOutlet weak var connectOnLogInMenuItem: NSMenuItem!

    @IBOutlet weak var excludeDDGRouteMenuItem: NSMenuItem!
    @IBOutlet weak var excludeLocalNetworksMenuItem: NSMenuItem!

    @IBOutlet weak var connectionTesterEnabledMenuItem: NSMenuItem!

    // MARK: - Debug Logic

    private let debugUtilities = NetworkProtectionDebugUtilities()

    // MARK: - Debug Menu IBActions

    /// Resets all state for NetworkProtection.
    ///
    @IBAction
    func resetAllState(_ sender: Any?) {
        Task { @MainActor in
            guard case .alertFirstButtonReturn = await NSAlert.resetNetworkProtectionAlert().runModal() else { return }

            do {
                try await debugUtilities.resetAllState()
            } catch {
                await NSAlert(error: error).runModal()
            }
        }
    }

    /// Removes the system extension and agents for Network Protection.
    ///
    @IBAction
    func removeSystemExtensionAndAgents(_ sender: Any?) {
        Task { @MainActor in
            guard case .alertFirstButtonReturn = await NSAlert.removeSystemExtensionAndAgentsAlert().runModal() else { return }

            do {
                try await debugUtilities.removeSystemExtensionAndAgents()
            } catch {
                await NSAlert(error: error).runModal()
            }
        }
    }

    /// Sends a test user notification.
    ///
    @IBAction
    func sendTestNotification(_ sender: Any?) {
        Task { @MainActor in
            do {
                try await debugUtilities.sendTestNotificationRequest()
            } catch {
                await NSAlert(error: error).runModal()
            }
        }
    }

    /// Sets the selected server.
    ///
    @IBAction
    func setSelectedServer(_ menuItem: NSMenuItem) {
        let title = menuItem.title
        let selectedServer: SelectedNetworkProtectionServer

        if title == "Automatic" {
            selectedServer = .automatic
        } else {
            let titleComponents = title.components(separatedBy: " ")
            selectedServer = .endpoint(titleComponents.first!)
        }

        debugUtilities.setSelectedServer(selectedServer: selectedServer)
    }

    /// Expires the registration key immediately.
    ///
    @IBAction
    func expireRegistrationKeyNow(_ sender: Any?) {
        Task {
            await debugUtilities.expireRegistrationKeyNow()
        }
    }

    /// Sets the registration key validity.
    ///
    @IBAction
    func setRegistrationKeyValidity(_ menuItem: NSMenuItem) {
        // nil means automatic
        let validity = menuItem.representedObject as? TimeInterval

        debugUtilities.registrationKeyValidity = validity
    }

    @IBAction
    func toggleConnectOnDemandAction(_ sender: Any?) {
        NetworkProtectionTunnelController().toggleOnDemandEnabled()
    }

    @IBAction
    func toggleEnforceRoutesAction(_ sender: Any?) {
        NetworkProtectionTunnelController().toggleShouldEnforceRoutes()
    }

    @IBAction
    func toggleIncludeAllNetworks(_ sender: Any?) {
        NetworkProtectionTunnelController().toggleShouldIncludeAllNetworks()
    }

    @IBAction
    func toggleShouldExcludeLocalRoutes(_ sender: Any?) {
        NetworkProtectionTunnelController().toggleShouldExcludeLocalRoutes()
    }

    @IBAction
    func toggleConnectOnLogInAction(_ sender: Any?) {
        NetworkProtectionTunnelController().toggleShouldAutoConnectOnLogIn()
    }

    @IBAction
    func toggleExclusionAction(_ sender: NSMenuItem) {
        guard let addressRange = sender.representedObject as? String else {
            assertionFailure("Unexpected representedObject")
            return
        }
        NetworkProtectionTunnelController().setExcludedRoute(addressRange, enabled: sender.state == .off)
    }

    @IBAction
    func toggleConnectionTesterEnabled(_ sender: Any) {
        NetworkProtectionTunnelController().toggleConnectionTesterEnabled()
    }

    // MARK: Populating Menu Items

    private func populateNetworkProtectionServerListMenuItems() {
        guard let submenu = preferredServerMenu,
              let automaticItem = preferredServerAutomaticItem else {
            assertionFailure("\(#function): Failed to get submenu")
            return
        }

        let networkProtectionServerStore = NetworkProtectionServerListFileSystemStore(errorEvents: nil)
        let servers = (try? networkProtectionServerStore.storedNetworkProtectionServerList()) ?? []

        if servers.isEmpty {
            submenu.items = [automaticItem]
        } else {
            submenu.items = [automaticItem, NSMenuItem.separator()] + servers.map({ server in
                let title: String

                if server.isRegistered {
                    title = "\(server.serverInfo.name) (\(server.serverInfo.serverLocation) – Public Key Registered)"
                } else {
                    title = "\(server.serverInfo.name) (\(server.serverInfo.serverLocation))"
                }

                return NSMenuItem(title: title,
                                  action: #selector(setSelectedServer(_:)),
                                  target: self,
                                  keyEquivalent: "")

            })
        }
    }

    private struct NetworkProtectionKeyValidityOption {
        let title: String
        let validity: TimeInterval
    }

    private static let registrationKeyValidityOptions: [NetworkProtectionKeyValidityOption] = [
        .init(title: "15 seconds", validity: .seconds(15)),
        .init(title: "30 seconds", validity: .seconds(30)),
        .init(title: "1 minute", validity: .minutes(1)),
        .init(title: "5 minutes", validity: .minutes(5)),
        .init(title: "30 minutes", validity: .minutes(30)),
        .init(title: "1 hour", validity: .hours(1))
    ]

    private func populateNetworkProtectionRegistrationKeyValidityMenuItems() {
#if DEBUG
        guard let menu = registrationKeyValidityMenu,
              let automaticItem = registrationKeyValidityAutomaticItem else {

            assertionFailure("\(#function): Failed to get menu or automatic item")
            return
        }

        if Self.registrationKeyValidityOptions.isEmpty {
            // Not likely to happen as it's hard-coded, but still...
            menu.items = [automaticItem]
        } else {
            menu.items = [automaticItem, NSMenuItem.separator()] + Self.registrationKeyValidityOptions.map { option in
                let menuItem = NSMenuItem(title: option.title,
                                          action: #selector(setRegistrationKeyValidity(_:)),
                                          target: self,
                                          keyEquivalent: "")

                menuItem.representedObject = option.validity
                return menuItem
            }
        }
#else
        guard let separator = registrationKeyValidityMenuSeparatorItem,
              let validityMenu = registrationKeyValidityMenuItem else {
            assertionFailure("\(#function): Failed to get menu or automatic item")
            return
        }

        separator.isHidden = true
        validityMenu.isHidden = true
#endif
    }

    private func populateExclusionsMenuItems() {
        exclusionsMenu.removeAllItems()

        for item in NetworkProtectionTunnelController.exclusionList {
            let menuItem: NSMenuItem
            switch item {
            case .section(let title):
                menuItem = NSMenuItem(title: title, action: nil, target: nil)
                menuItem.isEnabled = false

            case .exclusion(range: let range, description: let description, default: _):
                menuItem = NSMenuItem(title: "\(range)\(description != nil ? " (\(description!))" : "")",
                                      action: #selector(toggleExclusionAction),
                                      target: self,
                                      representedObject: range.stringRepresentation)
            }
            exclusionsMenu.addItem(menuItem)
        }
    }

    // MARK: - Menu State Update

    override func update() {
        updatePreferredServerMenu()
        updateRekeyValidityMenu()
        updateNetworkProtectionMenuItemsState()
    }

    private func updatePreferredServerMenu() {
        guard let menu = preferredServerMenu else {
            assertionFailure("Outlet not connected for preferredServerMenu")
            return
        }

        let selectedServerName = debugUtilities.selectedServerName()

        if selectedServerName == nil {
            menu.items.first?.state = .on
        } else {
            menu.items.first?.state = .off
        }

        // We're skipping the first two items because they're the automatic menu item and
        // the separator line.
        let serverItems = menu.items.dropFirst(2)

        for item in serverItems {
            if let selectedServerName,
               item.title.hasPrefix(selectedServerName) {
                item.state = .on
            } else {
                item.state = .off
            }
        }
    }

    private func updateRekeyValidityMenu() {
        guard let menu = registrationKeyValidityMenu else {
            assertionFailure("Outlet not connected for preferredServerMenu")
            return
        }

        let selectedValidity = debugUtilities.registrationKeyValidity

        if selectedValidity == nil {
            menu.items.first?.state = .on
        } else {
            menu.items.first?.state = .off
        }

        // We're skipping the first two items because they're the automatic menu item and
        // the separator line.
        let serverItems = menu.items.dropFirst(2)

        for item in serverItems {
            if item.representedObject as? TimeInterval == selectedValidity {
                item.state = .on
            } else {
                item.state = .off
            }
        }
    }

    private func updateNetworkProtectionMenuItemsState() {
        let controller = NetworkProtectionTunnelController()

        enableConnectOnDemandMenuItem.state = controller.isOnDemandEnabled ? .on : .off
        // On-Demand should always be enabled for the Kill Switch to work
        enableConnectOnDemandMenuItem.isEnabled = !controller.shouldEnforceRoutes

        shouldEnforceRoutesMenuItem.state = controller.shouldEnforceRoutes ? .on : .off
        shouldIncludeAllNetworksMenuItem.state = controller.shouldIncludeAllNetworks ? .on : .off
        connectOnLogInMenuItem.state = controller.shouldAutoConnectOnLogIn ? .on : .off

        excludeLocalNetworksMenuItem.state = controller.shouldExcludeLocalRoutes ? .on : .off
        connectionTesterEnabledMenuItem.state = controller.isConnectionTesterEnabled ? .on : .off
    }

}
@available(macOS 11.4, *)
extension NetworkProtectionDebugMenu: NSMenuDelegate {

    func menuNeedsUpdate(_ menu: NSMenu) {
        if menu === exclusionsMenu {
            let controller = NetworkProtectionTunnelController()
            for item in menu.items {
                guard let route = item.representedObject as? String else { continue }
                item.state = controller.isExcludedRouteEnabled(route) ? .on : .off
                // TO BE fixed: see NetworkProtectionTunnelController.excludedRoutes()
                item.isEnabled = !(controller.shouldEnforceRoutes && route == "10.0.0.0/8")
            }
        }
    }

}

#endif