import 'package:flutter/painting.dart';
import 'wander_system.dart';

/// Default critter configurations for the sanctuary
/// These are used when no saved animal positions exist
class DefaultCritters {
  DefaultCritters._();

  /// Shared activity bounds for all animals (0.47-0.85 vertical range, ~320px height on 844px screen)
  static const Rect _sharedBounds = Rect.fromLTRB(0.05, 0.47, 0.95, 0.85);

  static const List<CritterConfig> configs = [
    // Chicken: smallest
    CritterConfig(
      id: 'chicken',
      assetPath: 'assets/animations/chicken.gif',
      baseSize: 64,
      boundsPct: _sharedBounds,
      speedMin: 4,
      speedMax: 8,
      edgeMargin: 0,
      seed: 1101,
      zIndex: 1,
    ),
    // Sheep: medium size
    CritterConfig(
      id: 'sheep',
      assetPath: 'assets/animations/sheep.gif',
      baseSize: 78,
      boundsPct: _sharedBounds,
      speedMin: 6,
      speedMax: 10,
      edgeMargin: 0,
      seed: 2202,
      zIndex: 2,
    ),
    // Pig: medium-large
    CritterConfig(
      id: 'pig',
      assetPath: 'assets/animations/pig.gif',
      baseSize: 84,
      boundsPct: _sharedBounds,
      speedMin: 6,
      speedMax: 10,
      edgeMargin: 0,
      seed: 3303,
      zIndex: 3,
    ),
    // Cow: largest
    CritterConfig(
      id: 'cow',
      assetPath: 'assets/animations/cow.gif',
      baseSize: 96,
      boundsPct: _sharedBounds,
      speedMin: 8,
      speedMax: 12,
      edgeMargin: 0,
      seed: 4404,
      zIndex: 4,
    ),
  ];
}

