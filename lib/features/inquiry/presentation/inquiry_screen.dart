import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/inquiry_repository.dart';

final _inquiryRepoProvider = Provider(
  (ref) => InquiryRepository(ref.watch(dioProvider)),
);

class InquiryScreen extends ConsumerStatefulWidget {
  const InquiryScreen({super.key});

  @override
  ConsumerState<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends ConsumerState<InquiryScreen> {
  final _emailCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _sending = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  bool get _isLoggedIn =>
      ref.read(authStateProvider).valueOrNull != null;

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (title.isEmpty || content.isEmpty) {
      setState(() => _error = '제목과 내용을 입력해주세요.');
      return;
    }
    if (!_isLoggedIn && email.isEmpty) {
      setState(() => _error = '이메일을 입력해주세요.');
      return;
    }

    setState(() { _sending = true; _error = null; });
    try {
      if (_isLoggedIn) {
        await ref.read(_inquiryRepoProvider).submitInquiry(
          title: title, content: content,
        );
      } else {
        await ref.read(_inquiryRepoProvider).submitGuestInquiry(
          email: email, title: title, content: content,
        );
      }
      setState(() { _done = true; _sending = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _sending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('1:1 문의')),
      body: _done
          ? const _DoneView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isLoggedIn) ...[
                    const Text('이메일', style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'example@email.com'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('제목', style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(hintText: '문의 제목을 입력해주세요'),
                  ),
                  const SizedBox(height: 16),
                  const Text('내용', style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _contentCtrl,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: '문의 내용을 입력해주세요.\n\n최대한 자세히 작성해주시면 빠르게 도움드릴 수 있습니다.',
                    ),
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
                      onPressed: _sending ? null : _submit,
                      child: _sending
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('문의 전송', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '접수된 문의는 영업일 기준 1~2일 내 이메일로 답변드립니다.',
                    style: TextStyle(color: AppColors.textSecond, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          const Text('문의가 접수되었습니다.',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('영업일 기준 1~2일 내 답변드립니다.',
              style: TextStyle(color: AppColors.textSecond)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
