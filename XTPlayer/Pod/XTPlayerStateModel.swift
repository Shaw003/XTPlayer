//
//  XTPlayerStateModel.swift
//
//  Created by Shaw on 2019/3/18.
//  Copyright © 2019 Shaw. All rights reserved.
//

import UIKit

public class XTPlayerStateModel {
    /** 播放状态*/
    public var state: XTPlayerState = .idle
    /** 播放进度*/
    public var progress: Float = 0
    /** 缓冲进度*/
    public var buffer: Float = 0
    /** 当前播放秒数*/
    public var current: UInt = 0
    /** 总时长*/
    public var duration: UInt = 0
//    /** 最大历史进度*/
//    var maxHistoricalProgress: Float = 0
}
