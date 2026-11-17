class Vivienda {
  const Vivienda({
    required this.id,
    required this.name,
    this.address = '',
    this.emergencyContact = '',
    required this.createdAt,
  });

  final String id;
  final String name;
  final String address;
  final String emergencyContact;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'address': address,
        'emergency_contact': emergencyContact,
        'created_at': createdAt.toIso8601String(),
      };

  factory Vivienda.fromMap(Map<String, dynamic> map) => Vivienda(
        id: map['id'] as String,
        name: map['name'] as String,
        address: map['address'] as String? ?? '',
        emergencyContact: map['emergency_contact'] as String? ?? '',
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class Estancia {
  const Estancia({
    required this.id,
    required this.homeId,
    required this.name,
    this.iconName = 'home',
  });

  final String id;
  final String homeId;
  final String name;
  final String iconName;

  Map<String, dynamic> toMap() => {
        'id': id,
        'home_id': homeId,
        'name': name,
        'icon_name': iconName,
      };

  factory Estancia.fromMap(Map<String, dynamic> map) => Estancia(
        id: map['id'] as String,
        homeId: map['home_id'] as String,
        name: map['name'] as String,
        iconName: map['icon_name'] as String? ?? 'home',
      );
}

class Ficha {
  const Ficha({
    required this.id,
    required this.roomId,
    required this.title,
    required this.summary,
    this.isEmergency = false,
    this.locationHint = '',
  });

  final String id;
  final String roomId;
  final String title;
  final String summary;
  final bool isEmergency;
  final String locationHint;

  Map<String, dynamic> toMap() => {
        'id': id,
        'room_id': roomId,
        'title': title,
        'summary': summary,
        'is_emergency': isEmergency ? 1 : 0,
        'location_hint': locationHint,
      };

  factory Ficha.fromMap(Map<String, dynamic> map) => Ficha(
        id: map['id'] as String,
        roomId: map['room_id'] as String,
        title: map['title'] as String,
        summary: map['summary'] as String? ?? '',
        isEmergency: (map['is_emergency'] as int? ?? 0) == 1,
        locationHint: map['location_hint'] as String? ?? '',
      );
}

class Paso {
  const Paso({
    required this.id,
    required this.cardId,
    required this.stepOrder,
    required this.instruction,
  });

  final String id;
  final String cardId;
  final int stepOrder;
  final String instruction;

  Map<String, dynamic> toMap() => {
        'id': id,
        'card_id': cardId,
        'step_order': stepOrder,
        'instruction': instruction,
      };

  factory Paso.fromMap(Map<String, dynamic> map) => Paso(
        id: map['id'] as String,
        cardId: map['card_id'] as String,
        stepOrder: map['step_order'] as int,
        instruction: map['instruction'] as String,
      );
}

class Tarea {
  const Tarea({
    required this.id,
    required this.homeId,
    required this.title,
    this.frequency = 'Mensual',
    this.isDone = false,
  });

  final String id;
  final String homeId;
  final String title;
  final String frequency;
  final bool isDone;

  Tarea copyWith({bool? isDone}) => Tarea(
        id: id,
        homeId: homeId,
        title: title,
        frequency: frequency,
        isDone: isDone ?? this.isDone,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'home_id': homeId,
        'title': title,
        'frequency': frequency,
        'is_done': isDone ? 1 : 0,
      };

  factory Tarea.fromMap(Map<String, dynamic> map) => Tarea(
        id: map['id'] as String,
        homeId: map['home_id'] as String,
        title: map['title'] as String,
        frequency: map['frequency'] as String? ?? 'Mensual',
        isDone: (map['is_done'] as int? ?? 0) == 1,
      );
}

