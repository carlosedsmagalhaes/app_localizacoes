// Representa uma linha da tabela localizacoes.
class Localizacao {
  final int? id;
  final double latitude;
  final double longitude;
  final double precisao;
  final DateTime instante;

  const Localizacao({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.precisao,
    required this.instante,
  });

  // Cria o objeto a partir de um mapa retornado pelo SQLite.
  Localizacao.deMapa(Map<String, Object?> mapa)
    : id = mapa['id'] as int,
      latitude = mapa['latitude'] as double,
      longitude = mapa['longitude'] as double,
      precisao = mapa['precisao'] as double,
      instante = DateTime.parse(mapa['instante'] as String);

  // Converte o objeto para o mapa usado no insert().
  // O id não é enviado, pois o banco o gera automaticamente.
  Map<String, Object?> paraMapa() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'precisao': precisao,
      'instante': instante.toUtc().toIso8601String(),
    };
  }
}
