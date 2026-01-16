import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/animation.dart';

/// Immutable configuration for a critter
class CritterConfig {
  final String id;
  final String assetPath;
  final double baseSize;
  /// Bounds as percentage (0..1): left, top, right, bottom
  final Rect boundsPct;
  final double speedMin;
  final double speedMax;
  final double edgeMargin;
  final int seed;
  final int zIndex;

  const CritterConfig({
    required this.id,
    required this.assetPath,
    required this.baseSize,
    required this.boundsPct,
    required this.speedMin,
    required this.speedMax,
    required this.edgeMargin,
    required this.seed,
    required this.zIndex,
  });
}

/// Mutable runtime state for a critter
class CritterState {
  Offset pos;
  Offset dir; // Normalized direction
  double segT; // Time elapsed in current segment
  double segDur; // Duration of current segment
  double pauseLeft; // Remaining pause time
  double speed; // Current speed (dp/s)
  double curvature; // Small curve amount (-1..1)
  Rect boundsPx; // Computed pixel bounds
  final Random rng;
  final CritterConfig config;
  
  // Direction tracking for flip control
  bool facingRight; // true if currently facing/moving right
  double sameDirTime; // Time spent facing the same direction
  double flipProgress; // 0.0 = facing left, 1.0 = facing right (for smooth animation)
  
  // Spawn animation
  double spawnProgress; // 0.0 = just spawned (above), 1.0 = landed
  
  // GIF phase delay (to desync animations)
  double gifPhaseDelay; // Random delay before showing GIF (seconds)
  double gifDelayElapsed; // Time elapsed during delay

  CritterState({
    required this.pos,
    required this.dir,
    required this.segT,
    required this.segDur,
    required this.pauseLeft,
    required this.speed,
    required this.curvature,
    required this.boundsPx,
    required this.rng,
    required this.config,
    this.facingRight = false,
    this.sameDirTime = 0,
    this.flipProgress = 0,
    this.spawnProgress = 0,
    this.gifPhaseDelay = 0,
    this.gifDelayElapsed = 0,
  });

  factory CritterState.fromConfig(CritterConfig config, {bool skipSpawnAnimation = false}) {
    final rng = Random(config.seed);
    final rawDir = _randomDir(rng);
    // Default to facing left (dx < 0)
    final initialDir = Offset(-rawDir.dx.abs(), rawDir.dy);
    
    // Random GIF phase delay: 0-3s for all animals
    final gifDelay = _randomRange(rng, 
        WanderConstants.gifPhaseDelayMin, 
        WanderConstants.gifPhaseDelayMax);
    
    return CritterState(
      pos: Offset.zero,
      dir: initialDir,
      segT: 0,
      segDur: _randomRange(rng, 1.8, 3.2),
      pauseLeft: 0,
      speed: _randomRange(rng, config.speedMin, config.speedMax),
      curvature: _randomRange(rng, -1, 1) * 2, // Small curvature
      boundsPx: Rect.zero,
      rng: rng,
      config: config,
      facingRight: false, // Default facing left
      sameDirTime: 0,
      flipProgress: 0.0, // 0.0 = facing left
      spawnProgress: skipSpawnAnimation ? 1.0 : 0.0, // Skip animation for existing animals
      gifPhaseDelay: gifDelay,
      // New animals: skip phase delay (show immediately with spawn animation)
      // Initial animals: use phase delay for staggered fade-in on app reload
      gifDelayElapsed: skipSpawnAnimation ? 0 : gifDelay,
    );
  }

  static Offset _randomDir(Random rng) {
    // Prefer horizontal movement
    final angle = (rng.nextDouble() - 0.5) * pi * 0.6; // -54° to +54°
    return Offset(cos(angle), sin(angle));
  }

  static double _randomRange(Random rng, double min, double max) {
    return min + rng.nextDouble() * (max - min);
  }
}

/// Constants for wander behavior
class WanderConstants {
  static const double lookaheadSec = 0.4; // Reduced for smoother edge detection
  static const double segDurMin = 5.0; // Moderate segments for calm movement
  static const double segDurMax = 15.0;
  static const double pauseMin = 0.3; // Longer pauses for healing feel
  static const double pauseMax = 0.8;
  static const double backStepMin = 2; // Smaller backstep
  static const double backStepMax = 5;
  static const double curveAmtMax = 3; // Slightly more curved paths
  static const double inwardBias = 0.5; // Stronger inward push
  static const double minSeparation = 80; // Larger separation
  static const double repulseStrength = 3.0; // Stronger repulse
  
