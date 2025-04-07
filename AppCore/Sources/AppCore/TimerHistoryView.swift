//
//  TimerHistoryView.swift
//  AppCore
//
//  Created by Rice Lin on 3/30/25.
//

import SwiftUI
import SwiftData

public struct TimerHistoryView: View {
  @Environment(\.modelContext) private var modelContext
  @Bindable var timer: TimerModel
  @State private var isEditingTitle = false
  @State private var newTitle = ""
  @State private var showingTimerRunView = false
  @State private var showingStatsView = false
  
  public init(timer: TimerModel) {
    self.timer = timer
  }
  
  public var body: some View {
    VStack {
      List {        
        Section {
          Button(action: { showingTimerRunView = true }) {
            Label("開始新計時", systemImage: "timer")
              .foregroundColor(.green)
          }
        }
        
        if !timer.records.isEmpty {
          Section {
            Button(action: { showingStatsView = true }) {
              Label("查看統計圖表", systemImage: "chart.line.uptrend.xyaxis")
                .foregroundColor(.blue)
            }
          }
        }
        
        Section("歷史記錄") {
          if timer.records.isEmpty {
            VStack(spacing: 20) {
              Image(systemName: "timer.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
              
              Text("尚無計時記錄")
                .font(.headline)
                .foregroundColor(.gray)              
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .listRowBackground(Color.clear)
          } else {
            ForEach(timer.records) { record in
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
            .onDelete(perform: deleteRecords)
          }
        }
      }
    }
    .navigationTitle(timer.title)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Button(action: { 
          newTitle = timer.title
          isEditingTitle = true 
        }) {
          Label("編輯", systemImage: "pencil")
        }
      }
    }
    #if os(iOS)
    .fullScreenCover(isPresented: $showingTimerRunView) {
      TimerRunView(timer: timer)
    }
    #else
    .sheet(isPresented: $showingTimerRunView) {
      TimerRunView(timer: timer)
    }
    #endif
    .sheet(isPresented: $showingStatsView) {
      TimerStatsView(timer: timer)
    }
    
    .alert("編輯計時器名稱", isPresented: $isEditingTitle) {
      TextField("計時器名稱", text: $newTitle)
      Button("取消", role: .cancel) {}
      Button("儲存") {
        if !newTitle.isEmpty {
          timer.title = newTitle
        }
      }
    }
  }
  
  private func deleteRecords(offsets: IndexSet) {
    let recordsToDelete = offsets.map { timer.records[$0] }
    for record in recordsToDelete {
      if let index = timer.records.firstIndex(where: { $0.id == record.id }) {
        timer.records.remove(at: index)
      }
    }
  }
}

#Preview {
  let preview = TimerModel(title: "預覽計時器")
  preview.records = [
    TimerRecord(duration: 10.5, timer: preview),
    TimerRecord(duration: 20.3, timer: preview)
  ]
  
  return TimerHistoryView(timer: preview)
    .modelContainer(for: TimerModel.self, inMemory: true)
} 
