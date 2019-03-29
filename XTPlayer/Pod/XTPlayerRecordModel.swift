//
//  XTPlayerRecordModel.swift
//
//  Created by Shaw on 2019/2/22.
//  Copyright © 2019 Shaw. All rights reserved.
//

import UIKit
import WCDBSwift

/** 表-用户行为-播放记录*/
let table_UserBehavior_PlayerRecord = "UserBehavior_PlayerRecord"

class XTPlayerRecordModel: TableCodable {
    /** 播放地址*/
    var xt_playURL: String?
    /** 文件名称*/
    var xt_sourceName: String?
    /** 唯一标识符*/
    var xt_uniqueID: String?
    /** 数据源时长*/
    var xt_duration: UInt?
    /** 记录播放进度*/
    var xt_playProgress: Float?
    /** 上一次播放日期*/
    var xt_lastPlayedTime: Date?
    /** 同一个日期下累计播放时长*/
    var xt_cumulativePlaybackTime: UInt?
    /** 历史最大进度*/
    var xt_maxHistoricalProgress: Float?
    
    enum CodingKeys: String, CodingTableKey {
        
        typealias Root = XTPlayerRecordModel
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case xt_playURL
        
        case xt_sourceName
        
        case xt_uniqueID
        
        case xt_duration
        
        case xt_playProgress
        
        case xt_lastPlayedTime
        
        case xt_cumulativePlaybackTime
        
        case xt_maxHistoricalProgress
        
    }
    
}
