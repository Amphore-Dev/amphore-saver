import Foundation

private struct APIAuthor: Decodable {
    let id: Int
    let username: String
}

private struct APIPoint: Decodable {
    let x: CGFloat
    let y: CGFloat
}

private struct APILayer: Decodable {
    let id: String
    let type: String
    let name: String
    let radius: CGFloat
    let rotation: CGFloat?
    let rotationSpeed: CGFloat?
    let angle: CGFloat?
    let color: String
    let filled: Bool?
    let lineWidth: CGFloat?
    let nbrChilds: Int?
    let childSize: CGFloat?
    let childAngle: CGFloat?
    let childRotationSpeed: CGFloat?
    let hasMask: Bool?
    let maskRadius: CGFloat?
    let maskX: CGFloat?
    let maskY: CGFloat?
    let position: APIPoint?
    let layerScale: CGFloat?
    let stretch: APIPoint?
}

private struct APIArtwork: Decodable {
    let id: Int
    let title: String
    let description: String
    let imageUrl: String?
    let author: APIAuthor
    let createdAt: String
    let updatedAt: String
    let likesCount: Int
    let layers: [APILayer]
}

private func layerType(from string: String) -> LayerType {
    switch string.lowercased() {
    case "circle": return .circle
    case "rosace", "rose": return .rosace
    case "line": return .line
    case "background": return .background
    default: return .circle
    }
}

private func convert(_ api: APIArtwork) -> ArtworkData {
    let layers = api.layers.map { l -> LayerData in
        let offset = LayerPoint(x: l.position?.x ?? 0, y: l.position?.y ?? 0)
        let stretch = LayerPoint(x: l.stretch?.x ?? 1, y: l.stretch?.y ?? 1)
        return LayerData(
            id: l.id,
            type: layerType(from: l.type),
            name: l.name,
            radius: l.radius,
            rotation: l.rotation,
            rotationSpeed: l.rotationSpeed,
            angle: l.angle,
            color: l.color,
            filled: l.filled,
            lineWidth: l.lineWidth,
            nbrChilds: l.nbrChilds,
            childSize: l.childSize,
            childAngle: l.childAngle,
            childRotationSpeed: l.childRotationSpeed,
            hasMask: l.hasMask,
            maskRadius: l.maskRadius,
            maskX: l.maskX,
            maskY: l.maskY,
            offset: offset,
            layerScale: l.layerScale,
            stretch: stretch
        )
    }
    return ArtworkData(
        id: String(api.id),
        title: api.title,
        description: api.description,
        imageUrl: api.imageUrl,
        author: AuthorData(id: String(api.author.id), username: api.author.username),
        createdAt: api.createdAt,
        updatedAt: api.updatedAt,
        likesCount: api.likesCount,
        layers: layers
    )
}

enum ArtworkService {
    static let apiURL = URL(string: "https://api.psykala.com/api/artworks/random?limit=20&screensaver=true")!

    static func fetchRandom(completion: @escaping ([ArtworkData]) -> Void) {
        let session = URLSession(configuration: .ephemeral)
        session.dataTask(with: apiURL) { data, _, error in
            guard error == nil, let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let decoder = JSONDecoder()
            if let artworks = try? decoder.decode([APIArtwork].self, from: data) {
                DispatchQueue.main.async { completion(artworks.map(convert)) }
            } else if let artwork = try? decoder.decode(APIArtwork.self, from: data) {
                DispatchQueue.main.async { completion([convert(artwork)]) }
            } else {
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }
}
