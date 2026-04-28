//
//  Item.swift
//  フィットネス
//
//  Created by haruto sugiyama on 2026/04/28.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
