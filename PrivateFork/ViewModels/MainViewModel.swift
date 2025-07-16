import SwiftUI

@MainActor
final class MainViewModel: ObservableObject {
    @Published var isShowingSettings: Bool = false

    init() {
        // Initialization code will be added as needed
    }

    func showSettings() {
        isShowingSettings = true
    }

    func hideSettings() {
        isShowingSettings = false
    }
}
