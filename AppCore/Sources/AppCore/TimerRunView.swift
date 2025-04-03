//
//  TimerRunView.swift
//  AppCore
//
//  Created by Rice Lin on 3/30/25.
//

import SwiftData
import SwiftUI

public struct TimerRunView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Bindable var timer: TimerModel
  @State private var timeElapsed: TimeInterval = 0
  @State private var timerObject: Timer?
  @State private var isRunning = false
  @State private var startTime: Date?
  @State private var countdownValue = 3
  @State private var isCountingDown = false
  @State private var countdownScale: CGFloat = 1.0
  @State private var countdownOpacity: Double = 1.0
  
  public init(timer: TimerModel) {
    self.timer = timer
  }
  
  public var body: some View {
    ZStack {
      VStack {
        Spacer()
        
        // 標題
        Text(timer.title)
          .font(.headline)
          .padding(.bottom)
        
        // 計時器顯示
        Text(formatTimeInterval(timeElapsed))
          .font(.system(size: 70, weight: .bold, design: .monospaced))
          .foregroundColor(isRunning ? .green : .primary)
          .padding()
        
        // 開始/停止按鈕
        Button(action: toggleTimer) {
          ZStack {
            Circle()
              .fill(isRunning || isCountingDown ? Color.red : Color.green)
              .frame(width: 320, height: 320)
            
            Image(systemName: isRunning || isCountingDown ? "pause.fill" : "play.fill")
              .font(.title)
              .foregroundColor(.white)
          }
        }
        .padding(.top, 30)
        
        // 倒數計時開關
        Toggle("啟用倒數計時", isOn: $timer.enableCountdown)
          .padding(.top, 20)
          .padding(.horizontal, 40)
        
        Spacer()
      }
      .navigationTitle("計時")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("取消") {
              dismiss()
            }
          }
        }
      
      // 倒數計時覆蓋效果
      if isCountingDown {
        Color.black.opacity(0.7)
          .edgesIgnoringSafeArea(.all)
          .allowsHitTesting(false)
        
        VStack {
          Text(countdownValue > 0 ? "\(countdownValue)" : "開始!")
            .font(.system(size: 150, weight: .bold, design: .rounded))
            .foregroundColor(countdownValue > 0 ? .orange : .green)
            .scaleEffect(countdownScale)
            .opacity(countdownOpacity)
          
          Text("預備...")
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.top, 20)
        }
        .allowsHitTesting(false)
      }
    }
    .onDisappear {
      if isRunning {
        stopTimerAndSave()
      } else if isCountingDown {
        cancelCountdown()
      }
    }
  }
  
  private func toggleTimer() {
    if isRunning {
      stopTimerAndSave()
    } else if isCountingDown {
      cancelCountdown()
    } else {
      if timer.enableCountdown {
        startCountdown()
      } else {
        startTimer()
      }
    }
  }
  
  private func startCountdown() {
    isCountingDown = true
    countdownValue = 3
    animateCountdown()
  }
  
  private func animateCountdown() {
    // 設定初始狀態
    countdownScale = 1.0
    countdownOpacity = 1.0
    
    // 第一個數字的動畫
    withAnimation(.easeOut(duration: 0.8)) {
      countdownScale = 1.5
      countdownOpacity = 0.2
    }
    
    // 延遲後開始第二個數字
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      // 確保還在倒數中
      guard isCountingDown else { return }
      
      countdownValue = 2
      countdownScale = 1.0
      countdownOpacity = 1.0
      
      withAnimation(.easeOut(duration: 0.8)) {
        countdownScale = 1.5
        countdownOpacity = 0.2
      }
      
      // 延遲後開始第三個數字
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        // 確保還在倒數中
        guard isCountingDown else { return }
        
        countdownValue = 1
        countdownScale = 1.0
        countdownOpacity = 1.0
        
        withAnimation(.easeOut(duration: 0.8)) {
          countdownScale = 1.5
          countdownOpacity = 0.2
        }
        
        // 延遲後顯示"開始"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
          // 確保還在倒數中
          guard isCountingDown else { return }
          
          countdownValue = 0
          countdownScale = 1.0
          countdownOpacity = 1.0
          
          withAnimation(.easeOut(duration: 0.8)) {
            countdownScale = 1.5
            countdownOpacity = 0
          }
          
          // 結束倒數並開始計時
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard isCountingDown else { return }
            cancelCountdown()
            startTimer()
          }
        }
      }
    }
  }
  
  private func cancelCountdown() {
    isCountingDown = false
  }
  
  private func startTimer() {
    isRunning = true
    startTime = Date()
    let startTimeCapture = startTime // 捕獲當前值
    
    timerObject = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
      if let capturedStartTime = startTimeCapture {
        let currentElapsed = Date().timeIntervalSince(capturedStartTime)
        Task { @MainActor in
          timeElapsed = currentElapsed
        }
      }
    }
  }
  
  private func stopTimerAndSave() {
    isRunning = false
    timerObject?.invalidate()
    timerObject = nil
    
    // 保存記錄並返回
    saveRecord()
    dismiss()
  }
  
  private func saveRecord() {
    guard timeElapsed > 0 else { return }
    
    let record = TimerRecord(duration: timeElapsed, timer: timer)
    timer.records.insert(record, at: 0)
  }
  
  private func formatTimeInterval(_ interval: TimeInterval) -> String {
    let totalSeconds = Int(interval)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    let milliseconds = Int((interval.truncatingRemainder(dividingBy: 1)) * 10)
    
    return String(format: "%02d:%02d.%01d", minutes, seconds, milliseconds)
  }
}

#Preview {
  let preview = TimerModel(title: "預覽計時器")
  preview.enableCountdown = true
  
  return NavigationStack {
    TimerRunView(timer: preview)
  }
  .modelContainer(for: TimerModel.self, inMemory: true)
}
