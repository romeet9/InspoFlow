import SwiftUI
import Photos
import SwiftData
import Combine
import Combine

class ScreenshotService: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    var isAuthorized = false
    @Published var latestScreenshot: UIImage? 
    @Published var showIngestionSheet = false
    
    private var modelContext: ModelContext?
    private var lastCheckDate: Date = Date()

    override init() {
        super.init()
    }
    
    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func requestPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                self.isAuthorized = (status == .authorized || status == .limited)
                if self.isAuthorized {
                    self.startObserving()
                    // Don't check old stuff on launch, only new observations
                    self.lastCheckDate = Date()
                }
            }
        }
    }
    
    private func startObserving() {
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // MARK: - Photo Library Changes
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            self.checkForNewScreenshots()
        }
    }
    
    private func checkForNewScreenshots() {
        // Fetch Options: Created after last check
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(
            format: "creationDate > %@",
            lastCheckDate as NSDate
        )
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        assets.enumerateObjects { asset, _, _ in
            self.processAsset(asset)
        }
        
        lastCheckDate = Date()
    }
    
    private func processAsset(_ asset: PHAsset) {
        // Only process if it looks like a screenshot (mediaSubtypes)
        if asset.mediaSubtypes.contains(.photoScreenshot) {
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            
            manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { image, info in
                guard let image = image else { return }
                
                DispatchQueue.main.async {
                    print("📸 Captured new screenshot! Presenting UI...")
                    self.latestScreenshot = image
                    self.showIngestionSheet = true
                }
            }
        }
    }
}
