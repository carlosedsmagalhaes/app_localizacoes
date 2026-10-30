import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Prepara o cache das imagens (tiles) do mapa em uma pasta privada do app.
class CacheMapa {
  static const _nomePasta = 'cache_mapa';
  static const _tamanhoMaximo = 200 * 1024 * 1024; // 200 MB

  static Future<MapCachingProvider> preparar() async {
    // Pasta privada: outros apps não acessam e ela é apagada na desinstalação.
    final pasta = await getApplicationSupportDirectory();

    return BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: p.join(pasta.path, _nomePasta),
      maxCacheSize: _tamanhoMaximo,
    );
  }
}
