import Foundation

class FileMonitor {
    var url: URL
    var onChange: ([URL]) -> Void

    private var fileMonitor: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32?

    init(url: URL) {
        self.url = url
        self.onChange = { _ in }
    }

    deinit {
        stopMonitoring()
    }

    func onChangeHandler(_ handler: @escaping ([URL]) -> Void) {
        onChange = handler
    }

    func startMonitoring() {
        fileDescriptor = open(url.path, O_EVTONLY)
        guard let fileDescriptor = fileDescriptor, fileDescriptor != -1 else {
            print("Failed to open file descriptor for \(url.path)")
            return
        }
        
        fileMonitor = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .write, queue: DispatchQueue.global())
        fileMonitor?.setEventHandler { [weak self] in
            guard let self = self else { return }
            let files = self.getFiles()
            DispatchQueue.main.async {
                self.onChange(files)
            }
        }
        fileMonitor?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            close(self.fileDescriptor!)
            self.fileDescriptor = nil
        }
        fileMonitor?.resume()
    }

    func stopMonitoring() {
        fileMonitor?.cancel()
        fileMonitor = nil
    }

    private func getFiles() -> [URL] {
        let fileManager = FileManager.default
        let fileUrls = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        return fileUrls ?? []
    }
}

