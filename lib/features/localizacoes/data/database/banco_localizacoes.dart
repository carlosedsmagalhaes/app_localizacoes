import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class BancoLocalizacoes {
  static const _nomeArquivo = 'localizacoes.db';
  static const _versao = 1;

  // Guarda a abertura em andamento ou concluída para reutilizar a conexão.
  static Future<Database>? _conexao;

  static Future<Database> obter() {
    // Abre o banco somente na primeira chamada.
    return _conexao ??= _abrir();
  }

  static Future<Database> _abrir() async {
    try {
      final pasta = await getDatabasesPath();

      return await openDatabase(
        p.join(pasta, _nomeArquivo),
        version: _versao,
        // Executado apenas quando o banco ainda não existe.
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE localizacoes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              precisao REAL NOT NULL,
              instante TEXT NOT NULL
            )
          ''');
        },
      );
    } catch (erro) {
      // Permite uma nova tentativa na próxima chamada de obter().
      _conexao = null;
      rethrow;
    }
  }
}
