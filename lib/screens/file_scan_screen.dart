import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/security_provider.dart';
import '../models/file_info.dart';
import '../utils/permission_utils.dart';

class FileScanScreen extends StatefulWidget {
  const FileScanScreen({super.key});

  @override
  State<FileScanScreen> createState() => _FileScanScreenState();
}

class _FileScanScreenState extends State<FileScanScreen> {
  String _filter = 'all'; // all, safe, suspicious, dangerous

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsAndScan();
    });
  }

  Future<void> _requestPermissionsAndScan() async {
    // Request storage permissions
    if (await Permission.storage.isDenied || 
        await Permission.manageExternalStorage.isDenied) {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يجب منح صلاحيات الوصول للملفات لفحص الملفات'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }
    
    // Start scanning
    if (context.mounted) {
      Provider.of<SecurityProvider>(context, listen: false).scanFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فحص الملفات'),
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
          if (provider.isScanningFiles) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جارٍ فحص الملفات...'),
                ],
              ),
            );
          }

          if (provider.scannedFiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد ملفات مفحوصة',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _requestPermissionsAndScan();
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('بدء فحص الملفات'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final filteredFiles = _getFilteredFiles(provider.scannedFiles);
          
          // Calculate statistics
          final totalFiles = provider.scannedFiles.length;
          final safeFiles = provider.scannedFiles
              .where((f) => f.securityLevel == FileSecurityLevel.safe)
              .length;
          final suspiciousFiles = provider.scannedFiles
              .where((f) => f.securityLevel == FileSecurityLevel.suspicious)
              .length;
          final dangerousFiles = provider.scannedFiles
              .where((f) => f.securityLevel == FileSecurityLevel.dangerous)
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
                          'إحصائيات الفحص',
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
                            label: 'إجمالي الملفات',
                            value: totalFiles.toString(),
                            color: Colors.blue,
                            icon: Icons.folder,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            label: 'آمنة',
                            value: safeFiles.toString(),
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
                            label: 'مشبوهة',
                            value: suspiciousFiles.toString(),
                            color: Colors.orange,
                            icon: Icons.warning,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            label: 'خطيرة',
                            value: dangerousFiles.toString(),
                            color: Colors.red,
                            icon: Icons.dangerous,
                          ),
                        ),
                      ],
                    ),
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
                        count: provider.scannedFiles.length,
                        isSelected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'آمن',
                        count: provider.scannedFiles
                            .where((f) => f.securityLevel == FileSecurityLevel.safe)
                            .length,
                        isSelected: _filter == 'safe',
                        color: Colors.green,
                        onTap: () => setState(() => _filter = 'safe'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'مشبوه',
                        count: provider.scannedFiles
                            .where((f) => f.securityLevel == FileSecurityLevel.suspicious)
                            .length,
                        isSelected: _filter == 'suspicious',
                        color: Colors.orange,
                        onTap: () => setState(() => _filter = 'suspicious'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'خطير',
                        count: provider.scannedFiles
                            .where((f) => f.securityLevel == FileSecurityLevel.dangerous)
                            .length,
                        isSelected: _filter == 'dangerous',
                        color: Colors.red,
                        onTap: () => setState(() => _filter = 'dangerous'),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              
              // Files List
              Expanded(
                child: ListView.builder(
                  itemCount: filteredFiles.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final file = filteredFiles[index];
                    return _FileCard(file: file);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<FileInfo> _getFilteredFiles(List<FileInfo> files) {
    switch (_filter) {
      case 'safe':
        return files
            .where((f) => f.securityLevel == FileSecurityLevel.safe)
            .toList();
      case 'suspicious':
        return files
            .where((f) => f.securityLevel == FileSecurityLevel.suspicious)
            .toList();
      case 'dangerous':
        return files
            .where((f) => f.securityLevel == FileSecurityLevel.dangerous)
            .toList();
      default:
        return files;
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

class _FileCard extends StatelessWidget {
  final FileInfo file;

  const _FileCard({required this.file});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (file.securityLevel) {
      case FileSecurityLevel.safe:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'آمن';
        break;
      case FileSecurityLevel.suspicious:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        statusText = 'مشبوه';
        break;
      case FileSecurityLevel.dangerous:
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
          file.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('الحجم: ${file.sizeFormatted}'),
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
                _InfoRow('المسار', file.path),
                _InfoRow('الحجم', file.sizeFormatted),
                _InfoRow('تاريخ التعديل', 
                  '${file.modifiedDate.day}/${file.modifiedDate.month}/${file.modifiedDate.year}'),
                if (file.threatType != null && file.threatType!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'نوع التهديد:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file.threatType!,
                    style: TextStyle(color: statusColor),
                  ),
                ],
                if (file.details != null && file.details!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'التفاصيل:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file.details!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
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

