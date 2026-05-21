import AppKit

struct ArtworkData {
   var id: String
   var title: String
   var description: String
   var imageUrl: String?
   var author: AuthorData
   var createdAt: String
   var updatedAt: String
   var likesCount: Int
   var layers: [LayerData]
}
