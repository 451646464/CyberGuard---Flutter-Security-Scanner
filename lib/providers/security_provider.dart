import 'package:flutter/foundation.dart';
import '../models/app_info.dart';
import '../models/network_info.dart';
import '../models/system_info.dart';
import '../models/security_scan.dart';
import '../models/file_info.dart';
import '../models/link_info.dart';
import '../services/security_scanner_service.dart';
import '../services/database_service.dart';

class SecurityProvider with ChangeNotifier {
  final SecurityScannerService _scanner = SecurityScannerService();
  
  bool _isScanning = false;
  bool _isScanningFiles = false;
  bool _isScanningLink = false;
  SecurityScan? _latestScan;
  List<AppInfo> _apps = [];
  NetworkInfo? _networkInfo;
  SystemInfo? _systemInfo;
  double _securityScore = 100.0;
  List<FileInfo> _scannedFiles = [];
  List<LinkInfo> _scannedLinks = [];

  bool get isScanning => _isScanning;
  bool get isScanningFiles => _isScanningFiles;
  bool get isScanningLink => _isScanningLink;
  SecurityScan? get latestScan => _latestScan;
  List<AppInfo> get apps => _apps;
  NetworkInfo? get networkInfo => _networkInfo;
  SystemInfo? get systemInfo => _systemInfo;
  double get securityScore => _securityScore;
  List<FileInfo> get scannedFiles => _scannedFiles;
  List<LinkInfo> get scannedLinks => _scannedLinks;

  List<AppInfo> get dangerousApps =>
      _apps.where((a) => a.securityLevel == AppSecurityLevel.dangerous).toList();

  List<AppInfo> get reviewApps =>
      _apps.where((a) => a.securityLevel == AppSecurityLevel.needsReview).toList();

  SecurityProvider() {
    loadLatestScan();
    loadScannedFiles();
    loadScannedLinks();
  }

  Future<void> loadLatestScan() async {
    _latestScan = await DatabaseService.instance.getLatestScan();
    if (_latestScan != null) {
      _securityScore = _latestScan!.securityScore;
    }
    notifyListeners();
  }

  Future<void> performFullScan() async {
    _isScanning = true;
    notifyListeners();

    try {
      final scan = await _scanner.performFullScan();
      _latestScan = scan;
      _securityScore = scan.securityScore;
      
      // Load apps
      _apps = await DatabaseService.instance.getAllApps();
      
      // Load network info
      _networkInfo = await _scanner.scanNetwork();
      
      // Load system info
      _systemInfo = await _scanner.scanSystem();
    } catch (e) {
      debugPrint('Scan error: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> refreshApps() async {
    _apps = await DatabaseService.instance.getAllApps();
    notifyListeners();
  }

  Future<void> refreshNetwork() async {
    _networkInfo = await _scanner.scanNetwork();
    notifyListeners();
  }

  Future<void> refreshSystem() async {
    _systemInfo = await _scanner.scanSystem();
    notifyListeners();
  }

  Future<void> scanFiles() async {
    _isScanningFiles = true;
    notifyListeners();

    try {
      _scannedFiles = await _scanner.scanFiles();
      await loadScannedFiles();
    } catch (e) {
      debugPrint('File scan error: $e');
    } finally {
      _isScanningFiles = false;
      notifyListeners();
    }
  }

  Future<void> loadScannedFiles() async {
    _scannedFiles = await DatabaseService.instance.getAllFiles();
    notifyListeners();
  }

  Future<void> scanLink(String url) async {
    _isScanningLink = true;
    notifyListeners();

    try {
      final linkInfo = await _scanner.scanLink(url);
      await loadScannedLinks();
    } catch (e) {
      debugPrint('Link scan error: $e');
    } finally {
      _isScanningLink = false;
      notifyListeners();
    }
  }

  Future<void> loadScannedLinks() async {
    _scannedLinks = await DatabaseService.instance.getAllLinks();
    notifyListeners();
  }
}

