//
//  MapLinkResolver.swift
//  TestApp
//
//  Resolves coordinates from a Maps link. FULL links are parsed directly and
//  offline; SHORTENED links (maps.app.goo.gl, goo.gl/maps) have no coordinates
//  inside, so we follow their network redirect and parse the resolved URL.
//

import Foundation

enum MapLinkResolver {

    // Async because short links require a network round-trip to resolve.
    static func coordinates(from text: String) async -> (latitude: Double, longitude: Double)? {
        // 1. Full link already contains the coordinates — no network needed.
        if let direct = MapLinkParser.coordinates(from: text) {
            return direct
        }

        // 2. Short link → follow the redirect and parse the final URL.
        guard let url = httpURL(in: text) else { return nil }
        guard let finalURL = await followRedirect(url) else { return nil }
        return MapLinkParser.coordinates(from: finalURL.absoluteString)
    }

    // URLSession follows redirects by default; `response.url` is the final URL.
    private static func followRedirect(_ url: URL) async -> URL? {
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return response.url
        } catch {
            return nil
        }
    }

    private static func httpURL(in text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme?.hasPrefix("http") == true else {
            return nil
        }
        return url
    }
}
