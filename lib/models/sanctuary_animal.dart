enum AnimalType {
  cow,
  sheep,
  pig,
  chicken,
}

/// Source information for animal cost calculations
class AnimalSourceInfo {
  final String description;
  final String originalRange;
  final String convertedGrams;
  final String meatType;

  const AnimalSourceInfo({
    required this.description,
    required this.originalRange,
    required this.convertedGrams,
    required this.meatType,
  });
}

extension AnimalSourceInfoExtension on AnimalType {
  AnimalSourceInfo get sourceInfo {
    switch (this) {
      case AnimalType.chicken:
        return const AnimalSourceInfo(
          description:
              'We use the lower bound of the yield range to make exchanges more achievable.',
          originalRange: '6 lb broiler yields 4.5–5 lb meat (we use 4.5 lb minimum)',
          convertedGrams: '4.5 lb = 2,041 g',
          meatType: 'retail meat',
        );
      case AnimalType.sheep:
        return const AnimalSourceInfo(
          description:
              'We use the lower bound of the yield range to make exchanges more achievable.',
          originalRange: '80 lb market lamb yields 33–38 lb meat (we use 33 lb minimum)',
          convertedGrams: '33 lb = 14,969 g',
          meatType: 'retail meat',
        );
      case AnimalType.pig:
        return const AnimalSourceInfo(
          description:
              'We use the lower bound of the yield range to make exchanges more achievable.',
          originalRange:
              'Boneless retail meat cuts: about 114–149 lb take-home (we use 114 lb minimum)',
          convertedGrams: '114 lb = 51,710 g',
          meatType: 'take-home boneless retail meat',
        );
      case AnimalType.cow:
        return const AnimalSourceInfo(
          description:
              'We use conservative minimums (lowest carcass weight × lowest retail yield %) to make exchanges more achievable.',
          originalRange:
              'Common carcass range: 600–900 lb (we use 600 lb minimum). Retail meat yield: 55%–75% of carcass (we use 55% minimum)',
          convertedGrams: '600 lb × 55% = 330 lb = 149,685 g',
          meatType: 'retail meat',
        );
    }
  }
}

/// Format large numbers for display (e.g., 149685 -> "149k")
String formatCostForDisplay(int cost) {
  if (cost >= 100000) {
    return '${(cost / 1000).toStringAsFixed(0)}k';
  } else if (cost >= 1000) {
    return '${(cost / 1000).toStringAsFixed(1)}k';
  }
  return cost.toString();
}

/// Format cost with thousands separator for detailed display
String formatCostDetailed(int cost) {
  final costStr = cost.toString();
  if (costStr.length <= 3) return costStr;
  
  final buffer = StringBuffer();
  for (int i = 0; i < costStr.length; i++) {
    if (i > 0 && (costStr.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(costStr[i]);
  }
  return buffer.toString();
}

extension AnimalTypeExtension on AnimalType {
  String get emoji {
    switch (this) {
      case AnimalType.cow:
        return '🐮';
      case AnimalType.sheep:
        return '🐑';
      case AnimalType.pig:
        return '🐷';
      case AnimalType.chicken:
        return '🐔';
    }
  }

  /// Source institution for yield data
  String get yieldSource {
    switch (this) {
      case AnimalType.chicken:
        return 'University of Minnesota Extension';
      case AnimalType.sheep:
        return 'University of Minnesota Extension';
      case AnimalType.pig:
        return 'Washington State University Extension';
      case AnimalType.cow:
        return 'South Dakota State University Extension';
    }
  }

  String get assetPath {
    switch (this) {
      case AnimalType.cow:
        return 'assets/animations/cow.gif';
      case AnimalType.sheep:
        return 'assets/animations/sheep.gif';
      case AnimalType.pig:
        return 'assets/animations/pig.gif';
      case AnimalType.chicken:
        return 'assets/animations/chicken.gif';
    }
  }

  String get name {
    switch (this) {
      case AnimalType.cow:
        return 'Cow';
      case AnimalType.sheep:
        return 'Sheep';
      case AnimalType.pig:
        return 'Pig';
      case AnimalType.chicken:
        return 'Chicken';
    }
  }

  int get cost {
    switch (this) {
      case AnimalType.cow:
        return 149685; // 330 lb minimum retail meat (600 lb carcass × 55%)
      case AnimalType.sheep:
        return 14969; // 33 lb minimum retail meat
      case AnimalType.pig:
        return 51710; // 114 lb minimum take-home boneless retail meat
      case AnimalType.chicken:
        return 2041; // 4.5 lb minimum meat from 6 lb broiler
    }
  }
}

class SanctuaryAnimal {
  final String id;
  final AnimalType type;
  final double x; // 0-100
  final double y; // 0-100

  SanctuaryAnimal({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'x': x,
      'y': y,
    };
  }

  factory SanctuaryAnimal.fromJson(Map<String, dynamic> json) {
    return SanctuaryAnimal(
      id: json['id'] as String,
      type: AnimalType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }
}
