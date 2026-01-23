import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/breakpoints.dart';
import '../theme/tokens.dart';

/// Debug-only widget that displays current device information
/// Only visible in debug mode (kDebugMode)
class DebugDeviceInfo extends StatelessWidget {
  const DebugDeviceInfo({super.key});

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final padding = mediaQuery.padding;
    final viewInsets = mediaQuery.viewInsets;
    final textScaleFactor = mediaQuery.textScaleFactor;
    final devicePixelRatio = mediaQuery.devicePixelRatio;
    final shortestSide = size.shortestSide;
    final isTablet = Breakpoints.isTablet(context);
    final scaleFactor = Breakpoints.getScaleFactor(context);
    final orientation = mediaQuery.orientation;

    return Card(
      elevation: 0,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        side: BorderSide(color: Colors.amber.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Debug: Device Info',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Screen Size', value: '${size.width.toStringAsFixed(0)} × ${size.height.toStringAsFixed(0)}'),
            _InfoRow(label: 'Shortest Side', value: shortestSide.toStringAsFixed(0)),
            _InfoRow(label: 'Orientation', value: orientation == Orientation.portrait ? 'Portrait' : 'Landscape'),
            _InfoRow(label: 'Device Type', value: isTablet ? '📱 Tablet (iPad)' : '📱 Phone'),
            const Divider(height: 16),
            _InfoRow(label: 'Safe Area Top', value: padding.top.toStringAsFixed(1)),
            _InfoRow(label: 'Safe Area Bottom', value: padding.bottom.toStringAsFixed(1)),
            _InfoRow(label: 'Safe Area Left', value: padding.left.toStringAsFixed(1)),
            _InfoRow(label: 'Safe Area Right', value: padding.right.toStringAsFixed(1)),
            const Divider(height: 16),
            _InfoRow(label: 'Text Scale Factor', value: textScaleFactor.toStringAsFixed(2)),
            _InfoRow(label: 'Device Pixel Ratio', value: devicePixelRatio.toStringAsFixed(2)),
            _InfoRow(label: 'Responsive Scale', value: scaleFactor.toStringAsFixed(2)),
            const Divider(height: 16),
            _InfoRow(label: 'Keyboard Height', value: viewInsets.bottom.toStringAsFixed(1)),
            const SizedBox(height: 8),
            // Quick reference for common device sizes
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'Common Device Sizes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              children: [
                _DeviceSizeRow(name: 'iPhone 14/15', size: '390 × 844'),
                _DeviceSizeRow(name: 'iPhone 14/15 Pro Max', size: '430 × 932'),
                _DeviceSizeRow(name: 'iPad Air 11"', size: '820 × 1180'),
                _DeviceSizeRow(name: 'iPad Pro 11"', size: '834 × 1194'),
                _DeviceSizeRow(name: 'iPad Pro 12.9"', size: '1024 × 1366'),
                _DeviceSizeRow(name: 'Tablet Threshold', size: 'shortestSide ≥ 600'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                  fontFamily: 'monospace',
                ),
          ),
        ],
      ),
    );
  }
}

class _DeviceSizeRow extends StatelessWidget {
  final String name;
  final String size;

  const _DeviceSizeRow({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
          ),
          Text(
            size,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.grey.shade700,
                ),
          ),
        ],
      ),
    );
  }
}

