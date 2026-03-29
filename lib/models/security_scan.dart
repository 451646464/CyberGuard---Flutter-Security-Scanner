class SecurityScan {
  final int? id;
  final double securityScore;
  final int dangerousAppsCount;
  final String networkStatus;
  final bool isNetworkSecure;
  final String androidVersion;
  final bool isDeveloperModeEnabled;
  final DateTime scanDate;
  final Map<String, dynamic> details;

  SecurityScan({
    this.id,
    required this.securityScore,
    required this.dangerousAppsCount,
    required this.networkStatus,
    required this.isNetworkSecure,
    required this.androidVersion,
    required this.isDeveloperModeEnabled,
    required this.scanDate,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'securityScore': securityScore,
      'dangerousAppsCount': dangerousAppsCount,
      'networkStatus': networkStatus,
      'isNetworkSecure': isNetworkSecure ? 1 : 0,
      'androidVersion': androidVersion,
      'isDeveloperModeEnabled': isDeveloperModeEnabled ? 1 : 0,
      'scanDate': scanDate.toIso8601String(),
      'details': details.toString(),
    };
  }

  factory SecurityScan.fromMap(Map<String, dynamic> map) {
    return SecurityScan(
      id: map['id'],
      securityScore: map['securityScore'],
      dangerousAppsCount: map['dangerousAppsCount'],
      networkStatus: map['networkStatus'],
      isNetworkSecure: map['isNetworkSecure'] == 1,
      androidVersion: map['androidVersion'],
      isDeveloperModeEnabled: map['isDeveloperModeEnabled'] == 1,
      scanDate: DateTime.parse(map['scanDate']),
      details: {},
    );
  }
}