  // Direction flip control
  static const double minSameDirTime = 20.0; // Minimum time before allowing direction change
  static const double flipDuration = 0.4; // Duration of flip animation in seconds
  
  // Spawn animation
  static const double spawnDuration = 0.5; // Duration of spawn drop animation in seconds
  static const double spawnDropRatio = 0.5; // Drop from 0.5 * animalWidth above
  
  // GIF phase offset (to desync animations on app reload)
  // All animals use same delay range: 0-3s
  static const double gifPhaseDelayMin = 0.0;
  static const double gifPhaseDelayMax = 3.0;
}

/// Core wander system - single Ticker drives all critters
class WanderSystem extends ChangeNotifier {
  final List<CritterConfig> configs;
  late List<CritterState> states;
  bool enableSeparation;
  bool _initialized = false;
  List<Rect> _exclusionZones = []; // Zones animals should avoid (e.g., pond)
  Size? _screenSize;
  Rect? _uiSafeRect;

  WanderSystem({
    required this.configs,
    this.enableSeparation = true,
  }) {
    // Initial animals skip spawn animation (already landed)
    states = configs.map((c) => CritterState.fromConfig(c, skipSpawnAnimation: true)).toList();
  }

  bool get isInitialized => _initialized;
  
  /// Add a new critter with spawn animation
  void addCritter(CritterConfig config) {
    // New animal with spawn animation (spawnProgress = 0)
    final state = CritterState.fromConfig(config, skipSpawnAnimation: false);
    
    // If already initialized, set up bounds and position
    if (_initialized && _screenSize != null) {
      _initializeState(state, _screenSize!, _uiSafeRect!);
    }
    
    states.add(state);
    notifyListeners();
  }
  
  /// Remove critters that are no longer in the list
  void syncWithAnimals(List<CritterConfig> newConfigs) {
    // Find configs that are new (not in current states)
    final currentIds = states.map((s) => s.config.id).toSet();
    final newIds = newConfigs.map((c) => c.id).toSet();
    
    // Remove states that are no longer needed
    states.removeWhere((s) => !newIds.contains(s.config.id));
    
    // Add new configs
    for (final config in newConfigs) {
      if (!currentIds.contains(config.id)) {
        addCritter(config);
      }
    }
  }

  /// Initialize with screen size, UI safe rect, and exclusion zones (all in pixels)
  void init(Size screenSize, Rect uiSafeRect, {List<Rect> exclusionZones = const []}) {
    _screenSize = screenSize;
    _uiSafeRect = uiSafeRect;
    _exclusionZones = exclusionZones;
    
    for (final state in states) {
      _initializeState(state, screenSize, uiSafeRect);
    }

    _initialized = true;
    notifyListeners();
  }
  
  /// Initialize a single state's bounds and position
  void _initializeState(CritterState state, Size screenSize, Rect uiSafeRect) {
    // Convert percentage bounds to pixel bounds
    var boundsPx = _rectFromPct(screenSize, state.config.boundsPct);

    // Exclude UI safe rect (top HUD area)
    if (boundsPx.top < uiSafeRect.bottom) {
      boundsPx = Rect.fromLTRB(
        boundsPx.left,
        uiSafeRect.bottom,
        boundsPx.right,
        boundsPx.bottom,
      );
    }

    // Clamp to screen
    boundsPx = Rect.fromLTRB(
      max(0, boundsPx.left),
      max(0, boundsPx.top),
      min(screenSize.width, boundsPx.right),
      min(screenSize.height, boundsPx.bottom),
    );

    // Account for critter size (so critter doesn't go off-screen)
    // Ensure effective bounds are valid (width/height > 0)
    final effectiveRight = max(boundsPx.left + state.config.baseSize + state.config.edgeMargin * 2, 
                                boundsPx.right - state.config.baseSize);
    final effectiveBottom = max(boundsPx.top + state.config.baseSize + state.config.edgeMargin * 2, 
                                 boundsPx.bottom - state.config.baseSize);
    
    final effectiveBounds = Rect.fromLTRB(
      boundsPx.left,
      boundsPx.top,
      effectiveRight,
      effectiveBottom,
    );

    state.boundsPx = effectiveBounds;

    // Initialize position avoiding exclusion zones
    state.pos = _findSafePosition(state.rng, effectiveBounds, state.config.baseSize);
    state.pos = _clampToRect(state.pos, effectiveBounds);

    // Start with fresh segment (not mid-segment)
    state.segT = 0;
    state.pauseLeft = 0;
    
    // Keep initial direction (facing left), just randomize vertical component
    final rawDir = _randomDir(state.rng);
    state.dir = Offset(-rawDir.dx.abs(), rawDir.dy); // Force left (dx < 0)
    state.facingRight = false;
    state.flipProgress = 0.0;
  }

