import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import '../models/link_info.dart';

class LinkScanScreen extends StatefulWidget {
  const LinkScanScreen({super.key});

  @override
  State<LinkScanScreen> createState() => _LinkScanScreenState();
}

class _LinkScanScreenState extends State<LinkScanScreen> {
  final TextEditingController _urlController = TextEditingController();
  String _filter = 'all'; // all, safe, suspicious, dangerous

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فحص الروابط'),
      ),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // URL Input Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'أدخل الرابط للفحص',
                        hintText: 'https://example.com',
                        prefixIcon: const Icon(Icons.link),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: provider.isScanningLink
                          ? null
                          : () async {
                              if (_urlController.text.trim().isNotEmpty) {
                                await provider.scanLink(_urlController.text.trim());
                                _urlController.clear();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم فحص الرابط'),
                                    ),
                                  );
                                }
                              }
                            },
                      icon: provider.isScanningLink
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.search),
                      label: Text(provider.isScanningLink ? 'جارٍ الفحص...' : 'فحص الرابط'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (provider.scannedLinks.isNotEmpty) ...[
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
                          count: provider.scannedLinks.length,
                          isSelected: _filter == 'all',
                          onTap: () => setState(() => _filter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'آمن',
                          count: provider.scannedLinks
                              .where((l) => l.securityLevel == LinkSecurityLevel.safe)
                              .length,
                          isSelected: _filter == 'safe',
                          color: Colors.green,
                          onTap: () => setState(() => _filter = 'safe'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'مشبوه',
                          count: provider.scannedLinks
                              .where((l) => l.securityLevel == LinkSecurityLevel.suspicious)
                              .length,
                          isSelected: _filter == 'suspicious',
                          color: Colors.orange,
                          onTap: () => setState(() => _filter = 'suspicious'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'خطير',
                          count: provider.scannedLinks
                              .where((l) => l.securityLevel == LinkSecurityLevel.dangerous)
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
              ],

              // Links List
              Expanded(
                child: provider.scannedLinks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.link_off, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد روابط مفحوصة',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'أدخل رابطاً للبدء',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _getFilteredLinks(provider.scannedLinks).length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final link = _getFilteredLinks(provider.scannedLinks)[index];
                          return _LinkCard(link: link);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<LinkInfo> _getFilteredLinks(List<LinkInfo> links) {
    switch (_filter) {
      case 'safe':
        return links
            .where((l) => l.securityLevel == LinkSecurityLevel.safe)
            .toList();
      case 'suspicious':
        return links
            .where((l) => l.securityLevel == LinkSecurityLevel.suspicious)
            .toList();
      case 'dangerous':
        return links
            .where((l) => l.securityLevel == LinkSecurityLevel.dangerous)
            .toList();
      default:
        return links;
    }
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

class _LinkCard extends StatelessWidget {
  final LinkInfo link;

  const _LinkCard({required this.link});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (link.securityLevel) {
      case LinkSecurityLevel.safe:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'آمن';
        break;
      case LinkSecurityLevel.suspicious:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        statusText = 'مشبوه';
        break;
      case LinkSecurityLevel.dangerous:
        statusColor = Colors.red;
        statusIcon = Icons.dangerous;
        statusText = 'خطير';
        break;
      case LinkSecurityLevel.unknown:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'غير معروف';
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
          link.url,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'تاريخ الفحص: ${link.scanDate.day}/${link.scanDate.month}/${link.scanDate.year}',
        ),
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
                _InfoRow('الرابط', link.url),
                _InfoRow('حالة الرابط', link.isValidUrl ? 'صحيح' : 'غير صحيح'),
                if (link.threatType != null && link.threatType!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'نوع التهديد:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    link.threatType!,
                    style: TextStyle(color: statusColor),
                  ),
                ],
                if (link.details != null && link.details!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'التفاصيل:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    link.details!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Open link in browser (would need url_launcher package)
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('فتح الرابط'),
                  ),
                ),
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

