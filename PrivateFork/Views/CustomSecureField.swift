import SwiftUI

struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    var isDisabled: Bool = false
    
    @State private var isSecured: Bool = true
    
    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }
    
    var body: some View {
        HStack {
            if isSecured {
                SecureField(title, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
            } else {
                TextField(title, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
            }
            
            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: isSecured ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help(isSecured ? "Show token" : "Hide token")
        }
    }
    
    func disabled(_ disabled: Bool) -> some View {
        var view = self
        view.isDisabled = disabled
        return view
    }
}

#Preview {
    @Previewable @State var tokenText = "sample_token_here"
    return CustomSecureField("Personal Access Token", text: $tokenText)
        .padding()
}