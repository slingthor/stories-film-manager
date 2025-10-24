import Foundation
import Combine

// MARK: - DownloadMonitor - Monitors Downloads folder for new Veo/Sora files

class DownloadMonitor: ObservableObject {
    @Published var detectedFiles: [URL] = []

    private var monitoringTimer: Timer?
    private var downloadsPath: URL?
    private var activationDate: Date?
    private var isMonitoring: Bool = false

    // MARK: - Start/Stop Monitoring
    func startMonitoring(downloadsPath: URL, since: Date) {
        self.downloadsPath = downloadsPath
        self.activationDate = since
        self.isMonitoring = true

        print("[Sora] 👀 Starting Downloads folder monitoring: \(downloadsPath.path)")

        // Poll every 0.5 seconds for new files
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.scanForNewFiles()
        }
    }

    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        isMonitoring = false
        downloadsPath = nil
        activationDate = nil
        detectedFiles.removeAll()

        print("[Sora] 🛑 Stopped Downloads folder monitoring")
    }

    // MARK: - File Scanning
    private func scanForNewFiles() {
        guard let downloadsPath = downloadsPath,
              let activationDate = activationDate else { return }

        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(
                at: downloadsPath,
                includingPropertiesForKeys: [.creationDateKey, .nameKey, .fileSizeKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )

            var newFiles: [URL] = []

            for fileURL in contents {
                let filename = fileURL.lastPathComponent

                // Skip non-mp4 files
                guard filename.lowercased().hasSuffix(".mp4") || filename.lowercased().hasSuffix(".mp4.download") else {
                    continue
                }

                // Get file creation date
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.creationDateKey, .fileSizeKey]),
                      let creationDate = resourceValues.creationDate else {
                    continue
                }

                // Only consider files created after mode activation
                guard creationDate >= activationDate else {
                    continue
                }

                // Remove .download extension if present for detection
                let cleanURL = filename.hasSuffix(".download")
                    ? downloadsPath.appendingPathComponent(filename.replacingOccurrences(of: ".download", with: ""))
                    : fileURL

                if !detectedFiles.contains(cleanURL) {
                    newFiles.append(cleanURL)
                }
            }

            // Publish new files
            if !newFiles.isEmpty {
                detectedFiles.append(contentsOf: newFiles)
                print("[Sora] 📁 Detected \(newFiles.count) new video file(s)")
            }

        } catch {
            print("[Sora] ⚠️ Error scanning Downloads folder: \(error.localizedDescription)")
        }
    }

    // MARK: - File Pattern Recognition
    private func isVeoOrSoraFile(_ filename: String) -> Bool {
        // Veo pattern: Subject_in_the_202510202228_mpoah.mp4
        let veoPattern = #"^[A-Za-z_]+\d{12}_[a-z0-9]+\.mp4$"#

        // Sora pattern: 20251019_1723_01k6f16xrsfnwts6dkfs9pcdsq.mp4
        let soraPattern = #"^\d{8}_\d{4}_[a-z0-9]+\.mp4$"#

        let isVeo = filename.range(of: veoPattern, options: .regularExpression) != nil
        let isSora = filename.range(of: soraPattern, options: .regularExpression) != nil

        return isVeo || isSora
    }
}
