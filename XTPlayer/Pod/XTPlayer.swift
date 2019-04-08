//
//  XTPlayer.swift
//
//  Created by Shaw on 2019/1/22.
//  Copyright © 2019年 Shaw. All rights reserved.
//

import UIKit
import AVFoundation

public let xt_player = XTPlayer.instance


// MARK: —————————— 播放器状态类型 ——————————
public enum XTPlayerState: String {
    
    case idle = "闲置中"
    case isPlaying = "正在播放中"
    case isBuffering = "正在缓冲中"
    case paused = "暂停"
    case stoped = "结束"
    case failed = "失败"
}
// MARK: —————————— 倒计时功能 ——————————
public enum XTPlayerCountdown {
    case none
    /** 播放完N条后停止*/
    case endCount(dataSourceCount: UInt)
    /** N秒后结束播放*/
    case endSecond(seconds: UInt)
}

private enum XTPlayerObserverKey: String {
    case status = "status"
    case loadedTimeRanges = "loadedTimeRanges"
    case playbackBufferEmpty = "playbackBufferEmpty"
    case playbackLikelyToKeepUp = "playbackLikelyToKeepUp"
}
// MARK: —————————— 播放器数据源类型 ——————————
public enum XTPlayerSourceType {
    /** 没有权限*/
    case noPermission
    /** 完整播放*/
    case full
    /** 部分播放，参数为允许播放时长*/
    case partly(length: UInt)
    
}
public enum XTPlayerSeekTime {
    case none
    case seekToTime(to: Float)
}

public class XTPlayerSettings {
    
    public var `default`: [String: Any] {
        set {
            _default = newValue
        }
        get {
            if let temp = _default {
                return temp
            } else {
                if let dict = UserDefaults.standard.value(forKey: kSettings) as? [String: Any] {
                    _default = dict
                    return dict
                } else {
                    let dict = [kRate: Float(1)]
                    UserDefaults.standard.setValue(dict, forKey: kSettings)
                    UserDefaults.standard.synchronize()
                    _default = dict
                    return dict
                }
            }
        }
    }
    
    public var rate: Float {
        get {
            if let temp = _rate {
                return temp
            } else {
                _rate = self.default[kRate] as? Float
            }
            return _rate ?? 1
        }
        set {
            _rate = newValue
            xt_player.player?.rate = newValue
            self.default[kRate] = newValue
            update()
        }
    }
    
    private var _rate: Float?
    private var _default: [String: Any]?
    private let kRate = "XTPlayerRate"
    private let kSettings = "XTPlayerSettings"
    
    private func update() {
        
        UserDefaults.standard.setValue(self.default, forKey: kSettings)
        UserDefaults.standard.synchronize()
        
    }
}

// MARK: —————————— 播放器数据源协议 ——————————
public protocol XTPlayerDataSource {
    
    /** 播放地址*/
    var xt_playURL: String? { get }
    /** 文件名称*/
    var xt_sourceName: String? { get }
    var xt_sourceType: XTPlayerSourceType { get }
}

// MARK: —————————— 播放器功能 ——————————
public struct XTPlayerFunction : OptionSet {
    public let rawValue: UInt
    /** 默认*/
    public static let `default` = XTPlayerFunction(rawValue: 1 << 0)
    /** 缓存*/
    public static let cache = XTPlayerFunction(rawValue: 1 << 1)
    /** 播放信息记录数据库*/
    public static let database = XTPlayerFunction(rawValue: 1 << 2)
    /** 跳转数据库记录的历史进度*/
    public static let seekToHistory = XTPlayerFunction(rawValue: 1 << 3)
    /** 允许蜂窝网络加载*/
    public static let allowWWAN = XTPlayerFunction(rawValue: 1 << 4)
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}
// MARK: —————————— 播放协议 ——————————
public protocol XTPlayerDelegate {
    
    /** 配置播放器功能等属性*/
    func configePlayer()
    
    func dataSourceDidChange(lastOriginal: [XTPlayerDataSource]?, lastAvailable: [XTPlayerDataSource]?, nowOriginal: [XTPlayerDataSource]?, nowAvailable: [XTPlayerDataSource]?)
    
    /// 播放源将要切换
    ///
    /// - Parameters:
    ///   - now: 当前播放的播放源，第一次播放时当前播放源为空
    ///   - new: 将要切换的播放源，之后的播放源可以为空
    func playDataSourceWillChange(now: XTPlayerDataSource?, new: XTPlayerDataSource?)
    
    /// 播放源已经切换
    ///
    /// - Parameters:
    ///   - last: 上一个播放的播放源，上一个播放源可以为空
    ///   - now: 当前播放的播放源
    func playDataSourceDidChanged(last: XTPlayerDataSource?, now: XTPlayerDataSource)
    
    /// 询问是否允许蜂窝网络加载
    ///
    /// - Parameter askingConfirmed: 询问的闭包
    func askForWWANLoadPermission(confirmed: @escaping () -> ())
    
    /// 已经获取到数据源的播放时长
    ///
    /// - Parameters:
    ///   - totalTime: 总时长秒数
    ///   - formatTime: 秒数格式化为00:00:00形式
    func didReadTotalTime(totalTime: UInt, formatTime: String)
    
    /// 数据源非完全拥有，没有权限继续播放数据源
    ///
    /// - Parameter dataSource: 数据源模型
    func noPermissionToPlayDataSource(dataSource: XTPlayerDataSource)
    
    /// 数据源播放至结尾处
    ///
    /// - Parameters:
    ///   - dataSource: 结束时的数据源
    ///   - isTheEnd: 是否是全部数据源数组的最后一条
    func didPlayToEnd(dataSource: XTPlayerDataSource, isTheEnd: Bool)
    
