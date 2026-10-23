import SwiftUI
import UIKit

struct PersonAvatar: View {
    let person: Person
    var size: CGFloat = 48
    var photoData: Data? = nil

    var body: some View {
        Group {
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Text(person.initials.isEmpty ? "?" : person.initials)
                    .font(.system(size: size * 0.32, weight: .semibold, design: .rounded))
                    .foregroundStyle(person.category.color)
                    .frame(width: size, height: size)
                    .background(person.category.color.opacity(0.13), in: Circle())
            }
        }
        .accessibilityHidden(true)
    }
}
