package com.example.secyrity

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "secyrity/scanner"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    try {
                        val apps = getInstalledApps()
                        result.success(apps)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get apps: ${e.message}", null)
                    }
                }
                "getWifiInfo" -> {
                    try {
                        val wifiInfo = getWifiInfo()
                        result.success(wifiInfo)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get WiFi info: ${e.message}", null)
                    }
                }
                "isDeveloperModeEnabled" -> {
                    try {
                        val isEnabled = isDeveloperModeEnabled()
                        result.success(isEnabled)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to check developer mode: ${e.message}", null)
                    }
                }
                "isDeviceRooted" -> {
                    try {
                        val isRooted = isDeviceRooted()
                        result.success(isRooted)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to check root: ${e.message}", null)
                    }
                }
                "scanFiles" -> {
                    try {
                        val files = scanFiles()
                        result.success(files)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to scan files: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val packageManager = applicationContext.packageManager
        val packages = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getInstalledPackages(PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getInstalledPackages(0)
            }
        } catch (e: Exception) {
            return emptyList()
        }

        val apps = mutableListOf<Map<String, Any>>()

        for (packageInfo in packages) {
            try {
                val appInfo = packageInfo.applicationInfo
                val appName = packageManager.getApplicationLabel(appInfo).toString()

                // Get permissions
                val permissions = mutableListOf<String>()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    val requestedPermissions = packageInfo.requestedPermissions
                    if (requestedPermissions != null) {
                        permissions.addAll(requestedPermissions)
                    }
                } else {
                    @Suppress("DEPRECATION")
                    val requestedPermissions = packageInfo.requestedPermissions
                    if (requestedPermissions != null) {
                        permissions.addAll(requestedPermissions)
                    }
                }

                // Get installation source
                var installSource = "other"
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        val installerPackageName = packageManager.getInstallSourceInfo(packageInfo.packageName).installingPackageName
                        installSource = when {
                            installerPackageName == null || installerPackageName.isEmpty() -> "unknown" // ✅ تم التصحيح
                            installerPackageName == "com.android.vending" || installerPackageName.contains("play") -> "playStore"
                            else -> "other"
                        }
                    } else {
                        @Suppress("DEPRECATION")
                        val installerPackageName = packageManager.getInstallerPackageName(packageInfo.packageName)
                        installSource = when {
                            installerPackageName == null || installerPackageName.isEmpty() -> "unknown" // ✅ تم التصحيح
                            installerPackageName == "com.android.vending" || installerPackageName.contains("play") -> "playStore"
                            else -> "other"
                        }
                    }
                } catch (e: Exception) {
                    installSource = "unknown"
                }

                val app = mapOf(
                    "packageName" to packageInfo.packageName,
                    "appName" to appName,
                    "version" to (packageInfo.versionName ?: "0.0.0"),
                    "versionCode" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        packageInfo.longVersionCode
                    } else {
                        @Suppress("DEPRECATION")
                        packageInfo.versionCode.toLong()
                    }),
                    "permissions" to permissions,
                    "isSystemApp" to ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0),
                    "installSource" to installSource,
                    "installDate" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        packageManager.getPackageInfo(
                            packageInfo.packageName,
                            PackageManager.PackageInfoFlags.of(0)
                        ).firstInstallTime
                    } else {
                        @Suppress("DEPRECATION")
                        packageManager.getPackageInfo(
                            packageInfo.packageName,
                            0
                        ).firstInstallTime
                    }),
                    "lastUpdateDate" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        packageManager.getPackageInfo(
                            packageInfo.packageName,
                            PackageManager.PackageInfoFlags.of(0)
                        ).lastUpdateTime
                    } else {
                        @Suppress("DEPRECATION")
                        packageManager.getPackageInfo(
                            packageInfo.packageName,
                            0
                        ).lastUpdateTime
                    })
                )
                apps.add(app)
            } catch (e: Exception) {
                // Skip apps that can't be accessed
                continue
            }
        }

        return apps
    }

    private fun getWifiInfo(): Map<String, Any> {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val wifiInfo: WifiInfo? = wifiManager.connectionInfo

        val ssid = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            wifiInfo?.ssid?.replace("\"", "") ?: "Unknown"
        } else {
            @Suppress("DEPRECATION")
            wifiInfo?.ssid?.replace("\"", "") ?: "Unknown"
        }

        // Check if network is secure (simplified check)
        val isSecure = wifiInfo != null && wifiManager.isWifiEnabled

        // Check if it's a public network (simplified - in production, use more sophisticated methods)
        val isPublic = ssid.contains("Public") || ssid.contains("Guest") ||
                ssid.contains("Free") || ssid.contains("WiFi")

        return mapOf(
            "ssid" to ssid,
            "isSecure" to isSecure,
            "isPublic" to isPublic
        )
    }

    private fun isDeveloperModeEnabled(): Boolean {
        return Settings.Global.getInt(
            applicationContext.contentResolver,
            Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
            0
        ) != 0
    }

    private fun isDeviceRooted(): Boolean {
        // Check for common root indicators
        val rootPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )

        for (path in rootPaths) {
            if (File(path).exists()) {
                return true
            }
        }

        // Check for su command availability
        try {
            val process = Runtime.getRuntime().exec("su")
            process.destroy()
            return true
        } catch (e: Exception) {
            // Not rooted
        }

        return false
    }

    private fun scanFiles(): List<Map<String, Any>> {
        val files = mutableListOf<Map<String, Any>>()
        val suspiciousExtensions = listOf(".exe", ".bat", ".cmd", ".com", ".pif", ".scr", ".vbs", ".js", ".jar", ".apk", ".sh", ".bin")
        val dangerousExtensions = listOf(".exe", ".bat", ".cmd", ".scr", ".vbs", ".sh")

        try {
            // Get external storage directory
            val externalStorageDir = Environment.getExternalStorageDirectory()

            // Scan all accessible directories
            val directoriesToScan = mutableListOf<File>()

            // Add external storage directories
            if (externalStorageDir != null && externalStorageDir.exists()) {
                directoriesToScan.add(externalStorageDir)
            }

            // Add common storage paths
            val storagePaths = listOf(
                "/storage/emulated/0",
                "/sdcard",
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)?.absolutePath,
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM)?.absolutePath,
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)?.absolutePath,
            )

            for (path in storagePaths) {
                if (path != null) {
                    val dir = File(path)
                    if (dir.exists() && dir.isDirectory && dir.canRead()) {
                        directoriesToScan.add(dir)
                    }
                }
            }

            // Add specific common directories
            val commonDirs = listOf(
                "Download", "Downloads", "Documents", "DCIM", "Pictures", "Music", "Movies"
            )

            for (baseDir in directoriesToScan) {
                // Scan common subdirectories
                for (commonDir in commonDirs) {
                    val dir = File(baseDir, commonDir)
                    if (dir.exists() && dir.isDirectory && dir.canRead()) {
                        try {
                            scanDirectory(dir, files, suspiciousExtensions, dangerousExtensions, 0, 3)
                        } catch (e: Exception) {
                            // Skip directories that can't be accessed
                        }
                    }
                }

                // Also scan the base directory itself (limited depth)
                try {
                    if (baseDir.canRead()) {
                        scanDirectory(baseDir, files, suspiciousExtensions, dangerousExtensions, 0, 2)
                    }
                } catch (e: Exception) {
                    // Skip if can't access
                }
            }
        } catch (e: Exception) {
            // Return empty list if scanning fails
        }

        return files
    }

    private fun scanDirectory(
        directory: File,
        files: MutableList<Map<String, Any>>,
        suspiciousExtensions: List<String>,
        dangerousExtensions: List<String>,
        depth: Int,
        maxDepth: Int
    ) {
        if (depth > maxDepth) return

        try {
            val fileList = directory.listFiles() ?: return

            for (file in fileList) {
                if (file.isDirectory) {
                    scanDirectory(file, files, suspiciousExtensions, dangerousExtensions, depth + 1, maxDepth)
                } else {
                    val fileName = file.name.lowercase()
                    val extension = if (fileName.contains(".")) {
                        fileName.substring(fileName.lastIndexOf("."))
                    } else {
                        ""
                    }

                    var securityLevel = "safe"
                    var threatType: String? = null
                    var details: String? = null

                    when {
                        dangerousExtensions.contains(extension) -> {
                            securityLevel = "dangerous"
                            threatType = "dangerous_file_type"
                            details = "ملف من نوع خطير: $extension"
                        }
                        suspiciousExtensions.contains(extension) -> {
                            securityLevel = "suspicious"
                            threatType = "suspicious_file_type"
                            details = "ملف مشبوه: $extension"
                        }
                        file.length() == 0L -> {
                            securityLevel = "suspicious"
                            threatType = "empty_file"
                            details = "ملف فارغ"
                        }
                        fileName.contains("virus") || fileName.contains("malware") ||
                                fileName.contains("trojan") || fileName.contains("hack") -> {
                            securityLevel = "dangerous"
                            threatType = "suspicious_name"
                            details = "اسم ملف مشبوه"
                        }
                    }

                    files.add(mapOf(
                        "path" to file.absolutePath,
                        "name" to file.name,
                        "size" to file.length(),
                        "modifiedDate" to file.lastModified(),
                        "securityLevel" to securityLevel,
                        "threatType" to (threatType ?: ""),
                        "details" to (details ?: "")
                    ))
                }
            }
        } catch (e: Exception) {
            // Skip files that can't be accessed
        }
    }
}