//
//  XTPlayerRecord.swift
//
//  Created by Shaw on 2019/3/25.
//  Copyright © 2019 Shaw. All rights reserved.
//

import UIKit
import WCDBSwift

public class XTPlayerRecord {

    /// 初始化配置
    public class func initConfig() {
        debugPrint("播放记录功能初始化")
        try? wcdb.create(table: table_UserBehavior_PlayerRecord, of: XTPlayerRecordModel.self)
        
    }
    
    /// 查询历史播放进度
    ///
    /// - Parameters:
    ///   - array: 要查询的数据源数组
    /// - Returns: 查询结果
    @discardableResult
    public class func queryHistoryPlayProgress(array: [XTPlayerDataSource], uniqueID: String) -> [Float] {
        var result = [Float]()
        for dataSource in array {
            let progress = queryHistoryPlayProgress(single: dataSource, uniqueID: uniqueID)
            result.append(progress)
        }
        return result
    }
    
    /// 查询历史播放进度
    ///
    /// - Parameters:
    ///   - single: 要查询的数据源
    /// - Returns: 查询结果
    @discardableResult
    public class func queryHistoryPlayProgress(single: XTPlayerDataSource, uniqueID: String) -> Float {
        
        var progress: Float = 0
        if let url = single.xt_playURL {
            let wExp1 = XTPlayerRecordModel.Properties.xt_uniqueID == uniqueID
            let wExp2 = XTPlayerRecordModel.Properties.xt_playURL == url
            
            if let temp = try? wcdb.getValue(on: XTPlayerRecordModel.Properties.xt_playProgress, fromTable: table_UserBehavior_PlayerRecord, where: wExp1 && wExp2, orderBy: [XTPlayerRecordModel.Properties.xt_lastPlayedTime.asOrder(by: .descending)], limit: nil, offset: nil).doubleValue {
                
                progress = Float(temp)
                debugPrint("数据库中查到了\(single.xt_sourceName!)的播放进度记录为\(progress)")
            } else {
                debugPrint("数据库中没查到\(single.xt_sourceName!)的播放进度记录")
            }
        } else {
            debugPrint("没有url")
        }
        
        return progress
    }

    
    /// 记录播放进度函数
    ///
    /// - Parameters:
    ///   - dataSource: 数据源
    ///   - uniqueID: 区别数据记录标识符
    ///   - progress: 当前播放进度值
    ///   - duration: 当前数据源时长
    ///   - deltaInterval: 要累加的播放时长
    /// - Throws: 异常处理
    public class func recordProgress(dataSource: XTPlayerDataSource, uniqueID: String, progress: Float, duration: UInt, deltaInterval: UInt) throws {
        guard let url = dataSource.xt_playURL else {
            let error = XTPlayerError.dataSourceError(reason: .invalidDataSource)
            throw error
        }
        let record = XTPlayerRecordModel()
        record.xt_playURL = dataSource.xt_playURL
        record.xt_uniqueID = uniqueID
        record.xt_duration = duration
        record.xt_playProgress = progress
        record.xt_sourceName = dataSource.xt_sourceName
        record.xt_lastPlayedTime = Date()
        record.xt_cumulativePlaybackTime = deltaInterval
        record.xt_maxHistoricalProgress = progress
        try? wcdb.run(transaction: {
            let wExp1 = XTPlayerRecordModel.Properties.xt_uniqueID == uniqueID
            let wExp2 = XTPlayerRecordModel.Properties.xt_playURL == url
            // 如果该日期下已经有记录，则更新一些信息
            let wExp3 = XTPlayerRecordModel.Properties.xt_lastPlayedTime > Date().zero
            let result: XTPlayerRecordModel? = try wcdb.getObject(on: XTPlayerRecordModel.Properties.all, fromTable: table_UserBehavior_PlayerRecord, where: wExp1 && wExp2 && wExp3, orderBy: nil, offset: nil)
            if let savedRecord = result {
                // 尝试读取数据库记录的最大进度
                let max = try wcdb.getValue(on: XTPlayerRecordModel.Properties.xt_maxHistoricalProgress.max(isDistinct: true), fromTable: table_UserBehavior_PlayerRecord, where: wExp1 && wExp2, orderBy: nil, limit: 1, offset: nil).doubleValue
                //                debugPrint("\(Date()) 读取到记录的最大进度为 \(max)")
                if progress > Float(max) {
                    record.xt_maxHistoricalProgress = progress
                } else {
                    record.xt_maxHistoricalProgress = Float(max)
                }
                
                if let cumulation = savedRecord.xt_cumulativePlaybackTime {
                    record.xt_cumulativePlaybackTime! += cumulation
                    //                    debugPrint("累计更新前 = \(cumulation)，更新后 = \(record.xt_cumulativePlaybackTime!)")
                }
                try wcdb.run(embeddedTransaction: {
                    // 对上一次播放时间戳、最大进度、累计播放时长、当前播放进度进行更新
                    try wcdb.update(table: table_UserBehavior_PlayerRecord, on: [XTPlayerRecordModel.Properties.xt_lastPlayedTime, XTPlayerRecordModel.Properties.xt_maxHistoricalProgress, XTPlayerRecordModel.Properties.xt_cumulativePlaybackTime, XTPlayerRecordModel.Properties.xt_playProgress], with: record, where: wExp1 && wExp2, orderBy: [XTPlayerRecordModel.Properties.xt_lastPlayedTime.asOrder(by: .descending)], limit: 1, offset: nil)
                })
            } else {
                debugPrint("\(Date()) 该日期下没有记录，新插入一条记录")
                try wcdb.run(embeddedTransaction: {
                    try wcdb.insert(objects: [record], intoTable: table_UserBehavior_PlayerRecord)
                    
                })
            }
            
        })
    }
}
