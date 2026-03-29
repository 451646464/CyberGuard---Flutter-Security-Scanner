import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';

class SystemScanScreen extends StatelessWidget {
  const SystemScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فحص النظام'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<SecurityProvider>(context, listen: false)
                  .refreshSystem();
            },
          ),
        ],
      ),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, _) {
          final systemInfo = provider.systemInfo;

          if (systemInfo == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_android, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('جارٍ فحص النظام...'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.refreshSystem();
                    },
                    child: const Text('فحص الآن'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Device Info Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.phone_android,
                          size: 64,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${systemInfo.deviceManufacturer} ${systemInfo.deviceModel}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // System Details
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'معلومات النظام',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        _DetailRow(
                          icon: Icons.android,
                          label: 'إصدار Android',
                          value: 'Android ${systemInfo.androidVersion}',
                        ),
                        _DetailRow(
                          icon: Icons.code,
                          label: 'إصدار SDK',
                          value: systemInfo.sdkVersion,
                        ),
                        _DetailRow(
                          icon: Icons.business,
                          label: 'الشركة المصنعة',
                          value: systemInfo.deviceManufacturer,
                        ),
                        _DetailRow(
                          icon: Icons.phone_iphone,
                          label: 'نموذج الجهاز',
                          value: systemInfo.deviceModel,
                        ),
                        if (systemInfo.lastSecurityUpdate != null)
                          _DetailRow(
                            icon: Icons.security_update,
                            label: 'آخر تحديث أمني',
                            value: _formatDate(systemInfo.lastSecurityUpdate!),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Security Status
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حالة الأمان',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        _SecurityStatusRow(
                          icon: Icons.developer_mode,
                          label: 'وضع المطور',
                          isEnabled: systemInfo.isDeveloperModeEnabled,
                          warning: systemInfo.isDeveloperModeEnabled
                              ? 'وضع المطور مفعّل - قد يشكل خطر أمني'
                              : null,
                        ),
                        _SecurityStatusRow(
                          icon: Icons.admin_panel_settings,
                          label: 'حالة الجذر',
                          isEnabled: !systemInfo.isRooted,
                          warning: systemInfo.isRooted
                              ? 'الجهاز مُجذّر - خطر أمني عالي جداً'
                              : null,
                        ),
                        if (systemInfo.lastSecurityUpdate != null)
                          _SecurityStatusRow(
                            icon: Icons.update,
                            label: 'التحديثات الأمنية',
                            isEnabled: _isSecurityUpdateRecent(
                                systemInfo.lastSecurityUpdate!),
                            warning: !_isSecurityUpdateRecent(
                                systemInfo.lastSecurityUpdate!)
                                ? 'التحديثات الأمنية قديمة - يرجى التحديث'
                                : null,
                          ),
                      ],
                    ),
                  ),
                ),

                // Warnings
                if (systemInfo.isRooted || systemInfo.isDeveloperModeEnabled)
                  const SizedBox(height: 24),
                if (systemInfo.isRooted)
                  _WarningCard(
                    icon: Icons.dangerous,
                    title: 'جهاز مُجذّر',
                    message:
                    'الجهاز مُجذّر مما يشكل خطر أمني عالي. يرجى إلغاء الجذر لتحسين الأمان.',
                    color: Colors.red,
                  ),
                if (systemInfo.isDeveloperModeEnabled)
                  _WarningCard(
                    icon: Icons.warning,
                    title: 'وضع المطور مفعّل',
                    message:
                    'وضع المطور مفعّل. يرجى إيقافه من إعدادات النظام لتحسين الأمان.',
                    color: Colors.orange,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  bool _isSecurityUpdateRecent(DateTime lastUpdate) {
    final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;
    return daysSinceUpdate <= 30;
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityStatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final String? warning;

  const _SecurityStatusRow({
    required this.icon,
    required this.label,
    required this.isEnabled,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isEnabled ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Chip(
                label: Text(isEnabled ? 'آمن' : 'غير آمن'),
                backgroundColor:
                (isEnabled ? Colors.green : Colors.red).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isEnabled ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (warning != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                warning!,
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final MaterialColor color;

  const _WarningCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: color.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(color: color.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}