import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:app_localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:app_localizacoes/features/localizacoes/presentation/widgets/item_localizacao.dart';

class MapaLocalizacoes extends StatefulWidget {
  // A primeira localização da lista é a mais recente.
  final List<Localizacao> localizacoes;
  final MapCachingProvider cache;

  const MapaLocalizacoes({
    super.key,
    required this.localizacoes,
    required this.cache,
  });

  @override
  State<MapaLocalizacoes> createState() => _MapaLocalizacoesState();
}

class _MapaLocalizacoesState extends State<MapaLocalizacoes> {
  final _controlador = MapController();

  // Baixa as imagens do mapa usando o cache preparado em CacheMapa.
  late final NetworkTileProvider _provedorDeImagens;

  @override
  void initState() {
    super.initState();
    // Criado uma única vez; o TileLayer o libera quando é descartado.
    _provedorDeImagens = NetworkTileProvider(cachingProvider: widget.cache);
  }

  LatLng _ponto(Localizacao localizacao) {
    return LatLng(localizacao.latitude, localizacao.longitude);
  }

  // Enquadramento que mostra todos os pontos na tela.
  CameraFit _enquadramento() {
    final pontos = widget.localizacoes.map(_ponto).toList();

    return CameraFit.coordinates(
      coordinates: pontos,
      padding: const EdgeInsets.all(48),
      maxZoom: 17,
    );
  }

  void _enquadrarPontos() {
    _controlador.fitCamera(_enquadramento());
  }

  void _mostrarDetalhes(Localizacao localizacao, bool maisRecente) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  maisRecente
                      ? 'Localização mais recente'
                      : 'Localização registrada',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ItemLocalizacao(
                  localizacao: localizacao,
                  destaque: maisRecente,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Marker> _criarMarcadores() {
    final marcadores = <Marker>[];

    // Percorre da mais antiga para a mais recente, para que o marcador
    // vermelho seja desenhado por último e fique por cima dos outros.
    for (final localizacao in widget.localizacoes.reversed) {
      final maisRecente = localizacao == widget.localizacoes.first;

      marcadores.add(
        Marker(
          point: _ponto(localizacao),
          width: 40,
          height: 40,
          // A ponta do ícone fica exatamente sobre a coordenada.
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _mostrarDetalhes(localizacao, maisRecente),
            child: Icon(
              Icons.location_on,
              size: 40,
              color: maisRecente ? Colors.red : Colors.blue,
            ),
          ),
        ),
      );
    }

    return marcadores;
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _controlador,
          options: MapOptions(
            // Enquadra os pontos assim que o mapa é criado.
            initialCameraFit: _enquadramento(),
            maxZoom: 19,
          ),
          children: [
            // Camada de ruas do OpenStreetMap.
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'br.edu.fatec.app_localizacoes',
              tileProvider: _provedorDeImagens,
            ),
            MarkerLayer(markers: _criarMarcadores()),
            // Atribuição exigida pelas regras de uso do OpenStreetMap.
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 48,
          child: FloatingActionButton.small(
            tooltip: 'Enquadrar todos os pontos',
            onPressed: _enquadrarPontos,
            child: const Icon(Icons.fit_screen),
          ),
        ),
      ],
    );
  }
}
