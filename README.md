# Localizações

Aplicativo Flutter (Android) que coleta a localização do aparelho a cada 20 segundos, salva as posições em um banco SQLite e as apresenta em uma lista e em um mapa interativo.

Atividade 1 – Coleta e visualização de localizações  
Programação para Dispositivos Móveis II – Prof. Arley – FATEC Jacareí

## Integrantes

- Carlos Eduardo da Silva Magalhães
- Andressa Stephane Toledo da Silva

## Funcionalidades

- Iniciar e parar a coleta, com verificação do GPS e da permissão de localização.
- Coleta contínua por stream, em serviço em primeiro plano com notificação.
- Histórico com as últimas 100 posições e opção de limpar todos os registros.
- Mapa do OpenStreetMap com marcadores, a posição mais recente em vermelho e botão para enquadrar os pontos.

## Pacotes utilizados

| Pacote | Uso |
|---|---|
| geolocator | Permissão, GPS e stream de posições |
| permission_handler | Permissão de notificações (Android 13+) |
| sqflite e path | Banco SQLite `localizacoes.db` |
| flutter_map e latlong2 | Mapa interativo |
| path_provider | Pasta privada para o cache do mapa |

## Como executar

```bash
flutter pub get
flutter run
```

É necessário um celular ou emulador Android com a localização ativada.

## Estrutura

```
lib/
├── main.dart
├── app.dart
└── features/localizacoes/
    ├── models/           # Classe Localizacao
    ├── data/             # Banco SQLite e repositório
    ├── services/         # Localização e cache do mapa
    └── presentation/     # Telas e widgets
```

Mapa: © colaboradores do [OpenStreetMap](https://www.openstreetmap.org/copyright).
