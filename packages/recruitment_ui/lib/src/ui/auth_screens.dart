import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../demo/session.dart';
import '../widgets.dart';
import 'scope.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;
  String _dial = '+966';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = DemoScope.of(context).session;
    if (_phone.text.isEmpty && session.phone.isNotEmpty) {
      _phone.text = session.phone;
      _dial = session.dialCode;
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  String? _validate(String? v) {
    final s = DemoScope.of(context).s;
    return switch (PhoneRules.validate(_dial, v ?? '')) {
      null => null,
      'required' => s.x('أدخل رقم الجوال', 'Enter your phone number'),
      'digits' => s.x('أرقام فقط', 'Digits only'),
      _ =>
        _dial == '+966'
            ? s.x(
                'رقم سعودي من 9 أرقام يبدأ بـ 5',
                'Saudi number: 9 digits starting with 5',
              )
            : s.x('رقم جوال غير صحيح', 'Invalid phone number'),
    };
  }

  Future<void> _continue() async {
    final d = DemoScope.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    d.session.setPhone(_dial, _phone.text.trim());
    final ok = await d.session.sendOtp();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pushNamed(DemoRoutes.otp);
    } else {
      setState(
        () => _error = d.s.x('تعذر إرسال الرمز', 'Could not send the code'),
      );
    }
  }

  Future<void> _biometric() async {
    final d = DemoScope.of(context);
    final confirmed = await showRuiDialog<bool>(
      context,
      (ctx) => AlertDialog(
        icon: const Icon(Icons.fingerprint, size: 48),
        title: Text(d.s.x('تسجيل الدخول بالبصمة', 'Biometric login')),
        content: Text(
          d.s.x(
            'محاكاة: لن يتم استخدام مستشعر الجهاز الحقيقي.',
            'Simulation: no real device biometric API is used.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(d.s.x('إلغاء', 'Cancel')),
          ),
          FilledButton(
            key: const ValueKey('biometric-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(d.s.x('تأكيد البصمة', 'Authenticate')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final ok = await d.session.biometricLogin();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(DemoRoutes.main, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: RuiBusy(
        busy: _busy,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Center(child: RuiLogo(logo: d.branding.logo, size: 84)),
                  const SizedBox(height: 12),
                  Text(
                    d.branding.appName(d.lang),
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.x('سجّل الدخول للمتابعة', 'Sign in to continue'),
                    textAlign: TextAlign.center,
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 108,
                        child: DropdownButtonFormField<String>(
                          key: const ValueKey('dial-code'),
                          initialValue: _dial,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: s.x('الرمز', 'Code'),
                          ),
                          items: [
                            for (final c in PhoneRules.dialCodes)
                              DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                          ],
                          onChanged: (v) => setState(() => _dial = v ?? _dial),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          key: const ValueKey('phone-field'),
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: s.x('رقم الجوال', 'Phone number'),
                            hintText: '5XXXXXXXX',
                          ),
                          validator: _validate,
                          onFieldSubmitted: (_) => _continue(),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null)
                    RuiNotice(_error!, kind: BannerKind.error),
                  const SizedBox(height: 16),
                  RuiButton(
                    key: const ValueKey('login-continue'),
                    template: d.template,
                    label: s.x('متابعة', 'Continue'),
                    loading: _busy,
                    onPressed: _continue,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(s.x('أو', 'or'), style: text.bodySmall),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RuiButton(
                    key: const ValueKey('login-biometric'),
                    template: d.template,
                    label: s.x(
                      'الدخول بالبصمة / الوجه',
                      'Fingerprint / Face ID',
                    ),
                    icon: Icons.fingerprint,
                    outlined: true,
                    onPressed: _biometric,
                  ),
                  const SizedBox(height: 24),
                  RuiNotice(
                    s.x(
                      'تجريبي: أي رقم سعودي صحيح مقبول (مثل 500000000)، ورمز التحقق هو ${d.session.repo.demoOtp}.',
                      'Demo: any valid Saudi number works (e.g. 500000000); the verification code is ${d.session.repo.demoOtp}. No SMS is sent.',
                    ),
                    icon: Icons.science_outlined,
                  ),
                  Text(
                    s.x(
                      'تطبيق تجريبي — لا يتم إرسال رسائل حقيقية.',
                      'Demo app — no real messages are sent.',
                    ),
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: scheme.outline),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _length = 6;
  static const _countdownSeconds = 30;

  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _remaining = _countdownSeconds;
  bool _busy = false;
  bool _verified = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _remaining = _countdownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _remaining--);
      if (_remaining <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final d = DemoScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await d.session.verifyOtp(_code.text);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = d.s.x(
          'رمز التحقق غير صحيح. حاول مرة أخرى.',
          'Incorrect code. Please try again.',
        );
      });
      return;
    }
    setState(() {
      _busy = false;
      _verified = true;
    });
    await Future<void>.delayed(d.session.repo.latency ~/ 2);
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(DemoRoutes.main, (_) => false);
  }

  Future<void> _resend() async {
    final d = DemoScope.of(context);
    await d.session.sendOtp();
    if (!mounted) return;
    _code.clear();
    setState(() => _error = null);
    _startTimer();
    showRuiSnack(
      context,
      d.s.x('تم "إرسال" رمز جديد (تجريبي)', 'A new code was "sent" (demo)'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final digits = _code.text;
    return RuiPage(
      title: s.x('رمز التحقق', 'Verification'),
      subtitle: '${d.session.dialCode} ${d.session.phone}',
      bottom: RuiButton(
        key: const ValueKey('otp-verify'),
        template: d.template,
        label: s.x('تحقق', 'Verify'),
        loading: _busy,
        onPressed: digits.length == _length && !_verified ? _verify : null,
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Icon(
            _verified ? Icons.verified : Icons.sms_outlined,
            size: 56,
            color: _verified ? Colors.green : scheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            _verified
                ? s.x('تم التحقق بنجاح', 'Verified successfully')
                : s.x(
                    'أدخل الرمز المكوّن من 6 أرقام',
                    'Enter the 6-digit code',
                  ),
            key: const ValueKey('otp-title'),
            style: text.titleMedium,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _focus.requestFocus,
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.ltr,
                  children: [
                    for (var i = 0; i < _length; i++)
                      Container(
                        width: 44,
                        height: 52,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            d.template.cornerRadius / 1.5,
                          ),
                          border: Border.all(
                            color: _error != null
                                ? scheme.error
                                : (i == digits.length
                                      ? scheme.primary
                                      : scheme.outline),
                            width: i == digits.length ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          i < digits.length ? digits[i] : '',
                          style: text.headlineSmall,
                        ),
                      ),
                  ],
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      key: const ValueKey('otp-field'),
                      controller: _code,
                      focusNode: _focus,
                      autofocus: true,
                      enabled: !_verified,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(_length),
                      ],
                      onChanged: (_) => setState(() => _error = null),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            RuiNotice(_error!, kind: BannerKind.error)
          else if (_verified)
            RuiNotice(
              s.x('جارٍ تحويلك إلى الرئيسية…', 'Taking you to Home…'),
              kind: BannerKind.success,
            ),
          const SizedBox(height: 16),
          if (_remaining > 0)
            Text(
              s.x(
                'إعادة الإرسال بعد $_remaining ثانية',
                'Resend code in ${_remaining}s',
              ),
              key: const ValueKey('otp-countdown'),
              style: text.bodyMedium,
            )
          else
            TextButton(
              key: const ValueKey('otp-resend'),
              onPressed: _resend,
              child: Text(s.x('إعادة إرسال الرمز', 'Resend code')),
            ),
          const SizedBox(height: 16),
          RuiNotice(
            s.x(
              'تجريبي: رمز التحقق هو ${d.session.repo.demoOtp}. لا يتم إرسال رسائل.',
              'Demo: the code is ${d.session.repo.demoOtp}. No SMS is sent.',
            ),
            icon: Icons.science_outlined,
          ),
        ],
      ),
    );
  }
}
