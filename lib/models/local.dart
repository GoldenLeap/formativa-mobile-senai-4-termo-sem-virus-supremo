class Local {
  const Local({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.cidade,
    required this.avaliacao,
    required this.distancia,
    required this.horario,
    required this.descricao,
    required this.favorito,
    this.endereco = '',
    this.telefone = '',
    this.fotos = const [],
    this.totalAvaliacoes = 0,
    this.mapX = .5,
    this.mapY = .5,
  });

  final String id;
  final String nome;
  final String categoria;
  final String cidade;
  final double avaliacao;
  final double distancia;
  final String horario;
  final String descricao;
  final bool favorito;
  final String endereco;
  final String telefone;
  final List<String> fotos;
  final int totalAvaliacoes;

  /// Posição relativa no mapa ilustrativo, entre 0 e 1.
  final double mapX;
  final double mapY;

  factory Local.fromMap(String id, Map<String, dynamic> data) {
    final fotos = data['fotos'];
    return Local(
      id: id,
      nome: _text(data['nome']),
      categoria: _text(data['categoria']),
      cidade: _text(data['cidade']),
      avaliacao: _number(data['avaliacao']),
      distancia: _number(data['distancia']),
      horario: _text(data['horario']),
      descricao: _text(data['descricao']),
      favorito: data['favorito'] == true,
      endereco: _text(data['endereco']),
      telefone: _text(data['telefone']),
      fotos: fotos is Iterable ? fotos.whereType<String>().toList() : const [],
      totalAvaliacoes: _number(data['totalAvaliacoes']).toInt(),
      mapX: _number(data['mapX'], fallback: .5),
      mapY: _number(data['mapY'], fallback: .5),
    );
  }

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'categoria': categoria,
    'cidade': cidade,
    'avaliacao': avaliacao,
    'distancia': distancia,
    'horario': horario,
    'descricao': descricao,
    'favorito': favorito,
    'endereco': endereco,
    'telefone': telefone,
    'fotos': fotos,
    'totalAvaliacoes': totalAvaliacoes,
    'mapX': mapX,
    'mapY': mapY,
  };

  Local copyWith({
    String? id,
    String? nome,
    String? categoria,
    String? cidade,
    double? avaliacao,
    double? distancia,
    String? horario,
    String? descricao,
    bool? favorito,
    String? endereco,
    String? telefone,
    List<String>? fotos,
    int? totalAvaliacoes,
    double? mapX,
    double? mapY,
  }) => Local(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    categoria: categoria ?? this.categoria,
    cidade: cidade ?? this.cidade,
    avaliacao: avaliacao ?? this.avaliacao,
    distancia: distancia ?? this.distancia,
    horario: horario ?? this.horario,
    descricao: descricao ?? this.descricao,
    favorito: favorito ?? this.favorito,
    endereco: endereco ?? this.endereco,
    telefone: telefone ?? this.telefone,
    fotos: fotos ?? this.fotos,
    totalAvaliacoes: totalAvaliacoes ?? this.totalAvaliacoes,
    mapX: mapX ?? this.mapX,
    mapY: mapY ?? this.mapY,
  );

  static String _text(dynamic value) => value is String ? value : '';

  static double _number(dynamic value, {double fallback = 0}) {
    final number = value is num
        ? value.toDouble()
        : value is String
        ? double.tryParse(value)
        : null;
    return number != null && number.isFinite ? number : fallback;
  }
}