    /// 播放状态发生改变
    ///
    /// - Parameter state: 播放状态
    func stateDidChanged(_ state: XTPlayerState)
    
    /// 更新界面变化
    ///
    /// - Parameters:
    ///   - dataSource: 当前数据源
    ///   - state: 播放状态
    ///   - isPlaying: 播放按钮选中状态
    ///   - detailInfo: 播放详细信息
    func updateUI(dataSource: XTPlayerDataSource?, state: XTPlayerState, isPlaying: Bool, detailInfo: XTPlayerStateModel?)
    
    
    /// 统一异常处理
    ///
    /// - Parameter error: 错误
    func unifiedExceptionHandle(error: XTPlayerError)
}
// MARK: —————————— 播放协议扩展 ——————————
extension XTPlayerDelegate {
    /** 实现可选方法的默认实现*/
    func playDataSourceWillChange(now: XTPlayerDataSource?, new: XTPlayerDataSource?) {}
    func playDataSourceDidChanged(last: XTPlayerDataSource?, now: XTPlayerDataSource) {}
    func didReadTotalTime(totalTime: UInt, formatTime: String) {}
    func didPlayToEnd(dataSource: XTPlayerDataSource, isTheEnd: Bool) {}
    func stateDidChanged(_ state: XTPlayerState) {}
    func updateUI(dataSource: XTPlayerDataSource?, state: XTPlayerState, isPlaying: Bool, detailInfo: XTPlayerStateModel?) {}
    func dataSourceDidChange(lastOriginal: [XTPlayerDataSource]?, lastAvailable: [XTPlayerDataSource]?, nowOriginal: [XTPlayerDataSource]?, nowAvailable: [XTPlayerDataSource]?) {}
    func unifiedExceptionHandle(error: Swift.Error) {}
}
// MARK: —————————— 核心播放器 ——————————
public class XTPlayer: NSObject {
    
    static let instance = XTPlayer()
    
    private override init() {
        super.init()
    }
    
    // MARK: —————————— 公开属性 ——————————
    /** 播放器实时状态*/
    public var state = XTPlayerState.idle {
        didSet {
            if oldValue != state {
                delegate?.stateDidChanged(state)
                updateUI()
            }
        }
    }
    /** 播放器实时进度*/
    public var progress: Float = 0 {
        didSet {
            currentModelState?.progress = progress
            let current = progress * Float(totalTime)
            currentModelState?.current = UInt(round(current))
            updateUI()
        }
    }
    /** 缓冲进度*/
    public var buffer: Float = 0 {
        didSet {
            currentModelState?.buffer = buffer
            updateUI()
        }
    }
    
    /** 播放器是否播放状态，用于外界处理播放按钮选中状态，而非实际播放状态*/
    public var isPlaying = false {
        didSet {
            updateUI()
        }
    }
    /** 播放器倒计时剩余秒数*/
    private (set) public var countdownSeconds = 0
    /** 所有原始数组*/
    public var allOriginalModels: Array<XTPlayerDataSource>? {
        didSet {
            
            guard let allModels = allOriginalModels else {
                
                delegate?.dataSourceDidChange(lastOriginal: oldValue, lastAvailable: allAvailableModels, nowOriginal: nil, nowAvailable: nil)
                
                //如果不存在也更新一下可播放数组
                allAvailableModels = nil
                firstAvailableIndex = NSNotFound
                return
            }
            var temp = Array<XTPlayerDataSource>()
            allModels.enumerated().forEach { (offset, element) in
                switch element.xt_sourceType {
                case .full:
                    if firstAvailableIndex == NSNotFound {
                        firstAvailableIndex = offset
                    }
                    temp.append(element)
                case .partly(let value):
                    if value > 0 {
                        if firstAvailableIndex == NSNotFound {
                            firstAvailableIndex = offset
                        }
                        temp.append(element)
                    }
                default:
                    break
                }
            }
            delegate?.dataSourceDidChange(lastOriginal: oldValue, lastAvailable: allAvailableModels, nowOriginal: allOriginalModels, nowAvailable: temp)
            allAvailableModels = temp
        }
    }
    
    /** 当前正在播放数据源的状态*/
    private (set) public var currentModelState: XTPlayerStateModel?
    
    /** 当前正在播放的数据源*/
    private (set) public var currentModel: XTPlayerDataSource? {
        didSet {
            currentModelState = XTPlayerStateModel()
            updateUI()
            guard let now = currentModel else {
                return
            }
            // 设置新的数据源，说明已经切换音频了
            delegate?.playDataSourceDidChanged(last: tempLastModel, now: now)
            
            tempLastModel = nil
        }
    }
    /** 上一个播放的数据源*/
    private (set) public var lastModel: XTPlayerDataSource? {
        didSet {
            guard let _ = lastModel else {
                return
            }
            if let _ = oldValue {
                tempLastModel = oldValue
            }
            // 设置上一个数据源，说明要切换音频了
            delegate?.playDataSourceWillChange(now: tempLastModel, new: lastModel)
            
        }
    }
    /** 播放器设置，存储到UserDefaults中*/
    public var settings = XTPlayerSettings()
    
    // 增加private (set)前缀修饰，该属性只在本类中读写，其它类只读
    /** 全部可以播放的数组*/
    private (set) public var allAvailableModels: Array<XTPlayerDataSource>?
    /** 代理*/
    public var delegate: XTPlayerDelegate?
    /** 播放器功能*/
    public var function: XTPlayerFunction = .default
    /** 记录数据库间隔*/
    public var recordInterval: UInt = 5
    /** 数据库唯一标记，用于区分数据库记录的信息*/
    public var databaseID: String = "XTPlayer" {
        didSet {
            xt_countdown.removeCountdown(key: oldValue)
        }
    }
    