  /// Update all critters (call each frame with dt in seconds)
  void update(double dt) {
    if (!_initialized) return;

    for (final state in states) {
      _updateOne(state, dt);
    }

    // Optional: lightweight separation
    if (enableSeparation) {
      _applySeparation(dt);
    }

    notifyListeners();
  }

  void _updateOne(CritterState st, double dt) {
    // Spawn animation (drop from above)
    if (st.spawnProgress < 1.0) {
      st.spawnProgress = (st.spawnProgress + dt / WanderConstants.spawnDuration).clamp(0.0, 1.0);
      // Don't move while spawning
      return;
    }
    
    // GIF phase delay (to desync animations)
    if (st.gifDelayElapsed < st.gifPhaseDelay) {
      st.gifDelayElapsed += dt;
    }
    
    // Track direction time (even during pause, direction stays the same)
    final nowFacingRight = st.dir.dx > 0;
    if (nowFacingRight == st.facingRight) {
      st.sameDirTime += dt;
    } else {
      st.facingRight = nowFacingRight;
      st.sameDirTime = 0;
    }
    
    // Smooth flip animation
    final targetFlip = st.facingRight ? 1.0 : 0.0;
    if (st.flipProgress != targetFlip) {
      final flipSpeed = dt / WanderConstants.flipDuration;
      if (st.facingRight) {
        st.flipProgress = (st.flipProgress + flipSpeed).clamp(0.0, 1.0);
      } else {
        st.flipProgress = (st.flipProgress - flipSpeed).clamp(0.0, 1.0);
      }
    }
    
    // Handle pause
    if (st.pauseLeft > 0) {
      st.pauseLeft -= dt;
      return;
    }

    // Check if currently in exclusion zone (e.g., pond)
    if (_inExclusionZone(st.pos, st.config.baseSize)) {
      // Push away until completely outside exclusion zone
      final normal = _exclusionZoneNormal(st.pos, st.config.baseSize);
      
      // Keep pushing until outside (max 10 iterations to prevent infinite loop)
      for (int i = 0; i < 10; i++) {
        st.pos = st.pos + normal * 30.0;
        st.pos = _clampToRect(st.pos, st.boundsPx);
        if (!_inExclusionZone(st.pos, st.config.baseSize)) break;
      }
      
      // Change direction to go away from zone
      st.dir = normal;
      
      // Short pause then continue moving
      st.pauseLeft = 0.3;
      st.segT = 0;
      st.segDur = _randomRange(st.rng, WanderConstants.segDurMin, WanderConstants.segDurMax);
      st.speed = _randomRange(st.rng, st.config.speedMin, st.config.speedMax);
      return;
    }

    // Check if currently at edge (not lookahead, check current position)
    if (_nearEdge(st.pos, st.boundsPx, st.config.edgeMargin * 0.2)) {
      // Already at edge - push inward until safe
      final normal = _edgeNormal(st.boundsPx, st.pos, st.config.edgeMargin);
      
      // Push until outside edge margin
      for (int i = 0; i < 5; i++) {
        st.pos = st.pos + normal * 20.0;
        st.pos = _clampToRect(st.pos, st.boundsPx);
        if (!_nearEdge(st.pos, st.boundsPx, st.config.edgeMargin * 0.5)) break;
      }
      
      // Change direction to go inward
      st.dir = normal;
      
      // Short pause then continue moving
      st.pauseLeft = 0.2;
      st.segT = 0;
      st.segDur = _randomRange(st.rng, WanderConstants.segDurMin, WanderConstants.segDurMax);
      return;
    }

    // Lookahead collision check for exclusion zones
    final predict = st.pos + st.dir * st.speed * WanderConstants.lookaheadSec;
    
    if (_inExclusionZone(predict, st.config.baseSize)) {
      // Will enter exclusion zone - turn away
      st.pauseLeft = _randomRange(st.rng, WanderConstants.pauseMin, WanderConstants.pauseMax);
      
      final normal = _exclusionZoneNormal(st.pos, st.config.baseSize);
      st.dir = Offset(
        st.dir.dx * 0.3 + normal.dx * 0.7,
        st.dir.dy * 0.3 + normal.dy * 0.7,
      );
      final len = st.dir.distance;
      if (len > 0.001) st.dir = st.dir / len;
      
      st.segT = 0;
      st.segDur = _randomRange(st.rng, WanderConstants.segDurMin, WanderConstants.segDurMax);
      return;
    }

    // Lookahead collision check for bounds edge
    if (_nearEdge(predict, st.boundsPx, st.config.edgeMargin)) {
      // Trigger edge avoidance: slow turn instead of hard stop
      // 1. Small pause
      st.pauseLeft = _randomRange(st.rng, WanderConstants.pauseMin, WanderConstants.pauseMax);

      // 2. Soft bounce + strong inward bias
      final normal = _edgeNormal(st.boundsPx, st.pos, st.config.edgeMargin);
      
      // Blend current direction with inward direction
      var newDir = Offset(
        st.dir.dx * 0.2 + normal.dx * 0.8,
        st.dir.dy * 0.2 + normal.dy * 0.8,
      );
      
      // Normalize
      final len = newDir.distance;
      st.dir = len > 0.001 ? newDir / len : _randomDir(st.rng);

      // Reset segment with new parameters
      st.segT = 0;
      st.segDur = _randomRange(st.rng, WanderConstants.segDurMin, WanderConstants.segDurMax);
      st.speed = _randomRange(st.rng, st.config.speedMin, st.config.speedMax);
      st.curvature = _randomRange(st.rng, -1, 1) * WanderConstants.curveAmtMax;
      return;
    }

    // Normal movement
    st.segT += dt;

    // Check if segment ended
    if (st.segT >= st.segDur) {
      _newSeg(st);
    }

    // Smooth speed curve: slow start, constant middle, slow end
    final t = (st.segT / st.segDur).clamp(0.0, 1.0);
    // Bell curve: peaks at 0.5
    final bellCurve = sin(t * pi);
    final speedFactor = 0.5 + 0.5 * bellCurve;

    // Perpendicular for micro-curve (very subtle)
    final perp = Offset(-st.dir.dy, st.dir.dx);
    final curveOffset = sin(t * pi * 2) * st.curvature * 0.15;

    // Velocity
    final v = st.dir * st.speed * speedFactor + perp * curveOffset;

    // Update position
    st.pos = st.pos + v * dt;
    st.pos = _clampToRect(st.pos, st.boundsPx);
  }

