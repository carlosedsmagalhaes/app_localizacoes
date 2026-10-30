import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:app_localizacoes/features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'package:app_localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:app_localizacoes/features/localizacoes/presentation/widgets/mapa_localizacoes.dart';
import 'package:app_localizacoes/features/localizacoes/services/cache_mapa.dart';

class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key});

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  final _repositorio = const RepositorioLocalizacoes();

  List<Localizacao> _localizacoes = [];
  MapCachingProvider? _cache;
  bool _carregando = true;
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
      // Prepara o cache antes de o mapa carregar as imagens.
      final cache = await CacheMapa.preparar();
      final localizacoes = await _repositorio.consultarRecentes();

      if (!mounted) return;

      setState(() {
        _cache = cache;
        _localizacoes = localizacoes;
      });
    } catch (erro, stackTrace) {
      debugPrint('Erro ao carregar o mapa: $erro');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar o mapa.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Widget _construirConteudo() {
    final cache = _cache;

    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null || cache == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_erro ?? 'Não foi possível carregar o mapa.'),
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

    return MapaLocalizacoes(localizacoes: _localizacoes, cache: cache);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _construirConteudo(),
    );
  }
}
