//
//  User View.swift
//  Mlem
//
//  Created by David Bureš on 02.04.2022.
//

import CachedAsyncImage
import SwiftUI

/// View for showing user profiles
/// Accepts the following parameters:
/// - **userID**: Non-optional ID of the user
/// - **account**: Authenticated account to make the requests
struct UserView: View {
    @EnvironmentObject var appState: AppState
    
    @State var userID: Int
    @State var account: SavedAccount
    
    @State var userDetails: APIPersonView?
    
    @State private var imageHeader: Image?
    
    @StateObject var privatePostTracker: PostTracker = .init()
    @StateObject var privateCommentTracker: CommentTracker = .init()
    
    @State private var errorAlert: ErrorAlert?
    
    var body: some View {
        contentView
            .alert(using: $errorAlert) { content in
                Alert(title: Text(content.title), message: Text(content.message))
            }
        
    }
    
    @ViewBuilder
    private var contentView: some View {
        if let userDetails {
            view(for: userDetails)
        } else {
            progressView
        }
    }
    
    private func view(for userDetails: APIPersonView) -> some View {
        ZStack {
            VStack {
                if let bannerUrl = userDetails.person.banner {
                    CachedAsyncImage(url: bannerUrl) { image in
                        image
                            .resizable()
                            .frame(width: .infinity, height: 200)
                    } placeholder: {
                        ProgressView()
                    }
                }
                Spacer()
            }
            VStack() {
               
                HStack {
                    VStack(alignment: .leading) {
                        Rectangle().frame(width: .infinity, height: 70).opacity(0.0)
                        if let avatarURL = userDetails.person.avatar {
                            CachedAsyncImage(url: avatarURL) { image in
                                image
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle()
                                        .stroke(.white, lineWidth: 1))
                            } placeholder: {
                                ProgressView()
                            }
                        }
                        
                    }.padding(10)
                    Spacer()
                    VStack(alignment: .trailing) {
                        HStack {
                            Text("20 Comments").foregroundColor(.white).background(RoundedRectangle(cornerRadius: 5).foregroundColor(.gray)).font(.footnote)
                            Text("30 Posts").foregroundColor(.white).background(RoundedRectangle(cornerRadius: 5).foregroundColor(.gray)).font(.footnote)
                        }.padding(EdgeInsets(top: 160, leading: 0, bottom: 10, trailing: 0))
                        Text(userDetails.person.name).font(.title)
                        Text("@\(userDetails.person.name)@\(userDetails.person.actorId.host()!)").font(.title3)
                    }.padding(10)
                }
                if let bio = userDetails.person.bio {
                    MarkdownView(text: bio)
                }
                
                HStack(alignment: .center, spacing: 20) {
                    VStack(alignment: .center, spacing: 2) {
                        Text(String(userDetails.counts.commentScore))
                            .fontWeight(.bold)
                        Text("Comment\nScore")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text(String(userDetails.counts.postScore))
                            .fontWeight(.bold)
                        Text("Post\nScore")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                Spacer()
            }.frame(maxWidth: .infinity)
            
            
#warning("TODO: Make showing a user's posts and comments work")
            /*
             Section
             {
             NavigationLink {
             ScrollView
             {
             LazyVStack {
             ForEach(privatePostTracker.posts)
             { post in
             NavigationLink {
             PostExpanded(account: account, postTracker: privatePostTracker, post: post, feedType: .constant(.subscribed))
             } label: {
             PostItem(postTracker: privatePostTracker, post: post, isExpanded: false, isInSpecificCommunity: false, account: account, feedType: .constant(.subscribed))
             }
             .buttonStyle(.plain)
             }
             }
             }
             .navigationTitle("Recents by \(userDetails.name)")
             .navigationBarTitleDisplayMode(.inline)
             } label: {
             Text("Recent Posts")
             }
             
             }
             */
        }
        .navigationTitle(userDetails.person.name)
        .navigationBarTitleDisplayMode(.inline)
        .headerProminence(.standard)
    }
    
    private var progressView: some View {
        ProgressView {
            Text("Loading user details…")
        }
        .task(priority: .background) {
            do {
                let response = try await loadUser()
                
                userDetails = response.personView
                privateCommentTracker.comments = response.comments.hierarchicalRepresentation
                privatePostTracker.add(response.posts)
            } catch {
                handle(error)
            }
        }
    }
    
    private func loadUser() async throws -> GetPersonDetailsResponse {
        let request = try GetPersonDetailsRequest(
            accessToken: account.accessToken,
            instanceURL: account.instanceLink,
            personId: userID
        )
        
        return try await APIClient().perform(request: request)
    }
    
    private func handle(_ error: Error) {
        switch error {
        case APIClientError.response(let message, _):
            errorAlert = .init(
                title: "Error",
                message: message.error
            )
        case is APIClientError:
            errorAlert = .init(
                title: "Couldn't load user info",
                message: "There was an error while loading user information.\nTry again later."
            )
        default:
            errorAlert = .unexpected
        }
    }
}


// TODO: darknavi - Move these to a common area for reuse
struct UserViewPreview : PreviewProvider {
    static let previewAccount = SavedAccount(id: 0, instanceLink: URL(string: "lemmy.com")!, accessToken: "abcdefg", username: "Test Account")
    
