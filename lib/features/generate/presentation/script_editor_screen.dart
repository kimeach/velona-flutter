import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../data/generate_repository.dart';

final _repoProvider = Provider((ref) => GenerateRepository(ref.watch(dioProvider)));

class ScriptEditorScreen extends ConsumerStatefulWidget {
  final int projectId;
  const ScriptEditorScreen({super.key, required this.projectId});

  @override
  ConsumerState<ScriptEditorScreen> createState() => _ScriptEditorScreenState();
}

class _ScriptEditorScreenState extends ConsumerState<ScriptEditorScreen> {
  List<Map<String, dynamic>> _clips = [];
  List<TextEditingController> _controllers = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScript();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadScript() async {
    try {
      final clips = await ref.read(_repoProvider).getScript(widget.projectId);
      _controllers = clips.map((c) =>
        TextEditingController(text: c['text'] as String? ?? '')
      ).toList();
      setState(() { _clips = clips; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = List<Map<String, dynamic>>.from(_clips);
      for (int i = 0; i < updated.length; i++) {
        updated[i] = {...updated[i], 'text': _controllers[i].text};
      }
      await ref.read(_repoProvider).updateScript(widget.projectId, updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('대본이 저장되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('대본 편집'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('저장', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : _clips.isEmpty
                  ? const Center(
                      child: Text('대본이 없습니다.', style: TextStyle(color: AppColors.textSecond)),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _clips.length,
                      onReorder: (oldIdx, newIdx) {
                        setState(() {
                          if (newIdx > oldIdx) newIdx--;
                          final clip = _clips.removeAt(oldIdx);
                          final ctrl = _controllers.removeAt(oldIdx);
                          _clips.insert(newIdx, clip);
                          _controllers.insert(newIdx, ctrl);
                        });
                      },
                      itemBuilder: (context, index) {
                        return _ClipCard(
                          key: ValueKey(_clips[index]['clipId'] ?? index),
                          index: index,
                          controller: _controllers[index],
                          clip: _clips[index],
                        );
                      },
                    ),
    );
  }
}

class _ClipCard extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final Map<String, dynamic> clip;

  const _ClipCard({
    super.key,
    required this.index,
    required this.controller,
    required this.clip,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '씬 ${index + 1}',
                    style: const TextStyle(color: AppColors.accent, fontSize: 12),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.drag_handle, color: AppColors.textSecond, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: null,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '대본을 입력하세요...',
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '예상 ${((controller.text.length / 6).ceil()).clamp(1, 999)}초',
              style: const TextStyle(color: AppColors.textSecond, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
