import 'dart:math';
import 'dart:ui';

import '../../constants/animal_messages.dart';
import 'dialogue_model.dart';

/// Constants for dialogue frequency control (方案1全局预算)
/// 目标：N=1..15 时，全局气泡出现频率大致落在 5–10 条/分钟
/// E(N) = 60 * Rmax * N / (N + beta)
/// N=1: E ≈ 5.4/min, N=15: E ≈ 10.1/min
class DialogueConstants {
  static const double beta = 1.0;
  static const double rMax = 0.18; // events per second, ~10.8/min theoretical max

  // 冷却与容量（配合 maxBubblesOnScreen=3，避免"爆屏"）
  static const double perCritterCooldownMin = 7.0;
  static const double perCritterCooldownMax = 14.0;

  static const double globalMinGapMin = 0.9;
  static const double globalMinGapMax = 1.6;

  static const double bubbleLifetimeMin = 1.4;
  static const double bubbleLifetimeMax = 1.9;

  static const int maxBubblesOnScreen = 3;

  static const double messageProbability = 0.10; // 10% messages, 90% sounds
}

/// Dialogue system - controls when and what bubbles appear
class DialogueSystem {
  final List<BubbleEvent> activeBubbles = [];
  double nextGlobalAllowedAtSec = 0;
  final Map<String, double> nextCritterAllowedAtSec = {};
  final Random _rng = Random();

  // Track last message index to avoid consecutive repeats
  int _lastMessageIndex = -1;

  /// Update dialogue system each frame
  void update({
    required double nowSec,
    required double dt,
    required List<CritterSnapshot> critters,
  }) {
    // 1) 清理过期气泡
    activeBubbles.removeWhere((b) => b.isExpired(nowSec));

    // 2) 若 activeBubbles >= maxBubblesOnScreen：return
    if (activeBubbles.length >= DialogueConstants.maxBubblesOnScreen) {
      return;
    }

    // 3) 若 nowSec < nextGlobalAllowedAtSec：return
    if (nowSec < nextGlobalAllowedAtSec) {
      return;
    }

    // 4) 遍历 critters（随机打乱避免总是同一只优先）
    if (critters.isEmpty) return;

    final shuffledCritters = List<CritterSnapshot>.from(critters)..shuffle(_rng);
    final n = critters.length;

    for (final critter in shuffledCritters) {
      // 若 nowSec < nextCritterAllowedAtSec[id]：continue
      final critterCooldown = nextCritterAllowedAtSec[critter.id] ?? 0;
      if (nowSec < critterCooldown) {
        continue;
      }

      // 计算 lambda_i 和 p
      final lambdaI = DialogueConstants.rMax / (n + DialogueConstants.beta);
      final p = 1 - exp(-lambdaI * dt);

      // 若 rng < p：触发
      if (_rng.nextDouble() < p) {
        // 生成 BubbleEvent
        final text = _selectText(critter.type);
        final lifetime = _randomRange(
          DialogueConstants.bubbleLifetimeMin,
          DialogueConstants.bubbleLifetimeMax,
        );

        // anchorPos = 动物头顶
        final anchorPos = Offset(
          critter.pos.dx + critter.size * 0.5,
          critter.pos.dy - 6,
        );

        final bubble = BubbleEvent(
          critterId: critter.id,
          text: text,
          createdAtSec: nowSec,
          lifetimeSec: lifetime,
          anchorPos: anchorPos,
          zIndex: critter.zIndex + 1, // 必须 = animal.zIndex + 1
        );

        activeBubbles.add(bubble);

        // 更新冷却时间
        nextGlobalAllowedAtSec = nowSec + _randomRange(
          DialogueConstants.globalMinGapMin,
          DialogueConstants.globalMinGapMax,
        );
        nextCritterAllowedAtSec[critter.id] = nowSec + _randomRange(
          DialogueConstants.perCritterCooldownMin,
          DialogueConstants.perCritterCooldownMax,
        );

        // 每帧最多出 1 条
        break;
      }
    }
  }

  /// 选择文本：30% animalMessages，70% animalSounds
  String _selectText(String animalType) {
    if (_rng.nextDouble() < DialogueConstants.messageProbability) {
      // 30%: 从 animalMessages 随机取 1 条（避免连续重复）
      final messages = AnimalMessages.animalMessages;
      int index;
      do {
        index = _rng.nextInt(messages.length);
      } while (index == _lastMessageIndex && messages.length > 1);
      _lastMessageIndex = index;
      return messages[index];
    } else {
      // 70%: animalSounds
      return AnimalMessages.getAnimalSound(animalType);
    }
  }

  double _randomRange(double min, double max) {
    return min + _rng.nextDouble() * (max - min);
  }

  /// Get bubble for a specific critter (if any)
  BubbleEvent? getBubbleForCritter(String critterId) {
    for (final bubble in activeBubbles) {
      if (bubble.critterId == critterId) {
        return bubble;
      }
    }
    return null;
  }

  /// Clear all bubbles
  void clear() {
    activeBubbles.clear();
    nextCritterAllowedAtSec.clear();
    nextGlobalAllowedAtSec = 0;
  }
}