    // Only Admin and Bot work right now
    // Because the rest require post/comment context
    enum PreviewUserType:  String, CaseIterable {
        case Normal = "normal"
        case Mod = "mod"
        case OP = "op"
        case Bot = "bot"
        case Admin = "admin"
        case Dev = "developer"
    }
    
    static func generatePreviewUser(name: String, displayName: String, userType: PreviewUserType) -> APIPerson {
        return APIPerson(id: name.hashValue, name: name, displayName: displayName, avatar: URL(string: "https://lemmy.ml/pictrs/image/df86c06d-341c-4e79-9c80-d7c7eb64967a.jpeg?format=webp"), banned: false, published: "idk", updated: nil, actorId: userType == .Dev ? URL(string: "http://\(UserProfileLink.developerNames[0])")! : URL(string: "https://google.com")!, bio: nil, local: false, banner: URL(string: "https://i.imgur.com/wcayaCB.jpeg"), deleted: false, inboxUrl: URL(string: "google.com")!, sharedInboxUrl: nil, matrixUserId: nil, admin: userType == .Admin, botAccount: userType == .Bot, banExpires: nil, instanceId: 123)
    }
    
    static func generatePreviewComment(creator: APIPerson, isMod: Bool) -> APIComment {
        return APIComment(id: 0, creatorId: creator.id, postId: 0, content: "", removed: false, deleted: false, published: Date.now, updated: nil, apId: "foo.bar", local: false, path: "foo", distinguished: isMod, languageId: 0)
    }
    
    static func generateFakeCommunity(id: Int, namePrefix: String) -> APICommunity {
        return APICommunity(id: id, name: "\(namePrefix) Fake Community \(id)", title: "\(namePrefix) Fake Community \(id) Title", description: "This is a fake community (#\(id))", published: Date.now, updated: nil, removed: false, deleted: false, nsfw: false, actorId: URL(string: "https://lemmy.google.com/c/\(id)")!, local: false, icon: nil, banner: nil, hidden: false, postingRestrictedToMods: false, instanceId: 0)
    }
    
    static func generatePreviewPost(creator: APIPerson) -> APIPostView {
        let community = generateFakeCommunity(id: 123, namePrefix: "Test")
        let post = APIPost(id: 123, name: "Test Post Title", url: nil, body: "This is a test post body", creatorId: creator.id, communityId: 123, deleted: false, embedDescription: "Embeedded Description", embedTitle: "Embedded Title", embedVideoUrl: nil, featuredCommunity: false, featuredLocal: false, languageId: 0, apId: "my.app.id", local: false, locked: false, nsfw: false, published: Date.now, removed: false, thumbnailUrl: nil, updated: nil)
        
        let postVotes = APIPostAggregates(id: 123, postId: post.id, comments: 0, score: 10, upvotes: 15, downvotes: 5, published: Date.now, newestCommentTime: Date.now, newestCommentTimeNecro: Date.now, featuredCommunity: false, featuredLocal: false)
        
        return APIPostView(post: post, creator: creator, community: community, creatorBannedFromCommunity: false, counts: postVotes, subscribed: .notSubscribed, saved: false, read: false, creatorBlocked: false, unreadComments: 0)
    }
    
    static func generateUserProfileLink(name: String, userType: PreviewUserType) -> UserProfileLink {
        let previewUser = generatePreviewUser(name: name, displayName: name, userType: userType);
        
        var postContext: APIPostView? = nil
        var commentContext: APIComment? = nil
        
        if userType == .Mod {
            commentContext = generatePreviewComment(creator: previewUser, isMod:  true)
        }
        
        if userType == .OP {
            commentContext = generatePreviewComment(creator: previewUser, isMod:  false)
            postContext = generatePreviewPost(creator: previewUser)
        }
        
        return UserProfileLink(account: UserProfileLinkPreview.previewAccount, user: previewUser, postContext: postContext, commentContext: commentContext)
    }
    
    static var previews: some View {
        UserView(userID: 123, account: previewAccount, userDetails: APIPersonView(person: generatePreviewUser(name: "Dave", displayName: "Dave", userType: .Normal), counts: APIPersonAggregates(id: 123, personId: 123, postCount: 123, postScore: 567, commentCount: 14, commentScore: 974)))
    }
}
