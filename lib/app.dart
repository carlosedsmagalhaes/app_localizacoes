import 'package:flutter/material.dart';

import 'package:app_localizacoes/features/localizacoes/presentation/screens/tela_coleta.dart';

class AppLocalizacoes extends StatelessWidget {
  const AppLocalizacoes({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Localizações',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TelaColeta(),
    );
  }
}
