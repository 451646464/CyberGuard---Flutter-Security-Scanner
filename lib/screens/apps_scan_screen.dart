import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/security_provider.dart';
import '../models/app_info.dart';

class AppsScanScreen extends StatefulWidget {
  const AppsScanScreen({super.key});

  @override
  State<AppsScanScreen> createState() => _AppsScanScreenState();
}

class _AppsScanScreenState extends State<AppsScanScreen> {
  String _filter = 'all'; // all, safe, review, dangerous

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsAndScan();
    });
  }

  Future<void> _requestPermissionsAndScan() async {
    // Request phone permission for getting installed apps
    if (await Permission.phone.isDenied) {
      final status = await Permission.phone.request();
      if (status.isDenied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يجب منح صلاحيات الوصول للمعلومات لفحص التطبيقات'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }
    
    // Start scanning
    if (context.mounted) {
      final provider = Provider.of<SecurityProvider>(context, listen: false);
      if (provider.apps.isEmpty) {
        await provider.performFullScan();
      } else {
        await provider.refreshApps();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فحص التطبيقات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _requestPermissionsAndScan();
            },
          ),
        ],
      ),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, _) {
          if (provider.apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.apps, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('لا توجد تطبيقات'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _requestPermissionsAndScan();
                    },
                    child: const Text('بدء الفحص'),
                  ),
                ],
              ),
            );
          }

          final filteredApps = _getFilteredApps(provider.apps);
          
          // Calculate statistics
          final totalApps = provider.apps.length;
          final safeApps = provider.apps
              .where((a) => a.securityLevel == AppSecurityLevel.safe)
              .length;
          final reviewApps = provider.apps
              .where((a) => a.securityLevel == AppSecurityLevel.needsReview)
              .length;
          final dangerousApps = provider.dangerousApps.length;
          final unknownSourceApps = provider.apps
              .where((a) => a.installSource == InstallSource.unknown)
              .length;

          return Column(
            children: [
              // Statistics Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'إحصائيات التطبيقات',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            label: 'إجمالي التطبيقات',
                            value: totalApps.toString(),
                            color: Colors.blue,
                            icon: Icons.apps,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            label: 'آمنة',
                            value: safeApps.toString(),
                            color: Colors.green,
                            icon: Icons.check_circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            label: 'تحتاج مراجعة',
                            value: reviewApps.toString(),
                            color: Colors.orange,
                            icon: Icons.warning,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            label: 'خطيرة',
                            value: dangerousApps.toString(),
                            color: Colors.red,
                            icon: Icons.dangerous,
                          ),
                        ),
                      ],
                    ),
                    if (unknownSourceApps > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'تطبيقات من مصادر غير معروفة: $unknownSourceApps',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Filter Chips
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'الكل',
                        count: provider.apps.length,
                        isSelected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'آمن',
                        count: provider.apps
                            .where((a) => a.securityLevel == AppSecurityLevel.safe)
                            .length,
                        isSelected: _filter == 'safe',
                        color: Colors.green,
                        onTap: () => setState(() => _filter = 'safe'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'يحتاج مراجعة',
                        count: provider.apps
                            .where((a) =>
                                a.securityLevel == AppSecurityLevel.needsReview)
                            .length,
                        isSelected: _filter == 'review',
                        color: Colors.orange,
                        onTap: () => setState(() => _filter = 'review'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'خطير',
                        count: provider.dangerousApps.length,
                        isSelected: _filter == 'dangerous',
                        color: Colors.red,
                        onTap: () => setState(() => _filter = 'dangerous'),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              
              // Apps List
              Expanded(
                child: ListView.builder(
                  itemCount: filteredApps.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final app = filteredApps[index];
                    return _AppCard(app: app);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<AppInfo> _getFilteredApps(List<AppInfo> apps) {
    switch (_filter) {
      case 'safe':
        return apps
            .where((a) => a.securityLevel == AppSecurityLevel.safe)
            .toList();
      case 'review':
        return apps
            .where((a) => a.securityLevel == AppSecurityLevel.needsReview)
            .toList();
      case 'dangerous':
        return apps
            .where((a) => a.securityLevel == AppSecurityLevel.dangerous)
            .toList();
      default:
        return apps;
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color?.withOpacity(0.3),
      checkmarkColor: color,
    );
  }
}

class _AppCard extends StatelessWidget {
  final AppInfo app;

  const _AppCard({required this.app});

  String _getInstallSourceText(InstallSource source) {
    switch (source) {
      case InstallSource.playStore:
        return 'متجر Google Play';
      case InstallSource.unknown:
        return 'مصدر غير معروف ⚠️';
      case InstallSource.other:
        return 'مصدر آخر';
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (app.securityLevel) {
      case AppSecurityLevel.safe:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'آمن';
        break;
      case AppSecurityLevel.needsReview:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        statusText = 'يحتاج مراجعة';
        break;
      case AppSecurityLevel.dangerous:
        statusColor = Colors.red;
        statusIcon = Icons.dangerous;
        statusText = 'خطير';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          app.appName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('الإصدار: ${app.version}'),
        trailing: Chip(
          label: Text(statusText),
          backgroundColor: statusColor.withOpacity(0.2),
          labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow('اسم الحزمة', app.packageName),
                _InfoRow('رمز الإصدار', app.versionCode.toString()),
                _InfoRow('نوع التطبيق', app.isSystemApp ? 'نظام' : 'مستخدم'),
                _InfoRow('مصدر التثبيت', _getInstallSourceText(app.installSource)),
                if (app.dangerousPermissions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'الصلاحيات الخطيرة:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...app.dangerousPermissions.map((perm) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text(
                          '• ${perm.split('.').last}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

