//
//  BlockPerson.swift
//  Mlem
//
//  Created by Jake Shirley on 6/29/23.
//

import Foundation

struct BlockPersonRequest: APIGetRequest {

    typealias Response = GetPersonDetailsResponse

    let instanceURL: URL
    let path = "user/block"
    let queryItems: [URLQueryItem]

    // lemmy_api_common::person::BlockPerson
    init(
        account: SavedAccount,
        person: APIPerson,
        block: Bool
    ) {
        self.instanceURL = account.instanceLink
        self.queryItems = [
            .init(name: "auth", value: account.accessToken),
            .init(name: "person_id", value: person.id.description),
            .init(name: "block", value: String(block))
        ]
    }
}

// lemmy_api_common::person::BlockPersonResponse
struct BlockPersonResponse: Decodable {
    let personView: APIPersonView
    let blocked: Bool
}