    /** 数据源时长*/
    private (set) public var totalTime: UInt = 0 {
        didSet {
            let time = xt_playerTool.formatTime(seconds: totalTime)
            delegate?.didReadTotalTime(totalTime: totalTime, formatTime: time)
            currentModelState?.duration = totalTime
            updateUI()
        }
    }
    /** 为保障音频播放质量，当 音频缓冲值 >= (能播放的最低缓冲值 + 最小额外缓冲值) 后才进行播放*/
    public var minExtraBuffer: Float = 0
    /** 播放器倒计时功能*/
    public var countdown: XTPlayerCountdown = .none {
        didSet {
            handleCountdown()
        }
    }
    
    /** 第一个可播放的数据源索引*/
    public var firstAvailableIndex = NSNotFound
    /** 播放器对象*/
    private (set) public var player: AVPlayer?
    
    // MARK: —————————— 私有属性 ——————————

    /** 正在等待进度跳转*/
    private var isSeekWaiting: XTPlayerSeekTime = .none
    
    /** 播放进度观察者*/
    private var timeObserver: Any?
    /** 当前正在播放的item*/
    private var _playerItem: AVPlayerItem?
    private var playerItem: AVPlayerItem? {
        get {
            return _playerItem
        }
        set {
            guard newValue != playerItem else { return }
            
            if let temp = playerItem {
                
                NotificationCenter.default.removeObserver(self)
                temp.removeObserver(self, forKeyPath: XTPlayerObserverKey.status.rawValue)
                temp.removeObserver(self, forKeyPath: XTPlayerObserverKey.loadedTimeRanges.rawValue)
                temp.removeObserver(self, forKeyPath: XTPlayerObserverKey.playbackBufferEmpty.rawValue)
                temp.removeObserver(self, forKeyPath: XTPlayerObserverKey.playbackLikelyToKeepUp.rawValue)
            }
            _playerItem = newValue
            if let temp = newValue {
                NotificationCenter.default.addObserver(self, selector: #selector(playerDidPlayEndToTime), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
                temp.addObserver(self, forKeyPath: XTPlayerObserverKey.status.rawValue, options: .new, context: nil)
                temp.addObserver(self, forKeyPath: XTPlayerObserverKey.loadedTimeRanges.rawValue, options: .new, context: nil)
                temp.addObserver(self, forKeyPath: XTPlayerObserverKey.playbackBufferEmpty.rawValue, options: .new, context: nil)
                temp.addObserver(self, forKeyPath: XTPlayerObserverKey.playbackLikelyToKeepUp.rawValue, options: .new, context: nil)
            }
        }
    }
    /** 当前播放的索引*/
    private var currentIndex = 0
    /** 跳转进度后是否需要恢复播放*/
    private var needResume = false
    /** 当前播放的数据源是否有缓存*/
    private var isCached: URL? = nil {
        didSet {
            currentModelState?.buffer = 1
            updateUI()
        }
    }
    /** 本次允许蜂窝网络加载*/
    private var allWWANLoadThisTime = false
    /** 等待播放器状态*/
    private var isPlayerStateWaiting = false
    /** 临时变量用于存储上个数据源*/
    private var tempLastModel: XTPlayerDataSource?
    /** 主观上希望暂停，用作暂停状态标记*/
    private var subjectivePause = false
    /** 实际播放进度*/
    private var actuallyPlayProgress: Float = 0
    /** 倒计时还剩几条数据源未播放*/
    private var dataSourceCountdonwLeftCount: UInt = 0
    /** 倒计时剩余未播放数据源总时长*/
    private var dataSourceCountdonwLeftTotalSeconds: UInt = 0
    /** 需要重新计算倒计时剩余未播放数据源总时长的标记*/
    private var dataSourceCountdonwRecalculateMark = false
    /** 倒计时数据源数量需要读取下一条数据源的标记*/
    private var dataSourceCountdonwReadNextModelMark = false
    /** 播放中计时器记录数据库, 开启一个12小时的计时器*/
    private let playTimerMark: (String, UInt) = ("XTPlayerProgressTiming", 12 * 3600)
    /** 计时器详细信息*/
    private var countdownInfo: CountdownDetailInfo?
    /** 倒计时功能标记*/
    private var countdownMark: String = "XTPlayerCountdown"
    
    // MARK: —————————— 公开方法 ——————————
    // MARK: —————————— 激活播放器 ——————————
    
    /// 激活播放器
    public func active() {
        
        xt_playerTool.initConfig()
        XTPlayerRecord.initConfig()
        
        try? AVAudioSession.sharedInstance().setActive(true, options: [])
        
        if #available(iOS 10.0, *) {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay])
        }
        initConfig()
    }
    
    
    
