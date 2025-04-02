//
//  TimerRunView.swift
//  AppCore
//
//  Created by Rice Lin on 3/30/25.
//

import SwiftUI
import SwiftData

public struct TimerRunView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Bindable var timer: TimerModel
  @State private var timeElapsed: TimeInterval = 0
  @State private var timerObject: Timer?
  @State private var isRunning = false
  @State private var startTime: Date?
  
  public init(timer: TimerModel) {
    self.timer = timer
  }
  
  public var body: some View {
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
            .fill(isRunning ? Color.red : Color.green)
            .frame(width: 320, height: 320)
          
          Image(systemName: isRunning ? "pause.fill" : "play.fill")
            .font(.title)
            .foregroundColor(.white)
        }
      }
      .padding(.top, 30)
      
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
    .onDisappear {
      if isRunning {
        stopTimerAndSave()
      }
    }
  }
  
  private func toggleTimer() {
    if isRunning {
      stopTimerAndSave()
    } else {
      startTimer()
    }
  }
  
  private func startTimer() {
    isRunning = true
    startTime = Date()
    let startTimeCapture = startTime  // 捕獲當前值
    
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
  
  return TimerRunView(timer: preview)
    .modelContainer(for: TimerModel.self, inMemory: true)
} 
