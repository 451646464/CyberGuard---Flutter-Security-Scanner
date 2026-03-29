enum FileSecurityLevel {
  safe,
  suspicious,
  dangerous,
}

class FileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime modifiedDate;
  final FileSecurityLevel securityLevel;
  final String? threatType;
  final String? details;

  FileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.modifiedDate,
    required this.securityLevel,
    this.threatType,
    this.details,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'size': size,
      'modifiedDate': modifiedDate.toIso8601String(),
      'securityLevel': securityLevel.name,
      'threatType': threatType,
      'details': details,
    };
  }

  factory FileInfo.fromMap(Map<String, dynamic> map) {
    return FileInfo(
      path: map['path'],
      name: map['name'],
      size: map['size'],
      modifiedDate: DateTime.parse(map['modifiedDate']),
      securityLevel: FileSecurityLevel.values.firstWhere(
        (e) => e.name == map['securityLevel'],
        orElse: () => FileSecurityLevel.safe,
      ),
      threatType: map['threatType'],
      details: map['details'],
    );
  }
}