    // MARK: —————————— 播放器播放步骤1 ——————————
    // MARK: —————————— 播放/暂停 ——————————
    /// 播放/暂停
    ///
    /// 播放流程步骤1:此函数为播放时最先调用的
    /// 说明：如果当前播放的内容和准备播放的内容一致，则进行播放/暂停的切换，否则进行新内容的播放
    /// - Parameter index: 数据源索引
    /// - Throws: 如果有错误就抛出XTPlayerError异常
    public func play(index: Int) throws {
        /** 如果没有设置数据源数组*/
        guard let allModels = allOriginalModels else {
            let error = XTPlayerError.dataSourceError(reason: .lackOfDataSource)
            unifiedExceptionHandle(error)
            throw error
        }
        /** 如果数据源数组中没有找到要播放的索引的数据*/
        guard let model = allModels[safe: index] else {
            let error = XTPlayerError.dataSourceError(reason: .lackOfDataSource)
            unifiedExceptionHandle(error)
            throw error
        }
        guard let urlString = model.xt_playURL else {
            let error = XTPlayerError.dataSourceError(reason: .invalidDataSource)
            unifiedExceptionHandle(error)
            throw error
        }
        guard let url = URL.init(string: urlString) else {
            let error = XTPlayerError.dataSourceError(reason: .invalidDataSource)
            unifiedExceptionHandle(error)
            throw error
        }
        guard !url.pathExtension.isEmpty else {
            let error = XTPlayerError.dataSourceError(reason: .invalidDataSource)
            unifiedExceptionHandle(error)
            throw error
        }
        switch model.xt_sourceType {
        case .noPermission:
            let error = XTPlayerError.dataSourceError(reason: .noPermission)
            unifiedExceptionHandle(error)
            throw error
        default:
            break
        }
        initConfig()
        // 正在播放的和准备播放的一致
        // 当前有正在播放的音频，并且当前正在播放的音频和上一条一样
        let condition1 = lastModel?.xt_playURL == currentModel?.xt_playURL && currentModel?.xt_playURL != nil
        // 要播放的音频和当前音频不一致
        let condition2 = urlString != currentModel?.xt_playURL
        
        guard !condition1 && condition2 else {
            switch state {
            //缓冲和播放状态时，暂停播放
            case .isBuffering, .isPlaying:
                pausePlayer()
            //除了缓冲和播放状态，其它都尝试去播放
            default:
                switch isSeekWaiting {
                case .seekToTime(_):
                    needResume = true
                    subjectivePause = false
                    isPlaying = true
                    
                    judgeProgress()
                default:
                    resumePlayer()
                }
            }
            return
        }
        
        try? prepareForPlay(model: model)
        
        if function.contains(.database) {
            prepareRecordDatabase()
        }
        
    }
    // MARK: —————————— 播放下一条数据源 ——————————
    /// 播放下一条数据源
    ///
    /// - Throws: 如果有错误就抛出XTPlayerError异常
    public func playNext() throws {
        
        guard let model = try getNextModel(after: true) else {
            let error = XTPlayerError.dataSourceError(reason: .noNextDataSource)
            unifiedExceptionHandle(error)
            throw error
        }
        currentIndex += 1
        
        try? prepareForPlay(model: model)
    }
    // MARK: —————————— 播放上一条数据源 ——————————
    /// 播放上一条数据源
    ///
    /// - Throws: 如果有错误就抛出XTPlayerError异常
    public func playLast() throws {
        
        guard let model = try getNextModel(after: false) else {
            let error = XTPlayerError.dataSourceError(reason: .noLastDataSource)
            unifiedExceptionHandle(error)
            throw error
        }
        currentIndex -= 1
        
        try? prepareForPlay(model: model)
    }
    // MARK: —————————— 暂停播放 ——————————
    public func pausePlayer() {
        guard state != .idle else { return }
        subjectivePause = true
        player?.pause()
        isPlaying = false
        state = .paused
        
        needResume = false
        switch countdown {
        case .endCount(_):
            xt_countdown.pauseOrResumeCountdown(key: countdownMark)
        default:
            break
        }
        if function.contains(.database) {
            countdownInfo?.pause()
            guard let model = currentModel else { return }
            guard let countdown = countdownInfo else { return }
            debugPrint("准备记录\(model.xt_sourceName!)的进度为\(self.actuallyPlayProgress)")
            recordProgress(dataSource: model, progress: self.actuallyPlayProgress, duration: self.totalTime, deltaInterval: countdown.runThisTime)
        }
    }
    
    // MARK: —————————— 恢复播放 ——————————
    public func resumePlayer() {
        subjectivePause = false
        player?.play()
        
        player?.rate = settings.rate
//        player?.rate = rate
        isPlaying = true
        isSeekWaiting = .none
        state = .isPlaying
        isPlayerStateWaiting = false
        needResume = true
        switch countdown {
        case .endCount(_):
            xt_countdown.pauseOrResumeCountdown(key: countdownMark)
        default:
            break
        }
        if function.contains(.database) {
            countdownInfo?.start()
        }
    }
    
    // MARK: —————————— 销毁播放器 ——————————
    public func destroyPlayer() {
        isPlayerStateWaiting = false
        currentIndex = 0
        isCached = nil
        pausePlayer()
        setPlayerToNil()
        playerItem = nil
        // 此处记录上一次播放的音频模型，用于下一次再启动播放器时能够读取到上一次播放的音频模型
        tempLastModel = currentModel
        allOriginalModels = nil
        currentModel = nil
        lastModel = nil
        needResume = false
        isSeekWaiting = .none
        subjectivePause = false
        state = .idle
        
        progress = 0
        buffer = 0
        isPlaying = false
        totalTime = 0
        currentModelState = nil
        // 倒计时相关
        countdownSeconds = 0
        countdown = .none
        dataSourceCountdonwLeftCount = 0
        dataSourceCountdonwLeftTotalSeconds = 0
        dataSourceCountdonwRecalculateMark = false
        dataSourceCountdonwReadNextModelMark = false
        xt_countdown.removeCountdown(key: countdownMark)
        xt_countdown.removeCountdown(key: databaseID)
    }
    
