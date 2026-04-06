import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../projects/presentation/projects_provider.dart';
import '../data/generate_repository.dart';
import '../domain/question_model.dart';
import '../domain/ai_result_models.dart';

final _generateRepoProvider = Provider(
  (ref) => GenerateRepository(ref.watch(dioProvider)),
);

// ─── 카테고리 정의 ─────────────────────────────────────────────────────────

const _categories = [
  _Category('stock', '미국 주식', Icons.show_chart, '주식 종목 분석 쇼츠 자동 생성'),
  _Category('crypto', '암호화폐', Icons.currency_bitcoin, '코인 시세 분석 쇼츠 자동 생성'),
  _Category('korea', '한국 주식', Icons.flag, '한국 주식 종목 분석 쇼츠 자동 생성'),
  _Category('macro_news', '매크로 뉴스', Icons.public, '글로벌 경제 뉴스 쇼츠 자동 생성'),
];

class _Category {
  final String key;
  final String label;
  final IconData icon;
  final String desc;
  const _Category(this.key, this.label, this.icon, this.desc);
}

const _templates = [
  _Template('dark_blue', '다크 블루', Color(0xFF1E3A8A)),
  _Template('dark_emerald', '다크 에메랄드', Color(0xFF065F46)),
  _Template('dark_red', '다크 레드', Color(0xFF7F1D1D)),
];

class _Template {
  final String key;
  final String label;
  final Color color;
  const _Template(this.key, this.label, this.color);
}

// ─── 빠른 입력 값 ──────────────────────────────────────────────────────────

const _quickValues = {
  'stock': ['AAPL', 'TSLA', 'NVDA', 'MSFT', 'GOOGL', 'AMZN', 'META', 'NFLX'],
  'crypto': ['BTC', 'ETH', 'XRP', 'SOL', 'DOGE', 'ADA'],
  'korea': ['005930.KS', '035720.KS', '000660.KS', '051910.KS', '035420.KS'],
  'macro_news': <String>[],
};

// ─── Screen ────────────────────────────────────────────────────────────────

class GenerateScreen extends ConsumerStatefulWidget {
  final int projectId;
  const GenerateScreen({super.key, required this.projectId});

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen> {
  // 단계: 0=카테고리, 1=템플릿, 2=설문, 3=생성중
  int _step = 0;

  String _category = 'stock';
  String _templateId = 'dark_blue';
  String _voice = 'ko-KR-InJoonNeural';
  int _duration = 60;

  List<QuestionModel> _questions = [];
  bool _questionsLoading = false;
  final Map<String, dynamic> _answers = {};

  bool _generating = false;
  String? _error;

  // 트렌딩
  List<TrendingTopicModel> _trending = [];

  static const _voices = [
    ('ko-KR-InJoonNeural', '남성 (InJoon)'),
    ('ko-KR-SunHiNeural', '여성 (SunHi)'),
    ('ko-KR-HyunsuMultilingualNeural', '남성 다국어 (Hyunsu)'),
  ];

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    try {
      final topics = await ref.read(_generateRepoProvider).getTrendingTopics();
      if (mounted) setState(() => _trending = topics);
    } catch (_) {}
  }

