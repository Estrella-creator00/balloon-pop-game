import 'package:flutter/material.dart';

import 'services/settings_service.dart';

/// ON-01 최초 닉네임 설정 화면.
class NicknameOnboardingPage extends StatefulWidget {
  const NicknameOnboardingPage({
    super.key,
    required this.onCompleted,
  });

  final VoidCallback onCompleted;

  @override
  State<NicknameOnboardingPage> createState() => _NicknameOnboardingPageState();
}

class _NicknameOnboardingPageState extends State<NicknameOnboardingPage> {
  late final TextEditingController _controller;
  String? _error;
  bool _submitting = false;

  bool get _isValid =>
      SettingsService.normalizeNickname(_controller.text) != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: SettingsService.nickname ?? '');
  }

  void _submit() {
    if (_submitting) return;
    final normalized = SettingsService.normalizeNickname(_controller.text);
    if (normalized == null) {
      setState(() => _error = '닉네임은 2자 이상 10자 이하로 입력해 주세요.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    if (!SettingsService.completeNicknameOnboarding(normalized)) {
      setState(() => _submitting = false);
      return;
    }
    widget.onCompleted();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('nickname-onboarding-page'),
      backgroundColor: const Color(0xFFE8F8FF),
      body: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x333B7995),
                      blurRadius: 22,
                      offset: Offset(0, 9),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _OnboardingLogo(),
                      const SizedBox(height: 24),
                      const Text(
                        '닉네임을 정해주세요 🎈',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFFF4F7B),
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        '게임에서 사용할 이름이에요',
                        style: TextStyle(
                          color: Color(0xFF688596),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        key: const ValueKey('onboarding-nickname-input'),
                        controller: _controller,
                        autofocus: true,
                        maxLength: SettingsService.maxNicknameLength,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() => _error = null),
                        onSubmitted: (_) {
                          if (_isValid) _submit();
                        },
                        decoration: InputDecoration(
                          hintText: '2~10자',
                          errorText: _error,
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFFF4FAFD),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFD4EAF2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6B9D),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE45B6E),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          key: const ValueKey('onboarding-start-button'),
                          onPressed: _isValid && !_submitting ? _submit : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4F7B),
                            disabledBackgroundColor: const Color(0xFFFFB5C7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 4,
                            shadowColor: const Color(0x55D93469),
                          ),
                          child: const Text(
                            '시작하기',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingLogo extends StatelessWidget {
  const _OnboardingLogo();

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(2, 4),
            child: const Text(
              'POPPOP',
              style: TextStyle(
                color: Color(0xFF663199),
                fontSize: 43,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
          ),
          Text(
            'POPPOP',
            style: TextStyle(
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [Color(0xFFFFD83D), Color(0xFFFF6B9D)],
                ).createShader(const Rect.fromLTWH(0, 0, 240, 60)),
              fontSize: 43,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              shadows: const [
                Shadow(color: Colors.white, blurRadius: 2),
              ],
            ),
          ),
        ],
      );
}
