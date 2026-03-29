class SystemInfo {
  final String androidVersion;
  final String sdkVersion;
  final String deviceModel;
  final String deviceManufacturer;
  final DateTime? lastSecurityUpdate;
  final bool isDeveloperModeEnabled;
  final bool isRooted;

  SystemInfo({
    required this.androidVersion,
    required this.sdkVersion,
    required this.deviceModel,
    required this.deviceManufacturer,
    this.lastSecurityUpdate,
    required this.isDeveloperModeEnabled,
    required this.isRooted,
  });

  String get securityStatus {
    if (isRooted) return 'الجهاز مُجذّر - خطر أمني';
    if (isDeveloperModeEnabled) return 'وضع المطور مفعّل';
    if (lastSecurityUpdate == null) return 'غير معروف';
    
    final daysSinceUpdate = DateTime.now().difference(lastSecurityUpdate!).inDays;
    if (daysSinceUpdate > 90) return 'تحديثات أمنية قديمة';
    if (daysSinceUpdate > 30) return 'يحتاج تحديث أمني';
    return 'آمن';
  }
}

