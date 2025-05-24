
/// Modelo para representar un usuario temporal dentro de una geocerca
class UserTemporal {
  final String id;
  final String firstName;
  final String lastName;
  final String profileImageUrl;
  final String description;
  final String geocercaId;
  final DateTime entryTime;
  
  UserTemporal({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profileImageUrl,
    required this.description,
    required this.geocercaId,
    required this.entryTime,
  });
  
  // Método para obtener el nombre completo
  String get fullName => '$firstName $lastName';
  
  // Método para obtener el tiempo transcurrido desde la entrada
  String get timeElapsed {
    final now = DateTime.now();
    final difference = now.difference(entryTime);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return '${difference.inSeconds}s';
    }
  }
  
  // Para serialización/deserialización
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'profileImageUrl': profileImageUrl,
      'description': description,
      'geocercaId': geocercaId,
      'entryTime': entryTime.toIso8601String(),
    };
  }
  
  factory UserTemporal.fromMap(Map<String, dynamic> map) {
    return UserTemporal(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      profileImageUrl: map['profileImageUrl'],
      description: map['description'],
      geocercaId: map['geocercaId'],
      entryTime: DateTime.parse(map['entryTime']),
    );
  }
  
  @override
  String toString() {
    return 'UserTemporal(id: $id, fullName: $fullName)';
  }
} 