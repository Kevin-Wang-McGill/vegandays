import 'dart:ui';

/// Snapshot of critter state for dialogue system (避免循环依赖)
class CritterSnapshot {
  final String id;
  final String type; // 'chicken', 'cow', 'pig', 'sheep'
  final Offset pos;
  final double size;
  final int zIndex;

  const CritterSnapshot({
    required this.id,
    required this.type,
    required this.pos,
    required this.size,
    required this.zIndex,
  });
}

/// Active bubble event
class BubbleEvent {
  final String critterId;
  final String text;
  final double createdAtSec;
  final double lifetimeSec;
  final Offset anchorPos; // 固定头顶位置
  final int zIndex; // = animal.zIndex + 1

  const BubbleEvent({
    required this.critterId,
    required this.text,
    required this.createdAtSec,
    required this.lifetimeSec,
    required this.anchorPos,
    required this.zIndex,
  });

  /// Check if bubble has expired
  bool isExpired(double nowSec) => nowSec >= createdAtSec + lifetimeSec;

  /// Get progress for fade animation (0.0 = just created, 1.0 = expired)
  double getProgress(double nowSec) {
    final elapsed = nowSec - createdAtSec;
    return (elapsed / lifetimeSec).clamp(0.0, 1.0);
  }
}

/// Render item for z-sorting (animal or bubble)
abstract class RenderItem {
  int get zIndex;
}

class AnimalRenderItem extends RenderItem {
  @override
  final int zIndex;
  final CritterSnapshot critter;

  AnimalRenderItem({required this.zIndex, required this.critter});
}

class BubbleRenderItem extends RenderItem {
  @override
  final int zIndex;
  final BubbleEvent bubble;
  final double nowSec;

  BubbleRenderItem({
    required this.zIndex,
    required this.bubble,
    required this.nowSec,
  });
}

