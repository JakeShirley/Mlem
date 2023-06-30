//
//  User Feed Item.swift
//  Mlem
//
//  Created by Jake Shirley on 6/30/23.
//

import Foundation
import SwiftUI

/**
 Protocol for items in the inbox to allow a unified, sorted feed
 */
struct UserFeedItem: Identifiable {
    let published: Date
    let id: Int
    let type: UserFeedType
}

extension UserFeedItem: Comparable {
    static func == (lhs: UserFeedItem, rhs: UserFeedItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func < (lhs: UserFeedItem, rhs: UserFeedItem) -> Bool {
        return lhs.published < rhs.published
    }
}
