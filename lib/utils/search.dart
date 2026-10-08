import '../models/local.dart';

String normalizeSearch(String value) {
  const accented = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  var result = value.toLowerCase();
  for (var index = 0; index < accented.length; index++) {
    result = result.replaceAll(accented[index], plain[index]);
  }
  return result.trim();
}

bool matchesLocal(Local local, String query) {
  final terms = normalizeSearch(query).split(RegExp(r'\s+'));
  final categoryNames = switch (normalizeSearch(local.categoria)) {
    'academia' || 'academias' => 'academia academias',
    'restaurante' || 'restaurantes' => 'restaurante restaurantes',
    'hospital' || 'hospitais' => 'hospital hospitais',
    'cafe' || 'cafes' => 'cafe cafes',
    'parque' || 'parques' => 'parque parques',
    'livraria' || 'livrarias' => 'livraria livrarias',
    'mercado' || 'mercados' => 'mercado mercados',
    _ => local.categoria,
  };
  final text = normalizeSearch(
    '${local.nome} $categoryNames ${local.cidade} ${local.endereco}',
  );
  return terms.every(text.contains);
}
