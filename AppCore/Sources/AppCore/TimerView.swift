//
//  TimerView.swift
//  AppCore
//
//  Created by Rice Lin on 3/30/25.
//

import SwiftUI

private struct TimerRecord: Identifiable {
  let id = UUID()
  let duration: TimeInterval
  let timestamp = Date()
}

public struct TimerView: View {
  @State private var timeElapsed: TimeInterval = 0
  @State private var timer: Timer?
  @State private var isRunning = false
  @State private var history: [TimerRecord] = []
  
  public init() {}
  
  public var body: some View {
    VStack {
      Text(String(format: "%.1f", timeElapsed))
        .font(.system(size: 50, weight: .bold))
        .padding()
      
      Button(action: {
        if isRunning {
          stopTimer()
        } else {
          startTimer()
        }
      }) {
        Text(isRunning ? "停止" : "開始")
          .font(.title)
          .padding()
          .background(isRunning ? Color.red : Color.green)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
      
      VStack(alignment: .leading) {
        Text("計時記錄")
          .font(.headline)
          .padding(.horizontal)
        
        List {
          ForEach(history) { record in
            HStack {
              VStack(alignment: .leading) {
                Text(String(format: "%.1f秒", record.duration))
                  .font(.body)
                Text(record.timestamp, style: .date)
                  .font(.caption)
                  .foregroundColor(.gray)
              }
              Spacer()
              Text(record.timestamp, style: .time)
                .foregroundColor(.gray)
            }
          }
          .onDelete { indexSet in
            history.remove(atOffsets: indexSet)
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
  
  private func startTimer() {
    isRunning = true
    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
      Task { @MainActor in
        timeElapsed += 0.1
      }
    }
  }
  
  private func stopTimer() {
    isRunning = false
    timer?.invalidate()
    timer = nil
    
    history.insert(TimerRecord(duration: timeElapsed), at: 0)
    timeElapsed = 0
  }
}

#Preview {
  TimerView()
}
