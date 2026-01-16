/// Messages displayed by animals and icon in the sanctuary

class AnimalMessages {
  AnimalMessages._();

  /// Messages displayed by animals when tapped or at random
  static const List<String> animalMessages = [
    'Thank you for saving me',
    'I am safe because you',
    'Thank you, kind human',
    'You gave me life',
    'Thank you for choosing me',
  ];

  /// Animal-specific sounds/expressions
  static const Map<String, String> animalSounds = {
    'chicken': 'Cluck',
    'cow': 'Moo~',
    'pig': 'Oink',
    'sheep': 'Baa baa',
  };

  /// Get sound for a specific animal type
  static String getAnimalSound(String animalType) {
    return animalSounds[animalType.toLowerCase()] ?? '';
  }

  /// Messages displayed by the sanctuary icon
  static const List<String> iconMessages = [
    "Thank you for choosing animals, even when it wasn't easy.",
    'You gave up comfort so others could live. Thank you!',
    'Because of you, animals get another tomorrow.',
    'Your choice protects lives that cannot speak. Thank you!',
    'Animals live because you chose differently. Thank you!',
  ];

  /// Get a random animal message
  static String getRandomAnimalMessage() {
    final index = DateTime.now().millisecondsSinceEpoch % animalMessages.length;
    return animalMessages[index];
  }

  /// Get a random icon message
  static String getRandomIconMessage() {
    final index = DateTime.now().millisecondsSinceEpoch % iconMessages.length;
    return iconMessages[index];
  }
}

