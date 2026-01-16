import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../constants/asset_paths.dart';
import '../services/app_state_service.dart';
import '../models/sanctuary_animal.dart';
import 'unique_asset_image.dart';
import 'sanctuary_assets.dart';
import 'grass_base_layer.dart';
import 'wavy_accent_strip.dart';
import 'distant_hills.dart';
import 'tree_line_layer.dart';
import 'wander/wander_system.dart';
import 'wander/default_critters.dart';
import 'dialogue/dialogue_system.dart';
import 'dialogue/dialogue_model.dart';

/// Color constants for flat design
class _SanctuaryColors {
  static const Color skyColor = Color(0xFFF1F6F9); // Very light blue/off-white
  static const Color grassLight = Color(0xFF6EAB4E); // Grass base layer color
  static const Color grassDeep = Color(0xFF5C953C); // Grass accent strip color
  static const Color hillsDark = Color(0xFF3D5F3A); // Dark green for distant hills
}

/// Simple ellipse shadow configuration for each animal type
class _AnimalShadowSpec {
  final double widthRatio;
  final double shadowWidthRatio;
  final double heightRatio;
  final double opacity;
  final double offsetY;
  final double upwardOffset;

  const _AnimalShadowSpec({
    required this.widthRatio,
    required this.shadowWidthRatio,
    required this.heightRatio,
    required this.opacity,
    required this.offsetY,
    required this.upwardOffset,
  });

  static const Color shadowColor = Color(0xFF4A4A4A);

  static const Map<String, _AnimalShadowSpec> specs = {
    'cow': _AnimalShadowSpec(
      widthRatio: 2.0,
      shadowWidthRatio: 1.667,
      heightRatio: 0.16,
      opacity: 0.35,
      offsetY: 0,
      upwardOffset: 17.0,
    ),
    'pig': _AnimalShadowSpec(
      widthRatio: 1.25,
      shadowWidthRatio: 1.056,
      heightRatio: 0.16,
      opacity: 0.35,
      offsetY: 0,
      upwardOffset: 10.0,
    ),
    'sheep': _AnimalShadowSpec(
      widthRatio: 1.0,
      shadowWidthRatio: 0.833,
      heightRatio: 0.15,
      opacity: 0.32,
      offsetY: 0,
      upwardOffset: 5.0,
    ),
    'chicken': _AnimalShadowSpec(
      widthRatio: 0.50,
      shadowWidthRatio: 0.50,
      heightRatio: 0.14,
      opacity: 0.30,
      offsetY: 0,
      upwardOffset: 2.5,
    ),
  };

  static _AnimalShadowSpec getSpec(String id) {
    // Handle 'cow_12345' format: extract type before underscore
    final typeId = id.contains('_') ? id.split('_').first : id;
    return specs[typeId] ?? specs['chicken']!;
  }
}

/// Full-screen Sanctuary scene with layered flat design and wandering animals
class SanctuaryScene extends StatefulWidget {
  const SanctuaryScene({super.key});

  @override
  State<SanctuaryScene> createState() => _SanctuarySceneState();
}