  Future<void> _loadQuestions(String category) async {
    setState(() { _questionsLoading = true; _questions = []; });
    try {
      final questions = await ref.read(_generateRepoProvider).getQuestions(category);
      if (mounted) {
        setState(() {
          _questions = questions;
          _questionsLoading = false;
          // 기본값 채우기
          for (final q in questions) {
            if (q.defaultVal != null && !_answers.containsKey(q.keyName)) {
              _answers[q.keyName] = q.defaultVal;
            }
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _questionsLoading = false);
    }
  }

  Future<void> _generate() async {
    setState(() { _generating = true; _error = null; });
    try {
      final options = Map<String, dynamic>.from(_answers);
      options['voice'] = _voice;
      options['target_duration'] = _duration;

      await ref.read(_generateRepoProvider).generate(
        category: _category,
        options: options,
        templateId: _templateId,
      );
      ref.invalidate(projectsProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() { _error = e.toString(); _generating = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle()),
        leading: _step > 0
            ? BackButton(onPressed: () => setState(() { _step--; _error = null; }))
            : null,
      ),
      body: IndexedStack(
        index: _step,
        children: [
          _CategoryStep(
            selected: _category,
            trending: _trending,
            onSelect: (cat) {
              setState(() { _category = cat; _answers.clear(); });
              _loadQuestions(cat);
              setState(() => _step = 1);
            },
          ),
          _TemplateStep(
            selected: _templateId,
            onSelect: (t) => setState(() { _templateId = t; _step = 2; }),
          ),
          _QuestionsStep(
            category: _category,
            questions: _questions,
            loading: _questionsLoading,
            answers: _answers,
            voice: _voice,
            duration: _duration,
            voices: _voices,
            quickValues: _quickValues[_category] ?? [],
            error: _error,
            generating: _generating,
            onAnswerChanged: (k, v) => setState(() => _answers[k] = v),
            onVoiceChanged: (v) => setState(() => _voice = v),
            onDurationChanged: (v) => setState(() => _duration = v),
            onGenerate: _generate,
          ),
        ],
      ),
    );
  }

  String _stepTitle() {
    switch (_step) {
      case 0: return '카테고리 선택';
      case 1: return '템플릿 선택';
      default: return '옵션 설정';
    }
  }
}

// ─── Step 0: 카테고리 ───────────────────────────────────────────────────────

class _CategoryStep extends StatelessWidget {
  final String selected;
  final List<TrendingTopicModel> trending;
  final void Function(String) onSelect;

  const _CategoryStep({
    required this.selected,
    required this.trending,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 트렌딩 토픽
        if (trending.isNotEmpty) ...[
          const Text('트렌딩 토픽', style: TextStyle(color: AppColors.textSecond, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trending.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Chip(
                label: Text(trending[i].topic, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        const Text('생성 카테고리', style: TextStyle(color: AppColors.textSecond, fontSize: 12)),
        const SizedBox(height: 12),

        ..._categories.map((cat) => _CategoryTile(
          category: cat,
          selected: selected == cat.key,
          onTap: () => onSelect(cat.key),
        )),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final _Category category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(category.icon, color: AppColors.accent, size: 22),
        ),
        title: Text(category.label,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Text(category.desc,
            style: const TextStyle(color: AppColors.textSecond, fontSize: 12)),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.accent)
            : const Icon(Icons.chevron_right, color: AppColors.textSecond),
        onTap: onTap,
      ),
    );
  }
}

// ─── Step 1: 템플릿 ─────────────────────────────────────────────────────────

class _TemplateStep extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _TemplateStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('템플릿을 선택하세요', style: TextStyle(color: AppColors.textSecond, fontSize: 12)),
        const SizedBox(height: 16),
        ..._templates.map((t) => _TemplateTile(
          template: t,
          selected: selected == t.key,
          onTap: () => onSelect(t.key),
        )),
      ],
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final _Template template;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateTile({required this.template, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: template.color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        title: Text(template.label,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.accent)
            : const Icon(Icons.chevron_right, color: AppColors.textSecond),
        onTap: onTap,
      ),
    );
  }
}

// ─── Step 2: 설문 + 옵션 ───────────────────────────────────────────────────

class _QuestionsStep extends StatelessWidget {
  final String category;
  final List<QuestionModel> questions;
  final bool loading;
  final Map<String, dynamic> answers;
  final String voice;
  final int duration;
  final List<(String, String)> voices;
  final List<String> quickValues;
  final String? error;
  final bool generating;
  final void Function(String, dynamic) onAnswerChanged;
  final void Function(String) onVoiceChanged;
  final void Function(int) onDurationChanged;
  final VoidCallback onGenerate;

  const _QuestionsStep({
    required this.category,
    required this.questions,
    required this.loading,
    required this.answers,
    required this.voice,
    required this.duration,
    required this.voices,
    required this.quickValues,
    this.error,
    required this.generating,
    required this.onAnswerChanged,
    required this.onVoiceChanged,
    required this.onDurationChanged,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 서버에서 받은 설문 질문들
          if (questions.isNotEmpty) ...[
            ...questions.map((q) => _QuestionWidget(
              question: q,
              value: answers[q.keyName],
              quickValues: q.keyName == 'ticker' || q.keyName == 'symbol'
                  ? quickValues
                  : [],
              onChanged: (v) => onAnswerChanged(q.keyName, v),
            )),
            const SizedBox(height: 16),
          ],

          // 설문 없을 때 fallback (ticker 직접 입력)
          if (questions.isEmpty && (category == 'stock' || category == 'crypto' || category == 'korea')) ...[
            const Text('종목 코드', style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
            const SizedBox(height: 6),
            _TickerField(
              value: answers['ticker'] as String? ?? '',
              quickValues: quickValues,
              onChanged: (v) => onAnswerChanged('ticker', v),
            ),
            const SizedBox(height: 20),
          ],

          // TTS 목소리
          const Text('TTS 목소리', style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
          const SizedBox(height: 6),
          ...voices.map((v) => RadioListTile<String>(
            value: v.$1,
            groupValue: voice,
            title: Text(v.$2, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            contentPadding: EdgeInsets.zero,
            dense: true,
            onChanged: (val) => onVoiceChanged(val!),
          )),
          const SizedBox(height: 16),

          // 목표 길이
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('목표 길이', style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
              Text('$duration 초', style: const TextStyle(color: AppColors.accent)),
            ],
          ),
          Slider(
            value: duration.toDouble(),
            min: 30,
            max: 180,
            divisions: 10,
            activeColor: AppColors.accent,
            onChanged: (v) => onDurationChanged(v.round()),
          ),
          const SizedBox(height: 24),

          if (error != null) ...[
            Text(error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: generating ? null : onGenerate,
              child: generating
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
    );
  }
}

class _QuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final dynamic value;
  final List<String> quickValues;
  final void Function(dynamic) onChanged;

  const _QuestionWidget({
    required this.question,
    required this.value,
    required this.quickValues,
    required this.onChanged,
  });

  @override
  State<_QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<_QuestionWidget> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(q.label,
                  style: const TextStyle(color: AppColors.textSecond, fontSize: 13)),
              if (q.required)
                const Text(' *', style: TextStyle(color: AppColors.error, fontSize: 13)),
            ],
          ),
          if (q.description != null) ...[
            const SizedBox(height: 2),
            Text(q.description!,
                style: const TextStyle(color: AppColors.textSecond, fontSize: 11)),
          ],
          const SizedBox(height: 6),
          _buildInput(q),
          if (widget.quickValues.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: widget.quickValues.map((v) => ActionChip(
                label: Text(v, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
                onPressed: () {
                  _ctrl.text = v;
                  widget.onChanged(v);
                },
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInput(QuestionModel q) {
    switch (q.type) {
      case 'single':
        final opts = q.options;
        if (opts.isEmpty) break;
        return DropdownButtonFormField<String>(
          value: widget.value as String?,
          dropdownColor: AppColors.surface,
          decoration: const InputDecoration(),
          items: opts.map((o) => DropdownMenuItem(
            value: o.value,
            child: Text(o.label, style: const TextStyle(color: AppColors.textPrimary)),
          )).toList(),
          onChanged: (v) => widget.onChanged(v),
        );

      case 'multi':
        final opts = q.options;
        final selected = (widget.value as List<dynamic>? ?? []).map((e) => e.toString()).toSet();
        return Column(
          children: opts.map((o) => CheckboxListTile(
            value: selected.contains(o.value),
            title: Text(o.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeColor: AppColors.accent,
            onChanged: (checked) {
              final newSet = Set<String>.from(selected);
              if (checked == true) { newSet.add(o.value); } else { newSet.remove(o.value); }
              widget.onChanged(newSet.toList());
            },
          )).toList(),
        );

      case 'number':
        return TextField(
          controller: _ctrl,
          keyboardType: TextInputType.number,
          onChanged: (v) => widget.onChanged(double.tryParse(v) ?? v),
          decoration: InputDecoration(
            hintText: q.defaultVal ?? '',
          ),
        );

      default: // text
        break;
    }

    return TextField(
      controller: _ctrl,
      textCapitalization: TextCapitalization.characters,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: q.defaultVal ?? '',
      ),
    );
  }
}

class _TickerField extends StatefulWidget {
  final String value;
  final List<String> quickValues;
  final void Function(String) onChanged;

  const _TickerField({
    required this.value,
    required this.quickValues,
    required this.onChanged,
  });

  @override
  State<_TickerField> createState() => _TickerFieldState();
}

class _TickerFieldState extends State<_TickerField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          textCapitalization: TextCapitalization.characters,
          onChanged: widget.onChanged,
          decoration: const InputDecoration(hintText: 'ex) AAPL, TSLA, 005930.KS'),
        ),
        if (widget.quickValues.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: widget.quickValues.map((v) => ActionChip(
              label: Text(v, style: const TextStyle(fontSize: 12)),
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
              onPressed: () {
                _ctrl.text = v;
                widget.onChanged(v);
              },
            )).toList(),
          ),
        ],
      ],
    );
  }
}
