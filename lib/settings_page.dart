import 'package:flutter/material.dart';

import 'services/settings_service.dart';

abstract final class AppVersion {
  static const current = '1.0.0';
}

/// SET-01 설정 메인.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.onDataReset,
  });

  final VoidCallback onDataReset;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _editNickname() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => NicknameEditDialog(
        initialNickname: SettingsService.nickname ?? '',
      ),
    );
    if (saved == true && mounted) setState(() {});
  }

  void _openInfo({
    required String title,
    required String content,
    required String pageKey,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsInfoPage(
          title: title,
          content: content,
          pageKey: pageKey,
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const SettingsResetDialog(),
    );
    if (confirmed != true || !mounted) return;
    SettingsService.resetAllData();
    widget.onDataReset();
    setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('게임 데이터가 초기화되었습니다.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('settings-page'),
      backgroundColor: const Color(0xFFE8F8FF),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Column(
          children: [
            _SettingsHeader(
              title: '설정',
              onBack: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                key: const ValueKey('settings-scroll'),
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  _SettingsSectionCard(
                    title: '플레이어',
                    children: [
                      _SettingsRow(
                        key: const ValueKey('settings-nickname-row'),
                        icon: Icons.person_rounded,
                        label: '닉네임',
                        trailingText: SettingsService.nickname ?? '설정 안 됨',
                        onTap: _editNickname,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SettingsSectionCard(
                    title: '게임 설정',
                    children: [
                      _SettingsSwitchRow(
                        key: const ValueKey('settings-sound-row'),
                        icon: Icons.volume_up_rounded,
                        label: '효과음',
                        value: SettingsService.soundEnabled,
                        switchKey: const ValueKey('settings-sound-switch'),
                        onChanged: (enabled) {
                          SettingsService.setSoundEnabled(enabled);
                          setState(() {});
                        },
                      ),
                      const _SettingsDivider(),
                      _SettingsSwitchRow(
                        key: const ValueKey('settings-haptic-row'),
                        icon: Icons.vibration_rounded,
                        label: '진동',
                        value: SettingsService.hapticEnabled,
                        switchKey: const ValueKey('settings-haptic-switch'),
                        onChanged: (enabled) {
                          SettingsService.setHapticEnabled(enabled);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SettingsSectionCard(
                    title: '정보',
                    children: [
                      _SettingsRow(
                        key: const ValueKey('settings-terms-row'),
                        icon: Icons.description_rounded,
                        label: '이용약관',
                        onTap: () => _openInfo(
                          title: '이용약관',
                          content: '정식 서비스 출시 전 이용약관이 제공될 예정입니다.',
                          pageKey: 'settings-terms-page',
                        ),
                      ),
                      const _SettingsDivider(),
                      _SettingsRow(
                        key: const ValueKey('settings-privacy-row'),
                        icon: Icons.privacy_tip_rounded,
                        label: '개인정보처리방침',
                        onTap: () => _openInfo(
                          title: '개인정보처리방침',
                          content: '정식 서비스 출시 전 개인정보처리방침이 제공될 예정입니다.',
                          pageKey: 'settings-privacy-page',
                        ),
                      ),
                      const _SettingsDivider(),
                      _SettingsRow(
                        key: const ValueKey('settings-contact-row'),
                        icon: Icons.chat_bubble_rounded,
                        label: '문의하기',
                        onTap: () => _openInfo(
                          title: '문의하기',
                          content: '문의 채널은 정식 출시 전 안내될 예정입니다.',
                          pageKey: 'settings-contact-page',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '버전 ${AppVersion.current}',
                    key: ValueKey('settings-version'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF718A98),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Center(
                    child: TextButton(
                      key: const ValueKey('settings-reset-button'),
                      onPressed: _confirmReset,
                      child: const Text(
                        '데이터 초기화',
                        style: TextStyle(
                          color: Color(0xFFCC5B68),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: Colors.white,
                elevation: 2,
                shadowColor: const Color(0x33003366),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  key: const ValueKey('settings-back-button'),
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF2D70A0),
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFFF4F7B),
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 6),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF315A70),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Material(
            color: Colors.white,
            elevation: 3,
            shadowColor: const Color(0x33204A5F),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Column(children: children),
            ),
          ),
        ],
      );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF42A7D8), size: 23),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF244F68),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (trailingText != null)
                  Flexible(
                    child: Text(
                      trailingText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF718A98),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF91A6B1),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      );
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.switchKey,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final Key switchKey;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 54,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF7354E8), size: 23),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF244F68),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Switch(
                key: switchKey,
                value: value,
                activeTrackColor: const Color(0xFFFF86A8),
                activeThumbColor: const Color(0xFFFF4F7B),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      );
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        indent: 48,
        endIndent: 14,
        color: Color(0xFFE7EFF3),
      );
}

/// SET-02 닉네임 변경 팝업.
class NicknameEditDialog extends StatefulWidget {
  const NicknameEditDialog({super.key, required this.initialNickname});

  final String initialNickname;

  @override
  State<NicknameEditDialog> createState() => _NicknameEditDialogState();
}

class _NicknameEditDialogState extends State<NicknameEditDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNickname);
  }

  void _save() {
    if (!SettingsService.saveNickname(_controller.text)) {
      setState(() => _error = '닉네임은 2자 이상 10자 이하로 입력해 주세요.');
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        key: const ValueKey('nickname-dialog'),
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Material(
            color: Colors.white,
            elevation: 12,
            shadowColor: const Color(0x553B246B),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '닉네임 변경',
                    style: TextStyle(
                      color: Color(0xFFFF4F7B),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('nickname-input'),
                    controller: _controller,
                    autofocus: true,
                    maxLength: SettingsService.maxNicknameLength,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      hintText: '2~10자',
                      errorText: _error,
                      filled: true,
                      fillColor: const Color(0xFFF4FAFD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      key: const ValueKey('nickname-save-button'),
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4F7B),
                      ),
                      child: const Text(
                        '저장',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// SET-03/04/05 공통 정보 화면. 본문만 교체하면 정식 문서로 확장된다.
class SettingsInfoPage extends StatelessWidget {
  const SettingsInfoPage({
    super.key,
    required this.title,
    required this.content,
    required this.pageKey,
  });

  final String title;
  final String content;
  final String pageKey;

  @override
  Widget build(BuildContext context) => Scaffold(
        key: ValueKey(pageKey),
        backgroundColor: const Color(0xFFE8F8FF),
        body: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Column(
            children: [
              _SettingsHeader(
                title: title,
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Material(
                  color: Colors.white,
                  elevation: 3,
                  shadowColor: const Color(0x33204A5F),
                  borderRadius: BorderRadius.circular(20),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        content,
                        style: const TextStyle(
                          color: Color(0xFF415F70),
                          fontSize: 15,
                          height: 1.55,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// SET-06 데이터 초기화 확인 팝업.
class SettingsResetDialog extends StatelessWidget {
  const SettingsResetDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
        key: const ValueKey('settings-reset-dialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          '모든 게임 데이터를 초기화할까요?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          '코인, 구매한 풍선, 장착 상태, 닉네임 및 설정이 모두 초기화됩니다.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('settings-reset-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            key: const ValueKey('settings-reset-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '초기화',
              style: TextStyle(
                color: Color(0xFFCC5B68),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      );
}
