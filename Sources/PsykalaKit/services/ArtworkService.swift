import Foundation
import ScreensaverCore
import CoreGraphics

// MARK: - Lenient JSON decoding
//
// The API (and the web editor) may add new layer keys at any time, and older
// artworks lack the newer ones. Every field is read individually and leniently:
// unknown keys are ignored, missing / null / mistyped keys fall back to nil
// (the default is resolved per layer type in BaseLayer). A single odd layer or
// artwork never makes the whole payload fail to decode.

private struct AnyKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ string: String) { stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

private extension KeyedDecodingContainer where K == AnyKey {
    func number(_ key: String) -> CGFloat? {
        let k = AnyKey(key)
        if let d = try? decodeIfPresent(Double.self, forKey: k) {
            return d.isFinite ? CGFloat(d) : nil
        }
        if let s = try? decodeIfPresent(String.self, forKey: k),
           let d = Double(s.trimmingCharacters(in: .whitespaces)), d.isFinite {
            return CGFloat(d)
        }
        return nil
    }

    func bool(_ key: String) -> Bool? {
        let k = AnyKey(key)
        if let b = try? decodeIfPresent(Bool.self, forKey: k) { return b }
        return nil
    }

    func string(_ key: String) -> String? {
        let k = AnyKey(key)
        if let s = try? decodeIfPresent(String.self, forKey: k) { return s }
        if let i = try? decodeIfPresent(Int.self, forKey: k) { return String(i) }
        if let d = try? decodeIfPresent(Double.self, forKey: k) { return String(d) }
        return nil
    }

    func point(_ key: String) -> LayerPoint? {
        guard let c = try? nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey(key)) else { return nil }
        let x = c.number("x")
        let y = c.number("y")
        if x == nil && y == nil { return nil }
        return LayerPoint(x: x ?? 0, y: y ?? 0)
    }
}

/// Decodes T, or nil when that element is malformed (never throws).
private struct Lossy<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws { value = try? T(from: decoder) }
}

private struct APILayer: Decodable {
    let data: LayerData?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        // Unknown / missing type: the layer is skipped instead of drawn as a circle
        guard let typeName = c.string("type"), let type = LayerType(apiName: typeName) else {
            data = nil
            return
        }
        var d = LayerData(id: c.string("id") ?? UUID().uuidString, type: type)
        d.name = c.string("name") ?? ""
        d.visible = c.bool("visible")
        d.radius = c.number("radius")
        d.rotation = c.number("rotation")
        d.rotationSpeed = c.number("rotationSpeed")
        d.angle = c.number("angle")
        d.color = c.string("color")
        d.filled = c.bool("filled")
        d.lineWidth = c.number("lineWidth")
        d.nbrChilds = c.number("nbrChilds")
        d.childSize = c.number("childSize")
        d.childAngle = c.number("childAngle")
        d.childRotation = c.number("childRotation")
        d.childRotationSpeed = c.number("childRotationSpeed")
        d.hasMask = c.bool("hasMask")
        d.maskRadius = c.number("maskRadius")
        d.maskX = c.number("maskX")
        d.maskY = c.number("maskY")
        d.offset = c.point("position")
        d.layerScale = c.number("scale")
        d.stretch = c.point("stretch")

        d.arcLength = c.number("arcLength")
        d.sides = c.number("sides")
        d.cornerRadius = c.number("cornerRadius")
        d.points = c.number("points")
        d.innerRatio = c.number("innerRatio")
        d.width = c.number("width")
        d.height = c.number("height")
        d.lobes = c.number("lobes")
        d.windings = c.number("windings")
        d.depth = c.number("depth")

        d.blendMode = c.string("blendMode")
        d.dashLength = c.number("dashLength")
        d.dashGap = c.number("dashGap")
        d.dashSpeed = c.number("dashSpeed")
        d.roundCap = c.bool("roundCap")
        d.pulseAmount = c.number("pulseAmount")
        d.pulseSpeed = c.number("pulseSpeed")
        d.pulseEasing = c.string("pulseEasing")
        d.gridCols = c.number("gridCols")
        d.gridRows = c.number("gridRows")
        d.gridSpacingX = c.number("gridSpacingX")
        d.gridSpacingY = c.number("gridSpacingY")
        d.gridAngleStep = c.number("gridAngleStep")
        d.gridAngleMode = c.string("gridAngleMode")
        data = d
    }
}

private struct APIArtwork: Decodable {
    let artwork: ArtworkData

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        let layers = (try? c.decode([Lossy<APILayer>].self, forKey: AnyKey("layers"))) ?? []
        var author = AuthorData(id: "", username: "")
        if let a = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("author")) {
            author = AuthorData(id: a.string("id") ?? "", username: a.string("username") ?? "")
        }
        artwork = ArtworkData(
            id: c.string("id") ?? "",
            title: c.string("title") ?? "",
            description: c.string("description") ?? "",
            imageUrl: c.string("imageUrl"),
            author: author,
            createdAt: c.string("createdAt") ?? "",
            updatedAt: c.string("updatedAt") ?? "",
            likesCount: Int(c.number("likesCount") ?? 0),
            layers: layers.compactMap { $0.value?.data }
        )
    }
}

enum ArtworkService {
    static let apiURL = URL(string: "https://api.psykala.com/api/artworks/random?limit=20&screensaver=true")!

    /// Decodes either an array of artworks or a single artwork (API or .psk JSON).
    /// Layers keep the order of the JSON (the API stores them top -> bottom).
    static func decodeArtworks(from data: Data) -> [ArtworkData] {
        let decoder = JSONDecoder()
        if let list = try? decoder.decode([Lossy<APIArtwork>].self, from: data) {
            return list.compactMap { $0.value?.artwork }
        }
        if let single = try? decoder.decode(APIArtwork.self, from: data) {
            return [single.artwork]
        }
        return []
    }

    /// Artworks shipped in the package (`Resources/Artworks/*.psk`).
    static func bundled() -> [ArtworkData] {
        guard let bundle = ResourceBundle.named("amphore-saver_PsykalaKit", containing: BundleAnchor.self),
              let urls = bundle.urls(forResourcesWithExtension: "psk", subdirectory: "Artworks")
        else { return [] }
        return urls
            .compactMap { try? Data(contentsOf: $0) }
            .flatMap { decodeArtworks(from: $0) }
            .filter { !$0.layers.isEmpty }
    }

    static func fetchRandom(completion: @escaping @MainActor ([ArtworkData]) -> Void) {
        let session = URLSession(configuration: .ephemeral)
        session.dataTask(with: apiURL) { data, _, error in
            guard error == nil, let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let artworks = decodeArtworks(from: data).filter { !$0.layers.isEmpty }
            DispatchQueue.main.async { completion(artworks) }
        }.resume()
    }
}

private final class BundleAnchor {}
