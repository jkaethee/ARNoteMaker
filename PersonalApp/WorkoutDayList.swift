//
//  WorkoutDayList.swift
//  PersonalApp
//
//  Created by Jathushan Kaetheeswaran on 2020-01-14.
//  Copyright © 2020 Jathushan Kaetheeswaran. All rights reserved.
//
import Foundation

extension Array {
  func randomItem() -> Element? {
    if isEmpty { return nil }
    let index = Int(arc4random_uniform(UInt32(self.count)))
    return self[index]
  }
}

public class WorkoutDayList
{
  public static func getDay() -> String {

    let animal = Animals[Int(arc4random_uniform(UInt32(Animals.count)))]

    return animal;
  }

  static let Animals: [String] = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ]
}

