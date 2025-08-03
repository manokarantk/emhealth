class Dependent {
  final String id;
  final String customerId;
  final String firstName;
  final String lastName;
  final int relationshipId;
  final Relationship relationship;
  final String contactNumber;
  final String dateOfBirth;
  final String gender;
  final String email;
  final String createdAt;
  final String updatedAt;

  Dependent({
    required this.id,
    required this.customerId,
    required this.firstName,
    required this.lastName,
    required this.relationshipId,
    required this.relationship,
    required this.contactNumber,
    required this.dateOfBirth,
    required this.gender,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Dependent.fromJson(Map<String, dynamic> json) {
    return Dependent(
      id: json['id'] ?? '',
      customerId: json['customer_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      relationshipId: _parseInt(json['relationship_id']),
      relationship: Relationship.fromJson(json['relationship'] ?? {}),
      contactNumber: json['contact_number'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      gender: json['gender'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'first_name': firstName,
      'last_name': lastName,
      'relationship_id': relationshipId,
      'relationship': relationship.toJson(),
      'contact_number': contactNumber,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'email': email,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get fullName => '$firstName $lastName'.trim();
  
  int get age {
    if (dateOfBirth.isEmpty) return 0;
    try {
      final birthDate = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }
}

class Relationship {
  final int id;
  final String name;
  final String description;
  final String createdAt;

  Relationship({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  factory Relationship.fromJson(Map<String, dynamic> json) {
    return Relationship(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt,
    };
  }
} 