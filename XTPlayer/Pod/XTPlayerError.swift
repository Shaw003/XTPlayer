//
//  XTPlayerError.swift
//
//  Created by Shaw on 2019/3/12.
//  Copyright © 2019 Shaw. All rights reserved.
//

import Foundation

// MARK: —————————— 播放器错误类型 ——————————
public enum XTPlayerError: Swift.Error {
    
    case dataSourceError(reason: DataSourceError)
    case networkError(reason: NetworkError)
    case functionError(reason: FunctionError)
    case playerStatusError(reason: PlayerStatusError)
    
    /** 数据源错误*/
    public enum DataSourceError {
        /** 缺少数据源*/
        case lackOfDataSource
        /** 没有权限播放数据源，或缺少授权信息*/
        case noPermission
        /** 无效的数据源，没有播放地址的数据源*/
        case invalidDataSource
        /** 没有上一条数据*/
        case noLastDataSource
        /** 没有下一条数据*/
        case noNextDataSource
    }
    /** 网络错误*/
    public enum NetworkError {
        /** 网络不可用*/
        case notReachable
        /** 网络超时*/
        case timeout
    }
    /** 功能异常*/
    public enum FunctionError {
        /** 缓存功能异常*/
        case cacheFailed
        /** 数据库记录异常*/
        case recordFailed
        /** 数据库功能未启用*/
        case databaseUnavailable
        /** 跳转历史进度功能未启用*/
        case seekToHistoryUnavailable
    }
    
    /** 播放器播放状态异常*/
    public enum PlayerStatusError {
        /** 未知异常*/
        case unknown
        /** 播放状态异常，无法播放*/
        case failed
    }
}

extension XTPlayerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .dataSourceError(let reason):
            return reason.localizedDescription
        case .functionError(let reason):
            return reason.localizedDescription
        case .networkError(let reason):
            return reason.localizedDescription
        case .playerStatusError(let reason):
            return reason.localizedDescription
        }
    }

}

extension XTPlayerError.DataSourceError {
    public var localizedDescription: String {
        switch self {
        case .invalidDataSource:
            return "Invalid DataSource."
        case .lackOfDataSource:
            return "Lack of DataSource."
        case .noLastDataSource:
            return "There is no exists or you have no permission to access the last DataSource."
        case .noNextDataSource:
            return "There is no exists or you have no permission to access the next DataSource."
        case .noPermission:
            return "You have no permission to access the DataSource."
        }
    }
    
}

extension XTPlayerError.NetworkError {
    public var localizedDescription: String {
        switch self {
        case .notReachable:
            return "Network is not reachable."
        case .timeout:
            return "Network is timeout."
        }
    }
}

extension XTPlayerError.FunctionError {
    public var localizedDescription: String {
        switch self {
        case .cacheFailed:
            return "Cache is failed."
        case .databaseUnavailable:
            return "Database function is unavailable."
        case .recordFailed:
            return "Play record write into database is failed."
        case .seekToHistoryUnavailable:
            return "Seek to history function is unavailable."
        }
    }
}

extension XTPlayerError.PlayerStatusError {
    public var localizedDescription: String {
        switch self {
        case .failed:
            return "Player play failed."
        case .unknown:
            return "There is an unknown error occurs while playing."
        }
    }
}
