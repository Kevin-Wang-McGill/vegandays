import 'sanctuary_animal.dart';

class AppState {
  DateTime? startDate;
  int impactedDays;
  int beans;
  String? lastCheckInDate; // 'YYYY-MM-DD'
  Map<AnimalType, int> animalCounts;
  List<SanctuaryAnimal> sanctuaryAnimals;

  AppState({
    this.startDate,
    this.impactedDays = 0,
    this.beans = 0,
    this.lastCheckInDate,
    Map<AnimalType, int>? animalCounts,
    List<SanctuaryAnimal>? sanctuaryAnimals,
  })  : animalCounts = animalCounts ?? {
          AnimalType.cow: 0,
          AnimalType.sheep: 0,
          AnimalType.pig: 0,
          AnimalType.chicken: 0,
        },
        sanctuaryAnimals = sanctuaryAnimals ?? [];

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate?.toIso8601String(),
      'impactedDays': impactedDays,
      'beans': beans,
      'lastCheckInDate': lastCheckInDate,
      'animalCounts': {
        for (var entry in animalCounts.entries)
          entry.key.toString().split('.').last: entry.value
      },
      'sanctuaryAnimals': sanctuaryAnimals.map((a) => a.toJson()).toList(),
    };
  }

  factory AppState.fromJson(Map<String, dynamic> json) {
    final animalCountsMap = <AnimalType, int>{};
    if (json['animalCounts'] != null) {
      (json['animalCounts'] as Map).forEach((key, value) {
        animalCountsMap[AnimalType.values.firstWhere(
          (e) => e.toString().split('.').last == key,
        )] = value as int;
      });
    }

    return AppState(
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      impactedDays: json['impactedDays'] ?? 0,
      beans: json['beans'] ?? 0,
      lastCheckInDate: json['lastCheckInDate'],
      animalCounts: animalCountsMap.isEmpty
          ? {
              AnimalType.cow: 0,
              AnimalType.sheep: 0,
              AnimalType.pig: 0,
              AnimalType.chicken: 0,
            }
          : animalCountsMap,
      sanctuaryAnimals: (json['sanctuaryAnimals'] as List?)
              ?.map((a) => SanctuaryAnimal.fromJson(a))
              .toList() ??
          [],
    );
  }

  AppState copyWith({
    DateTime? startDate,
    int? impactedDays,
    int? beans,
    String? lastCheckInDate,
    Map<AnimalType, int>? animalCounts,
    List<SanctuaryAnimal>? sanctuaryAnimals,
  }) {
    return AppState(
      startDate: startDate ?? this.startDate,
      impactedDays: impactedDays ?? this.impactedDays,
      beans: beans ?? this.beans,
      lastCheckInDate: lastCheckInDate ?? this.lastCheckInDate,
      animalCounts: animalCounts ?? Map.from(this.animalCounts),
      sanctuaryAnimals: sanctuaryAnimals ?? List.from(this.sanctuaryAnimals),
    );
  }
}
