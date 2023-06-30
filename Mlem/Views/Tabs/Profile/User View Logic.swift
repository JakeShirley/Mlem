//
//  User View Logic.swift
//  Mlem
//
//  Created by Jake Shirley on 6/30/23.
//

import Foundation

extension UserView {
    
    func tryLoadUser() async {
        do {
            let authoredContent = try await loadUser(savedItems: false)
            var savedContentData: GetPersonDetailsResponse?
            if isShowingOwnProfile() {
                savedContentData = try await loadUser(savedItems: true)
            }
            
            privateCommentTracker.add(authoredContent.comments
                .sorted(by: { $0.comment.published > $1.comment.published})
                .map({HierarchicalComment(comment: $0, children: [])}))
            
            privatePostTracker.add(authoredContent.posts)
            
            if let savedContent = savedContentData {
                privateCommentTracker.add(savedContent.comments
                    .sorted(by: { $0.comment.published > $1.comment.published})
                    .map({HierarchicalComment(comment: $0, children: [])}))
                
                privatePostTracker.add(savedContent.posts)
            }
            
            userDetails = authoredContent.personView
            updateAvatarSubtext()
        } catch {
            handle(error)
        }
    }
    
    private func loadUser(savedItems: Bool) async throws -> GetPersonDetailsResponse {
        let request = try GetPersonDetailsRequest(
            account: account,
            limit: 20, // TODO: Stream pages
            savedOnly: savedItems,
            personId: userID
        )

        return try await APIClient().perform(request: request)
    }

    func handle(_ error: Error) {
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
    
    func generateCommentFeed(savedItems: Bool) -> [FeedItem] {
        return privateCommentTracker.comments
            // Matched saved state
            .filter({
                if savedItems {
                    return $0.commentView.saved
                } else {
                    // If we un-favorited something while
                    // here we don't want it showing up in our feed
                    return $0.commentView.creator.id == userID
                }
            })
        
            // Create Feed Items
            .map({
                return FeedItem(published: $0.commentView.comment.published, comment: $0, post: nil)
            })
        
            // Newest first
            .sorted(by: {
            $0.published > $1.published
        })
    }
    
    func generatePostFeed(savedItems: Bool) -> [FeedItem] {
        return privatePostTracker.items
            // Matched saved state
            .filter({
                if savedItems {
                    return $0.saved
                } else {
                    // If we un-favorited something while
                    // here we don't want it showing up in our feed
                    return $0.creator.id == userID
                }
            })
        
            // Create Feed Items
            .map({
                return FeedItem(published: $0.post.published, comment: nil, post: $0)
            })
        
            // Newest first
            .sorted(by: {
            $0.published > $1.published
        })
    }
    
    func generateMixedFeed(savedItems: Bool) -> [FeedItem] {
        var result: [FeedItem] = []
        
        result.append(contentsOf: generatePostFeed(savedItems: savedItems))
        result.append(contentsOf: generateCommentFeed(savedItems: savedItems))
        
        // Sort by authored date, newest first
        result = result.sorted(by: {
            $0.published > $1.published
        })
        
        return result
    }
    
    /*
     Updates the text under the avatar between the cake
     day and the relative days since joining.
     */
    private func updateAvatarSubtext() {
        if let user = userDetails {
            if showingCakeDay {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "ddMMYY", options: 0, locale: Locale.current)
                
                avatarSubtext = "Joined \(dateFormatter.string(from: user.person.published))"
            } else {
                avatarSubtext = "Joined \(user.person.published.getRelativeTime(date: Date.now))"
            }
        } else {
            avatarSubtext = ""
        }
    }
    
    func toggleCakeDayVisible() {
        showingCakeDay = !showingCakeDay
        updateAvatarSubtext()
    }
    
    func isShowingOwnProfile() -> Bool {
        return userID == account.id
    }
    
}
