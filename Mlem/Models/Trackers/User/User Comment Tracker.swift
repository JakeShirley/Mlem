//
//  User Comment Tracker.swift
//  Mlem
//
//  Created by Jake Shirley on 6/30/23.
//

import Foundation

@MainActor
class UserCommentTracker: FeedTracker<APICommentView> {
    let userId: Int
    let savedComments: Bool
    
    let itemsPerPage = 50
    
    init(userId: Int, savedComments: Bool) {
        self.userId = userId
        self.savedComments = saved
    }
    
    func loadNextPage(account: SavedAccount) async throws {
        let request = try GetPersonDetailsRequest(
            account: account,
            page: page,
            limit: itemsPerPage,
            savedOnly: savedComments,
            personId: userId
        )
        
        try await perform(request)
    }
    
    func refresh(account: SavedAccount) async throws {
        let request = try GetPersonDetailsRequest(
            account: account,
            page: 1,
            limit: itemsPerPage,
            savedOnly: savedComments,
            personId: userId
        )
        try await refresh(request)
    }
}
