//
//  Discover Communities View.swift
//  Mlem
//
//  Created by Jake Shirley on 6/30/23.
//

import SwiftUI

struct DiscoverCommunityListView: View {
    let account: SavedAccount
    @State var discoveredCommunities = [APICommunity]()

    private var hasTestCommunities = false

    init(account: SavedAccount, testCommunities: [APICommunity]? = nil) {
        self.account = account

        if testCommunities != nil {
            self.discoveredCommunities = State(initialValue: testCommunities!)
            self.hasTestCommunities = true
        }
    }

    var body: some View {
        VStack {
            ScrollViewReader { scrollProxy in
                HStack {
                    List {
                        ForEach(discoveredCommunities
                        ) { listedCommunity in
                            CommuntiyFeedRowView(
                                account: account,
                                community: listedCommunity,
                                subscribed: false,
                                communitySubscriptionChanged: self.hydrateCommunityData
                            )
                        }
                    }
                    .navigationTitle("Communities")
                    .listStyle(PlainListStyle())
                    .scrollIndicators(.hidden)
                }
            }
        }
        .refreshable {
            await refreshCommunitiesList()
        }
        .task(priority: .userInitiated) {
            // NOTE: This will not auto request if data is provided
            // This is normally only during preview
            if hasTestCommunities == false {
                await refreshCommunitiesList()
            }

        }
    }

    private func refreshCommunitiesList() async {
        let communitiesRequestCount = 50
        do {
            var moreCommunities = true
            var refreshedCommunities: [APICommunity] = []
            var communitiesPage = 1
            repeat {
                let request = ListCommunitiesRequest(
                    account: account,
                    sort: PostSortType.hot,
                    page: communitiesPage,
                    limit: communitiesRequestCount,
                    type: FeedType.all
                )
                
                let response = try await APIClient().perform(request: request)
                
                let newSubscribedCommunities = response.communities.map({
                    return $0.community
                }).sorted(by: {
                    $0.name < $1.name
                })
                
                refreshedCommunities.append(contentsOf: newSubscribedCommunities)
                
                communitiesPage += 1
                
                // Go until we get less than the count we ask for
                moreCommunities = response.communities.count == communitiesRequestCount
            } while (moreCommunities)
            
            discoveredCommunities = refreshedCommunities.sorted(by: { $0.name < $1.name })
        } catch {
            print("Failed to refresh communities: \(error)")
        }
    }
}

// TODO: darknavi - Move API struct generation
// to a common test area for easier discoverability
// and broader usage
let fakeCommunityPrefixes: [String] =
// Generate A-Z
Array(65...90).map({
    var asciiStr = ""
    asciiStr.append(Character(UnicodeScalar($0)!))
    return asciiStr
}) +
// Generate a-z
Array(97...122).map({
    var asciiStr = ""
    asciiStr.append(Character(UnicodeScalar($0)!))
    return asciiStr
}) +
// Generate A bunch of randomm ASCII to make sure sorting works
Array(33...95).map({
    var asciiStr = ""
    asciiStr.append(Character(UnicodeScalar($0)!))
    return asciiStr
})

func generateFakeCommunity(id: Int, namePrefix: String) -> APICommunity {
    APICommunity(
        id: id,
        name: "\(namePrefix) Fake Community \(id)",
        title: "\(namePrefix) Fake Community \(id) Title",
        description: "This is a fake community (#\(id))",
        published: Date.now,
        updated: nil,
        removed: false,
        deleted: false,
        nsfw: false,
        actorId: URL(string: "https://lemmy.google.com/c/\(id)")!,
        local: false,
        icon: nil,
        banner: nil,
        hidden: false,
        postingRestrictedToMods: false,
        instanceId: 0
    )
}

func generateFakeFavoritedCommunity(id: Int, namePrefix: String) -> FavoriteCommunity {
    return FavoriteCommunity(forAccountID: 0, community: generateFakeCommunity(id: id, namePrefix: namePrefix))
}

struct CommunityListViewPreview: PreviewProvider {
    static let favoritesTracker: FavoriteCommunitiesTracker = FavoriteCommunitiesTracker(favoriteCommunities: [
        generateFakeFavoritedCommunity(id: 0, namePrefix: fakeCommunityPrefixes[0]),
        generateFakeFavoritedCommunity(id: 20, namePrefix: fakeCommunityPrefixes[20]),
        generateFakeFavoritedCommunity(id: 10, namePrefix: fakeCommunityPrefixes[10])
    ])

    static var previews: some View {
        CommunityListView(
            account: SavedAccount(id: 0, instanceLink: URL(string: "lemmy.com")!, accessToken: "abcdefg", username: "Test Account"),
            testCommunities: fakeCommunityPrefixes.enumerated().map({ index, element in
                generateFakeCommunity(id: index, namePrefix: element)
            })
        ).environmentObject(favoritesTracker)
    }
}
