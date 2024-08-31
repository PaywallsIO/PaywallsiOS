import SwiftUI

struct SkeltonView: View {
    @State private var blinking: Bool = false

    var body: some View {
        VStack(spacing: 15) {
            Rectangle()
                .frame(width: 100, height: 100)
                .cornerRadius(25)
                .padding(.top, 80)
                .padding(.bottom, 40)

            Rectangle()
                .frame(width: 300, height: 30)
                .cornerRadius(8)
                .padding(.bottom, 30)

            HStack {
                Image(systemName: "checkmark.circle.fill")
                Rectangle()
                    .frame(width: 200, height: 15)
                    .cornerRadius(5)
            }

            HStack {
                Image(systemName: "checkmark.circle.fill")
                Rectangle()
                    .frame(width: 250, height: 15)
                    .cornerRadius(5)
            }

            HStack {
                Image(systemName: "checkmark.circle.fill")
                Rectangle()
                    .frame(width: 180, height: 15)
                    .cornerRadius(5)
            }
            
            Spacer()
        }
        .foregroundStyle(.gray)
        .frame(maxWidth: .infinity)
        .opacity(blinking ? 0.3 : 1)
        .animation(.easeInOut(duration: 1).repeatForever(), value: blinking)
        .onAppear {
            blinking.toggle()
        }
    }
}
