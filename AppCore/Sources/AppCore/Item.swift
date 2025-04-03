//
//  TimerModel.swift
//  Faster
//
//  Created by Rice Lin on 3/30/25.
//

import Foundation
import SwiftData

@Model
public final class TimerModel {
  public var title: String
  public var createdAt: Date
  public var records: [TimerRecord] = []
  public var enableCountdown: Bool = true
  
  public init(title: String, createdAt: Date = Date()) {
    self.title = title
    self.createdAt = createdAt
  }
}

@Model
public final class TimerRecord {
  public var duration: TimeInterval
  public var timestamp: Date
  public var timer: TimerModel?
  
  public init(duration: TimeInterval, timestamp: Date = Date(), timer: TimerModel? = nil) {
    self.duration = duration
    self.timestamp = timestamp
    self.timer = timer
  }
}
