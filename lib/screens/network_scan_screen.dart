import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';

class NetworkScanScreen extends StatelessWidget {
  const NetworkScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فحص الشبكة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<SecurityProvider>(context, listen: false)
                  .refreshNetwork();
            },
          ),
        ],
      ),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, _) {
          final networkInfo = provider.networkInfo;

          if (networkInfo == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.network_check, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('جارٍ فحص الشبكة...'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.refreshNetwork();
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
                // Network Status Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: networkInfo.isSecure
                            ? [Colors.green.shade600, Colors.green.shade400]
                            : [Colors.red.shade600, Colors.red.shade400],
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          networkInfo.isConnected
                              ? Icons.wifi
                              : Icons.wifi_off,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          networkInfo.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          networkInfo.statusText,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Network Details
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
                          'تفاصيل الشبكة',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Divider(),
                        _DetailRow(
                          icon: Icons.network_wifi,
                          label: 'نوع الشبكة',
                          value: networkInfo.displayName,
                        ),
                        if (networkInfo.ssid != null)
                          _DetailRow(
                            icon: Icons.router,
                            label: 'اسم الشبكة (SSID)',
                            value: networkInfo.ssid!,
                          ),
                        _DetailRow(
                          icon: Icons.security,
                          label: 'حالة الأمان',
                          value: networkInfo.isSecure ? 'آمنة' : 'غير آمنة',
                          valueColor: networkInfo.isSecure
                              ? Colors.green
                              : Colors.red,
                        ),
                        _DetailRow(
                          icon: Icons.public,
                          label: 'نوع الشبكة',
                          value: networkInfo.isPublicNetwork
                              ? 'شبكة عامة'
                              : 'شبكة خاصة',
                          valueColor: networkInfo.isPublicNetwork
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Security Recommendations
                if (!networkInfo.isSecure || networkInfo.isPublicNetwork)
                  Card(
                    elevation: 2,
                    color: Colors.orange.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.orange.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'تحذير أمني',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '• تجنب إرسال معلومات حساسة على هذه الشبكة\n'
                            '• استخدم VPN عند الاتصال بشبكات عامة\n'
                            '• تأكد من تفعيل جدار الحماية\n'
                            '• لا تقم بإجراء معاملات مالية على شبكات عامة',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
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
              color: valueColor ?? Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

