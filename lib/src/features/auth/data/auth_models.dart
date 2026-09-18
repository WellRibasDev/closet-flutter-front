class User {
  const User({
    required this.id,
    required this.email,
    this.nome,
    this.fotoUrl,
    this.createdAt,
  });

  final String id;
  final String email;
  final String? nome;
  final String? fotoUrl;
  final DateTime? createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      nome: json['nome'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? nome,
    String? fotoUrl,
    DateTime? createdAt,
    bool clearFoto = false,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nome: nome ?? this.nome,
      fotoUrl: clearFoto ? null : (fotoUrl ?? this.fotoUrl),
      createdAt: createdAt ?? this.createdAt,
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
