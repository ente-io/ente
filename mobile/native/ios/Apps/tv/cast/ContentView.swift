import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CastViewModel()
    
    var body: some View {
        ZStack {
            switch viewModel.currentView {
            case .connecting:
                StatusView(
                    status: .loading(viewModel.statusMessage),
                    onRetry: nil,
                    debugLogs: nil
                )
                
            case .pairing:
                PairingView(deviceCode: viewModel.deviceCode)
                
            case .slideshow:
                SlideshowView(
                    imageData: viewModel.currentImageData,
                    videoData: viewModel.currentVideoData,
                    isVideo: viewModel.currentFile?.isVideo ?? false,
                    slideshowService: viewModel.slideshowService
                )
                
            case .error:
                StatusView(
                    status: .error(viewModel.errorMessage ?? "Unknown error"),
                    onRetry: viewModel.retryOperation,
                    debugLogs: nil
                )
                
            case .empty:
                StatusView(
                    status: .empty("No photos were found in this album"),
                    onRetry: nil,
                    debugLogs: nil
                )
            }
        }
        .animation(.easeInOut(duration: 0.6), value: viewModel.currentView)
    }
}

struct CinematicBackground: View {
    var body: some View {
        ZStack {
            // Clean, sophisticated gradient like Spotify
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.08),
                    Color(red: 0.04, green: 0.04, blue: 0.04),
                    Color(red: 0.02, green: 0.02, blue: 0.02)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Subtle brand accent - strategic placement
            RadialGradient(
                colors: [
                    Color(red: 29/255, green: 185/255, blue: 84/255).opacity(0.08),
                    Color.clear
                ],
                center: UnitPoint(x: 0.3, y: 0.2),
                startRadius: 200,
                endRadius: 800
            )
            
            
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
