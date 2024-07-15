import Foundation

class FolderMonitor: ObservableObject {
    @Published var files: [URL] = []
    var fileTypes: Set<String> = ["docx", "png", "xlsx", "pptx", "pdf", "mp3", "mp4", "mov", "jpeg"]
    private var folderURL: URL
    private var fileManager: FileManager
    private var fileMonitor: FileMonitor?
    private var destinationURLs: [String: URL] = [:]
    private var processedFiles: Set<URL> = Set<URL>()
    private let defaults = UserDefaults.standard

    init() {
        self.folderURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        self.fileManager = FileManager.default
        loadDestinationURLs()
    }

    func startMonitoring() {
        fileMonitor = FileMonitor(url: folderURL)
        fileMonitor?.onChangeHandler { [weak self] files in
            self?.handleNewFiles(files)
        }
        fileMonitor?.startMonitoring()
    }

    func stopMonitoring() {
        fileMonitor?.stopMonitoring()
    }

    func setDestinationURL(for fileType: String, url: URL) {
        destinationURLs[fileType] = url
        defaults.set(url.path, forKey: fileType)
    }

    func getDestinationURL(for fileType: String) -> URL? {
        if let path = defaults.string(forKey: fileType) {
            return URL(fileURLWithPath: path)
        }
        return destinationURLs[fileType]
    }

    private func handleNewFiles(_ files: [URL]) {
        for fileURL in files {
            guard fileTypes.contains(fileURL.pathExtension.lowercased()) else {
                continue
            }

            if !processedFiles.contains(fileURL) {
                do {
                    try moveFile(at: fileURL)
                    processedFiles.insert(fileURL)
                } catch {
                    print("Error moving file: \(error.localizedDescription)")
                }
            }
        }
    }

    private func moveFile(at fileURL: URL) throws {
        guard let destinationURL = getDestinationURL(for: fileURL.pathExtension.lowercased()) else {
            return
        }

        let destinationFileURL = destinationURL.appendingPathComponent(fileURL.lastPathComponent)
        try fileManager.moveItem(at: fileURL, to: destinationFileURL)

        // Update published files array
        DispatchQueue.main.async {
            self.files.append(destinationFileURL)
        }
    }

    private func loadDestinationURLs() {
        for fileType in fileTypes {
            if let path = defaults.string(forKey: fileType) {
                let url = URL(fileURLWithPath: path)
                destinationURLs[fileType] = url
            }
        }
    }
}
