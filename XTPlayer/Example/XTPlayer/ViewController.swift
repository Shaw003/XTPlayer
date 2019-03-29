//
//  ViewController.swift
//  XTPlayer
//
//  Created by shawtun1211@163.com on 03/28/2019.
//  Copyright (c) 2019 shawtun1211@163.com. All rights reserved.
//

import UIKit
import XTPlayer

class ViewController: UIViewController {
    
    @IBOutlet weak var audioTitleLbl: UILabel!
    
    @IBOutlet weak var audioDurationLbl: UILabel!
    
    @IBOutlet weak var audioProgressSlider: UISlider!
    
    @IBOutlet weak var bufferProgress: UIProgressView!
    
    @IBOutlet weak var playLastBtn: UIButton!
    
    @IBOutlet weak var playBtn: UIButton!
    
    @IBOutlet weak var playNextBtn: UIButton!
    
    @IBOutlet weak var loadDataBtn: UIButton!
    
    @IBOutlet weak var changeRateBtn: UIButton!
    
    @IBOutlet weak var destoryPlayerBtn: UIButton!
    
    
    var allModels: [CustomAudioModel] {
        get {
            
            let model1 = CustomAudioModel()
            model1.audioUrl = "http://admin.jingpinyuedu.com/public/freeaudio/undefined/b01d628503150dd0763fd21150539c46.mp3"
            model1.isFree = 1
            model1.freeTime = 0
            model1.audioTitle = "音频1"
            
            let model2 = CustomAudioModel()
            model2.audioUrl = "http://sc1.111ttt.cn/2018/1/03/13/396131232171.mp3"
            model2.isFree = 0
            model2.freeTime = 100
            model2.audioTitle = "音频2"
            
            let model3 = CustomAudioModel()
            model3.audioUrl = "http://admin.jingpinyuedu.com/private/chapter/undefined/dffe6e029934e14aaf8fe633942c73f9.mp3"
            model3.isFree = 0
            model3.freeTime = 0
            model3.audioTitle = "音频3"

            /**
             音频1:可以播放完整音频
             音频2:可以播放50秒
             音频3:不可以播放
             */
            return [model1, model2, model3]
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        xt_player.delegate = self
        playBtn.setTitle("暂停", for: .selected)
        playBtn.setTitle("播放", for: .normal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func changeProgress(_ sender: Any) {
        guard let slider = sender as? UISlider else { return }
        xt_player.prepareForSeek(to: slider.value)
    }
    
    @IBAction func playLastBtnClicked(_ sender: Any) {
        try? xt_player.playLast()
    }
    
    @IBAction func playBtnClicked(_ sender: Any) {
        do {
            try xt_player.play(index: 0)
        } catch let error {
            debugPrint(error)
        }
    }
    
    @IBAction func playNextBtnClicked(_ sender: Any) {
        try? xt_player.playNext()
    }
    @IBAction func loadDataBtnClicked(_ sender: Any) {
        xt_player.allOriginalModels = allModels
    }
    
    @IBAction func changeRateBtnClicked(_ sender: Any) {
        
        if xt_player.settings.rate >= 2 {
            xt_player.settings.rate = 0.25
        } else {
            xt_player.settings.rate += 0.25
        }
    }
    @IBAction func destoryPlayerBtnClicked(_ sender: Any) {
        xt_player.allOriginalModels = nil
        xt_player.destroyPlayer()
    }
}

extension ViewController: XTPlayerDelegate {
    
    func configePlayer() {
        xt_player.function = [.cache, .database, .seekToHistory]
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
    
    
    func askForWWANLoadPermission(confirmed: @escaping () -> ()) {
        let alert = UIAlertController.init(title: "网络环境确认", message: "当前非wifi环境，确定继续加载么", preferredStyle: .alert)
        let confirmAction = UIAlertAction.init(title: "确定", style: .default) {_ in
            confirmed()
        }
        alert.addAction(confirmAction)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    func stateDidChanged(_ state: XTPlayerState) {

    }
    
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

