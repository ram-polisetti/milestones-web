import SwiftUI

struct ASCIIBrandMark: View {
    var size: CGFloat = 40
    var foreground: Color = .white
    var background: Color = .blue

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(background.gradient)

            Text("M>\n--|")
                .font(.system(size: size * 0.27, weight: .black, design: .monospaced))
                .foregroundStyle(foreground)
                .multilineTextAlignment(.center)
                .lineSpacing(-size * 0.08)
                .minimumScaleFactor(0.7)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Milestones")
    }
}
