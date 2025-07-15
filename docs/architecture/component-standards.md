# **Component Standards**

## **Component Template**

All SwiftUI Views must be lightweight and delegate logic to their ViewModel. They should be structured as follows:

import SwiftUI

struct MainView: View {  
    // Use @StateObject to create and own the ViewModel instance.  
    @StateObject private var viewModel \= MainViewModel()

    var body: some View {  
        VStack {  
            // UI elements bind directly to @Published properties in the ViewModel.  
            TextField("Public Repo URL", text: $viewModel.repoURL)

            // Actions call methods on the ViewModel.  
            Button("Create Private Fork") {  
                viewModel.createPrivateFork()  
            }  
            .disabled(viewModel.isForking) // UI state is driven by the ViewModel.

            Text(viewModel.statusMessage)  
        }  
        .padding()  
        // Example of presenting a sheet for settings.  
        .sheet(isPresented: $viewModel.isShowingSettings) {  
            SettingsView()  
        }  
    }  
}

## **Naming Conventions**

- **Views**: PascalCase, suffixed with View (e.g., MainView.swift).  
- **ViewModels**: PascalCase, suffixed with ViewModel (e.g., MainViewModel.swift).  
- **Services (Protocols)**: PascalCase, suffixed with ServiceProtocol (e.g., GitServiceProtocol.swift).  
- **Services (Implementations)**: PascalCase, suffixed with Service (e.g., GitService.swift).  
- **Models**: PascalCase, descriptive name (e.g., ForkRequest.swift).