    // MARK: —————————— 跳转到指定位置 ——————————
    /// 为跳转到指定位置做准备操作
    ///
    /// - Parameter to: 要跳转的进度
    public func prepareForSeek(to: Float) {
        
        guard let model = currentModel else {
            let error = XTPlayerError.dataSourceError(reason: .lackOfDataSource)
            unifiedExceptionHandle(error)
            return
        }
        
        updateCountdownSeconds()
        
        switch model.xt_sourceType {
        case .partly(let length):
            var currentTime: UInt = 0
            
            if totalTime > 0 {
                currentTime = UInt(to * Float(totalTime))
            } else {
                guard let urlString = model.xt_playURL else {
                    let error = XTPlayerError.dataSourceError(reason: .invalidDataSource)
                    unifiedExceptionHandle(error)
                    return
                }
                let totalTime = xt_playerTool.readDuration(url: urlString)
                if totalTime > 0 {
                    
                    self.totalTime = totalTime
                    currentTime = UInt(to * Float(totalTime))
                }
            }
            if currentTime > length {
                pausePlayer()
                delegate?.noPermissionToPlayDataSource(dataSource: model)
                progress = actuallyPlayProgress
                return
            }
        default:
            break
        }
        
        player?.pause()
        
        needResume = isPlaying
        
        var alreadyInSeeking = false
        let condition1 = function.contains(.cache) && isCached != nil
        let condition2 = buffer > 0 && buffer < 1
        if !condition1, condition2 {
            alreadyInSeeking = true
        }
        isSeekWaiting = .seekToTime(to: to)
        progress = to
        
        let canPlay = self.canPlay(progress: to)
        if canPlay {
            seek(to: to)
        } else {
            // 当前没有在缓冲等待且没有在等待播放器状态
            if !alreadyInSeeking, !isPlayerStateWaiting {
                // 继续尝试加载数据源
                try? prepareForLoadDataSource()
            }
            // 非主观希望暂停，设置状态为缓冲中
            if !subjectivePause {
                state = .isBuffering
            }
        }
    }
    
    
    
    
    // MARK: —————————— 私有方法 ——————————
    // MARK: —————————— 初始化配置 ——————————
    private func initConfig() {
        
        self.delegate?.configePlayer()
    }
    
    /** 统一异常处理*/
    private func unifiedExceptionHandle(_ error: XTPlayerError) {
        
        delegate?.unifiedExceptionHandle(error: error)
    }
    
