//
//  CustomAudioModel.swift
//  XTPlayer_Example
//
//  Created by Shaw on 2019/3/28.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import XTPlayer

class CustomAudioModel: XTPlayerDataSource {
    /** 需要具体描述音频数据源的播放类型，共有3种类型，
     /** 没有权限*/
     case noPermission
     /** 完整播放*/
     case full
     /** 部分播放，参数为允许播放时长*/
     case partly(length: UInt)
     */
    var xt_sourceType: XTPlayerSourceType {
        get {
            if isFree == 1 {
                return .full
            } else if let length = freeTime {
                return .partly(length: length)
            } else {
                return .noPermission
            }
        }
    }
    
    var xt_playURL: String? {
        get {
            return audioUrl
        }
    }
    
    var xt_sourceName: String? {
        get {
            return audioTitle
        }
    }
    
    /** 音频地址*/
    var audioUrl: String?
    /** 音频标题*/
    var audioTitle: String?
    /** 是否可以完整播放*/
    var isFree: Int?
    /** 不可以完整播放时能播放的秒数*/
    var freeTime: UInt?
}
