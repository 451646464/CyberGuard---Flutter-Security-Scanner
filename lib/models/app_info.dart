enum AppSecurityLevel {
  safe,
  needsReview,
  dangerous,
}

enum InstallSource {
  playStore,
  unknown,
  other,
}

class AppInfo {
  final String packageName;
  final String appName;
  final String version;
  final int versionCode;
  final AppSecurityLevel securityLevel;
  final List<String> dangerousPermissions;
  final bool isSystemApp;
  final DateTime installDate;
  final DateTime lastUpdateDate;
  final InstallSource installSource;

  AppInfo({
    required this.packageName,
    required this.appName,
    required this.version,
    required this.versionCode,
    required this.securityLevel,
    required this.dangerousPermissions,
    required this.isSystemApp,
    required this.installDate,
    required this.lastUpdateDate,
    this.installSource = InstallSource.other,
  });

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'version': version,
      'versionCode': versionCode,
      'securityLevel': securityLevel.name,
      'dangerousPermissions': dangerousPermissions.join(','),
      'isSystemApp': isSystemApp ? 1 : 0,
      'installDate': installDate.toIso8601String(),
      'lastUpdateDate': lastUpdateDate.toIso8601String(),
      'installSource': installSource.name,
    };
  }

  factory AppInfo.fromMap(Map<String, dynamic> map) {
    return AppInfo(
      packageName: map['packageName'],
      appName: map['appName'],
      version: map['version'],
      versionCode: map['versionCode'],
      securityLevel: AppSecurityLevel.values.firstWhere(
        (e) => e.name == map['securityLevel'],
        orElse: () => AppSecurityLevel.safe,
      ),
      dangerousPermissions: (map['dangerousPermissions'] as String?)
              ?.split(',')
              .where((p) => p.isNotEmpty)
              .toList() ??
          [],
      isSystemApp: map['isSystemApp'] == 1,
      installDate: DateTime.parse(map['installDate']),
      lastUpdateDate: DateTime.parse(map['lastUpdateDate']),
      installSource: map['installSource'] != null
          ? InstallSource.values.firstWhere(
              (e) => e.name == map['installSource'],
              orElse: () => InstallSource.other,
            )
          : InstallSource.other,
    );
  }
}

