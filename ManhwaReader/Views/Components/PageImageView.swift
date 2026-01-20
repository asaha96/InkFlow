import SwiftUI
import Photos

struct PageImageView: View {
    let page: Page
    let referer: String?
    
    @Environment(ImageLoader.self) private var imageLoader
    @Environment(HapticManager.self) private var hapticManager
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    
    @AppStorage("webtoonModeEnabled") private var webtoonMode = true
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .onTapGesture(count: 2) {
                        saveToPhotos(image)
                    }
            } else if isLoading {
                Rectangle()
                    .fill(.gray.opacity(0.1))
                    .frame(height: 400)
                    .overlay {
                        ProgressView()
                    }
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Failed to load")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
            }
        }
        // Remove spacing between images in webtoon mode
        .padding(.vertical, webtoonMode ? -0.5 : 0)
        .task {
            await loadImage()
        }
        .alert("Save Image", isPresented: $showingSaveAlert) {
            Button("OK") { }
        } message: {
            Text(saveAlertMessage)
        }
    }
    
    private func loadImage() async {
        isLoading = true
        image = await imageLoader.loadImage(from: page.imageURL, referer: referer)
        isLoading = false
    }
    
    private func saveToPhotos(_ image: UIImage) {
        hapticManager.doubleTapSave()
        
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            if status == .authorized || status == .limited {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                DispatchQueue.main.async {
                    saveAlertMessage = "Image saved to Photos!"
                    showingSaveAlert = true
                }
            } else {
                DispatchQueue.main.async {
                    saveAlertMessage = "Please allow photo access in Settings to save images."
                    showingSaveAlert = true
                }
            }
        }
    }
}
