import SwiftUI

extension Font {

    /// Poppins con peso y tamaño exactos.
    static func poppins(_ weight: PoppinsWeight = .regular, size: CGFloat) -> Font {
        .custom(weight.fontName, size: size)
    }

    enum PoppinsWeight {
        case thin, extraLight, light, regular, medium, semiBold, bold, extraBold, black

        var fontName: String {
            switch self {
            case .thin:       return "Poppins-Thin"
            case .extraLight: return "Poppins-ExtraLight"
            case .light:      return "Poppins-Light"
            case .regular:    return "Poppins-Regular"
            case .medium:     return "Poppins-Medium"
            case .semiBold:   return "Poppins-SemiBold"
            case .bold:       return "Poppins-Bold"
            case .extraBold:  return "Poppins-ExtraBold"
            case .black:      return "Poppins-Black"
            }
        }
    }
}
