import 'package:flutter/material.dart';

import 'package:app_localizacoes/features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'package:app_localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:app_localizacoes/features/localizacoes/presentation/widgets/item_localizacao.dart';

class TelaLocalizacoes extends StatefulWidget {
  // Informa se a coleta estava ativa quando a tela foi aberta.
  final bool coletaAtiva;

  const TelaLocalizacoes({super.key, required this.coletaAtiva});

  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  final _repositorio = const RepositorioLocalizacoes();

  List<Localizacao> _localizacoes = [];
  bool _carregando = true;
  bool _excluindo = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final localizacoes = await _repositorio.consultarRecentes();
      if (!mounted) return;
      setState(() => _localizacoes = localizacoes);
    } catch (erro, stackTrace) {
      debugPrint('Erro ao carregar o histórico: $erro');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar o histórico.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _confirmarLimpeza() async {
    final aviso = widget.coletaAtiva
        ? '\n\nA coleta está ativa: novos registros continuarão sendo salvos.'
        : '';

    // showDialog devolve o valor passado em Navigator.pop.
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Limpar histórico'),
          content: Text(
            'Todas as localizações salvas serão excluídas, inclusive as que '
            'não aparecem na lista. Esta operação é permanente.$aviso',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Limpar histórico'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    // null acontece quando o usuário fecha a janela tocando fora dela.
    if (confirmado == true) {
      await _limparHistorico();
    }
  }

  Future<void> _limparHistorico() async {
    setState(() => _excluindo = true);

    try {
      await _repositorio.excluirTodas();
      if (!mounted) return;
      _mostrarMensagem('Histórico limpo com sucesso.');
      await _carregar();
    } catch (erro, stackTrace) {
      debugPrint('Erro ao limpar o histórico: $erro');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _mostrarMensagem('Não foi possível limpar o histórico.');
    } finally {
      if (mounted) setState(() => _excluindo = false);
    }
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Widget _construirLista() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_erro!),
            TextButton(
              onPressed: _carregar,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_localizacoes.isEmpty) {
      return const Center(child: Text('Nenhuma localização registrada.'));
    }

    return ListView.builder(
      itemCount: _localizacoes.length,
      itemBuilder: (context, index) {
        return ItemLocalizacao(
          localizacao: _localizacoes[index],
          // A primeira da lista é a mais recente.
          destaque: index == 0,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = _carregando || _excluindo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: ocupado ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Limpar histórico',
            onPressed: ocupado ? null : _confirmarLimpeza,
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: _construirLista(),
    );
  }
}
