//
//  TimerListView.swift
//  AppCore
//
//  Created by Rice Lin on 3/30/25.
//

import SwiftUI
import SwiftData

public struct TimerListView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var timers: [TimerModel]
  @State private var isAddingNewTimer = false
  @State private var newTimerTitle = ""
  @State private var newlyCreatedTimer: TimerModel?
  
  public init() {}
  
  public var body: some View {
    NavigationStack {
      List {
        ForEach(timers) { timer in
          NavigationLink(destination: TimerHistoryView(timer: timer)) {
            HStack {
              Text(timer.title)
                .font(.headline)
              
              Spacer()
              
              VStack(alignment: .trailing) {
                Text("已建立: \(timer.createdAt, format: .dateTime)")
                  .font(.caption)
                  .foregroundColor(.gray)
                
                Text("\(timer.records.count) 筆記錄")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
            .padding(.vertical, 4)
          }
        }
        .onDelete(perform: deleteTimers)
      }
      .navigationTitle("計時器列表")
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button(action: { isAddingNewTimer = true }) {
            Label("新增計時器", systemImage: "plus")
          }
        }
      }
      .alert("新增計時器", isPresented: $isAddingNewTimer) {
        TextField("計時器名稱", text: $newTimerTitle)
        Button("取消", role: .cancel) {
          newTimerTitle = ""
        }
        Button("建立") {
          addTimer()
        }
      }
      .navigationDestination(item: $newlyCreatedTimer) { timer in
        TimerHistoryView(timer: timer)
      }
    }
  }
  
  private func addTimer() {
    let title = newTimerTitle.isEmpty ? "新計時器 \(timers.count + 1)" : newTimerTitle
    let timer = TimerModel(title: title)
    modelContext.insert(timer)
    newTimerTitle = ""
    newlyCreatedTimer = timer
  }
  
  private func deleteTimers(offsets: IndexSet) {
    for index in offsets {
      modelContext.delete(timers[index])
    }
  }
}

#Preview {
  TimerListView()
    .modelContainer(for: TimerModel.self, inMemory: true)
} 