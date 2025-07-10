class GalleryEvent {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int imageCount;
  final String status;
  final DateTime date;
  final List<GalleryImage> images;

  GalleryEvent({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.imageCount,
    required this.status,
    required this.date,
    required this.images,
  });

  factory GalleryEvent.fromMap(String id, Map<String, dynamic> data) {
    return GalleryEvent(
      id: id,
      createdAt: data['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'].millisecondsSinceEpoch)
          : null,
      updatedAt: data['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'].millisecondsSinceEpoch)
          : null,
      imageCount: data['imageCount'] ?? 0,
      status: data['status'] ?? 'complete',
      date: data['date'] != null
          ? (data['date'] is String 
              ? DateTime.parse(data['date'])
              : DateTime.fromMillisecondsSinceEpoch(data['date'].millisecondsSinceEpoch))
          : DateTime.now(),
      images: (data['images'] as List<dynamic>?)
          ?.map((img) => GalleryImage.fromMap(img as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageCount': imageCount,
      'status': status,
      'date': date.toIso8601String(),
      'images': images.map((img) => img.toMap()).toList(),
    };
  }
}

class GalleryImage {
  final String url;
  final String path;
  final String name;
  final String type;
  final int size;

  GalleryImage({
    required this.url,
    required this.path,
    required this.name,
    required this.type,
    required this.size,
  });

  factory GalleryImage.fromMap(Map<String, dynamic> data) {
    return GalleryImage(
      url: data['url'] ?? '',
      path: data['path'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      size: data['size'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'path': path,
      'name': name,
      'type': type,
      'size': size,
    };
  }
} 