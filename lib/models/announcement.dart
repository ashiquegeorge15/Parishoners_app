class AnnouncementAttachment {
  final String fileType;
  final String downloadURL;
  final String fileName;
  final int fileSize;

  AnnouncementAttachment({
    required this.fileType,
    required this.downloadURL,
    required this.fileName,
    required this.fileSize,
  });

  factory AnnouncementAttachment.fromMap(Map<String, dynamic> map) {
    return AnnouncementAttachment(
      fileType: map['fileType'] ?? '',
      downloadURL: map['downloadURL'] ?? '',
      fileName: map['fileName'] ?? '',
      fileSize: map['fileSize'] ?? 0,
    );
  }

  bool get isImage => fileType.startsWith('image/');
  bool get isPdf => fileType == 'application/pdf';
  
  String get fileSizeFormatted {
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).round()} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

class Announcement {
  final String id;
  final String title;
  final String body;
  final String date; // DD/MM/YYYY format
  final String time;
  final AnnouncementAttachment? attachment;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.time,
    this.attachment,
  });

  factory Announcement.fromMap(String id, Map<String, dynamic> map) {
    return Announcement(
      id: id,
      title: map['Title'] ?? '',
      body: map['Body'] ?? '',
      date: map['Date'] ?? '',
      time: map['Time'] ?? '',
      attachment: map['attachment'] != null 
          ? AnnouncementAttachment.fromMap(Map<String, dynamic>.from(map['attachment']))
          : null,
    );
  }

  String get formattedDateTime {
    // Convert from DD/MM/YYYY to more readable format
    final parts = date.split('/');
    if (parts.length != 3) return '$date at $time';
    
    final day = parts[0];
    final month = parts[1];
    final year = parts[2];
    
    // Convert month number to month name
    const monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    
    final monthIndex = int.tryParse(month);
    if (monthIndex == null || monthIndex < 1 || monthIndex > 12) {
      return '$date at $time';
    }
    
    final monthName = monthNames[monthIndex - 1];
    return '$monthName $day, $year at $time';
  }

  DateTime get dateTimeForSorting {
    try {
      final parts = date.split('/');
      if (parts.length != 3) return DateTime.now();
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      // Parse time (assuming HH:MM format)
      final timeParts = time.split(':');
      int hour = 0;
      int minute = 0;
      if (timeParts.length >= 2) {
        hour = int.tryParse(timeParts[0]) ?? 0;
        minute = int.tryParse(timeParts[1]) ?? 0;
      }
      
      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      return DateTime.now();
    }
  }
} 