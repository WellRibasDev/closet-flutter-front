class ClothingItem {
  const ClothingItem({
    required this.id,
    required this.nome,
    required this.categoria,
    this.cor,
    this.tamanho,
    this.marca,
    this.observacao,
    this.fotoUrl,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String nome;
  final String categoria;
  final String? cor;
  final String? tamanho;
  final String? marca;
  final String? observacao;
  final String? fotoUrl;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'] as String,
      nome: json['nome'] as String,
      categoria: json['categoria'] as String,
      cor: json['cor'] as String?,
      tamanho: json['tamanho'] as String?,
      marca: json['marca'] as String?,
      observacao: json['observacao'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
      userId: json['userId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'categoria': categoria,
      if (cor != null) 'cor': cor,
      if (tamanho != null) 'tamanho': tamanho,
      if (marca != null) 'marca': marca,
      if (observacao != null) 'observacao': observacao,
      if (fotoUrl != null) 'fotoUrl': fotoUrl,
    };
  }

  ClothingItem copyWith({
    String? id,
    String? nome,
    String? categoria,
    String? cor,
    String? tamanho,
    String? marca,
    String? observacao,
    String? fotoUrl,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      categoria: categoria ?? this.categoria,
      cor: cor ?? this.cor,
      tamanho: tamanho ?? this.tamanho,
      marca: marca ?? this.marca,
      observacao: observacao ?? this.observacao,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class PaginatedClothing {
  const PaginatedClothing({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<ClothingItem> data;
  final int page;
  final int limit;
  final int total;

  bool get hasMore => page * limit < total;

  factory PaginatedClothing.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>? ?? [])
        .map((e) => ClothingItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedClothing(
      data: list,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? list.length,
    );
  }
}
