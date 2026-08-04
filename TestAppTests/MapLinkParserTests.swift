//
//  MapLinkParserTests.swift
//  TestAppTests
//
//  Tests the offline coordinate extraction from pasted Maps URLs.
//

import Testing

@testable import TestApp

@Suite("MapLinkParser")
struct MapLinkParserTests {

  @Test("reads Google place pin (!3d!4d), the most precise source")
  func googlePlacePin() throws {
    let url = "https://www.google.com/maps/place/X/@14.05,-87.19,17z/data=!3d14.0812!4d-87.2068"
    let coords = try #require(MapLinkParser.coordinates(from: url))
    #expect(abs(coords.latitude - 14.0812) < 0.0001)
    #expect(abs(coords.longitude - (-87.2068)) < 0.0001)
  }

  @Test("reads Google viewport (@lat,lng)")
  func googleViewport() throws {
    let coords = try #require(
      MapLinkParser.coordinates(from: "https://maps.google.com/maps/@14.08,-87.20,17z"))
    #expect(abs(coords.latitude - 14.08) < 0.0001)
    #expect(abs(coords.longitude - (-87.20)) < 0.0001)
  }

  @Test("reads Apple Maps (?ll=lat,lng)")
  func appleLL() throws {
    let coords = try #require(
      MapLinkParser.coordinates(from: "https://maps.apple.com/?ll=40.7128,-74.0060"))
    #expect(abs(coords.latitude - 40.7128) < 0.0001)
    #expect(abs(coords.longitude - (-74.0060)) < 0.0001)
  }

  @Test("reads generic ?q=lat,lng")
  func genericQuery() throws {
    let coords = try #require(MapLinkParser.coordinates(from: "geo:?q=51.5074,-0.1278"))
    #expect(abs(coords.latitude - 51.5074) < 0.0001)
    #expect(abs(coords.longitude - (-0.1278)) < 0.0001)
  }

  @Test("returns nil when there are no coordinates")
  func noCoordinates() {
    #expect(MapLinkParser.coordinates(from: "https://maps.app.goo.gl/abc123") == nil)
    #expect(MapLinkParser.coordinates(from: "just some text") == nil)
  }

  @Test("rejects out-of-range coordinates")
  func outOfRange() {
    // Latitude 99 is invalid.
    #expect(MapLinkParser.coordinates(from: "https://maps.google.com/maps/@99.0,10.0,17z") == nil)
  }
}
