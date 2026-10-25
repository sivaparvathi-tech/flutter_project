class User {
  final int? id;
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String role;

  const User({
    this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'fullName': fullName,
      'email': email.trim().toLowerCase(),
      'phone': phone,
      'password': password,
      'role': role,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      fullName: map['fullName'],
      email: map['email'],
      phone: map['phone'],
      password: map['password'],
      role: map['role'],
    );
  }
}
