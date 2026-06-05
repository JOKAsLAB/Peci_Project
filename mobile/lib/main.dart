import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Bloqueio rigoroso de orientação (Portrait Lock)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // ProviderScope injeta o contentor de estado global na raiz da árvore
  runApp(const ProviderScope(child: PECIApp()));
}

/// Transição para ConsumerWidget para observação reativa do routerProvider.
class PECIApp extends ConsumerWidget {
  const PECIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A obtenção reativa assegura a reconstrução da árvore de navegação
    // sempre que as dependências do router (ex: estado de autenticação) sofrerem mutação.
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      scrollBehavior: const _NoOverscrollBehavior(),
      routerConfig: goRouter,
    );
  }
}

/// Supressão global do efeito visual de overscroll (stretch/glow) 
/// para prevenir deformações de layout nos limites das listas.
class _NoOverscrollBehavior extends MaterialScrollBehavior {
  const _NoOverscrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}