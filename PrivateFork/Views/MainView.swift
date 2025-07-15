import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("PrivateFork")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Create private mirrors of GitHub repositories")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Placeholder for future UI elements
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("UI elements will be added here")
                        .foregroundColor(.secondary)
                )
        }
        .frame(width: 500, height: 400)
        .padding()
    }
}