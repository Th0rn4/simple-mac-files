import SwiftUI

class FolderMonitorWrapper: ObservableObject {
    private var folderMonitor: FolderMonitor?

    func startMonitoring() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select the Downloads Folder"
        openPanel.message = "Please select your Downloads folder."
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false

        openPanel.begin { [weak self] result in
            guard result == .OK, let url = openPanel.url else {
                print("No folder selected or panel closed.")
                return
            }

            self?.folderMonitor = FolderMonitor(url: url)
            self?.folderMonitor?.startMonitoring()
            print("Started monitoring: \(url.path)")
        }
    }
}
