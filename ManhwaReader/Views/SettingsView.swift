import SwiftUI

struct SettingsView: View {
    @AppStorage("ghostModeEnabled") private var ghostModeEnabled = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("webtoonModeEnabled") private var webtoonModeEnabled = true
    
    @Environment(ImageLoader.self) private var imageLoader
    @State private var cacheSize: Int64 = 0
    @State private var showClearCacheAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Reading Section
                Section {
                    Toggle(isOn: $webtoonModeEnabled) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Webtoon Mode")
                                Text("Seamless vertical scrolling")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "arrow.up.and.down.text.horizontal")
                        }
                    }
                    
                    Toggle(isOn: $hapticsEnabled) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Haptic Feedback")
                                Text("Chapter end and save vibrations")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "waveform")
                        }
                    }
                } header: {
                    Text("Reading")
                }
                
                // Privacy Section
                Section {
                    Toggle(isOn: $ghostModeEnabled) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Ghost Mode")
                                Text("Don't save reading history")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "eye.slash.fill")
                                .foregroundStyle(ghostModeEnabled ? .purple : .secondary)
                        }
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    if ghostModeEnabled {
                        Text("Your reading history won't be saved while Ghost Mode is enabled.")
                    }
                }
                
                // Storage Section
                Section {
                    HStack {
                        Label("Cache Size", systemImage: "internaldrive")
                        Spacer()
                        Text(cacheSize.formattedBytes)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button(role: .destructive) {
                        showClearCacheAlert = true
                    } label: {
                        Label("Clear Cache", systemImage: "trash")
                    }
                } header: {
                    Text("Storage")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                cacheSize = imageLoader.cacheSize
            }
            .alert("Clear Cache?", isPresented: $showClearCacheAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    imageLoader.clearCache()
                    cacheSize = 0
                }
            } message: {
                Text("This will delete all cached images. They will be re-downloaded as needed.")
            }
        }
    }
}
