import SwiftUI

struct PersonAvatar: View {
    let person: Person
    var size: CGFloat = 48

    var body: some View {
        Text(person.initials.isEmpty ? "?" : person.initials)
            .font(.system(size: size * 0.32, weight: .semibold, design: .rounded))
            .foregroundStyle(person.category.color)
            .frame(width: size, height: size)
            .background(person.category.color.opacity(0.13), in: Circle())
            .accessibilityHidden(true)
    }
}
