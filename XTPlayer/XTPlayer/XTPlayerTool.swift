//
//  XTPlayerTool.swift
//
//  Created by Shaw on 2019/1/24.
//  Copyright © 2019年 Shaw. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire
import CommonCrypto

public let xt_playerTool = XTPlayerTool.instance

public enum NetworkStatus {
    case notReachable, wifi, wwan
}

public class XTPlayerTool {
    
    static let instance = XTPlayerTool()
    
    public var netStatus: NetworkStatus = .notReachable
    
    private let netManager = NetworkReachabilityManager.init(host: "https://www.baidu.com")
    
    public func initConfig() {
        startListen()
    }
    /** 开启网络监听*/
    public func startListen() {
        
        netManager?.listener = { status in
            switch status {
            case .notReachable:
                self.netStatus = .notReachable
            case .unknown:
                self.netStatus = .notReachable
            case .reachable(.ethernetOrWiFi):
                self.netStatus = .wifi
            case .reachable(.wwan):
                self.netStatus = .wwan
            }
        }
        netManager?.startListening()
    }
    
    public func formatTime(seconds: UInt) -> String {
        if seconds == 0 {
            return "00:00"
        }
        let hour = seconds / 3600
        let minute = (seconds % 3600) / 60
        let second = seconds % 60
        if hour > 0 {
            return String.init(format: "%02d:%02d:%02d", hour, minute, second)
        } else {
            return String.init(format: "%02d:%02d", minute, second)
        }
    }
    
    /// 根据数据源地址读取数据源播放时长
    ///
    /// - Parameter urlString: 数据源地址
    /// - Returns: 数据源时长
    public func readDuration(url urlString: String) -> UInt {
        let url_ = URL.init(string: urlString)
        guard let url = url_ else {
            return 0
        }
        let asset = AVURLAsset.init(url: url)
        let duration = asset.duration
        let seconds = CMTimeGetSeconds(duration)
        guard seconds > 0 else {
            return 0
        }
        return UInt(ceil(seconds))
    }
    
    public func download(_ url: URL, downloadProgress: ((Double) -> ())?, completionHandler: ((URL) -> ())?) {
        
        guard let cache = generateCachePath(original: url.absoluteString) else {
            return
        }
        let cacheURL = URL.init(fileURLWithPath: cache)
        Alamofire.download(url) { (savedURL, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
            
            return (cacheURL, [.createIntermediateDirectories, .removePreviousFile])
            
            }.downloadProgress { (progress) in
                downloadProgress?(progress.fractionCompleted)
            }.responseData { (response) in
                switch response.result {
                case .success:
                    completionHandler?(cacheURL)
                case .failure(let error):
                    debugPrint(error)
                }
        }
        
    }
    
    public func checkFileExist(url: String) -> String? {
        guard let cache = generateCachePath(original: url) else {
            return nil
        }
        let result = FileManager.default.fileExists(atPath: cache)
        guard result else {
            return nil
        }
        return cache
    }
    
    public func generateCachePath(original: String) -> String? {
        guard let url = URL.init(string: original) else {
            return nil
        }
        let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        let fileType = url.pathExtension
        guard !fileType.isEmpty else {
            return nil
        }
        let cachePath = cacheDir + "/XTPlayer/" + url.absoluteString.md5 + ".\(fileType)"
        return cachePath
    }
}


extension String {
    
    var md5: String {
        get {
            let str = self.cString(using: String.Encoding.utf8)
            let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
            let digestLen = Int(CC_MD5_DIGEST_LENGTH)
            let result = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
            CC_MD5(str!, strLen, result)
            let hash = NSMutableString()
            for i in 0 ..< digestLen {
                hash.appendFormat("%02x", result[i])
            }
            free(result)
            return String(format: hash as String)
        }
    }
    
}

extension Date {
    
    /** 获取该日期的零点*/
    public var zero: Date {
        get {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: self)
            return calendar.date(from: components) ?? self
        }
    }
    
}

extension Array {
    
    /// 对数组等类型进行安全访问
    ///
    /// - Parameter index: 访问的索引值
    subscript (safe index: Int) -> Element? {
        return (0 ..< count).contains(index) ? self[index] : nil
    }
}
