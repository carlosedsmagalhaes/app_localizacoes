import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:app_localizacoes/features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'package:app_localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:app_localizacoes/features/localizacoes/presentation/screens/tela_localizacoes.dart';
import 'package:app_localizacoes/features/localizacoes/presentation/screens/tela_mapa.dart';
import 'package:app_localizacoes/features/localizacoes/presentation/widgets/item_localizacao.dart';
import 'package:app_localizacoes/features/localizacoes/services/servico_localizacao.dart';

class TelaColeta extends StatefulWidget {
  const TelaColeta({super.key});

  @override
  State<TelaColeta> createState() => _TelaColetaState();
}

class _TelaColetaState extends State<TelaColeta> {
  final _servico = const ServicoLocalizacao();
  final _repositorio = const RepositorioLocalizacoes();

  // Assinatura do stream de posições. Diferente de null = coleta ativa.
  StreamSubscription<void>? _assinatura;

  bool _iniciando = false;
  bool _mostrarConfiguracoesLocalizacao = false;
  int _salvasNestaColeta = 0;
  Localizacao? _ultimaSalva;
  String _mensagem = 'Pressione Iniciar coleta para registrar sua localização.';

  bool get _coletando => _assinatura != null;

  Future<void> _iniciarColeta() async {
    // Evita assinaturas duplicadas.
    if (_coletando || _iniciando) return;

    setState(() {
      _iniciando = true;
      _mostrarConfiguracoesLocalizacao = false;
      _mensagem = 'Verificando a localização e as permissões...';
    });

    try {
      final situacao = await _servico.verificarAcesso();
      if (!mounted) return;

      if (situacao != SituacaoAcesso.autorizado) {
        setState(() {
          _mensagem = _orientacao(situacao);
          _mostrarConfiguracoesLocalizacao =
              situacao == SituacaoAcesso.servicoDesativado;
        });
        return;
      }

      final notificacoesPermitidas = await _servico.solicitarNotificacoes();
      if (!mounted) return;

      // asyncMap só entrega a próxima posição depois que a gravação
      // anterior terminar. Assim, as gravações nunca se sobrepõem.
      _assinatura = _servico
          .fluxoDePosicoes()
          .asyncMap(_salvarPosicao)
          .listen((_) {}, onError: _tratarErroDaColeta);

      setState(() {
        _salvasNestaColeta = 0;
        _mensagem = notificacoesPermitidas
            ? 'Coleta ativa. Aguardando a primeira posição...'
            : 'Coleta ativa. Para ver a notificação da coleta, permita '
                  'notificações em Configurações de permissão.';
      });
    } catch (erro, stackTrace) {
      debugPrint('Erro ao iniciar a coleta: $erro');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _mensagem = 'Não foi possível iniciar a coleta.');
    } finally {
      if (mounted) setState(() => _iniciando = false);
    }
  }

  String _orientacao(SituacaoAcesso situacao) {
    switch (situacao) {
      case SituacaoAcesso.servicoDesativado:
        return 'Ative a localização do aparelho e tente novamente.';
      case SituacaoAcesso.negado:
        return 'A coleta depende da permissão de localização. '
            'Pressione Iniciar coleta para solicitá-la novamente.';
      case SituacaoAcesso.negadoPermanentemente:
        return 'A permissão de localização foi bloqueada. Habilite-a em '
            'Configurações de permissão.';
      case SituacaoAcesso.autorizado:
        return 'Acesso autorizado.';
    }
  }

  // Chamado pelo stream a cada posição recebida.
  Future<void> _salvarPosicao(Position posicao) async {
    final localizacao = Localizacao(
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      precisao: posicao.accuracy,
      instante: posicao.timestamp.toUtc(),
    );

    try {
      await _repositorio.inserir(localizacao);
      if (!mounted) return;
      setState(() {
        _salvasNestaColeta++;
        _ultimaSalva = localizacao;
        _mensagem = 'Coleta ativa.';
      });
    } catch (erro, stackTrace) {
      debugPrint('Erro ao salvar a posição: $erro');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a posição.')),
      );
    }
  }

  // Erros do stream, como a localização desativada durante a coleta.
  void _tratarErroDaColeta(Object erro) {
    debugPrint('Erro na coleta: $erro');
    _assinatura?.cancel();
    _assinatura = null;

    if (!mounted) return;
    setState(() {
      _mensagem = erro is LocationServiceDisabledException
          ? 'A localização do aparelho foi desativada. Coleta interrompida.'
          : 'Não foi possível obter a localização. Coleta interrompida.';
    });
  }

  Future<void> _pararColeta() async {
    final assinatura = _assinatura;
    if (assinatura == null) return;

    setState(() {
      _assinatura = null;
      _mensagem = 'Coleta interrompida.';
    });

    // Cancelar a assinatura encerra o stream e o serviço em primeiro plano.
    await assinatura.cancel();
  }

  Future<void> _abrirConfiguracoes({required bool doAplicativo}) async {
    try {
      final abriu = doAplicativo
          ? await _servico.abrirConfiguracoesDoApp()
          : await _servico.abrirConfiguracoesDeLocalizacao();
      if (!mounted) return;
      if (!abriu) _informarFalhaNasConfiguracoes();
    } catch (erro) {
      if (!mounted) return;
      _informarFalhaNasConfiguracoes();
    }
  }

  void _informarFalhaNasConfiguracoes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir as configurações.')),
    );
  }

  void _abrirHistorico() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TelaLocalizacoes(coletaAtiva: _coletando),
      ),
    );
  }

  void _abrirMapa() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const TelaMapa()),
    );
  }

  @override
  void dispose() {
    // Libera a assinatura se a tela for descartada com a coleta ativa.
    _assinatura?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ultimaSalva = _ultimaSalva;

    return Scaffold(
      appBar: AppBar(title: const Text('Coleta de localizações')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  _coletando ? Icons.gps_fixed : Icons.gps_off,
                  color: _coletando ? Colors.green : Colors.grey,
                ),
                title: Text(_coletando ? 'Coleta ativa' : 'Coleta parada'),
                subtitle: Text(
                  'Posições salvas nesta coleta: $_salvasNestaColeta',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(_mensagem),
            if (_mostrarConfiguracoesLocalizacao) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _abrirConfiguracoes(doAplicativo: false),
                child: const Text('Ativar localização do aparelho'),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _coletando || _iniciando ? null : _iniciarColeta,
              child: const Text('Iniciar coleta'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _coletando ? _pararColeta : null,
              child: const Text('Parar coleta'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _abrirHistorico,
              child: const Text('Consultar histórico'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _abrirMapa,
              child: const Text('Ver mapa'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _abrirConfiguracoes(doAplicativo: true),
              child: const Text('Configurações de permissão'),
            ),
            if (_iniciando) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
            if (ultimaSalva != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Última posição salva',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Card(child: ItemLocalizacao(localizacao: ultimaSalva)),
            ],
          ],
        ),
      ),
    );
  }
}
