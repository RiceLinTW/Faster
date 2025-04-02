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
          Button(action: addTimer) {
            Label("新增計時器", systemImage: "plus")
          }
        }
      }
    }
  }
  
  private func addTimer() {
    let timer = TimerModel(title: "新計時器 \(timers.count + 1)")
    modelContext.insert(timer)
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