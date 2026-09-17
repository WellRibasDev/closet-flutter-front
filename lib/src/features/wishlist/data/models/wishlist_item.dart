class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.nome,
    this.categoria,
    this.cor,
    this.tamanho,
    this.marca,
    this.precoAlvo,
    this.linkRef,
    this.prioridade = 0,
    this.observacao,
    this.fotoUrl,
    this.comprado = false,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String nome;
  final String? categoria;
  final String? cor;
  final String? tamanho;
  final String? marca;
  final double? precoAlvo;
  final String? linkRef;
  final int prioridade;
  final String? observacao;
  final String? fotoUrl;
  final bool comprado;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as String,
      nome: json['nome'] as String,
      categoria: json['categoria'] as String?,
      cor: json['cor'] as String?,
      tamanho: json['tamanho'] as String?,
      marca: json['marca'] as String?,
      precoAlvo: json['precoAlvo'] == null
          ? null
          : (json['precoAlvo'] as num).toDouble(),
      linkRef: json['linkRef'] as String?,
      prioridade: json['prioridade'] as int? ?? 0,
      observacao: json['observacao'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
      comprado: json['comprado'] as bool? ?? false,
      userId: json['userId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

class PaginatedWishlist {
  const PaginatedWishlist({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<WishlistItem> data;
  final int page;
  final int limit;
  final int total;

  factory PaginatedWishlist.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>? ?? [])
        .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedWishlist(
      data: list,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? list.length,
    );
  }
}
