import 'package:app_localizacoes/features/localizacoes/data/database/banco_localizacoes.dart';
import 'package:app_localizacoes/features/localizacoes/models/localizacao.dart';

// Único ponto do app que executa operações na tabela localizacoes.
class RepositorioLocalizacoes {
  static const _tabela = 'localizacoes';

  const RepositorioLocalizacoes();

  // INSERT: grava uma localização e retorna o id gerado.
  Future<int> inserir(Localizacao localizacao) async {
    final banco = await BancoLocalizacoes.obter();
    return banco.insert(_tabela, localizacao.paraMapa());
  }

  // SELECT: retorna as mais recentes primeiro, limitadas a [limite].
  Future<List<Localizacao>> consultarRecentes({int limite = 100}) async {
    final banco = await BancoLocalizacoes.obter();
    final registros = await banco.query(
      _tabela,
      orderBy: 'id DESC',
      limit: limite,
    );

    return registros.map((registro) => Localizacao.deMapa(registro)).toList();
  }

  // DELETE sem WHERE: remove todas as linhas e mantém a tabela.
  Future<int> excluirTodas() async {
    final banco = await BancoLocalizacoes.obter();
    return banco.delete(_tabela);
  }
}
