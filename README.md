# XTPlayer
`XTPlayer`是一款简单易用的基于`AVPlayer`封装的纯`Swift`音频播放器，满足对音频文件播放的基本需求。
- [功能](#功能)
- [要求](#要求)
- [安装](#安装)
- [示例工程](#示例工程)
- [使用方式](#使用方式)
- [基本用法](#基本用法)

## 功能:
- [x] 支持对音频资源的权限管理
- [x] 支持播放的同时缓存文件
- [x] 支持播放时记录播放进度
- [x] 支持对历史进度的跳转
- [x] 支持对播放状态改变的监听
- [x] 处理了弱网环境的播放问题
- [x] 支持实时更新UI
- [x] 倒计时暂停播放
- [x] 支持对音频资源的播放进度进行查询

## 要求
- iOS 9.0+
- Xcode 10.1+
- Swift 4.2+

## 安装
### CocoaPods

可以通过`CocoaPods`方式对`XTPlayer`进行集成，在你工程的`Podfile`文件中写上如下代码

```
pod 'XTPlayer'
```
## 示例工程
你可以从[这里](https://github.com/Shaw003/XTPlayer)将示例工程下载下来，运行`Example`文件夹中的`XTPlayer.xcworkspace`
![XTPlayer使用.2019-04-10 14_21_13.gif](https://upload-images.jianshu.io/upload_images/3073983-cd30b323af938b6a.gif?imageMogr2/auto-orient/strip)

示例工程中只展示了`XTPlayer`的几个功能，还有一些功能并未展示出来，`XTPlayer`实现了数据源的访问权限管理、进度跳转、切换数据源、改变播放速率、缓存音频数据源、区别用户记录播放记录、统计日播放时长、倒计时暂停播放、后台播放、区别用户的历史播放进度跳转等功能。

## 使用方式
`XTPlayer`内置了一个全局的单例对象，可以使用`xt_player`访问该对象，在使用播放器前需要调用实例方法`active()`来对`XTPlayer`进行初始化，这里同时对计时器进行了初始化操作，如果不需要对播放中的音频进行播放记录同时也不需要设置倒计时关闭播放，这里可以不用初始化计时器。

```Swift
func application(_ application: UIApplication, 
didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
  initConfig()
  return true
}
    
/** 初始化配置*/
func initConfig() {
  /** 激活播放器*/
  xt_player.active()
  /** 计时器初始化配置*/
  xt_countdown.initConfig()
}
```

## 基本用法
首先配置播放数据源模型，自建一个自定义对象，需要遵守`XTPlayerDataSource`协议，并实现协议要求的3个属性，分别为`xt_playURL`（对应播放源地址）和`xt_sourceName`（对应播放源名称）以及`xt_sourceType`（对应播放源访问权限）。
其中，播放源访问权限有3种权限可以设置，分别为

```
1. noPermission 没有权限播放
2. full 完整权限播放
3. partly(length: UInt) 仅可以播放前length秒的长度
```
开发者可以在自定义模型类中实现这3个属性的`get`方法。


```Swift
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
    
    //以下内容开发者可以根据实际情况自定义属性 
    /** 音频地址*/
    var audioUrl: String?
    /** 音频标题*/
    var audioTitle: String?
    /** 是否可以完整播放*/
    var isFree: Int?
    /** 不可以完整播放时能播放的秒数*/
    var freeTime: UInt?
}
```

待数据源模型配置好后，我们可以准备调用`XTPlayer`的相关API了。`XTPlayer`提供的公开API有播放、暂停、切换音频、恢复播放、跳转进度。

```Swift
var allModels: [CustomAudioModel] {
        get {
            let model1 = CustomAudioModel()
            model1.audioUrl = "http://sc1.111ttt.cn/2018/1/03/13/396131229550.mp3"
            model1.isFree = 1
            model1.freeTime = 0
            model1.audioTitle = "音频1"
            
            let model2 = CustomAudioModel()
            model2.audioUrl = "http://sc1.111ttt.cn/2018/1/03/13/396131232171.mp3"
            model2.isFree = 0
            model2.freeTime = 100
            model2.audioTitle = "音频2"
            
            let model3 = CustomAudioModel()
            model3.audioUrl = "http://sc1.111ttt.cn/2018/1/03/13/396131228287.mp3"
            model3.isFree = 0
            model3.freeTime = 0
            model3.audioTitle = "音频3"

            /**
             音频1:可以播放完整音频
             音频2:可以播放100秒
             音频3:不可以播放
             */
            return [model1, model2, model3]
        }
    }
    // 跳转进度
    @IBAction func changeProgress(_ sender: Any) {
        guard let slider = sender as? UISlider else { return }
        xt_player.prepareForSeek(to: slider.value)
    }
    // 上一条音频
    @IBAction func playLastBtnClicked(_ sender: Any) {
        try? xt_player.playLast()
    }
    // 播放/暂停
    @IBAction func playBtnClicked(_ sender: Any) {
        do {
            try xt_player.play(index: 0)
        } catch let error {
            debugPrint(error)
        }
    }
    // 下一条音频
    @IBAction func playNextBtnClicked(_ sender: Any) {
        try? xt_player.playNext()
    }
    // XTPlayer加载原始数据源
    @IBAction func loadDataBtnClicked(_ sender: Any) {
        xt_player.allOriginalModels = allModels
    }
    // 切换播放速率
    @IBAction func changeRateBtnClicked(_ sender: Any) {
        
        if xt_player.settings.rate >= 2 {
            xt_player.settings.rate = 0.25
        } else {
            xt_player.settings.rate += 0.25
        }
    }
    // 销毁播放器
    @IBAction func destoryPlayerBtnClicked(_ sender: Any) {
        xt_player.allOriginalModels = nil
        xt_player.destroyPlayer()
    }
```

要对播放器的功能进行设置或对各种状态进行监听，需要遵守`XTPlayerDelegate`协议，并设置`XTPlayer`的代理。

```
xt_player.delegate = self
```

实现协议方法，其中`configePlayer`方法为必须要实现的，其它方法是可选的。
在`configePlayer`方法中，我们需要完成对播放器功能的配置，播放器功能包括如下几种

```Swift
// MARK: —————————— 播放器功能 ——————————
public struct XTPlayerFunction : OptionSet {
    /** 默认*/
    public static let `default` = XTPlayerFunction(rawValue: 1 << 0)
    /** 缓存*/
    public static let cache = XTPlayerFunction(rawValue: 1 << 1)
    /** 播放信息记录数据库*/
    public static let database = XTPlayerFunction(rawValue: 1 << 2)
    /** 跳转数据库记录的历史进度，如果需要跳转历史进度，必须拥有database功能*/
    public static let seekToHistory = XTPlayerFunction(rawValue: 1 << 3)
    /** 允许蜂窝网络加载*/
    public static let allowWWAN = XTPlayerFunction(rawValue: 1 << 4)
}
```
其中`cache`功能为在播放的同时，对数据源进行缓存；`database`功能为在播放的同时，记录播放记录，这里播放记录支持对不同的用户进行记录，通过对`databaseID`属性进行设置即可；`seekToHistory`功能支持对历史播放进度的跳转，如果需要跳转音频的历史进度，必须设置功能包括`database`；`allowWWAN `功能为允许使用蜂窝网络加载网络音频资源。

```Swift
extension ViewController: XTPlayerDelegate {
    
    func configePlayer() {
        xt_player.function = [.cache, .database, .seekToHistory]
        xt_player.databaseID = "customUID"
    }
    
    func playDataSourceWillChange(now: XTPlayerDataSource?, new: XTPlayerDataSource?) {
        debugPrint("设置上一个数据源，说明要切换音频了，当前是\(now?.xt_sourceName!)，即将播放的是\(new?.xt_sourceName!)")
    }
    
    func playDataSourceDidChanged(last: XTPlayerDataSource?, now: XTPlayerDataSource) {
        debugPrint("设置新的数据源，说明已经切换音频了，原来是\(last?.xt_sourceName!)，当前是\(now.xt_sourceName!)")
    }
    
    func didPlayToEnd(dataSource: XTPlayerDataSource, isTheEnd: Bool) {
        debugPrint("数据源\(dataSource.xt_sourceName!)已播放至结尾")
    }
    
    
    func noPermissionToPlayDataSource(dataSource: XTPlayerDataSource) {
        debugPrint("没有权限播放\(dataSource.xt_sourceName!)")
    }
    
    func didReadTotalTime(totalTime: UInt, formatTime: String) {
        //        debugPrint("已经读取到时长为duration = \(totalTime), format = \(formatTime)")
    }
    
    // 通过block方式询问当没有wlan网络时，是否允许通过wwan方式访问网络音频资源
    func askForWWANLoadPermission(confirmed: @escaping () -> ()) {
        let alert = UIAlertController.init(title: "网络环境确认", message: "当前非wifi环境，确定继续加载么", preferredStyle: .alert)
        let confirmAction = UIAlertAction.init(title: "确定", style: .default) {_ in
            confirmed()
        }
        alert.addAction(confirmAction)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
   // 用于监听播放器状态改变
    func stateDidChanged(_ state: XTPlayerState) {
    }
    
    // 用于更新播放器界面UI
    func updateUI(dataSource: XTPlayerDataSource?, state: XTPlayerState, isPlaying: Bool, detailInfo: XTPlayerStateModel?) {
        
        playBtn.isSelected = isPlaying
        
        audioTitleLbl.text = dataSource?.xt_sourceName!
        guard let detail = detailInfo else { return }
        let currentTime = xt_playerTool.formatTime(seconds: detail.current)
        let durationTime = xt_playerTool.formatTime(seconds: detail.duration)
        audioDurationLbl.text = currentTime + "/" + durationTime
        bufferProgress.progress = detail.buffer
        audioProgressSlider.value = detail.progress
        
    }
    
    // 数据源发生改变时会调用此方法
    func dataSourceDidChange(lastOriginal: [XTPlayerDataSource]?, lastAvailable: [XTPlayerDataSource]?, nowOriginal: [XTPlayerDataSource]?, nowAvailable: [XTPlayerDataSource]?) {
    }
    
    func unifiedExceptionHandle(error: XTPlayerError) {
        debugPrint(error)
        
        let alert = UIAlertController.init(title: "Error", message: error.errorDescription, preferredStyle: .alert)
        let confirm = UIAlertAction.init(title: "ok", style: .default, handler: nil)
        alert.addAction(confirm)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
```

## XTPlayerError
如果`XTPlayer`在播放音频资源出错时，会将错误信息通过`unifiedExceptionHandle`代理方法传出来，并停止播放，错误基本分为四种类型。
1. 数据源错误
2. 网络错误
3. 功能异常
4. 播放器状态异常

具体错误原因请开发者查看`XTPlayerError`类详细了解。

## XTPlayerStateModel
在播放过程中，如果需要更新界面信息，XTPlayer通过`updateUI(dataSource: XTPlayerDataSource?, state: XTPlayerState, isPlaying: Bool, detailInfo: XTPlayerStateModel?)`代理方法将可以更新的内容反馈出来，具体播放进度的详细音频信息存储在`XTPlayerStateModel`中。

```Swift
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
}
```

## XTPlayerRecord
`XTPlayerRecord`类完成对用户播放进度的记录以及提供历史播放进度的查询功能。如果开启了`database`功能，`XTPlayer`在播放过程中，默认每`5秒钟`会自动记录一次播放进度，这个时间间隔可以通过`recordInterval`属性进行设置修改，另外在播放器暂停时也会记录一次数据库。

## XTCountdown
`XTCountdown`类实现了倒计时的功能，为`XTPlayer`的播放进度和倒计时暂停功能提供计时器相关功能的支持。
`XTCountdown`同样有一个`xt_countdown`的单例，通过`initConfig`函数对计时器进行初始化，其公开了如下几个函数：

```Swift
// 初始化计时器
func initConfig()
// 检查是否存在以key为标记的未完成计时的计时器对象，并以block形式将该对象的详细信息传出来
func checkCountdown(key: String, progressHandler: ((inout CountdownDetailInfo) -> ())? = nil) -> (Bool, Bool)
// 移除以key为标识的计时器对象
func removeCountdown(key: String)
// 暂停或恢复计时
func pauseOrResumeCountdown(key: String, forcePause: Bool? = nil) -> CountdownDetailInfo?
// 开启或暂停计时器
func startCountdown(key: String, seconds: UInt, function: XTCountdownFunction = .default, onlyStart: Bool = false, progressHandler progress: ((inout CountdownDetailInfo) -> ())? = nil) -> CountdownDetailInfo?
```
`XTCountdown`也提供了一些可选功能，包括如下

```Swift
// MARK: —————————— 定时器功能 ——————————
public struct XTCountdownFunction: OptionSet {
    
    /** 默认*/
    public static let `default` = XTCountdownFunction(rawValue: 1 << 0)
    /** 持久化，是否需要杀死程序后仍然开启计时*/
    public static let cache = XTCountdownFunction(rawValue: 1 << 3)
    /** 持久化时是否需要保持计时*/
    public static let remainTiming = XTCountdownFunction(rawValue: 1 << 4)
}
```
如果开发者设置了功能包括`cache`以及`remainTiming `，则应用程序在被杀死到下一次启动时的时间间隔也会影响倒计时剩余时间；如果功能只包括`cache`，则应用在被杀死时，会做持久化记录，下次启动时将继续进行上次未完成的计时；如果不需要对未完成计时设置持久化，则设置功能只包括`default`即可。
`XTCountdown`通过Block将未完成的计时器详细信息封装成一个`CountdownDetailInfo`类传出来，`CountdownDetailInfo`类还支持获取到某个计时器对象，使其执行开启计时、暂停计时、销毁操作，`CountdownDetailInfo`包括的计时器信息包括如下：

```Swift
/** 计时器详细信息*/
public class CountdownDetailInfo {
    /** 功能状态值*/
    var state: Int = 0
    /** 已经运行时长*/
    var run: UInt = 0
    /** 剩余时长*/
    var left: UInt = 0
    /** 总计时长*/
    var total: UInt = 0
    /** 定时器对象*/
    var timer: Timer = Timer()
    /** 节点时间戳*/
    var checkpointStamp: Double = 0
    /** 结束时间戳*/
    var endStamp: Double = 0
    /** 唯一标识符*/
    var key: String = ""
    /** 本次运行时长*/
    var runThisTime: UInt = 0
    
    func start() {
        xt_countdown.pauseOrResumeCountdown(key: key, forcePause: false)
    }
    
    func pause() {
        xt_countdown.pauseOrResumeCountdown(key: key, forcePause: true)
    }
    
    func drop() {
        xt_countdown.removeCountdown(key: key)
    }
}
```

## XTPlayerTool
作为`XTPlayer`的辅助工具类，`XTPlayerTool `提供一些工具方法，包括开启网络状态监听、设置音频播放进度时长输出格式、根据某个`URL`信息读取该音频资源总时长、下载音频资源等功能。