  void _newSeg(CritterState st) {
    // New direction (prefer horizontal)
    final angle = (st.rng.nextDouble() - 0.5) * pi * 0.6;
    
    double flipX;
    
    // If same direction < 20s, keep current direction (no flip allowed)
    if (st.sameDirTime < WanderConstants.minSameDirTime) {
      // Keep current direction
      flipX = st.facingRight ? 1.0 : -1.0;
    } else {
      // After 20s, allow random direction change
      flipX = st.rng.nextBool() ? 1.0 : -1.0;
    }
    
    st.dir = Offset(cos(angle) * flipX, sin(angle));
    
    // Update facing direction (based on dir.dx)
    final newFacingRight = st.dir.dx > 0;
    if (newFacingRight != st.facingRight) {
      st.facingRight = newFacingRight;
      st.sameDirTime = 0; // Reset timer on direction change
    }

    st.segT = 0;
    st.segDur = _randomRange(st.rng, WanderConstants.segDurMin, WanderConstants.segDurMax);
    st.speed = _randomRange(st.rng, st.config.speedMin, st.config.speedMax);
    st.curvature = _randomRange(st.rng, -1, 1) * WanderConstants.curveAmtMax;
  }

  void _applySeparation(double dt) {
    // O(n^2) but n is small (4 animals)
    for (int i = 0; i < states.length; i++) {
      for (int j = i + 1; j < states.length; j++) {
        final a = states[i];
        final b = states[j];
        
        // Skip if either animal is paused (avoid jitter during pause)
        if (a.pauseLeft > 0 || b.pauseLeft > 0) continue;
        
        final diff = a.pos - b.pos;
        final dist = diff.distance;

        // Only apply separation if significantly overlapping (reduce sensitivity)
        if (dist < WanderConstants.minSeparation * 0.8 && dist > 0.001) {
          final overlap = WanderConstants.minSeparation - dist;
          // Gentler repulsion force
          final repulseStrength = min(overlap * 0.15, WanderConstants.repulseStrength * dt);
          final repulse = (diff / dist) * repulseStrength;

          a.pos = _clampToRect(a.pos + repulse, a.boundsPx);
          b.pos = _clampToRect(b.pos - repulse, b.boundsPx);
        }
      }
    }
  }

  // Utility functions
  Rect _rectFromPct(Size s, Rect pct) {
    return Rect.fromLTRB(
      pct.left * s.width,
      pct.top * s.height,
      pct.right * s.width,
      pct.bottom * s.height,
    );
  }

