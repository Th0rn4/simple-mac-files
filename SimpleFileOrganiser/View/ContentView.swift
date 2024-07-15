import SwiftUI
import Cocoa
import AppKit

struct ContentView: View {
    @StateObject var folderMonitor = FolderMonitor()
    @State private var selectedFileType: String = "docx"
    @State private var refresh: Bool = false

    var body: some View {
        ZStack {
            BlurredBackgroundView()

            VStack {
                HStack {
                    
                    Picker("File Type", selection: $selectedFileType) {
                        ForEach(folderMonitor.fileTypes.sorted(), id: \.self) { fileType in
                            Text(fileType.uppercased()).tag(fileType)
                                .font(.headline)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 200)
                    .padding()

                   
                    Button("Choose Destination") {
                        chooseDestinationFolder()
                    }
                    .padding()
                }
                .padding()

               
                if let url = folderMonitor.getDestinationURL(for: selectedFileType) {
                    Text("Destination: \(url.path)")
                        .font(.headline) // Increase font size
                        .padding()
                } else {
                    Text("No destination set for \(selectedFileType.uppercased()) files.")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .onAppear {
                folderMonitor.startMonitoring()
            }
            .onDisappear {
                folderMonitor.stopMonitoring()
            }
            .onChange(of: selectedFileType) { _ in
                refresh.toggle()
            }
            .onChange(of: refresh) { _ in }
        }
        .edgesIgnoringSafeArea(.all)
    }

    private func chooseDestinationFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.begin { result in
            if result == .OK, let url = panel.url {
                folderMonitor.setDestinationURL(for: selectedFileType, url: url)
                refresh.toggle() 
            }
        }
    }
}

