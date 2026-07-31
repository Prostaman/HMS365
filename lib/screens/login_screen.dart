import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../ui_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorText;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await _authService.signIn(
        _emailController.text,
        _passwordController.text,
      );
      // Дальше навигацией управляет StreamBuilder на authStateChanges
      // в main.dart — отдельный Navigator.push здесь не нужен.
    } catch (e) {
      setState(() {
        _errorText = _authService.mapErrorToMessage(e);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Image.asset('assets/logo.png')),
                const SizedBox(height: 20),
                Text(
                  "Добро пожаловать!",
                  style: TextStyle(
                    fontSize: 25,
                    color: colorOrange,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Заполните поля для входа в систему",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Введите email' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Пароль',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Введите пароль' : null,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorText!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Войти в систему',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

///PSN
//          child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   SafeArea(child: SizedBox(height: 44)),
//                   Center(
//                     child: Container(
//                       width: 289,
//                       height: 119,
//                       child: SvgPicture.asset(IMG.icons.logoPNG,
//                           fit: BoxFit.scaleDown),
//                     ),
//                   ),
//                   SizedBox(height: 66),
//                   Text(
//                     "Добро пожаловать!",
//                     style: textStyle(
//                       size: 25,
//                       color: ColorTextOrange,
//                       weight: FontWeight.bold,
//                     ),
//                     textAlign: TextAlign.left,
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     "Заполните поля для входа в систему",
//                     style: textStyle(size: 16, color: Colors.black),
//                     textAlign: TextAlign.left,
//                   ),
//                   SizedBox(height: 46),
//                   DefaultTextField(
//                     key: Key('usernameField'),
//                     initialText: _cubit.signInRequest.login,
//                     placeholder: "Логин",
//                     keyboardType: TextInputType.text,
//                     onChanged: (newValue) {
//                       _cubit.signInRequest.login = newValue;
//                     },
//                   ),
//                   SizedBox(height: 16),
//                   DefaultTextField(
//                     key: Key('passwordField'),
//                     initialText: _cubit.signInRequest.password,
//                     placeholder: "Пароль",
//                     obscureText: true,
//                     keyboardType: TextInputType.visiblePassword,
//                     onChanged: (newValue) {
//                       _cubit.signInRequest.password = newValue;
//                     },
//                   ),
//                   SizedBox(height: 14),
//                   showError
//                       ? Container(
//                           height: 48,
//                           padding: EdgeInsets.symmetric(horizontal: 20),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(8),
//                             color: Color.fromRGBO(237, 57, 57, 0.04),
//                           ),
//                           child: SingleChildScrollView(
//                               // Adding SingleChildScrollView here
//                               scrollDirection: Axis
//                                   .vertical, // Allowing horizontal scrolling
//                               child: Padding(
//                                   padding: EdgeInsets.only(top: 12),
//                                   child: Row(
//                                     children: [
//                                       SvgPicture.asset(IMG.icons.iconWarning,
//                                           fit: BoxFit.scaleDown),
//                                       SizedBox(width: 8),
//                                       Expanded(
//                                           child: Text(
//                                         "${textError ?? ""}",
//                                         style: TextStyle(
//                                           fontSize: 14,
//                                           color: Color.fromRGBO(255, 41, 41, 1),
//                                         ),
//                                       ))
//                                     ],
//                                   ))))
//                       : SizedBox(height: 48),
//                   SizedBox(height: 14),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: DefaultButton(
//                           key: Key('loginButton'),
//                           title: "Войти в систему",
//                           rounded: 10,
//                           textSize: 18,
//                           height: 55,
//                           scheme: DefaultButtonScheme.Orange,
//                           onPressed: () {
//                             showError = false;
//                             _cubit.signIn();
//                           },
//                         ),
//                       )
//                     ],
//                   ),
//                   SafeArea(
//                     child: Container(
//                       child: RichText(
//                         textAlign: TextAlign.center,
//                         text: TextSpan(
//                           children: [
//                             TextSpan(
//                               text:
//                                   "Для получения доступа, обратитесь на Email: ",
//                               style: textStyle(size: 16, color: Colors.black),
//                             ),
//                             TextSpan(
//                               text: "info@poehalisnami.com",
//                               style: textStyle(
//                                 size: 16,
//                                 color: ColorOrange,
//                               ),
//                               recognizer: TapGestureRecognizer()
//                                 ..onTap = () async {
//                                   Clipboard.setData(ClipboardData(
//                                       text: "info@poehalisnami.com"));
//                                   showSnackBar(
//                                     context: context,
//                                     message: "email скопирован в буфер обмена",
//                                     error: false,
//                                   );
//                                 },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 44),
//                 ],
//               ),
//             ),
//           )
