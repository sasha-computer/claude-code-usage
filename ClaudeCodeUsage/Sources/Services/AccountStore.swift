import Foundation
import Combine

/// Error wrapper for MCC file parsing.
struct MCCParseError: Error, Equatable {
    let message: String
}

/// A single account parsed from the pi multi-claude-code config.
struct MCCAccount: Identifiable, Equatable {
    let label: String
    let accessToken: String
    let expiresAt: TimeInterval?  // ms since epoch

    var id: String { label }

    var isTokenExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return expiresAt <= Date().timeIntervalSince1970 * 1000
    }
}

/// Reads accounts from `~/.pi/agent/multi-claude-code.json`.
/// The MCC extension owns the tokens; this class is read-only.
@MainActor
final class AccountStore: ObservableObject {

    static let defaultFilePath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".pi/agent/multi-claude-code.json")

    private static let enabledKey = "mccEnabled"
    private static let activeAccountKey = "mccActiveAccount"

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            if isEnabled { reload() } else { accounts = []; fileError = nil }
        }
    }

    @Published private(set) var accounts: [MCCAccount] = []
    @Published var activeLabel: String? {
        didSet { UserDefaults.standard.set(activeLabel, forKey: Self.activeAccountKey) }
    }
    @Published private(set) var fileError: String?

    private let filePath: URL

    var activeAccount: MCCAccount? {
        if let label = activeLabel {
            return accounts.first { $0.label.caseInsensitiveCompare(label) == .orderedSame }
        }
        return accounts.first
    }

    init(filePath: URL? = nil) {
        self.filePath = filePath ?? Self.defaultFilePath
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        self.activeLabel = UserDefaults.standard.string(forKey: Self.activeAccountKey)
        if isEnabled { reload() }
    }

    func reload() {
        let result = Self.parseFile(at: filePath)
        switch result {
        case .success(let parsed):
            accounts = parsed.accounts
            fileError = nil
            // Use MCC's active label if ours doesn't match any account
            if activeLabel == nil || activeAccount == nil {
                activeLabel = parsed.activeLabel ?? parsed.accounts.first?.label
            }
        case .failure(let error):
            accounts = []
            fileError = error.message
        }
    }

    func setActive(_ label: String) {
        guard accounts.contains(where: { $0.label.caseInsensitiveCompare(label) == .orderedSame }) else { return }
        activeLabel = label
    }

    func cycleAccount() {
        guard accounts.count > 1 else { return }
        let current = activeAccount
        let idx = current.flatMap { acc in accounts.firstIndex(where: { $0.label == acc.label }) } ?? -1
        let next = accounts[(idx + 1) % accounts.count]
        activeLabel = next.label
    }

    // MARK: - Parsing (static for testability)

    struct ParsedData {
        let accounts: [MCCAccount]
        let activeLabel: String?
    }

    static func parseFile(at path: URL) -> Result<ParsedData, MCCParseError> {
        guard FileManager.default.fileExists(atPath: path.path) else {
            return .failure(MCCParseError(message: L10n.mccFileNotFound))
        }
        guard let data = try? Data(contentsOf: path) else {
            return .failure(MCCParseError(message: L10n.mccFileUnreadable))
        }
        return parseJSON(data)
    }

    static func parseJSON(_ data: Data) -> Result<ParsedData, MCCParseError> {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .failure(MCCParseError(message: L10n.mccFileInvalidJSON))
        }
        guard let accountsArray = json["accounts"] as? [[String: Any]] else {
            return .failure(MCCParseError(message: L10n.mccFileNoAccounts))
        }

        let accounts = accountsArray.compactMap { dict -> MCCAccount? in
            guard let label = dict["label"] as? String,
                  let accessToken = dict["accessToken"] as? String else { return nil }
            return MCCAccount(
                label: label,
                accessToken: accessToken,
                expiresAt: dict["expiresAt"] as? TimeInterval
            )
        }

        if accounts.isEmpty {
            return .failure(MCCParseError(message: L10n.mccFileNoValidAccounts))
        }

        return .success(ParsedData(
            accounts: accounts,
            activeLabel: json["activeLabel"] as? String
        ))
    }
}
