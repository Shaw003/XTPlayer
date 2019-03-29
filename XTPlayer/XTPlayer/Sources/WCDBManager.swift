//
//  WCDBManager.swift
//
//  Created by Shaw on 2019/2/20.
//  Copyright © 2019 Shaw. All rights reserved.
//

import UIKit
import WCDBSwift

public let wcdb = WCDBManager.instance.database
public let dbm = WCDBManager.instance

public class WCDBManager {
    
    static let dbDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    static let instance = WCDBManager()
    
    public var database: Database
    
    private init() {
        debugPrint("数据库功能初始化")
        self.database = WCDBManager.database()
    }
    
    public func initConfig(execute: @escaping () -> ()) {
        execute()
    }

    
    /// 读取数据库
    ///
    /// - Parameters:
    ///   - name: 数据库的文件名
    ///   - tag: 数据库标签
    /// - Returns: 读取到的数据库实体
    @discardableResult
    public class func database(_ name: String? = nil, tag: Int = 1) -> Database {
        var dbName = Bundle.main.bundleIdentifier!
        if let name = name {
            if !name.isEmpty {
                dbName = name
            }
        }
        let path = dbDirectory + "/\(dbName)" + ".db"
        let database = Database(withPath: path)
        database.tag = tag
        debugPrint("创建数据库地址\(path)")
        return database
    }
    
}
