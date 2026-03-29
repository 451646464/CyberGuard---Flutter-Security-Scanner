import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/security_scan.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'week'; // week, month, all
  List<SecurityScan> _scans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    setState(() => _isLoading = true);

    DateTime startDate;
    final endDate = DateTime.now();

    switch (_selectedPeriod) {
      case 'week':
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = endDate.subtract(const Duration(days: 30));
        break;
      default:
        startDate = DateTime(2020);
        break;
    }

    final scans = await DatabaseService.instance.getScansByDateRange(
      startDate,
      endDate,
    );

    setState(() {
      _scans = scans;
      _isLoading = false;
    });
  }

  // تمت إزالة didUpdateWidget لأنها تسبب خطأ وليست ضرورية في هذا السياق.

  double _getAverageScore() {
    if (_scans.isEmpty) return 0;
    final sum = _scans.fold<double>(
      0,
          (sum, scan) => sum + scan.securityScore,
    );
    return sum / _scans.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScans,
          ),
        ],
      ),
      body: Column(
        children: [
          // Period Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PeriodChip(
                  label: 'أسبوع',
                  value: 'week',
                  selected: _selectedPeriod == 'week',
                  onTap: () => setState(() {
                    _selectedPeriod = 'week';
                    _loadScans();
                  }),
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'شهر',
                  value: 'month',
                  selected: _selectedPeriod == 'month',
                  onTap: () => setState(() {
                    _selectedPeriod = 'month';
                    _loadScans();
                  }),
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'الكل',
                  value: 'all',
                  selected: _selectedPeriod == 'all',
                  onTap: () => setState(() {
                    _selectedPeriod = 'all';
                    _loadScans();
                  }),
                ),
              ],
            ),
          ),
          const Divider(),

          // Statistics
          if (!_isLoading && _scans.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'إحصائيات',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: 'متوسط الأمان',
                            value: '${_getAverageScore().toStringAsFixed(1)}%',
                            icon: Icons.security,
                            color: Colors.blue,
                          ),
                          _StatItem(
                            label: 'عدد الفحوصات',
                            value: _scans.length.toString(),
                            icon: Icons.assessment,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Charts and List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _scans.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assessment,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('لا توجد تقارير في هذه الفترة'),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _scans.length,
              itemBuilder: (context, index) {
                final scan = _scans[index];
                return _ScanCard(scan: scan);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ScanCard extends StatelessWidget {
  final SecurityScan scan;

  const _ScanCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    Color scoreColor;
    if (scan.securityScore >= 80) {
      scoreColor = Colors.green;
    } else if (scan.securityScore >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(scan.scanDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${scan.securityScore.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: scan.securityScore / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.warning,
                  label: '${scan.dangerousAppsCount} تطبيق خطير',
                  color: Colors.red,
                ),
                _InfoChip(
                  icon: Icons.network_wifi,
                  label: scan.networkStatus,
                  color: scan.isNetworkSecure ? Colors.green : Colors.orange,
                ),
                if (scan.isDeveloperModeEnabled)
                  _InfoChip(
                    icon: Icons.developer_mode,
                    label: 'وضع المطور',
                    color: Colors.orange,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(fontSize: 12, color: color),
      ),
      backgroundColor: color.withOpacity(0.1),
    );
  }
}