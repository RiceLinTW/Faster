//
//  TimerStatsView.swift
//  AppCore
//
//  Created by Rice Lin on 3/30/25.
//

import SwiftUI
import SwiftData
import Charts

public struct TimerStatsView: View {
  let timer: TimerModel
  @Environment(\.dismiss) private var dismiss
  @State private var timeRange: TimeRange = .week
  @State private var selectedRecord: TimerRecord?
  
  enum TimeRange: String, CaseIterable, Identifiable {
    case week = "一週"
    case month = "一個月"
    case year = "一年"
    case all = "全部"
    
    var id: String { self.rawValue }
  }
  
  public var body: some View {
    NavigationStack {
      VStack {
        Picker("時間範圍", selection: $timeRange) {
          ForEach(TimeRange.allCases) { range in
            Text(range.rawValue).tag(range)
          }
        }
        .pickerStyle(.segmented)
        .padding()
        
        if filteredRecords.isEmpty {
          ContentUnavailableView("無資料", systemImage: "chart.line.downtrend.xyaxis", description: Text("所選時間範圍內沒有計時記錄"))
        } else {
          ScrollView {
            VStack(spacing: 20) {
              // 趨勢圖
              GroupBox("計時趨勢") {
                Chart {
                  ForEach(Array(filteredRecords.prefix(50))) { record in
                    LineMark(
                      x: .value("日期", record.timestamp),
                      y: .value("時間(秒)", record.duration)
                    )
                    .interpolationMethod(.catmullRom)
                    .symbol(.circle)
                    .symbolSize(30)
                    .foregroundStyle(.blue.gradient)
                    
                    PointMark(
                      x: .value("日期", record.timestamp),
                      y: .value("時間(秒)", record.duration)
                    )
                    .symbolSize(100)
                    .foregroundStyle(.blue.opacity(0.3))
                  }
                  
                  if let selected = selectedRecord {
                    RuleMark(x: .value("選擇日期", selected.timestamp))
                      .foregroundStyle(.gray.opacity(0.3))
                      .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                      x: .value("選擇日期", selected.timestamp),
                      y: .value("時間", selected.duration)
                    )
                    .symbolSize(180)
                    .foregroundStyle(.orange.opacity(0.3))
                    
                    PointMark(
                      x: .value("選擇日期", selected.timestamp),
                      y: .value("時間", selected.duration)
                    )
                    .symbolSize(80)
                    .foregroundStyle(.orange)
                  }
                  
                  RuleMark(y: .value("平均", averageDuration))
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                      Text("平均: \(String(format: "%.1f秒", averageDuration))")
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
                .frame(height: 250)
                .chartYScale(domain: minDuration...maxDuration)
                .chartXAxis {
                  AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                      if let date = value.as(Date.self) {
                        Text(date, format: dateFormat())
                      }
                    }
                  }
                }
                .chartOverlay { proxy in
                  GeometryReader { geometry in
                    Rectangle()
                      .fill(Color.clear)
                      .contentShape(Rectangle())
                      .gesture(
                        DragGesture()
                          .onChanged { value in
                            let location = value.location
                            if let (date, _) = proxy.value(at: location, as: (Date, Double).self) {
                              if let record = findClosestRecord(to: date) {
                                selectedRecord = record
                              }
                            }
                          }
                          .onEnded { _ in
                            // 保持選擇的記錄，不清除
                          }
                      )
                      .onTapGesture { location in
                        if let (date, _) = proxy.value(at: location, as: (Date, Double).self) {
                          if let record = findClosestRecord(to: date) {
                            if selectedRecord?.id == record.id {
                              selectedRecord = nil
                            } else {
                              selectedRecord = record
                            }
                          }
                        } else {
                          selectedRecord = nil
                        }
                      }
                  }
                }
                .padding()
                
                if let selected = selectedRecord {
                  VStack(alignment: .leading, spacing: 5) {
                    Text(selected.timestamp, format: .dateTime.day().month().year())
                      .font(.subheadline)
                    
                    HStack {
                      Text("時間:")
                        .foregroundColor(.secondary)
                      Text(String(format: "%.1f秒", selected.duration))
                        .font(.headline)
                    }
                    
                    Text(selected.timestamp, format: .dateTime.hour().minute())
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.horizontal)
                  .padding(.vertical, 8)
                  .background(Color.secondary.opacity(0.1))
                  .cornerRadius(8)
                  .padding(.horizontal)
                }
              }
              .padding(.horizontal)
              
              // 統計數據
              GroupBox("統計摘要") {
                VStack(spacing: 15) {
                  StatRowView(title: "總計次數", value: "\(filteredRecords.count)次")
                  StatRowView(title: "平均時間", value: String(format: "%.1f秒", averageDuration))
                  StatRowView(title: "最短時間", value: String(format: "%.1f秒", minDuration))
                  StatRowView(title: "最長時間", value: String(format: "%.1f秒", maxDuration))
                }
                .padding()
              }
              .padding(.horizontal)
            }
            .padding(.vertical)
          }
        }
      }
      .navigationTitle("計時統計")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("關閉") {
            dismiss()
          }
        }
      }
    }
  }
  
  private var filteredRecords: [TimerRecord] {
    let now = Date()
    
    let filterDate: Date? = {
      switch timeRange {
      case .week:
        return Calendar.current.date(byAdding: .day, value: -7, to: now)
      case .month:
        return Calendar.current.date(byAdding: .month, value: -1, to: now)
      case .year:
        return Calendar.current.date(byAdding: .year, value: -1, to: now)
      case .all:
        return nil
      }
    }()
    
    if let filterDate = filterDate {
      return timer.records.filter { $0.timestamp >= filterDate }.sorted(by: { $0.timestamp < $1.timestamp })
    } else {
      return timer.records.sorted(by: { $0.timestamp < $1.timestamp })
    }
  }
  
  private var minDuration: Double {
    guard !filteredRecords.isEmpty else { return 0 }
    return filteredRecords.min(by: { $0.duration < $1.duration })?.duration ?? 0
  }
  
  private var maxDuration: Double {
    guard !filteredRecords.isEmpty else { return 0 }
    return filteredRecords.max(by: { $0.duration < $1.duration })?.duration ?? 0
  }
  
  private var averageDuration: Double {
    guard !filteredRecords.isEmpty else { return 0 }
    let total = filteredRecords.reduce(0) { $0 + $1.duration }
    return total / Double(filteredRecords.count)
  }
  
  private func findClosestRecord(to date: Date) -> TimerRecord? {
    guard !filteredRecords.isEmpty else { return nil }
    
    return filteredRecords.min { record1, record2 in
      abs(record1.timestamp.timeIntervalSince(date)) < abs(record2.timestamp.timeIntervalSince(date))
    }
  }
  
  private func dateFormat() -> Date.FormatStyle {
    switch timeRange {
    case .week:
      return .dateTime.day().month()
    case .month:
      return .dateTime.day().month()
    case .year:
      return .dateTime.month().year()
    case .all:
      return .dateTime.month().year()
    }
  }
}

