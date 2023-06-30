//
//  CommunityListSidebarEntry.swift
//  Mlem
//
//  Created by Jake Shirley on 6/19/23.
//

import Foundation

protocol SidebarEntry {
    var sidebarLabel: String? {get set}
    var sidebarIcon: String? {get set}
    func contains(community: APICommunity, isSubscribed: Bool, isModerator: Bool) -> Bool
}

// Filters no communities, used for top entry in sidebar
struct EmptySidebarEntry: SidebarEntry {
    var sidebarLabel: String?
    var sidebarIcon: String?

    func contains(community: APICommunity, isSubscribed: Bool, isModerator: Bool) -> Bool {
        return false
    }
}

// Filters based on community name
struct RegexCommunityNameSidebarEntry: SidebarEntry {
    var communityNameRegex: Regex<Substring>
    var sidebarLabel: String?
    var sidebarIcon: String?

    func contains(community: APICommunity, isSubscribed: Bool, isModerator: Bool) -> Bool {
        // Ignore unsubscribed subs from main list
        if !isSubscribed {
            return false
        }
        return community.name.starts(with: communityNameRegex)
    }
}

// Filters to favorited communities
struct FavoritesSidebarEntry: SidebarEntry {
    let account: SavedAccount
    let favoritesTracker: FavoriteCommunitiesTracker
    var sidebarLabel: String?
    var sidebarIcon: String?

    func contains(community: APICommunity, isSubscribed: Bool, isModerator: Bool) -> Bool {
        return getFavoritedCommunities(account: account, favoritedCommunitiesTracker: favoritesTracker).contains(community)
    }
}

// Filters to moderated
struct ModeratedSidebarEntry: SidebarEntry {
    let account: SavedAccount
    var sidebarLabel: String?
    var sidebarIcon: String?

    func contains(community: APICommunity, isSubscribed: Bool, isModerator: Bool) -> Bool {
        return isModerator
    }
}
