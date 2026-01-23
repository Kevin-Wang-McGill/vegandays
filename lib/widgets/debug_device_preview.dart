import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Debug-only device preview wrapper that simulates different screen sizes
/// Only available in debug mode (kDebugMode)
class DebugDevicePreview extends StatefulWidget {
  final Widget child;
  
  const DebugDevicePreview({
    super.key,
    required this.child,
  });

  @override
  State<DebugDevicePreview> createState() => _DebugDevicePreviewState();
}

class _DebugDevicePreviewState extends State<DebugDevicePreview> {
  bool _isPreviewEnabled = false;
  _DevicePreset _selectedDevice = _DevicePreset.phone390;
  Orientation _simulatedOrientation = Orientation.portrait;

  @override
  Widget build(BuildContext context) {
    // In release mode, just return the child directly
    if (!kDebugMode) {
      return widget.child;
    }

    // If preview is not enabled, show normal app with FAB
    if (!_isPreviewEnabled) {
      return Stack(
        children: [
          widget.child,
          // Debug FAB to enable preview mode
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton.small(
              heroTag: 'debug_preview_fab',
              backgroundColor: Colors.amber.shade600,
              onPressed: () {
                setState(() {
                  _isPreviewEnabled = true;
                });
              },
              child: const Icon(Icons.devices, size: 20, color: Colors.white),
            ),
          ),
        ],
      );
    }

    // Preview mode enabled - show device frame
    final deviceSize = _selectedDevice.getSize(_simulatedOrientation);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade800,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Device Preview: ${_selectedDevice.name}',
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            setState(() {
              _isPreviewEnabled = false;
            });
          },
        ),
        actions: [
          // Orientation toggle
          IconButton(
            icon: Icon(
              _simulatedOrientation == Orientation.portrait
                  ? Icons.stay_current_portrait
                  : Icons.stay_current_landscape,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _simulatedOrientation = _simulatedOrientation == Orientation.portrait
                    ? Orientation.landscape
                    : Orientation.portrait;
              });
            },
            tooltip: 'Toggle Orientation',
          ),
          // Device selector
          PopupMenuButton<_DevicePreset>(
            icon: const Icon(Icons.phone_android, color: Colors.white),
            onSelected: (device) {
              setState(() {
                _selectedDevice = device;
              });
            },
            itemBuilder: (context) => _DevicePreset.values.map((device) {
              return PopupMenuItem(
                value: device,
                child: Row(
                  children: [
                    Icon(
                      device == _selectedDevice ? Icons.check : Icons.devices,
                      size: 16,
                      color: device == _selectedDevice ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(device.displayName),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: deviceSize.width,
          height: deviceSize.height,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade600, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: deviceSize,
                padding: _selectedDevice.getSafeAreaPadding(_simulatedOrientation),
                viewPadding: _selectedDevice.getSafeAreaPadding(_simulatedOrientation),
              ),
              child: SizedBox(
                width: deviceSize.width,
                height: deviceSize.height,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: deviceSize.width,
                    height: deviceSize.height,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.grey.shade900,
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PreviewInfoChip(
              label: 'Size',
              value: '${deviceSize.width.toInt()} × ${deviceSize.height.toInt()}',
            ),
            _PreviewInfoChip(
              label: 'Shortest',
              value: '${deviceSize.shortestSide.toInt()}',
            ),
            _PreviewInfoChip(
              label: 'Type',
              value: deviceSize.shortestSide >= 600 ? 'Tablet' : 'Phone',
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewInfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewInfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Preset device configurations for quick switching
enum _DevicePreset {
  phone390('iPhone 14/15', 390, 844, 59, 34),
  phone430('iPhone 14 Pro Max', 430, 932, 59, 34),
  phoneSE('iPhone SE', 375, 667, 20, 0),
  tabletAir11('iPad Air 11"', 820, 1180, 24, 20),
  tabletPro11('iPad Pro 11"', 834, 1194, 24, 20),
  tabletPro129('iPad Pro 12.9"', 1024, 1366, 24, 20);

  final String displayName;
  final double width;
  final double height;
  final double safeTop;
  final double safeBottom;

  const _DevicePreset(
    this.displayName,
    this.width,
    this.height,
    this.safeTop,
    this.safeBottom,
  );

  String get name => displayName;

  Size getSize(Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return Size(width, height);
    } else {
      return Size(height, width);
    }
  }

  EdgeInsets getSafeAreaPadding(Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return EdgeInsets.only(top: safeTop, bottom: safeBottom);
    } else {
      // In landscape, safe areas are typically on the sides
      return EdgeInsets.only(left: safeTop, right: safeBottom);
    }
  }
}

