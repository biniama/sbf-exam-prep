import Foundation

/// Mirrors progress data to iCloud key-value storage so it follows the user to
/// their other devices and survives a reinstall.  Data stays in the user's own
/// iCloud account; the developer has no access to it.
///
/// Conflict handling is last-writer-wins per key, using a timestamp stored next
/// to every value.
@MainActor
final class CloudSync {
    static let shared = CloudSync()

    private let kv = NSUbiquitousKeyValueStore.default
    private let defaults = UserDefaults.standard
    private var observer: NSObjectProtocol?

    static let enabledKey = "iCloudSyncEnabled"

    var isEnabled: Bool {
        get { defaults.object(forKey: Self.enabledKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Self.enabledKey) }
    }

    /// Start observing remote changes; ``onChange`` receives the keys that changed.
    func start(onChange: @escaping @MainActor ([String]) -> Void) {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kv, queue: .main
        ) { note in
            let keys = (note.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]) ?? []
            Task { @MainActor in onChange(keys.filter { !$0.hasPrefix("ts.") }) }
        }
        kv.synchronize()
    }

    func push(_ data: Data?, forKey key: String, modified: Date) {
        guard isEnabled else { return }
        kv.set(data, forKey: key)
        kv.set(modified.timeIntervalSince1970, forKey: "ts." + key)
    }

    /// Remote value if it is newer than ``localModified``.
    func newerValue(forKey key: String, than localModified: Date?) -> Data? {
        guard isEnabled, let data = kv.data(forKey: key) else { return nil }
        let remote = kv.double(forKey: "ts." + key)
        guard remote > 0 else { return nil }
        if let localModified, Date(timeIntervalSince1970: remote) <= localModified { return nil }
        return data
    }

    func remoteTimestamp(forKey key: String) -> Date? {
        let t = kv.double(forKey: "ts." + key)
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }

    func removeAll(keys: [String]) {
        for key in keys {
            kv.removeObject(forKey: key)
            kv.removeObject(forKey: "ts." + key)
        }
    }
}
