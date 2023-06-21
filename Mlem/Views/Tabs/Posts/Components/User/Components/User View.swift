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
    
    @State private var selectionSection = 0
    
    enum FeedType : String, CaseIterable, Identifiable {
        case Overview = "Overview"
        case Comments = "Comments"
        case Posts = "Posts"
        case Saved = "Saved"
        
        var id: String { return self.rawValue }
    }
    
    struct PostFeedItem {
        let account: SavedAccount
        let post: APIPostView
        
        @ViewBuilder
        func view() -> some View {
            NavigationLink {
                ExpandedPost(account: account , post: post, feedType: .constant(.subscribed))
            } label: {
                FeedPost(postView: post, account: account, feedType: .constant(.subscribed))
            }
            .buttonStyle(.plain)
        }
    }
    
    struct CommentFeedItem {
        let account: SavedAccount
        let comment: HierarchicalComment
        
        @ViewBuilder
        func view() -> some View {
            CommentItem(account: account, hierarchicalComment: comment, embedPost: true)
        }
    }
    
    struct FeedItem : Identifiable {
        let id = UUID()
        let published: Date
        let comment: CommentFeedItem?
        let post: PostFeedItem?
    }
    
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
        ScrollView {
            ZStack {
                // Banner
                VStack {
                    if let bannerUrl = userDetails.person.banner {
                        CachedAsyncImage(url: bannerUrl) { image in
                            image
                                .resizable()
                                .frame(height: 200)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                    Spacer()
                }
                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Spacer().frame(height: 110)
                            if let avatarURL = userDetails.person.avatar {
                                CachedAsyncImage(url: avatarURL) { image in
                                    image
                                        .resizable()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .shadow(radius: 10)
                                        .overlay(Circle()
                                            .stroke(.background, lineWidth: 2))
                                } placeholder: {
                                    ProgressView()
                                }
                            } else {
                                Spacer().frame(height: 120) // TODO: Show blank avatar
                            }
                            HStack {
                                Image(systemName: "birthday.cake.fill")
                                Text("Joined 2y ago")
                            }.foregroundColor(.gray)
                            
                        }.padding([.leading])
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Spacer().frame(height: 170)
                            HStack {
                                Text("20 Comments").padding(3).foregroundColor(.white).background(RoundedRectangle(cornerRadius: 5).foregroundColor(.gray)).font(.footnote)
                                Text("30 Posts").padding(3).foregroundColor(.white).background(RoundedRectangle(cornerRadius: 5).foregroundColor(.gray)).font(.footnote)
                            }
                            Spacer().frame(height: 20)
                            
                            Text(userDetails.person.name).font(.title).bold()
                            Text("@\(userDetails.person.name)@\(userDetails.person.actorId.host()!)").font(.footnote)
                            
                        }.padding([.trailing])
                    }
                    
                    if let bio = userDetails.person.bio {
                        MarkdownView(text: bio).padding()
                    }
                }.frame(maxWidth: .infinity)
            }
            
            Picker(selection: $selectionSection, label: Text("Profile Section")) {
                Text(FeedType.Overview.rawValue).tag(0)
                Text(FeedType.Comments.rawValue).tag(1)
                Text(FeedType.Posts.rawValue).tag(2)

                // Only show saved posts if we are
                // browsing our own profile
                if userID == account.id {
                    Text(FeedType.Saved.rawValue).tag(3)
                }
                
            }
            .pickerStyle(.segmented)
           
            if selectionSection == 0 {
                LazyVStack {
                    ForEach(generateMixedFeed())
                    { feedItem in
                        
                        if let comment = feedItem.comment {
                            comment.view()
                        }
                        else if let post = feedItem.post {
                            post.view()
                        }
                        Spacer().frame(height: 8)
                    }
                }.background(Color.secondarySystemBackground)
            }
            else if selectionSection == 1 {
                LazyVStack {
                    ForEach(privateCommentTracker.comments)
                    { comment in
                        CommentItem(account: account, hierarchicalComment: comment, embedPost: true)
                        Spacer().frame(height: 8)
                    }
                }.background(Color.secondarySystemBackground)
            }
            else if selectionSection == 2 {
                LazyVStack {
                    ForEach(privatePostTracker.posts)
                    { post in
                        NavigationLink {
                            ExpandedPost(account: account , post: post, feedType: .constant(.subscribed))
                        } label: {
                            FeedPost(postView: post, account: account, feedType: .constant(.subscribed))
                        }
                        .buttonStyle(.plain)
                        Spacer().frame(height: 8)
                    }
                }.background(Color.secondarySystemBackground)
            }
        }
        .navigationTitle(userDetails.person.name)
        .navigationBarTitleDisplayMode(.inline)
        .headerProminence(.standard)
    }
    
    private func generateMixedFeed() -> [FeedItem] {
        var result: [FeedItem] = []
        
        // Add comments
        result.append(contentsOf: privateCommentTracker.comments.map({
            return FeedItem(published: $0.commentView.comment.published, comment: CommentFeedItem(account: account, comment: $0), post: nil)
        }))
        
        // Add posts
        result.append(contentsOf: privatePostTracker.posts.map({
            return FeedItem(published: $0.post.published, comment: nil, post: PostFeedItem(account: account, post: $0))
        }))
        
        // Sort by authored date, newest first
        result = result.sorted(by: {
            $0.published > $1.published
        })
        
        return result;
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
        return APIPerson(id: name.hashValue, name: name, displayName: displayName, avatar: URL(string: "https://lemmy.ml/pictrs/image/df86c06d-341c-4e79-9c80-d7c7eb64967a.jpeg?format=webp"), banned: false, published: "idk", updated: nil, actorId: URL(string: "https://google.com")!, bio: "Just here for the good vibes!", local: false, banner: URL(string: "https://i.imgur.com/wcayaCB.jpeg"), deleted: false, inboxUrl: URL(string: "google.com")!, sharedInboxUrl: nil, matrixUserId: nil, admin: userType == .Admin, botAccount: userType == .Bot, banExpires: nil, instanceId: 123)
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
        
        return UserProfileLink(account: UserViewPreview.previewAccount, user: previewUser)
    }
    
    static var previews: some View {
        UserView(userID: 123, account: previewAccount, userDetails: APIPersonView(person: generatePreviewUser(name: "actualUsername", displayName: "PreferredUsername", userType: .Normal), counts: APIPersonAggregates(id: 123, personId: 123, postCount: 123, postScore: 567, commentCount: 14, commentScore: 974)))
    }
}