  Offset _clampToRect(Offset p, Rect r) {
    return Offset(
      p.dx.clamp(r.left, r.right),
      p.dy.clamp(r.top, r.bottom),
    );
  }

  bool _nearEdge(Offset p, Rect b, double m) {
    return p.dx < b.left + m ||
        p.dx > b.right - m ||
        p.dy < b.top + m ||
        p.dy > b.bottom - m;
  }

  Offset _edgeNormal(Rect b, Offset p, double m) {
    // Find which edge is closest and return inward normal
    final dLeft = p.dx - b.left;
    final dRight = b.right - p.dx;
    final dTop = p.dy - b.top;
    final dBottom = b.bottom - p.dy;

    final minDist = [dLeft, dRight, dTop, dBottom].reduce(min);

    if (minDist == dLeft) return const Offset(1, 0); // Push right
    if (minDist == dRight) return const Offset(-1, 0); // Push left
    if (minDist == dTop) return const Offset(0, 1); // Push down
    return const Offset(0, -1); // Push up
  }

  Offset _randomDir(Random rng) {
    final angle = (rng.nextDouble() - 0.5) * pi * 0.6;
    return Offset(cos(angle), sin(angle));
  }

  double _randomRange(Random rng, double min, double max) {
    return min + rng.nextDouble() * (max - min);
  }

  /// Check if a point (with critter size) overlaps any exclusion zone
  bool _inExclusionZone(Offset pos, double critterSize) {
    final critterRect = Rect.fromLTWH(pos.dx, pos.dy, critterSize, critterSize);
    for (final zone in _exclusionZones) {
      if (critterRect.overlaps(zone)) {
        return true;
      }
    }
    return false;
  }

  /// Get push-away direction from nearest exclusion zone
  Offset _exclusionZoneNormal(Offset pos, double critterSize) {
    final critterCenter = Offset(pos.dx + critterSize / 2, pos.dy + critterSize / 2);
    
    for (final zone in _exclusionZones) {
      final zoneCenter = zone.center;
      final diff = critterCenter - zoneCenter;
      final dist = diff.distance;
      if (dist > 0.001) {
        return diff / dist; // Normalized direction away from zone center
      }
    }
    return const Offset(0, -1); // Default: push up
  }

  /// Find a safe spawn position avoiding exclusion zones
  Offset _findSafePosition(Random rng, Rect bounds, double critterSize) {
    const maxAttempts = 50; // Increased attempts
    
    // First: try random positions
    for (int i = 0; i < maxAttempts; i++) {
      final x = bounds.left + rng.nextDouble() * bounds.width;
      final y = bounds.top + rng.nextDouble() * bounds.height;
      final pos = Offset(x, y);
      
      if (!_inExclusionZone(pos, critterSize)) {
        return pos;
      }
    }
    
    // Fallback: try corners and edges of bounds (outside exclusion zones)
    final fallbackPositions = [
      // Corners
      Offset(bounds.left + critterSize, bounds.top + critterSize),
      Offset(bounds.right - critterSize, bounds.top + critterSize),
      Offset(bounds.left + critterSize, bounds.bottom - critterSize),
      Offset(bounds.right - critterSize, bounds.bottom - critterSize),
      // Edge centers
      Offset(bounds.left + critterSize, bounds.center.dy),
      Offset(bounds.right - critterSize, bounds.center.dy),
      Offset(bounds.center.dx, bounds.top + critterSize),
      Offset(bounds.center.dx, bounds.bottom - critterSize),
    ];
    
    for (final pos in fallbackPositions) {
      if (!_inExclusionZone(pos, critterSize)) {
        return pos;
      }
    }
    
    // Last resort: find position furthest from all exclusion zone centers
    Offset bestPos = bounds.topLeft;
    double bestDist = 0;
    
    for (int i = 0; i < 100; i++) {
      final x = bounds.left + (i % 10) / 10.0 * bounds.width;
      final y = bounds.top + (i ~/ 10) / 10.0 * bounds.height;
      final pos = Offset(x, y);
      
      if (!_inExclusionZone(pos, critterSize)) {
        return pos;
      }
      
      // Track position furthest from exclusion zones
      double minZoneDist = double.infinity;
      for (final zone in _exclusionZones) {
        final dist = (pos - zone.center).distance;
        minZoneDist = min(minZoneDist, dist);
      }
      if (minZoneDist > bestDist) {
        bestDist = minZoneDist;
        bestPos = pos;
      }
    }
    
    return bestPos;
  }
}

// Extension for Offset dot product
extension OffsetDot on Offset {
  double dot(Offset other) => dx * other.dx + dy * other.dy;
}

