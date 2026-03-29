import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import '../models/app_info.dart';
import '../models/network_info.dart';
import '../models/system_info.dart';
import '../models/security_scan.dart';
import '../models/file_info.dart';
import '../models/link_info.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/permission_utils.dart';

class SecurityScannerService {
  static const MethodChannel _channel = MethodChannel('secyrity/scanner');
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Connectivity _connectivity = Connectivity();

  // Dangerous permissions list
  static const List<String> dangerousPermissions = [
    'android.permission.READ_SMS',
    'android.permission.SEND_SMS',
    'android.permission.READ_PHONE_STATE',
    'android.permission.CALL_PHONE',
    'android.permission.READ_CONTACTS',
    'android.permission.WRITE_CONTACTS',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO',
    'android.permission.READ_EXTERNAL_STORAGE',
    'android.permission.WRITE_EXTERNAL_STORAGE',
    'android.permission.READ_CALENDAR',
    'android.permission.WRITE_CALENDAR',
  ];

  Future<List<AppInfo>> scanInstalledApps() async {
    try {
      final List<dynamic> appsData = await _channel.invokeMethod('getInstalledApps');
      debugPrint('Found ${appsData.length} installed apps');
      
      if (appsData.isEmpty) {
        debugPrint('No apps found - this might be a permission issue');
        return [];
      }
      
      final List<AppInfo> apps = [];

      for (var appData in appsData) {
        try {
          final installSourceStr = appData['installSource'] ?? 'other';
          final installSource = InstallSource.values.firstWhere(
            (e) => e.name == installSourceStr,
            orElse: () => InstallSource.other,
          );
          
          final app = AppInfo(
            packageName: appData['packageName'] ?? '',
            appName: appData['appName'] ?? 'Unknown',
            version: appData['version'] ?? '0.0.0',
            versionCode: appData['versionCode'] ?? 0,
            securityLevel: _determineSecurityLevel(appData, installSource),
            dangerousPermissions: _extractDangerousPermissions(appData),
            isSystemApp: appData['isSystemApp'] ?? false,
            installSource: installSource,
            installDate: DateTime.fromMillisecondsSinceEpoch(
              appData['installDate'] ?? DateTime.now().millisecondsSinceEpoch,
            ),
            lastUpdateDate: DateTime.fromMillisecondsSinceEpoch(
              appData['lastUpdateDate'] ?? DateTime.now().millisecondsSinceEpoch,
            ),
          );
          apps.add(app);
        } catch (e) {
          debugPrint('Error processing app: $e');
          continue;
        }
      }

      debugPrint('Successfully processed ${apps.length} apps');
      
      // Save apps to database
      await DatabaseService.instance.saveApps(apps);

      return apps;
    } catch (e) {
      debugPrint('Error scanning installed apps: $e');
      // Fallback: return empty list if native method fails
      return [];
    }
  }

  AppSecurityLevel _determineSecurityLevel(Map<dynamic, dynamic> appData, InstallSource installSource) {
    final permissions = _extractDangerousPermissions(appData);
    final isSystemApp = appData['isSystemApp'] ?? false;
    
    // Check for unknown source installation - this is a major security risk
    if (installSource == InstallSource.unknown && !isSystemApp) {
      return AppSecurityLevel.dangerous;
    }
    
    // Check for too many dangerous permissions
    if (permissions.length >= 5) {
      return AppSecurityLevel.dangerous;
    }
    
    // Check for critical permissions combination
    final hasLocation = permissions.contains('android.permission.ACCESS_FINE_LOCATION') ||
        permissions.contains('android.permission.ACCESS_COARSE_LOCATION');
    final hasSMS = permissions.contains('android.permission.READ_SMS') ||
        permissions.contains('android.permission.SEND_SMS');
    final hasContacts = permissions.contains('android.permission.READ_CONTACTS');
    
    if ((hasLocation && hasSMS) || (hasSMS && hasContacts)) {
      return AppSecurityLevel.dangerous;
    }
    
    // Check for suspicious permissions with unknown source
    if (permissions.isNotEmpty && installSource == InstallSource.unknown) {
      return AppSecurityLevel.dangerous;
    }
    
    // Check for suspicious permissions
    if (permissions.isNotEmpty && !isSystemApp) {
      return AppSecurityLevel.needsReview;
    }
    
    return AppSecurityLevel.safe;
  }

