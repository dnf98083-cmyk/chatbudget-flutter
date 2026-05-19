class UserModel {
  final int? id;
  final String username;
  final String passwordHash;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.createdAt,
  });

  UserModel copyWith({int? id}) => UserModel(
        id: id ?? this.id,
        username: username,
        passwordHash: passwordHash,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'password_hash': passwordHash,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'],
        username: map['username'],
        passwordHash: map['password_hash'],
        createdAt: DateTime.parse(map['created_at']),
      );
}
