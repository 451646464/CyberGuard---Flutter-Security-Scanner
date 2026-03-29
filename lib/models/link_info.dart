enum LinkSecurityLevel {
  safe,
  suspicious,
  dangerous,
  unknown,
}

class LinkInfo {
  final String url;
  final LinkSecurityLevel securityLevel;
  final String? threatType;
  final String? details;
  final DateTime scanDate;
  final bool isValidUrl;

  LinkInfo({
    required this.url,
    required this.securityLevel,
    this.threatType,
    this.details,
    required this.scanDate,
    required this.isValidUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'securityLevel': securityLevel.name,
      'threatType': threatType,
      'details': details,
      'scanDate': scanDate.toIso8601String(),
      'isValidUrl': isValidUrl ? 1 : 0,
    };
  }

  factory LinkInfo.fromMap(Map<String, dynamic> map) {
    return LinkInfo(
      url: map['url'],
      securityLevel: LinkSecurityLevel.values.firstWhere(
        (e) => e.name == map['securityLevel'],
        orElse: () => LinkSecurityLevel.unknown,
      ),
      threatType: map['threatType'],
      details: map['details'],
      scanDate: DateTime.parse(map['scanDate']),
      isValidUrl: map['isValidUrl'] == 1,
    );
  }
}

