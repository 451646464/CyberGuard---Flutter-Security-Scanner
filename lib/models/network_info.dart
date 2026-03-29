enum NetworkType {
  wifi,
  mobile,
  none,
}

class NetworkInfo {
  final NetworkType type;
  final bool isConnected;
  final bool isSecure;
  final String? ssid;
  final bool isPublicNetwork;

  NetworkInfo({
    required this.type,
    required this.isConnected,
    required this.isSecure,
    this.ssid,
    required this.isPublicNetwork,
  });

  String get displayName {
    switch (type) {
      case NetworkType.wifi:
        return 'WiFi';
      case NetworkType.mobile:
        return 'شبكة محمولة';
      case NetworkType.none:
        return 'غير متصل';
    }
  }

  String get statusText {
    if (!isConnected) return 'غير متصل';
    if (isPublicNetwork) return 'شبكة عامة - غير آمنة';
    if (!isSecure) return 'شبكة غير آمنة';
    return 'شبكة آمنة';
  }
}

