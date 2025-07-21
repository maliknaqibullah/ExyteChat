//
//  Created by Alex.M on 07.07.2022.
//

import SwiftUI

struct AvatarView: View {

    let user: User?
    let avatarSize: CGFloat

    var body: some View {
        CachedAsyncImage(url: user?.avatarURL, urlCache: .imageCache) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Rectangle().fill(Color.gray)
        }
        .viewSize(avatarSize)
        .clipShape(Circle())
    }
}

struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        AvatarView(
            user: User(id: UUID().uuidString, name: "Dummy User", avatarURL:URL(string: "https://placeimg.com/640/480/sepia"), isCurrentUser:false),
            avatarSize: 32
        )
    }
}
