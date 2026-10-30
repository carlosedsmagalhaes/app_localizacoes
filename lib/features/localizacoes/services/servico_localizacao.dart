import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

// Resultado da verificação feita antes de iniciar a coleta.
enum SituacaoAcesso {
  autorizado,
  servicoDesativado,
  negado,
  negadoPermanentemente,
}

class ServicoLocalizacao {
  const ServicoLocalizacao();

  // Verifica o GPS e a permissão, solicitando-a quando possível.
  Future<SituacaoAcesso> verificarAcesso() async {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();

    if (!servicoAtivo) {
      return SituacaoAcesso.servicoDesativado;
    }

    var permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    if (permissao == LocationPermission.deniedForever) {
      return SituacaoAcesso.negadoPermanentemente;
    }

    if (permissao == LocationPermission.whileInUse ||
        permissao == LocationPermission.always) {
      return SituacaoAcesso.autorizado;
    }

    return SituacaoAcesso.negado;
  }

  // No Android 13 ou superior, a notificação da coleta só aparece
  // se o usuário autorizar notificações.
  Future<bool> solicitarNotificacoes() async {
    final status = await Permission.notification.request();
    return status == PermissionStatus.granted;
  }

  // Stream que entrega uma nova posição aproximadamente a cada 20 segundos.
  Stream<Position> fluxoDePosicoes() {
    final configuracao = AndroidSettings(
      accuracy: LocationAccuracy.high,
      intervalDuration: const Duration(seconds: 20),
      // Mantém a coleta em um serviço em primeiro plano, com notificação.
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Coleta de localização ativa',
        notificationText: 'O app está registrando sua localização.',
        notificationChannelName: 'Coleta de localização',
        notificationIcon: AndroidResource(name: 'ic_notificacao_localizacao'),
        setOngoing: true,
      ),
    );

    return Geolocator.getPositionStream(locationSettings: configuracao);
  }

  Future<bool> abrirConfiguracoesDoApp() {
    return Geolocator.openAppSettings();
  }

  Future<bool> abrirConfiguracoesDeLocalizacao() {
    return Geolocator.openLocationSettings();
  }
}