class _SanctuarySceneState extends State<SanctuaryScene>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late WanderSystem _wanderSystem;
  late DialogueSystem _dialogueSystem;
  Duration _lastTime = Duration.zero;
  double _nowSec = 0; // 累计时间（秒）
  Size? _lastScreenSize;
  List<SanctuaryAnimal> _lastAnimals = [];
  
  // Track which animals were loaded on restart vs newly purchased
  final Set<String> _initialAnimalIds = {};
  // Random offset for initial animals to desync GIF playback
  final Map<String, int> _initialAnimalRandomOffset = {};
  final Random _random = Random();

  // HUD禁区高度比例 (TODO: 从 HomeScreen 精确获取，暂用 0.18h)
  static const double _hudHeightPct = 0.18;
  // 额外安全边距
  static const double _hudMargin = 12.0;

  @override
  void initState() {
    super.initState();

    // Build configs from AppStateService's sanctuaryAnimals
    final animals = AppStateService.instance.state.sanctuaryAnimals;
    _lastAnimals = List.from(animals);
    
    // Mark all initial animals (loaded on restart) and assign random offset for desync
    for (final animal in animals) {
      final typeId = _getTypeId(animal.type);
      final configId = '${typeId}_${animal.id}';
      _initialAnimalIds.add(configId);
      _initialAnimalRandomOffset[configId] = _random.nextInt(10000);
    }
    
    _wanderSystem = WanderSystem(
      configs: _buildConfigsFromAnimals(animals),
      enableSeparation: true,
    );

    // Initialize dialogue system (temporarily disabled)
    _dialogueSystem = DialogueSystem();
    // TODO: Re-enable dialogue system when ready

    // Listen to AppStateService for animal changes
    AppStateService.instance.addListener(_onAppStateChanged);

    // Single Ticker drives all animals and dialogue
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onAppStateChanged() {
    final newAnimals = AppStateService.instance.state.sanctuaryAnimals;
    
    // Check if animal list changed
    if (_animalsChanged(newAnimals)) {
      _lastAnimals = List.from(newAnimals);
      
      // Sync with new animals (only new animals get spawn animation)
      final newConfigs = _buildConfigsFromAnimals(newAnimals);
      _wanderSystem.syncWithAnimals(newConfigs);
      
      setState(() {});
    }
  }

  bool _animalsChanged(List<SanctuaryAnimal> newAnimals) {
    if (newAnimals.length != _lastAnimals.length) return true;
    for (int i = 0; i < newAnimals.length; i++) {
      if (newAnimals[i].id != _lastAnimals[i].id) return true;
    }
    return false;
  }

  /// Convert SanctuaryAnimal list to CritterConfig list
  List<CritterConfig> _buildConfigsFromAnimals(List<SanctuaryAnimal> animals) {
    if (animals.isEmpty) {
      return []; // No animals yet
    }

    return animals.asMap().entries.map((entry) {
      final index = entry.key;
      final animal = entry.value;
      final typeId = _getTypeId(animal.type);
      final defaultConfig = _getDefaultConfigForType(animal.type);
      
      return CritterConfig(
        id: '${typeId}_${animal.id}', // Unique id: type + animal.id
        assetPath: defaultConfig.assetPath,
        baseSize: defaultConfig.baseSize,
        boundsPct: defaultConfig.boundsPct,
        speedMin: defaultConfig.speedMin,
        speedMax: defaultConfig.speedMax,
        edgeMargin: defaultConfig.edgeMargin,
        seed: animal.id.hashCode + index, // Unique seed per animal
        zIndex: index,
      );
    }).toList();
  }

  /// Get type id string that matches _AnimalShadowSpec.specs keys
  String _getTypeId(AnimalType type) {
    switch (type) {
      case AnimalType.chicken:
        return 'chicken';
      case AnimalType.sheep:
        return 'sheep';
      case AnimalType.pig:
        return 'pig';
      case AnimalType.cow:
        return 'cow';
    }
  }

  /// Get default config template for an animal type
  CritterConfig _getDefaultConfigForType(AnimalType type) {
    switch (type) {
      case AnimalType.chicken:
        return DefaultCritters.configs.firstWhere((c) => c.id == 'chicken');
      case AnimalType.sheep:
        return DefaultCritters.configs.firstWhere((c) => c.id == 'sheep');
      case AnimalType.pig:
        return DefaultCritters.configs.firstWhere((c) => c.id == 'pig');
      case AnimalType.cow:
        return DefaultCritters.configs.firstWhere((c) => c.id == 'cow');
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
      return;
    }

    final dt = (elapsed - _lastTime).inMicroseconds / 1000000.0;
    _lastTime = elapsed;

    // Cap dt to avoid huge jumps (e.g., after app resume)
    final cappedDt = dt.clamp(0.0, 0.1);
    
    // Update cumulative time
    _nowSec += cappedDt;
    
    // 1) Update wander system
    _wanderSystem.update(cappedDt);
    
    // 2) Build critter snapshots for dialogue system (temporarily disabled)
    // final critterSnapshots = _buildCritterSnapshots();
    
    // 3) Update dialogue system (temporarily disabled)
    // _dialogueSystem.update(
    //   nowSec: _nowSec,
    //   dt: cappedDt,
    //   critters: critterSnapshots,
    // );
  }

  /// Build snapshots of current critter states for dialogue system
  List<CritterSnapshot> _buildCritterSnapshots() {
    if (!_wanderSystem.isInitialized) return [];
    
    final baseAnimalWidth = _lastScreenSize != null 
        ? 0.18 * _lastScreenSize!.width 
        : 70.0;
    
    return _wanderSystem.states.asMap().entries.map((entry) {
      final index = entry.key;
      final state = entry.value;
      final shadowSpec = _AnimalShadowSpec.getSpec(state.config.id);
      final animalWidth = baseAnimalWidth * shadowSpec.widthRatio;
      
      // Extract type from id (e.g., 'cow_12345' -> 'cow')
      final type = state.config.id.contains('_') 
          ? state.config.id.split('_').first 
          : state.config.id;
      
      return CritterSnapshot(
        id: state.config.id,
        type: type,
        pos: state.pos,
        size: animalWidth,
        zIndex: index,
      );
    }).toList();
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onAppStateChanged);
    _ticker.dispose();
    _wanderSystem.dispose();
    super.dispose();
  }

  void _forceReinitWanderSystem(Size screenSize) {
    _lastScreenSize = screenSize;
    
    // Calculate HUD exclusion zone
    final hudBottom = screenSize.height * _hudHeightPct + _hudMargin;
    final uiSafeRect = Rect.fromLTRB(0, 0, screenSize.width, hudBottom);

    _wanderSystem.init(screenSize, uiSafeRect);
  }

  void _initWanderSystemIfNeeded(Size screenSize) {
    if (_lastScreenSize == screenSize && _wanderSystem.isInitialized) {
      return;
    }
    _lastScreenSize = screenSize;

    final w = screenSize.width;
    final h = screenSize.height;
    final grassH = 0.50 * h;

    // Calculate HUD safe rect (top area where animals can't go)
    final hudBottom = h * _hudHeightPct + _hudMargin;
    final uiSafeRect = Rect.fromLTRB(0, 0, w, hudBottom);

    // No pond exclusion zone - animals can walk freely
    _wanderSystem.init(screenSize, uiSafeRect);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final w = screenSize.width;
    final h = screenSize.height;

    // Initialize wander system with screen size
    _initWanderSystemIfNeeded(screenSize);

    // Layout constants
    final grassH = 0.50 * h;
    final stripH = 0.09 * h;
    final hillsH = 0.22 * h;
    final hillsOverlap = 0.03 * h;
    final horizonBottom = grassH - hillsOverlap;

    final sunSize = 0.30 * w;
    final pondW = 0.40 * w;
    final cloud1W = 0.26 * w * 1.45 * 1.1;
    final cloud2W = 0.22 * w * 1.35 * 1.1;
    final cloud3W = 0.24 * w * 1.42 * 1.1;
    final cloud4W = 0.20 * w * 1.38 * 1.1;
    final cloud5W = 0.23 * w * 1.48 * 1.1;

    return ListenableBuilder(
      listenable: _wanderSystem,
      builder: (context, _) {
        return Container(
          width: w,
          height: h,
          child: Stack(
            children: [
              // A. Sky background
              Positioned.fill(
                child: Container(
                  color: _SanctuaryColors.skyColor,
                ),
              ),

              // B. Sun
              Positioned(
                left: 0.03 * w,
                top: 0.10 * h,
                width: sunSize,
                height: sunSize,
                child: Image.asset(
                  SanctuaryAssets.sun01,
                  fit: BoxFit.contain,
                ),
              ),

              // C. Clouds
              Positioned(
                left: 0.08 * w,
                top: 0.12 * h,
                child: Image.asset(
                  SanctuaryAssets.cloud03,
                  width: cloud1W,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                left: 0.03 * w,
                top: 0.22 * h,
                child: Image.asset(
                  SanctuaryAssets.cloud03,
                  width: cloud2W,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                left: 0.50 * w,
                top: 0.16 * h,
                child: Image.asset(
                  SanctuaryAssets.cloud03,
                  width: cloud3W,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                left: 0.45 * w,
                top: 0.26 * h,
                child: Image.asset(
                  SanctuaryAssets.cloud03,
                  width: cloud4W,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                right: 0.03 * w,
                top: 0.18 * h,
                child: Image.asset(
                  SanctuaryAssets.cloud03,
                  width: cloud5W,
                  fit: BoxFit.contain,
                ),
              ),

              // D. Distant Hills
              DistantHills(
                height: hillsH,
                bottom: horizonBottom,
                color: _SanctuaryColors.hillsDark,
              ),

              // E. GrassBaseLayer
              GrassBaseLayer(
                height: grassH,
                color: _SanctuaryColors.grassLight,
              ),

              // F. WavyAccentStrip
              WavyAccentStrip(
                height: stripH,
                grassHeight: grassH,
                color: _SanctuaryColors.grassDeep,
              ),

              // G. TreeLineLayer
              TreeLineLayer(
                screenWidth: w,
                screenHeight: h,
                grassH: grassH,
                horizonBottom: horizonBottom,
                treeAssetPath: SanctuaryAssets.tree01,
              ),

              // H. Pond
              Positioned(
                left: 230,
                bottom: 280,
                child: Image.asset(
                  SanctuaryAssets.pond01,
                  width: pondW,
                  fit: BoxFit.contain,
                ),
              ),

              // I. Animal Shadows - above background, below Icon and all animal GIFs
              ..._buildAnimalShadows(w),

              // J. Icon GIF - above animal shadows, below animal GIFs
              Positioned(
                left: 0.33 * w,
                bottom: 0.38 * h,
                child: Builder(
                  builder: (context) {
                    final iconW = 0.35 * w;
                    const shadowWidthRatio = 0.6;
                    final shadowW = iconW * shadowWidthRatio;
                    final shadowH = iconW * 0.12;

                    return Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -18),
                          child: IgnorePointer(
                            child: SizedBox(
                              width: shadowW,
                              height: shadowH,
                              child: ClipOval(
                                child: ColoredBox(
                                  color: _AnimalShadowSpec.shadowColor.withOpacity(0.30),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Image.asset(
                          AssetPaths.iconGif,
                          width: iconW,
                          fit: BoxFit.contain,
                        ),
                      ],
                    );
                  },
                ),
              ),

              // K. Animals and Bubbles - z-sorted together
              ..._buildAnimalsAndBubbles(w),
            ],
          ),
        );
      },
    );
  }

  /// Build animals and bubbles together, z-sorted
  List<Widget> _buildAnimalsAndBubbles(double screenWidth) {
    if (!_wanderSystem.isInitialized) return [];

    final baseAnimalWidth = 0.18 * screenWidth;

    // Build render items (animals + bubbles)
    final List<_RenderItem> items = [];

    // Sort animals by bottom Y position for proper layering
    final sortedStates = List<CritterState>.from(_wanderSystem.states)
      ..sort((a, b) {
        final aSpec = _AnimalShadowSpec.getSpec(a.config.id);
        final bSpec = _AnimalShadowSpec.getSpec(b.config.id);
        final aBottom = a.pos.dy + baseAnimalWidth * aSpec.widthRatio;
        final bBottom = b.pos.dy + baseAnimalWidth * bSpec.widthRatio;
        return aBottom.compareTo(bBottom);
      });

    // Add animals and their bubbles
    for (int i = 0; i < sortedStates.length; i++) {
      final state = sortedStates[i];
      final zIndex = i * 2; // Even numbers for animals

      // Add animal
      items.add(_RenderItem(
        zIndex: zIndex,
        widget: _buildSingleAnimalGif(state, baseAnimalWidth),
      ));

      // Check if this animal has an active bubble (temporarily disabled)
      // final bubble = _dialogueSystem.getBubbleForCritter(state.config.id);
      // if (bubble != null) {
      //   final shadowSpec = _AnimalShadowSpec.getSpec(state.config.id);
      //   final animalWidth = baseAnimalWidth * shadowSpec.widthRatio;
      //   
      //   items.add(_RenderItem(
      //     zIndex: zIndex + 1, // Odd numbers for bubbles (above their animal)
      //     widget: _buildBubbleWidget(bubble, state.pos, animalWidth, state.facingRight),
      //   ));
      // }
    }

    // Sort by zIndex
    items.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return items.map((item) => item.widget).toList();
  }

  /// Build a single animal GIF widget
  Widget _buildSingleAnimalGif(CritterState state, double baseAnimalWidth) {
    final shadowSpec = _AnimalShadowSpec.getSpec(state.config.id);
    final animalWidth = baseAnimalWidth * shadowSpec.widthRatio;

    // Check if this is an initial animal (loaded on restart)
    final isInitialAnimal = _initialAnimalIds.contains(state.config.id);

    // Use UniqueAssetImage with unique seed for independent GIF streams
    // For initial animals: add random offset (generated once at init) to uniqueId for desync
    final randomOffset = _initialAnimalRandomOffset[state.config.id] ?? 0;
    final uniqueId = '${state.config.id}_${state.config.seed}_$randomOffset';
    
    Widget gifWidget = Image(
      image: UniqueAssetImage(
        state.config.assetPath,
        uniqueId: uniqueId,
      ),
      key: ValueKey('gif_$uniqueId'),
      width: animalWidth,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );

    // Flip animation
    final scaleX = 1.0 - 2.0 * state.flipProgress;
    if (scaleX != 1.0) {
      gifWidget = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(scaleX, 1.0),
        child: gifWidget,
      );
    }

    // Spawn animation for newly purchased animals only
    final spawnComplete = state.spawnProgress >= 1.0;
    
    double opacity;
    if (!spawnComplete && !isInitialAnimal) {
      // During spawn for new animals: use spawn progress for opacity
      opacity = state.spawnProgress;
    } else {
      // Fully visible (no fade-in for restart loaded animals)
      opacity = 1.0;
    }

    // Drop animation only during spawn for new animals
    final dropOffset = (spawnComplete || isInitialAnimal)
        ? 0.0 
        : animalWidth * 0.5 * (1.0 - _easeOutCubic(state.spawnProgress));
    final displayY = state.pos.dy - dropOffset;

    return Positioned(
      left: state.pos.dx,
      top: displayY,
      child: Opacity(
        opacity: opacity,
        child: gifWidget,
      ),
    );
  }

  /// Build a speech bubble widget
  Widget _buildBubbleWidget(BubbleEvent bubble, Offset animalPos, double animalWidth, bool facingRight) {
    final progress = bubble.getProgress(_nowSec);
    
    // Fade in/out animation
    double opacity;
    if (progress < 0.15) {
      // Fade in
      opacity = progress / 0.15;
    } else if (progress > 0.85) {
      // Fade out
      opacity = (1.0 - progress) / 0.15;
    } else {
      opacity = 1.0;
    }

    // Bubble position: above animal's head
    // 水平：根据朝向偏移 20px（向左走左偏，向右走右偏）
    // 垂直：气泡下沿紧贴动物顶部（偏移 0）
    final horizontalOffset = facingRight ? 20.0 : -20.0;
    final bubbleX = animalPos.dx + animalWidth * 0.5 + horizontalOffset;
    final estimatedBubbleHeight = 30.0; // padding 6*2 + text ~18px
    final bubbleBottomY = animalPos.dy; // 气泡下沿 = 动物顶部
    final bubbleTopY = bubbleBottomY - estimatedBubbleHeight; // 气泡上沿位置

    // 气泡尾巴偏移：根据朝向指向动物
    final tailOffsetX = facingRight ? 30.0 : -30.0;

    return Positioned(
      left: bubbleX - 60, // Center the bubble (maxWidth=120, so -60 to center)
      top: bubbleTopY,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: facingRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // 气泡主体
            Container(
              constraints: const BoxConstraints(maxWidth: 120),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                bubble.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF533D2D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // 气泡尾巴（三角形指向动物）
            Padding(
              padding: EdgeInsets.only(
                left: facingRight ? 0 : 20,
                right: facingRight ? 20 : 0,
              ),
              child: CustomPaint(
                size: const Size(12, 8),
                painter: _BubbleTailPainter(
                  color: Colors.white.withOpacity(0.95),
                  pointsRight: facingRight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build animal shadows - rendered first (below all GIFs)
  List<Widget> _buildAnimalShadows(double screenWidth) {
    if (!_wanderSystem.isInitialized) return [];

    final baseAnimalWidth = 0.18 * screenWidth;

    // Sort by bottom Y position (pos.dy + animalHeight): animals with feet lower on screen render on top
    // This creates proper 2.5D depth effect based on where animals "stand"
    final sortedStates = List<CritterState>.from(_wanderSystem.states)
      ..sort((a, b) {
        final aSpec = _AnimalShadowSpec.getSpec(a.config.id);
        final bSpec = _AnimalShadowSpec.getSpec(b.config.id);
        final aBottom = a.pos.dy + baseAnimalWidth * aSpec.widthRatio;
        final bBottom = b.pos.dy + baseAnimalWidth * bSpec.widthRatio;
        return aBottom.compareTo(bBottom);
      });

    return sortedStates.map((state) {
      final shadowSpec = _AnimalShadowSpec.getSpec(state.config.id);
      final animalWidth = baseAnimalWidth * shadowSpec.widthRatio;
      final shadowWidth = baseAnimalWidth * shadowSpec.shadowWidthRatio;
      final shadowHeight = animalWidth * shadowSpec.heightRatio;

      // Calculate shadow position (centered below animal feet)
      // Animal pos is top-left, shadow should be at bottom-center
      final shadowLeft = state.pos.dx + (animalWidth - shadowWidth) / 2;
      final shadowTop = state.pos.dy + animalWidth - shadowHeight + shadowSpec.offsetY - shadowSpec.upwardOffset;

      // Check if this is an initial animal (loaded on restart)
      final isInitialAnimal = _initialAnimalIds.contains(state.config.id);
      
      // During spawn animation for NEW animals only, shadow grows from small to full size
      // Initial animals: no animation, immediately full size
      final effectiveSpawnProgress = isInitialAnimal ? 1.0 : state.spawnProgress;
      final spawnT = _easeOutCubic(effectiveSpawnProgress);
      final shadowScale = 0.3 + 0.7 * spawnT; // Start at 30% size
      final shadowOpacity = shadowSpec.opacity * spawnT;
      
      final scaledShadowWidth = shadowWidth * shadowScale;
      final scaledShadowHeight = shadowHeight * shadowScale;
      final scaledShadowLeft = shadowLeft + (shadowWidth - scaledShadowWidth) / 2;
      final scaledShadowTop = shadowTop + (shadowHeight - scaledShadowHeight) / 2;

      return Positioned(
        left: scaledShadowLeft,
        top: scaledShadowTop,
        child: IgnorePointer(
          child: SizedBox(
            width: scaledShadowWidth,
            height: scaledShadowHeight,
            child: ClipOval(
              child: ColoredBox(
                color: _AnimalShadowSpec.shadowColor.withOpacity(shadowOpacity),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Easing function for spawn animation (fast start, slow end)
  double _easeOutCubic(double t) {
    return 1 - (1 - t) * (1 - t) * (1 - t);
  }
}

/// Helper class for z-sorted rendering
class _RenderItem {
  final int zIndex;
  final Widget widget;

  _RenderItem({required this.zIndex, required this.widget});
}

/// Custom painter for bubble tail (triangle pointing to animal)
class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool pointsRight;

  _BubbleTailPainter({required this.color, required this.pointsRight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (pointsRight) {
      // 尾巴指向右下角
      path.moveTo(0, 0); // 左上角
      path.lineTo(size.width, 0); // 右上角
      path.lineTo(size.width, size.height); // 右下角（尖端）
      path.close();
    } else {
      // 尾巴指向左下角
      path.moveTo(0, 0); // 左上角
      path.lineTo(size.width, 0); // 右上角
      path.lineTo(0, size.height); // 左下角（尖端）
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pointsRight != pointsRight;
  }
}
