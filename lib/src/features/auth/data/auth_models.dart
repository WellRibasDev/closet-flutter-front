class User {
  const User({
    required this.id,
    required this.email,
    this.nome,
    this.createdAt,
  });

  final String id;
  final String email;
  final String? nome;
  final DateTime? createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      nome: json['nome'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class AuthState {
  const AuthState({this.user, this.token});

  final User? user;
  final String? token;

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  AuthState copyWith({User? user, String? token, bool clear = false}) {
    if (clear) {
      return const AuthState();
    }
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
    );
  }
}
