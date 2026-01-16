/// Diet type enum
enum DietType {
  vegetarian,
  vegan,
}

extension DietTypeExtension on DietType {
  String get displayName {
    switch (this) {
      case DietType.vegetarian:
        return 'Vegetarian';
      case DietType.vegan:
        return 'Vegan';
    }
  }
  
  String get storageKey {
    switch (this) {
      case DietType.vegetarian:
        return 'vegetarian';
      case DietType.vegan:
        return 'vegan';
    }
  }
  
  static DietType? fromStorageKey(String? key) {
    if (key == null) return null;
    switch (key) {
      case 'vegetarian':
        return DietType.vegetarian;
      case 'vegan':
        return DietType.vegan;
      default:
        return null;
    }
  }
}

