import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../projects/presentation/projects_provider.dart';
import '../data/generate_repository.dart';

final _generateRepoProvider = Provider(
  (ref) => GenerateRepository(ref.watch(dioProvider)),
);

class GenerateScreen extends ConsumerStatefulWidget {
  final int projectId;
  const GenerateScreen({super.key, required this.projectId});

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen> {
  final _tickerCtrl = TextEditingController();
  String _voice = 'ko-KR-InJoonNeural';
  int _duration = 60;
  bool _loading = false;
  String? _error;

  static const _voices = [
    ('ko-KR-InJoonNeural', '남성 (InJoon)'),
    ('ko-KR-SunHiNeural', '여성 (SunHi)'),
    ('ko-KR-HyunsuMultilingualNeural', '남성 다국어 (Hyunsu)'),
  ];

  static const _popularTickers = [
    'AAPL', 'TSLA', 'NVDA', 'MSFT', 'GOOGL',
    'AMZN', 'META', '005930.KS', '035720.KS',
  ];

  @override
  void dispose() {
    _tickerCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final ticker = _tickerCtrl.text.trim().toUpperCase();
    if (ticker.isEmpty) {
      setState(() => _error = '종목 코드를 입력해주세요.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(_generateRepoProvider).generateStock(
        projectId: widget.projectId,
        ticker: ticker,
        voice: _voice,
        targetDuration: _duration,
      );
      ref.invalidate(projectsProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('영상 생성')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 종목코드
            const Text('종목 코드', style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _tickerCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'ex) AAPL, TSLA, 005930.KS',
              ),
            ),
            const SizedBox(height: 8),

            // 빠른 선택
            Wrap(
              spacing: 6,
              children: _popularTickers.map((t) => ActionChip(
                label: Text(t, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
                onPressed: () => _tickerCtrl.text = t,
              )).toList(),
            ),
            const SizedBox(height: 24),

            // 목소리
            const Text('TTS 목소리', style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
            const SizedBox(height: 6),
            ...(_voices.map((v) => RadioListTile<String>(
              value: v.$1,
              groupValue: _voice,
              title: Text(v.$2, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              contentPadding: EdgeInsets.zero,
              dense: true,
              onChanged: (val) => setState(() => _voice = val!),
            ))),
            const SizedBox(height: 16),

            // 목표 길이
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('목표 길이', style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
                Text('$_duration 초', style: const TextStyle(color: AppColors.accent)),
              ],
            ),
            Slider(
              value: _duration.toDouble(),
              min: 30,
              max: 180,
              divisions: 10,
              activeColor: AppColors.accent,
              onChanged: (v) => setState(() => _duration = v.round()),
            ),
            const SizedBox(height: 24),

            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _generate,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('생성 시작', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
