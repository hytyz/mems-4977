import SwiftUI

struct EmailField: View {
    @Binding var text: String

    var body: some View {
        TextField("Email", text: $text)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }
}

#if DEBUG
struct EmailField_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            EmailField(text: .constant(""))
            EmailField(text: .constant("alex.voter@example.com"))
        }
    }
}
#endif
