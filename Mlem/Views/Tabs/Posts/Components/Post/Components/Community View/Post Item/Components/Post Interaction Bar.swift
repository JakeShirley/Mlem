//
//  File.swift
//  Mlem
//
//  Created by Eric Andrews on 2023-06-10.
//

import SwiftUI

import Foundation

/**
 View grouping post interactions--upvote, downvote, save, reply, plus post info
 */
struct PostInteractionBar: View {
    // ==== TEMPORARY ====
    @State var isPresentingAlert: Bool = false
    // ==== END TEMPORARY ==== //
    
    // constants
    let iconToTextSpacing: CGFloat = 2
    let iconPadding: CGFloat = 4
    let iconCorner: CGFloat = 2
    let scoreItemWidth: CGFloat = 12
    
    // state fakers--these let the upvote/downvote/score/save views update instantly even if the call to the server takes longer
    @State var dirtyVote: ScoringOperation
    @State var dirtyScore: Int
    @State var dirtySaved: Bool
    @State var dirty: Bool
    
    // computed properties--if dirty, show dirty value, otherwise show post value
    var displayedVote: ScoringOperation { dirty ? dirtyVote : post.myVote ?? .resetVote }
    var displayedScore: Int { dirty ? dirtyScore : post.counts.score }
    
    // parameters
    let post: APIPostView
    let account: SavedAccount
    let compact: Bool
    let voteOnPost: (ScoringOperation) async -> Void
    
    init(post: APIPostView, account: SavedAccount, compact: Bool, voteOnPost: @escaping (ScoringOperation) async -> Void) {
        self.post = post
        self.account = account
        self.compact = compact
        self.voteOnPost = voteOnPost
        _dirtyVote = State(initialValue: post.myVote ?? .resetVote)
        _dirtyScore = State(initialValue: post.counts.score)
        _dirtySaved = State(initialValue: false)
        _dirty = State(initialValue: false)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                VoteComplex(vote: displayedVote, score: displayedScore, upvote: upvote, downvote: downvote)
                    .padding(.trailing, 8)
                SaveButton(saved: false)
                    .onTapGesture {
                        Task(priority: .userInitiated) {
                            await savePost()
                        }
                        // ==== TEMPORARY ==== //
                        isPresentingAlert = true
                    }
                    .alert("That feature isn't implemented yet!",
                           isPresented: $isPresentingAlert) {
                    }
                // ==== END TEMPORARY ==== //
                ReplyButton()
                    .onTapGesture {
                        // ==== TEMPORARY ==== //
                        isPresentingAlert = true
                    }
                    .alert("That feature isn't implemented yet!",
                           isPresented: $isPresentingAlert) {
                    }
                // ==== END TEMPORARY ==== //
                Spacer()
                infoBlock
            }
            .padding(.horizontal)
            .padding(.vertical, compact ? 2 : 6)
        }
        .dynamicTypeSize(compact ? .small : .medium)
    }
    
    // subviews
    
    var infoBlock: some View {
        // post info component
        HStack(spacing: 8) {
            HStack(spacing: iconToTextSpacing) {
                Image(systemName: "clock")
                Text(getTimeIntervalFromNow(date: post.post.published))
            }
            HStack(spacing: iconToTextSpacing) {
                Image(systemName: "bubble.left")
                Text(String(post.counts.comments))
            }
        }
        .foregroundColor(.secondary)
    }
    
    // helper functions
    
    func upvote() async -> Void {
        // fake downvote
        switch (displayedVote) {
        case .upvote:
            dirtyVote = .resetVote
            dirtyScore = displayedScore - 1
        case .resetVote:
            dirtyVote = .upvote
            dirtyScore = displayedScore + 1
        case .downvote:
            dirtyVote = .upvote
            dirtyScore = displayedScore + 2
        }
        dirty = true
        
        // wait for vote
        await voteOnPost(.upvote)
        
        // unfake downvote
        dirty = false
    }
    
    func downvote() async -> Void {
        // fake upvote
        switch (displayedVote) {
        case .upvote:
            dirtyVote = .downvote
            dirtyScore = displayedScore - 2
        case .resetVote:
            dirtyVote = .downvote
            dirtyScore = displayedScore - 1
        case .downvote:
            dirtyVote = .resetVote
            dirtyScore = displayedScore + 1
        }
        dirty = true
        
        // wait for vote
        await voteOnPost(.downvote)
        
        // unfake upvote
        dirty = false
    }
    
    /**
     Sends a save request for the current post
     */
    func savePost() async {
        // TODO: implement
    }
}
