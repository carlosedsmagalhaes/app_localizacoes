import 'package:flutter/material.dart';

import 'package:app_localizacoes/features/localizacoes/models/localizacao.dart';

// Apresenta os dados de uma localização.
// Usado na tela de coleta, na lista do histórico e nos detalhes do mapa.
class ItemLocalizacao extends StatelessWidget {
  final Localizacao localizacao;
  final bool destaque;

  const ItemLocalizacao({
    super.key,
    required this.localizacao,
    this.destaque = false,
  });

  // O banco guarda UTC; a tela apresenta no horário local do aparelho.
  String _formatarDataHora(DateTime instante) {
    final data = instante.toLocal();
    String doisDigitos(int numero) => numero.toString().padLeft(2, '0');

    final dia = [
      doisDigitos(data.day),
      doisDigitos(data.month),
      data.year.toString(),
    ].join('/');
    final horario = [
      doisDigitos(data.hour),
      doisDigitos(data.minute),
      doisDigitos(data.second),
    ].join(':');

    return '$dia $horario';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.location_on,
        color: destaque ? Colors.red : Theme.of(context).colorScheme.primary,
      ),
      title: Text(_formatarDataHora(localizacao.instante)),
      subtitle: Text(
        'Latitude: ${localizacao.latitude.toStringAsFixed(6)}\n'
        'Longitude: ${localizacao.longitude.toStringAsFixed(6)}\n'
        'Precisão: ${localizacao.precisao.toStringAsFixed(1)} m',
      ),
      isThreeLine: true,
    );
  }
}
