//
//  Communities View.swift
//  Mlem
//
//  Created by Ethan Hargus on 6/18/23.
//

import SwiftUI

struct CommunitiesListView: View {
    @EnvironmentObject var favoritedCommunitiesTracker: FavoriteCommunitiesTracker
    @State var subscribedCommunities: [APICommunity]?

    var account: SavedAccount
    
    var body: some View {
        VStack (alignment: .leading, spacing: 10) {
            List {
                Section {
                    NavigationLink(destination: CommunityView(account: account, community: nil, feedType: .subscribed)) {
                        Label("Subscribed", systemImage: "house")
                    }
                    
                    NavigationLink(destination: CommunityView(account: account, community: nil, feedType: .all)) {
                        Label("All", systemImage: "rectangle.stack.fill")
                    }
                }
                
                Section {
                    if !getFavoritedCommunitiesForAccount(account: account, tracker: favoritedCommunitiesTracker).isEmpty
                    {
                        ForEach(getFavoritedCommunitiesForAccount(account: account, tracker: favoritedCommunitiesTracker))
                        { favoritedCommunity in
                            NavigationLink(destination: CommunityView(account: account, community: favoritedCommunity.community, feedType: .all))
                            {
                                Text("\(favoritedCommunity.community.name)\(Text("@\(favoritedCommunity.community.actorId.host ?? "ERROR")").foregroundColor(.secondary).font(.caption))")
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true)
                                {
                                    Button(role: .destructive)
                                    {
                                        unfavoriteCommunity(account: account, community: favoritedCommunity.community, favoritedCommunitiesTracker: favoritedCommunitiesTracker)
                                    } label: {
                                        Label("Unfavorite", systemImage: "star.slash")
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        VStack(alignment: .center, spacing: 10)
                        {
                            Image(systemName: "star.slash")
                            Text("You have no communities favorited")
                        }
                        .listRowBackground(Color.clear)
                        .frame(maxWidth: .infinity)
                    }
                } header: {
                    Text("Favorites")
                }
                
                Section {
                    if subscribedCommunities != nil {
                        if !subscribedCommunities!.isEmpty
                        {
                            ForEach(subscribedCommunities!)
                            { subscribedCommunity in
                                NavigationLink(destination: CommunityView(account: account, community: subscribedCommunity, feedType: .all))
                                {
                                    Text("\(subscribedCommunity.name)\(Text("@\(subscribedCommunity.actorId.host!)").foregroundColor(.secondary).font(.caption))")
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true)
                                    {
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        VStack(alignment: .center, spacing: 10)
                        {
                            Image(systemName: "star.slash")
                            Text("You have no community subscriptions")
                        }
                        .listRowBackground(Color.clear)
                        .frame(maxWidth: .infinity)
                    }
                    
                } header: {
                    Text("Subscribed")
                }
            }
        }
        .task {
            let request = ListCommunitiesRequest(account: account, sort: nil, page: nil, limit: nil, type: FeedType.subscribed);
            do {
                let response = try await APIClient().perform(request: request);
                subscribedCommunities = response.communities.map({
                    return $0.community;
                }).sorted(by: {
                    $0.name < $1.name
                });
            } catch {
                
            }
        }
    }
    
    internal func getFavoritedCommunitiesForAccount(account: SavedAccount, tracker: FavoriteCommunitiesTracker) -> [FavoriteCommunity]
    {
        return tracker.favoriteCommunities.filter { $0.forAccountID == account.id }
    }
}