    // MARK: —————————— 播放进度观察 ——————————
    /// 添加播放进度观察者
    private func addPlayProgressTimeObserver() {
        timeObserver = self.player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: nil, using: { [weak self] (time) in
            
            guard let `self` = self else { return }
            
            guard let currentItem = self.playerItem else { return }
            let loadedRanges = currentItem.seekableTimeRanges
            if loadedRanges.count > 0, currentItem.duration.timescale != 0 {
                
                
                let currentTime = CMTimeGetSeconds(time)
                
                var progress: Float = 0
                //总时间
                if self.totalTime == 0 {
                    if let duration = self.player?.currentItem?.duration {
                        let totalTime = CMTimeGetSeconds(duration)
                        
                        if totalTime > 0 {
                            self.totalTime = UInt(ceil(totalTime))
                        }
                    }
                }
                progress = Float(currentTime) / Float(self.totalTime)
                
                if progress >= 0 && progress <= 1 {
                    self.actuallyPlayProgress = progress
                }
                
                // 提前结束
                var earlyTermination = false
                // 如果不是主观上希望暂停，就将播放状态设置成在播放
                // 之所以此处加这个判断是因为在调用player.pause()函数后，还会再走一次这个闭包，避免播放状态设置错误
                if self.subjectivePause == false {
                    switch self.isSeekWaiting {
                    case .none:
                        self.isPlaying = true
                        self.state = .isPlaying
                        // 判断数据源是否可以播放
                        if let sourceType = self.currentModel?.xt_sourceType {
                            switch sourceType {
                            // 如果数据源只能播放一部分
                            case .partly(let length):
                                if UInt(currentTime) > length {
                                    self.pausePlayer()
                                    self.delegate?.noPermissionToPlayDataSource(dataSource: self.currentModel!)
                                    earlyTermination = true
                                }
                            default:
                                break
                            }
                        }
                    default:
                        break
                    }
                    if !earlyTermination {
                        switch self.isSeekWaiting {
                        case .seekToTime(_):
                            self.player?.pause()
                        default:
                            self.progress = self.actuallyPlayProgress
                        }
                    }
                    
                    self.updateCountdownSeconds()
                    
                }
                
            }
        })
    }
    
    // MARK: —————————— 缓冲进度观察 ——————————
    /// 添加缓冲进度观察者
    private func addBufferProgressObserver() {
        guard let item = playerItem else { return }
        guard !((function.contains(.cache) && isCached != nil) || buffer == 1) else {
            judgeProgress()
            return
        }
        guard let bufferRange = item.loadedTimeRanges.first?.timeRangeValue else { return }
        let bufferStart = CMTimeGetSeconds(bufferRange.start)
        let bufferDuration = CMTimeGetSeconds(bufferRange.duration)
        let bufferInterval = bufferStart + bufferDuration
        let duration = CMTimeGetSeconds(item.duration)
        if duration > 0 {
            totalTime = UInt(ceil(duration))
            let bufferProgress = bufferInterval / duration
            if bufferProgress >= 0 && bufferProgress <= 1 {
                buffer = Float(bufferProgress)
            }
        }
        judgeProgress()
    }
    
    /// 进度发生变化，需要判断是否可播放
    private func judgeProgress() {
        switch isSeekWaiting {
        case .none:
            break
        case .seekToTime(let value):
            let canPlay = self.canPlay(progress: value)
            if canPlay {
                self.seek(to: value)
            } else {
                if !subjectivePause {
                    state = .isBuffering
                }
            }
        }
        
    }
    
    // MARK: —————————— 播放器播放步骤2 ——————————
    /// 播放前准备
    ///
    /// 播放流程步骤2:此函数为播放前准备操作
    /// - Parameter model: 要播放的数据源
    /// - Throws: 抛出异常
    private func prepareForPlay(model: XTPlayerDataSource) throws {
        subjectivePause = false
        isPlaying = true
        needResume = true
        buffer = 0
        progress = 0
        isCached = nil
        actuallyPlayProgress = 0
        totalTime = 0
        
        if timeObserver != nil {
            player?.removeTimeObserver(timeObserver!)
            timeObserver = nil
        }
        player?.pause()
        
        // 记录上一个播放的音频
        lastModel = model
        
        currentModel = model
        
        try? prepareForLoadDataSource()
        
        if function.contains(.database) {
            countdownInfo?.start()
        }
        try? seekToHistory()
    }
    
    // MARK: —————————— 播放器播放步骤3 ——————————
    /// 准备加载数据源
    ///
    /// 播放流程步骤3:此函数为加载数据源准备操作
    /// - Throws: 抛出异常
    private func prepareForLoadDataSource() throws {
        guard let url = currentModel?.xt_playURL else {
            let error = XTPlayerError.dataSourceError(reason: .invalidDataSource)
            unifiedExceptionHandle(error)
            throw error
        }
        
        var cacheURL: URL? = nil
        /** 如果允许缓存*/
        if function.contains(.cache) {
            // 从下载管理类中查询下载的地址
            if let cache = xt_playerTool.checkFileExist(url: url) {
                cacheURL = URL.init(fileURLWithPath: cache)
            }
        }
        
        // 如果没有网络并且没有缓存
        guard (xt_playerTool.netStatus != .notReachable) || (cacheURL != nil) else {
            let error = XTPlayerError.networkError(reason: .notReachable)
            unifiedExceptionHandle(error)
            throw error
        }
        let condition1 = xt_playerTool.netStatus == .wwan
        let condition2 = !(function.contains(.allowWWAN) || allWWANLoadThisTime)
        if condition1, condition2 {
            self.delegate?.askForWWANLoadPermission(confirmed: {
                self.loadDataSource(cacheURL: cacheURL)
            })
        } else {
            self.loadDataSource(cacheURL: cacheURL)
        }
    }
    
    // MARK: —————————— 播放器播放步骤4 ——————————
    /// 加载数据源
    ///
    /// 播放流程步骤4:此函数为加载数据源情况判断
    /// - Parameter cacheURL: 数据源缓存地址
    private func loadDataSource(cacheURL: URL?) {
        
        guard let cache = cacheURL, function.contains(.cache) else {
            // 由于之前已经判断过，此处可以用强制解包
            let netURL = URL.init(string: currentModel!.xt_playURL!)!
            try? loadNetURL(netURL)
            return
        }
        isCached = cacheURL
        loadItem(url: cache)
        
    }
    
    // MARK: —————————— 播放器播放步骤5-1 ——————————
    /// 使用url加载item
    ///
    /// 播放流程步骤5-1:此函数为使用url方式加载数据源
    /// - Parameter url: 数据源url
    private func loadItem(url: URL) {
        let item = AVPlayerItem.init(url: url)
        loadPlayer(item: item)
    }
    
    // MARK: —————————— 播放器播放步骤5-2 ——————————
    /// 从网络地址加载资源
    ///
    /// 播放流程步骤5-2:此函数为加载网络url数据源
    /// - Parameter url: 网络地址
    private func loadNetURL(_ url: URL) throws {
        
        guard xt_playerTool.netStatus != .notReachable else {
            let error = XTPlayerError.networkError(reason: .notReachable)
            unifiedExceptionHandle(error)
            throw error
        }
        state = .isBuffering
        
        buffer = 0
        
        let asset = AVURLAsset.init(url: url)
        loadItem(asset: asset)
        if function.contains(.cache) {
            xt_playerTool.download(url, downloadProgress: nil) { (filePath) in
                if url.absoluteString == self.currentModel?.xt_playURL {
                    self.isCached = filePath
                }
            }
        }
    }
    
    // MARK: —————————— 播放器播放步骤5-3 ——————————
    /// 使用asset加载item
    ///
    /// 播放流程步骤5-3:此函数为使用asset方式加载数据源
    /// - Parameter asset: 数据源asset
    private func loadItem(asset: AVURLAsset) {
        let item = AVPlayerItem.init(asset: asset)
        loadPlayer(item: item)
    }
    
    // MARK: —————————— 播放器播放步骤6 ——————————
    /// 加载播放器对象
    ///
    /// 播放流程步骤6:此函数为加载播放器的最后一步，至此开始播放
    /// - Parameter item: 播放器播放的item
    private func loadPlayer(item: AVPlayerItem) {
        //如果有player对象，先置空
        setPlayerToNil()
        player = AVPlayer.init(playerItem: item)
        playerItem = item

        player?.rate = settings.rate
        // 设置此属性，使得音频播放只要缓冲够了就可以马上播放，而不用等待缓冲完成
        if #available(iOS 10.0, *) {
            player?.automaticallyWaitsToMinimizeStalling = false
        }
        addPlayProgressTimeObserver()

    }
    
    /// 获取下一个播放数据源
    ///
    /// - Parameter after: true后一个，false前一个
    /// - Returns: 下一个数据源
    /// - Throws: 数据源错误
    private func getNextModel(after: Bool) throws -> XTPlayerDataSource? {
        
        /** 如果没有设置数据源数组*/
        guard let allModels = allAvailableModels else {
            let error = XTPlayerError.dataSourceError(reason: .lackOfDataSource)
            unifiedExceptionHandle(error)
            throw error
        }
        
        var index = currentIndex
        
        if after {
            // 如果当前的数据源已是最后一条可播放的
            guard currentModel?.xt_playURL != allModels.last?.xt_playURL else {
                let error = XTPlayerError.dataSourceError(reason: .noNextDataSource)
                unifiedExceptionHandle(error)
                throw error
            }
            index += 1
        } else {
            // 如果当前的数据源已是第一条可播放的
            guard currentModel?.xt_playURL != allModels.first?.xt_playURL else {
                let error = XTPlayerError.dataSourceError(reason: .noLastDataSource)
                unifiedExceptionHandle(error)
                throw error
            }
            index -= 1
        }
        
        /** 如果数据源数组中没有找到要播放的索引的数据*/
        guard let model = allModels[safe: index] else {
            let error = XTPlayerError.dataSourceError(reason: .lackOfDataSource)
            unifiedExceptionHandle(error)
            throw error
        }
        return model
    }
    
    /// 最终跳转进度函数
    ///
    /// - Parameter to: 跳转的进度值
    private func seek(to: Float) {
        
        if xt_playerTool.netStatus == .notReachable {
            if totalTime == 0 && function.contains(.cache) {
                if let cacheURL = isCached {
                    totalTime = xt_playerTool.readDuration(url: cacheURL.absoluteString)
                }
            }
        } else {
            if totalTime == 0 {
                totalTime = xt_playerTool.readDuration(url: currentModel!.xt_playURL!)
            }
        }
        
        let value = Int64(Float(totalTime) * to)
        let seekTime = CMTimeMake(value: value, timescale: 1)
        
        debugPrint("准备跳转到\(to)")
        player?.seek(to: seekTime, toleranceBefore: CMTimeMake(value: 1, timescale: 1), toleranceAfter: CMTimeMake(value: 1, timescale: 1), completionHandler: { [weak self] (finished) in
            if finished {
                guard self?.player?.currentTime() == seekTime else {
                    return
                }
                guard self?.canPlay(progress: to) == true else {
                    return
                }
                guard let `self` = self else {
                    return
                }
                self.progress = to
                guard self.needResume == true else {
                    debugPrint("跳转进度\(to)完成，不恢复播放")
                    return
                }
                debugPrint("跳转进度\(to)完成，需要恢复播放")
                self.resumePlayer()
                self.needResume = false
                
            }
        })
    }
    
    /// 判断当前缓冲和缓存情况以及播放器准备状态三个指标是否都能够支持要判断的进度值进行播放
    ///
    /// - Parameter progress: 要判断的进度值
    /// - Returns: 是否能够播放的结果
    private func canPlay(progress: Float) -> Bool {
        var canPlay = false
        // 是否有足够的缓冲进度
        var condition1 = false
        // 播放所需要的缓冲进度
        var needBuffer = progress + minExtraBuffer
        // 当前已达到的缓冲进度
        let current = buffer
        if progress <= 1 - minExtraBuffer {
            condition1 = current > needBuffer
        } else {
            needBuffer = 1
            condition1 = current == needBuffer
        }
        debugPrint("当前缓冲到\(current)，需要缓冲到\(needBuffer)")
        let condition2 = function.contains(.cache) && isCached != nil
        if condition1 || condition2 {
            canPlay = player?.status == .readyToPlay
            if !canPlay {
                isPlayerStateWaiting = true
            }
        }
        return canPlay
    }
    
    private func setPlayerToNil() {
        //如果有player对象，置空
        if let player = self.player {
            player.pause()
            player.currentItem?.cancelPendingSeeks()
            player.currentItem?.asset.cancelLoading()
            player.replaceCurrentItem(with: nil)
            self.player = nil
        }
    }
    
    /// 自动播放至结尾了
    @objc private func playerDidPlayEndToTime() {

        progress = 1
        actuallyPlayProgress = 1
        if function.contains(.database) {
            if let model = currentModel, let countdown = countdownInfo {
                recordProgress(dataSource: model, progress: self.actuallyPlayProgress, duration: self.totalTime, deltaInterval: countdown.runThisTime)
            }
        }
        
        switch countdown {
        case .endCount(_):
            dataSourceCountdonwReadNextModelMark = true
            dataSourceCountdonwLeftCount -= 1
            guard dataSourceCountdonwLeftCount > 0 else {
                seek(to: 0)
                pausePlayer()
                countdown = .none
                countdownSeconds = 0
                return
            }
            dataSourceCountdonwRecalculateMark = true
            updateCountdownSeconds()
        default:
            break
        }
        
        delegate?.didPlayToEnd(dataSource: currentModel!, isTheEnd: false)
        
        guard currentModel?.xt_playURL != allAvailableModels?.last?.xt_playURL else {
            // 归零
            seek(to: 0)
            pausePlayer()
            delegate?.didPlayToEnd(dataSource: currentModel!, isTheEnd: true)
            return
        }
        try? playNext()
    }
    
    private func updateUI() {
        
        delegate?.updateUI(dataSource: currentModel, state: state, isPlaying: isPlaying, detailInfo: currentModelState)
    }
    
    /** 倒计时功能*/
    private func handleCountdown() {
        switch countdown {
        case .endCount(_):
            dataSourceCountdonwRecalculateMark = true
            updateCountdownSeconds()
        case .endSecond(let seconds):
            debugPrint("设置结束时间为\(seconds)秒")
            
            xt_countdown.startCountdown(key: countdownMark, seconds: seconds, function: .default) { (info) in
                let left = info.left
                self.countdownSeconds = Int(left)
                if left == 0 {
                    self.pausePlayer()
                }
            }
            
        default:
            break
        }
    }
    /** 更新倒计时时长*/
    private func updateCountdownSeconds() {
        switch countdown {
        case .endCount(let count):
            
            if dataSourceCountdonwLeftCount == 0 {
                dataSourceCountdonwLeftCount = count
            }
            let leftCount = dataSourceCountdonwLeftCount
            
            var leftSeconds: UInt = 0
            
            var currentTotal: UInt = 0
            var currentTime: Double = 0

            if dataSourceCountdonwReadNextModelMark {
                do {
                    if let url = try getNextModel(after: true)?.xt_playURL {
                        currentTotal = UInt(xt_playerTool.readDuration(url: url))
                        currentTime = Double(currentTotal)
                    }
                } catch {
                    
                }
                dataSourceCountdonwReadNextModelMark = false
            } else {
                currentTotal = UInt(xt_playerTool.readDuration(url: currentModel!.xt_playURL!))
                currentTime = Double(currentTotal) * Double(1 - progress)
            }
            
            
            if dataSourceCountdonwRecalculateMark {
                dataSourceCountdonwLeftTotalSeconds = UInt(calculateLeftDuration(count: UInt(leftCount)))
                dataSourceCountdonwRecalculateMark = false
            }
            
            leftSeconds = UInt(round(currentTime)) + dataSourceCountdonwLeftTotalSeconds
            
            countdownSeconds = Int(leftSeconds)
            
            if leftSeconds <= 0 {
                seek(to: 0)
                pausePlayer()
            }
        default:
            break
        }
    }
    
    /** 计算剩余时长*/
    private func calculateLeftDuration(count: UInt) -> UInt {
        var total: UInt = 0
        var leftCount = count
        
        while leftCount > 1 {
            do {
                if let model = try getNextModel(after: true) {
                    total += xt_playerTool.readDuration(url: model.xt_playURL!)
                }
            } catch {
                
            }
            leftCount -= 1
        }
        return UInt(total)
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let playerItem = object as? AVPlayerItem else { return }
        switch keyPath {
        case XTPlayerObserverKey.status.rawValue:
            switch playerItem.status {
            case .unknown:
                state = .failed
                let error = XTPlayerError.playerStatusError(reason: .unknown)
                unifiedExceptionHandle(error)
                countdownInfo?.pause()
            case .readyToPlay:
                judgeProgress()
                if isPlayerStateWaiting {
                    try? seekToHistory()
                }
            case .failed:
                state = .failed
                let error = XTPlayerError.playerStatusError(reason: .failed)
                unifiedExceptionHandle(error)
                countdownInfo?.pause()
            }
        case XTPlayerObserverKey.loadedTimeRanges.rawValue:
            addBufferProgressObserver()
            
        case XTPlayerObserverKey.playbackBufferEmpty.rawValue:
            if isCached == nil {
                if !subjectivePause {
                    state = .isBuffering
                }
            }
        case XTPlayerObserverKey.playbackLikelyToKeepUp.rawValue:
            break
        default:
            break
        }
    }
    
    /** 准备开始记录数据库*/
    private func prepareRecordDatabase() {
        let condition1 = function.contains(.database)
        // 设置有效时间间隔后才开启记录
        let condition2 = recordInterval > 0
        guard condition1, condition2 else {
            return
        }
        
        countdownInfo = xt_countdown.startCountdown(key: databaseID, seconds: playTimerMark.1, function: .default, onlyStart: true, progressHandler: { (info) in
            let run = info.run
            let cp_record = run % self.recordInterval == 0
            guard cp_record else { return }
            guard let model = self.currentModel else { return }
            
            debugPrint("准备记录\(model.xt_sourceName!)的进度为\(self.actuallyPlayProgress)")
            self.recordProgress(dataSource: model, progress: self.actuallyPlayProgress, duration: self.totalTime, deltaInterval: info.runThisTime)
            // 记录完本次运行时长后归零
            info.runThisTime = 0
        })
    }
    
    /// 记录播放进度
    ///
    /// - Parameters:
    ///   - dataSource: 需要记录的数据源
    ///   - progress: 要记录的进度值
    ///   - duration: 数据源总时长
    ///   - deltaInterval: 记录间隔，即上一次记录时间距离本次记录时间间隔
    private func recordProgress(dataSource: XTPlayerDataSource, progress: Float, duration: UInt, deltaInterval: UInt) {
        guard function.contains(.database) else {
            let error = XTPlayerError.functionError(reason: .databaseUnavailable)
            unifiedExceptionHandle(error)
            return
        }
        do {
            guard progress > 0 else { return }
            try XTPlayerRecord.recordProgress(dataSource: dataSource, uniqueID: databaseID, progress: progress, duration: duration, deltaInterval: deltaInterval)
        } catch let error {
            unifiedExceptionHandle(error as! XTPlayerError)
        }
    }
    
    
    /** 跳转历史进度*/
    private func seekToHistory() throws {
        
        guard function.contains(.database) else {
            let error = XTPlayerError.functionError(reason: .databaseUnavailable)
            unifiedExceptionHandle(error)
            throw error
        }
        guard function.contains(.seekToHistory) else {
            let error = XTPlayerError.functionError(reason: .seekToHistoryUnavailable)
            unifiedExceptionHandle(error)
            throw error
        }
        let progress = XTPlayerRecord.queryHistoryPlayProgress(single: currentModel!, uniqueID: databaseID)
        guard progress > 0 && progress != 1 else {
            return
        }
        
        // 判断数据源是否可以播放
        if let sourceType = self.currentModel?.xt_sourceType {
            switch sourceType {
            // 如果数据源只能播放一部分
            case .partly(let length):
                guard let url = self.currentModel?.xt_playURL else { return }
                let total = xt_playerTool.readDuration(url: url)
                let willSeekTime = UInt(progress * Float(total))
                guard willSeekTime < length else { return }
            default:
                break
            }
        }
        prepareForSeek(to: progress)
    }
}
