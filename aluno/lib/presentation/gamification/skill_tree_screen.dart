import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/remote/student_repository.dart';
import '../../data/models/topic.dart';

// Provider que recebe o courseId e vai buscar os tópicos
final topicsProvider = FutureProvider.family<List<Topic>, int>((ref, courseId) {
  return ref.watch(studentRepositoryProvider).getTopics(courseId);
});

class CoursePathScreen extends ConsumerWidget {
  final int courseId;
  final String courseName;

  const CoursePathScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider(courseId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(courseName, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surfaceSecondary,
        elevation: 0,
      ),
      body: topicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erro ao carregar tópicos: $e',
              style: const TextStyle(color: AppTheme.textSecondary)),
        ),
        data: (topics) => topics.isEmpty
            ? const Center(
                child: Text('Sem tópicos disponíveis.',
                    style: TextStyle(color: AppTheme.textSecondary)),
              )
            : SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: List.generate(topics.length, (index) {
                    final topic = topics[index];
                    final alignment = index % 2 == 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight;

                    return Column(
                      children: [
                        if (index > 0) _PathConnector(),
                        Align(
                          alignment: alignment,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: index % 2 == 0 ? 48 : 0,
                              right: index % 2 != 0 ? 48 : 0,
                            ),
                            child: _TopicNode(
                              topic: topic,
                              index: index,
                              courseId: courseId,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
      ),
    );
  }
}

class _PathConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Center(
        child: Container(
          width: 3,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.brandAccent.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _TopicNode extends StatelessWidget {
  final Topic topic;
  final int index;
  final int courseId;

  const _TopicNode({
    required this.topic,
    required this.index,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTopicDetail(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.brandAccent, width: 3),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppTheme.brandAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 160,
            child: Text(
              topic.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTopicDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              topic.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
              
                },
                child: const Text('Começar'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}