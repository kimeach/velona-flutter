import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../data/voice_repository.dart';
import '../domain/voice_model.dart';

final _voiceRepoProvider = Provider((ref) => VoiceRepository(ref.watch(dioProvider)));

final voicesProvider = FutureProvider<List<VoiceModel>>((ref) {
  return ref.read(_voiceRepoProvider).getVoices();
});

class VoiceListScreen extends ConsumerStatefulWidget {
  const VoiceListScreen({super.key});

  @override
  ConsumerState<VoiceListScreen> createState() => _VoiceListScreenState();
}

class _VoiceListScreenState extends ConsumerState<VoiceListScreen> {
  bool _cloning = false;

  Future<void> _showCloneDialog() async {
    final nameCtrl = TextEditingController();
    String? selectedFile;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('목소리 복제',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: '목소리 이름 (예: 내 목소리)',
                  labelText: '이름',
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  // 파일 피커 - path_provider 경로 안내
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('파일 피커 기능은 file_picker 패키지 추가 후 사용 가능합니다.'),
                    ),
                  );
                },
                icon: const Icon(Icons.audio_file),
                label: Text(selectedFile != null
                    ? selectedFile!.split('/').last
                    : '오디오 파일 선택 (.mp3, .wav)'),
              ),
              if (selectedFile != null)
                Text(selectedFile!.split('/').last,
                    style: const TextStyle(color: AppColors.textSecond, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: selectedFile != null && nameCtrl.text.isNotEmpty
                  ? () => Navigator.pop(ctx, {
                        'name': nameCtrl.text.trim(),
                        'file': selectedFile!,
                      })
                  : null,
              child: const Text('복제 시작'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();

    if (result != null) {
      setState(() => _cloning = true);
      try {
        await ref.read(_voiceRepoProvider).cloneVoice(
          filePath: result['file']!,
          name: result['name']!,
        );
        ref.invalidate(voicesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('목소리 복제가 완료되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('복제 실패: $e')));
        }
      } finally {
        if (mounted) setState(() => _cloning = false);
      }
    }
  }

  Future<void> _deleteVoice(VoiceModel voice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('목소리 삭제',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('\'${voice.name}\' 목소리를 삭제하시겠습니까?',
            style: const TextStyle(color: AppColors.textSecond)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(_voiceRepoProvider).deleteVoice(voice.voiceId);
        ref.invalidate(voicesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('목소리가 삭제되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final voicesAsync = ref.watch(voicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 목소리 관리'),
        actions: [
          if (_cloning)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '목소리 복제',
              onPressed: _showCloneDialog,
            ),
        ],
      ),
      body: voicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: 12),
              Text(e.toString(), style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(voicesProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (voices) {
          if (voices.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic_none_outlined, size: 48, color: AppColors.textSecond),
                  const SizedBox(height: 16),
                  const Text(
                    '복제된 목소리가 없습니다.\n오른쪽 상단 + 버튼으로 추가하세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecond),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showCloneDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('목소리 복제'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(voicesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: voices.length,
              itemBuilder: (_, i) {
                final v = voices[i];
                final dt = v.createdAt;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.mic, color: AppColors.accent, size: 22),
                    ),
                    title: Text(v.name,
                        style: const TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text(
                      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: AppColors.textSecond, fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => _deleteVoice(v),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
