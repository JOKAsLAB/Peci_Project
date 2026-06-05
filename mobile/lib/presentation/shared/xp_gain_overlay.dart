import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Overlay flutuante que aparece depois de uma resposta correta mostrando o XP ganho.
class XpGainOverlay {
  static void show(
    BuildContext context, {
    required int xp,
    bool levelUp = false,
    int newLevel = 1,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _XpBadge(
        xp: xp,
        levelUp: levelUp,
        newLevel: newLevel,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _XpBadge extends StatefulWidget {
  final int xp;
  final bool levelUp;
  final int newLevel;
  final VoidCallback onDone;

  const _XpBadge({required this.xp, required this.levelUp, required this.newLevel, required this.onDone});

  @override
  State<_XpBadge> createState() => _XpBadgeState();
}

class _XpBadgeState extends State<_XpBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
    ]).animate(_ctrl);
    _slide = Tween(begin: const Offset(0, 0.3), end: const Offset(0, -0.5))
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_ctrl);
    _ctrl.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.25,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _slide,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.brandAccent,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: AppTheme.brandAccent.withValues(alpha: 0.5), blurRadius: 16, spreadRadius: 2),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '+${widget.xp} XP',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    if (widget.levelUp) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFFFB300).withValues(alpha: 0.5), blurRadius: 12),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Nível ${widget.newLevel}!',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