  List<String> _extractDangerousPermissions(Map<dynamic, dynamic> appData) {
    final List<dynamic> permissions = appData['permissions'] ?? [];
    return permissions
        .where((p) => dangerousPermissions.contains(p))
        .cast<String>()
        .toList();
  }

  Future<NetworkInfo> scanNetwork() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isConnected = connectivityResult != ConnectivityResult.none;
      
      NetworkType type;
      bool isSecure = true;
      bool isPublicNetwork = false;
      String? ssid;

      if (connectivityResult == ConnectivityResult.wifi) {
        type = NetworkType.wifi;
        // Try to get WiFi info
        try {
          final wifiInfo = await _channel.invokeMethod('getWifiInfo');
          ssid = wifiInfo['ssid'];
          isPublicNetwork = wifiInfo['isPublic'] ?? false;
          isSecure = !isPublicNetwork && (wifiInfo['isSecure'] ?? true);
        } catch (e) {
          // If we can't determine, assume it might be insecure
          isSecure = false;
        }
      } else if (connectivityResult == ConnectivityResult.mobile) {
        type = NetworkType.mobile;
        isSecure = true; // Mobile networks are generally secure
      } else {
        type = NetworkType.none;
        isSecure = false;
      }

      return NetworkInfo(
        type: type,
        isConnected: isConnected,
        isSecure: isSecure,
        ssid: ssid,
        isPublicNetwork: isPublicNetwork,
      );
    } catch (e) {
      return NetworkInfo(
        type: NetworkType.none,
        isConnected: false,
        isSecure: false,
        isPublicNetwork: false,
      );
    }
  }

  Future<SystemInfo> scanSystem() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      
      // Check developer mode
      bool isDeveloperModeEnabled = false;
      try {
        isDeveloperModeEnabled = await _channel.invokeMethod('isDeveloperModeEnabled') ?? false;
      } catch (e) {
        // Fallback
      }

      // Check if device is rooted
      bool isRooted = false;
      try {
        isRooted = await _channel.invokeMethod('isDeviceRooted') ?? false;
      } catch (e) {
        // Check common root indicators
        isRooted = await _checkRootIndicators();
      }

      return SystemInfo(
        androidVersion: androidInfo.version.release,
        sdkVersion: androidInfo.version.sdkInt.toString(),
        deviceModel: androidInfo.model,
        deviceManufacturer: androidInfo.manufacturer,
        lastSecurityUpdate: androidInfo.version.securityPatch != null
            ? DateTime.tryParse(androidInfo.version.securityPatch!)
            : null,
        isDeveloperModeEnabled: isDeveloperModeEnabled,
        isRooted: isRooted,
      );
    } catch (e) {
      return SystemInfo(
        androidVersion: 'Unknown',
        sdkVersion: '0',
        deviceModel: 'Unknown',
        deviceManufacturer: 'Unknown',
        isDeveloperModeEnabled: false,
        isRooted: false,
      );
    }
  }

  Future<bool> _checkRootIndicators() async {
    // Check for common root files
    final rootFiles = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
    ];

    for (var file in rootFiles) {
      if (await File(file).exists()) {
        return true;
      }
    }
    return false;
  }

  Future<SecurityScan> performFullScan() async {
    // Scan all components
    final apps = await scanInstalledApps();
    final networkInfo = await scanNetwork();
    final systemInfo = await scanSystem();

    // Calculate security score
    double securityScore = 100.0;

    // Deduct points for dangerous apps
    final dangerousApps = apps.where((a) => a.securityLevel == AppSecurityLevel.dangerous).toList();
    securityScore -= dangerousApps.length * 5.0;

    // Deduct points for apps needing review
    final reviewApps = apps.where((a) => a.securityLevel == AppSecurityLevel.needsReview).toList();
    securityScore -= reviewApps.length * 2.0;

    // Deduct points for insecure network
    if (!networkInfo.isSecure || networkInfo.isPublicNetwork) {
      securityScore -= 10.0;
    }

    // Deduct points for developer mode
    if (systemInfo.isDeveloperModeEnabled) {
      securityScore -= 5.0;
    }

    // Deduct points for rooted device
    if (systemInfo.isRooted) {
      securityScore -= 20.0;
    }

    // Deduct points for outdated security patch
    if (systemInfo.lastSecurityUpdate != null) {
      final daysSinceUpdate = DateTime.now().difference(systemInfo.lastSecurityUpdate!).inDays;
      if (daysSinceUpdate > 90) {
        securityScore -= 15.0;
      } else if (daysSinceUpdate > 30) {
        securityScore -= 5.0;
      }
    }

    // Ensure score is between 0 and 100
    securityScore = securityScore.clamp(0.0, 100.0);

    // Create scan result
    final scan = SecurityScan(
      securityScore: securityScore,
      dangerousAppsCount: dangerousApps.length,
      networkStatus: networkInfo.statusText,
      isNetworkSecure: networkInfo.isSecure,
      androidVersion: systemInfo.androidVersion,
      isDeveloperModeEnabled: systemInfo.isDeveloperModeEnabled,
      scanDate: DateTime.now(),
      details: {
        'totalApps': apps.length,
        'dangerousApps': dangerousApps.length,
        'reviewApps': reviewApps.length,
        'networkType': networkInfo.displayName,
        'isRooted': systemInfo.isRooted,
      },
    );

    // Save scan to database
    await DatabaseService.instance.saveSecurityScan(scan);

    // Send notifications for critical issues
    if (dangerousApps.isNotEmpty) {
      await NotificationService.instance.showSecurityAlert(
        title: '⚠️ تطبيقات خطيرة',
        message: 'تم اكتشاف ${dangerousApps.length} تطبيق خطير',
      );
      await DatabaseService.instance.saveNotification(
        title: 'تطبيقات خطيرة',
        message: 'تم اكتشاف ${dangerousApps.length} تطبيق خطير يحتاج مراجعة',
        type: 'dangerous_apps',
      );
    }

    if (!networkInfo.isSecure || networkInfo.isPublicNetwork) {
      await NotificationService.instance.showSecurityAlert(
        title: '📡 شبكة غير آمنة',
        message: 'الشبكة الحالية غير آمنة',
      );
      await DatabaseService.instance.saveNotification(
        title: 'شبكة غير آمنة',
        message: 'الشبكة المتصلة بها غير آمنة أو عامة',
        type: 'network',
      );
    }

    if (systemInfo.isRooted) {
      await NotificationService.instance.showSecurityAlert(
        title: '🔓 جهاز مُجذّر',
        message: 'الجهاز مُجذّر - خطر أمني عالي',
      );
      await DatabaseService.instance.saveNotification(
        title: 'جهاز مُجذّر',
        message: 'الجهاز مُجذّر مما يشكل خطر أمني عالي',
        type: 'system',
      );
    }

    return scan;
  }

  Future<List<FileInfo>> scanFiles() async {
    try {
      debugPrint('Starting file scan...');
      final List<dynamic> filesData = await _channel.invokeMethod('scanFiles');
      debugPrint('Found ${filesData.length} files');
      
      if (filesData.isEmpty) {
        debugPrint('No files found - this might be a permission issue');
        return [];
      }
      
      final List<FileInfo> files = [];

      for (var fileData in filesData) {
        try {
          final securityLevelStr = fileData['securityLevel'] ?? 'safe';
          final securityLevel = FileSecurityLevel.values.firstWhere(
            (e) => e.name == securityLevelStr,
            orElse: () => FileSecurityLevel.safe,
          );

          final file = FileInfo(
            path: fileData['path'] ?? '',
            name: fileData['name'] ?? 'Unknown',
            size: fileData['size'] ?? 0,
            modifiedDate: DateTime.fromMillisecondsSinceEpoch(
              fileData['modifiedDate'] ?? DateTime.now().millisecondsSinceEpoch,
            ),
            securityLevel: securityLevel,
            threatType: fileData['threatType'],
            details: fileData['details'],
          );
          files.add(file);
        } catch (e) {
          debugPrint('Error processing file: $e');
          continue;
        }
      }

      debugPrint('Successfully processed ${files.length} files');
      
      // Save files to database
      await DatabaseService.instance.saveFiles(files);

      return files;
    } catch (e) {
      debugPrint('File scan error: $e');
      return [];
    }
  }

  Future<LinkInfo> scanLink(String url) async {
    try {
      // Validate URL format
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        return LinkInfo(
          url: url,
          securityLevel: LinkSecurityLevel.unknown,
          scanDate: DateTime.now(),
          isValidUrl: false,
          details: 'رابط غير صحيح',
        );
      }

      // Check for suspicious patterns
      final lowerUrl = url.toLowerCase();
      bool isSuspicious = false;
      bool isDangerous = false;
      String? threatType;
      String? details;

      // Dangerous patterns
      final dangerousPatterns = [
        'phishing',
        'malware',
        'virus',
        'trojan',
        'hack',
        'steal',
        'scam',
        'fraud',
      ];

      // Suspicious patterns
      final suspiciousPatterns = [
        'bit.ly',
        'tinyurl',
        'short.link',
        'redirect',
        'free',
        'prize',
        'winner',
        'click.here',
      ];

      // Check for dangerous patterns
      for (var pattern in dangerousPatterns) {
        if (lowerUrl.contains(pattern)) {
          isDangerous = true;
          threatType = 'dangerous_keywords';
          details = 'يحتوي الرابط على كلمات خطيرة';
          break;
        }
      }

      // Check for suspicious patterns
      if (!isDangerous) {
        for (var pattern in suspiciousPatterns) {
          if (lowerUrl.contains(pattern)) {
            isSuspicious = true;
            threatType = 'suspicious_pattern';
            details = 'نمط مشبوه في الرابط';
            break;
          }
        }
      }

      // Check for HTTP (insecure)
      if (uri.scheme == 'http' && !isDangerous) {
        isSuspicious = true;
        if (threatType == null) {
          threatType = 'insecure_protocol';
          details = 'رابط غير آمن (HTTP)';
        }
      }

      // Check domain reputation (simplified - in production use a real API)
      final host = uri.host.toLowerCase();
      final knownSafeDomains = [
        'google.com',
        'youtube.com',
        'facebook.com',
        'twitter.com',
        'instagram.com',
        'github.com',
        'stackoverflow.com',
      ];

      final knownDangerousDomains = [
        'malware.com',
        'virus.com',
        'phishing.com',
      ];

      if (knownDangerousDomains.any((domain) => host.contains(domain))) {
        isDangerous = true;
        threatType = 'known_dangerous_domain';
        details = 'نطاق معروف بالخطر';
      } else if (!knownSafeDomains.any((domain) => host.contains(domain)) && !isSuspicious) {
        // Unknown domain - mark as suspicious
        isSuspicious = true;
        if (threatType == null) {
          threatType = 'unknown_domain';
          details = 'نطاق غير معروف';
        }
      }

      final securityLevel = isDangerous
          ? LinkSecurityLevel.dangerous
          : isSuspicious
              ? LinkSecurityLevel.suspicious
              : LinkSecurityLevel.safe;

      final linkInfo = LinkInfo(
        url: url,
        securityLevel: securityLevel,
        threatType: threatType,
        details: details,
        scanDate: DateTime.now(),
        isValidUrl: true,
      );

      // Save link to database
      await DatabaseService.instance.saveLink(linkInfo);

      return linkInfo;
    } catch (e) {
      debugPrint('Link scan error: $e');
      return LinkInfo(
        url: url,
        securityLevel: LinkSecurityLevel.unknown,
        scanDate: DateTime.now(),
        isValidUrl: false,
        details: 'خطأ في فحص الرابط: $e',
      );
    }
  }
}

