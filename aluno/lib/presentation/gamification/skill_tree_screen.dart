import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SkillTreeScreen extends StatelessWidget {
  const SkillTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Módulos'),
        backgroundColor: AppTheme.surfaceSecondary,
      ),
      body: const Center(
        child: Text(
          'Skill Tree — Em desenvolvimento',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
        ),
      ),
    );
  }
}
