//
//  DistanceFormatterTests.swift
//  TestAppTests
//
//  Tests the meters -> "350 m" / "1.2 km" formatting used in the place list.
//

import Testing

@testable import TestApp

@Suite("DistanceFormatter")
struct DistanceFormatterTests {

  @Test("under a kilometer shows whole meters")
  func meters() {
    #expect(DistanceFormatter.string(forMeters: 0) == "0 m")
    #expect(DistanceFormatter.string(forMeters: 349.6) == "350 m")
    #expect(DistanceFormatter.string(forMeters: 999) == "999 m")
  }

  @Test("a kilometer or more shows one decimal in km")
  func kilometers() {
    #expect(DistanceFormatter.string(forMeters: 1000) == "1.0 km")
    #expect(DistanceFormatter.string(forMeters: 1234) == "1.2 km")
    #expect(DistanceFormatter.string(forMeters: 15800) == "15.8 km")
  }
}
