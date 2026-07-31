//
//  MapLinkParser.swift
//  TestApp
//
//  Pulls (latitude, longitude) out of a pasted Google/Apple Maps URL, so the
//  user can pick a place without us building a MapKit picker.
//
//  IMPORTANT: works with FULL links that already contain the coordinates
//  (e.g. ".../@14.08,-87.20,17z" or "?ll=14.08,-87.20"). Shortened "share"
//  links (maps.app.goo.gl, goo.gl/maps) do NOT contain coordinates — they'd
//  need a network redirect to resolve, which we don't do here.
//

import Foundation

enum MapLinkParser {

    static func coordinates(from text: String) -> (latitude: Double, longitude: Double)? {
        // Ordered by how specific each source is.
        let patterns = [
            #"!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)"#,    // Google place PIN (most precise)
            #"@(-?\d+\.\d+),(-?\d+\.\d+)"#,        // Google:  .../@lat,lng (viewport)
            #"[?&]ll=(-?\d+\.\d+),(-?\d+\.\d+)"#,  // Apple:   ?ll=lat,lng
            #"coordinate=(-?\d+\.\d+),(-?\d+\.\d+)"#,
            #"[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)"#     // generic: ?q=lat,lng
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            guard let match = regex.firstMatch(in: text, range: range),
                  match.numberOfRanges == 3,
                  let latRange = Range(match.range(at: 1), in: text),
                  let lngRange = Range(match.range(at: 2), in: text),
                  let latitude = Double(text[latRange]),
                  let longitude = Double(text[lngRange])
            else { continue }

            // Sanity check: valid coordinate ranges.
            guard (-90...90).contains(latitude), (-180...180).contains(longitude) else { continue }
            return (latitude, longitude)
        }

        return nil
    }
}
