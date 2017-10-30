//
//  Feed.swift
//  AwesomeBlogs
//
//  Created by wade.hawk on 2017. 8. 27..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

class Feed: Object {
    @objc dynamic var group: String = ""
    @objc dynamic var title: String = ""
    @objc dynamic var desc: String = ""
    @objc dynamic var updatedAt: Double = 0
    @objc dynamic var expiredTime: Double = 0
    
    let entries = List<EntryDB>()
    
    override static func primaryKey() -> String? {
        return "group"
    }
    
    convenience init(group: AwesomeBlogs.Group, json: JSON) {
        self.init()
        self.group = group.rawValue
        self.title = json["title"].stringValue
        self.desc = json["description"].stringValue
        self.updatedAt = DateAtTransform().transformFromJSON(json["updated_at"].string)?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
        self.expiredTime = Date().timeIntervalSince1970
    }
    
    func isExpired(time: TimeInterval) -> Bool {
        return Date(timeIntervalSince1970: expiredTime).timeIntervalSinceNow < time
    }
}