struct StatRowView: View {
  let title: String
  let value: String
  
  var body: some View {
    HStack {
      Text(title)
        .foregroundColor(.secondary)
      Spacer()
      Text(value)
        .font(.headline)
    }
  }
}

// MARK: - Previews
#Preview("統計視圖 - 週") {
  let preview = TimerModel(title: "預覽計時器")
  // 創建多日的測試數據
  let today = Date()
  let dates = (0..<7).map { day in
    Calendar.current.date(byAdding: .day, value: -day, to: today)!
  }
  
  preview.records = dates.enumerated().map { index, date in
    let randomDuration = Double.random(in: 10...30)
    return TimerRecord(duration: randomDuration, timestamp: date, timer: preview)
  }
  
  return TimerStatsView(timer: preview)
    .modelContainer(for: TimerModel.self, inMemory: true)
}

#Preview("統計視圖 - 月") {
  let preview = TimerModel(title: "預覽計時器")
  // 創建一個月的測試數據
  let today = Date()
  let dates = (0..<30).map { day in
    Calendar.current.date(byAdding: .day, value: -day, to: today)!
  }
  
  preview.records = dates.enumerated().map { index, date in
    // 隨機數據，但加入趨勢：時間越晚，成績越好（時間越短）
    let randomBase = Double.random(in: 10...20)
    let trend = Double(index) / 4.0 // 添加趨勢因子
    let duration = max(5, 30 - trend + randomBase)
    return TimerRecord(duration: duration, timestamp: date, timer: preview)
  }
  
  return TimerStatsView(timer: preview)
    .modelContainer(for: TimerModel.self, inMemory: true)
}

#Preview("統計視圖 - 無資料") {
  let preview = TimerModel(title: "空計時器")
  
  return TimerStatsView(timer: preview)
    .modelContainer(for: TimerModel.self, inMemory: true)
} 
