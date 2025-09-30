import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:writeright/new/ui/view_model/login.dart';

class LoginPage extends StatefulWidget {
  final _formKey = GlobalKey<FormState>();

  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: viewModel.backgroundImage, // Background image
          ),

          // Content overlay
          LayoutBuilder(
            builder: (context, constraints) {
              // Check if the screen width is larger than 800px
              final isWideScreen = constraints.maxWidth > 800;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800), // Max width of the container
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9), // Slight opacity for overlay
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: isWideScreen
                        ? Row(
                            children: [
                              // Left side: Icon and welcome text
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    viewModel.iconImage,
                                    SizedBox(height: 16.0),
                                    Text(
                                      'Welcome Back!',
                                      style: TextStyle(
                                        fontSize: 24.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              // Divider
                              const SizedBox(width: 24.0), // Add spacing between sides
                              Container(
                                width: 1.0,
                                height: 300.0,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 24.0), // Add spacing between sides

                              // Right side: Login Form
                              Expanded(
                                flex: 2,
                                child: _buildLoginForm(viewModel, showIcon: false),
                              ),
                            ],
                          )
                        : _buildLoginForm(viewModel, showIcon: true), // Single-column layout for smaller screens
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(LoginViewModel viewModel, {required bool showIcon}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showIcon)
          const Icon(Icons.lock, size: 72.0, color: Colors.blue),
        if (showIcon) const SizedBox(height: 24.0),
        const Text(
          'Login',
          style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24.0),

        // Login Form
        Form(
          key: widget._formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                // Email Field
                TextFormField(
                  controller: viewModel.emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: viewModel.validateEmail,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    if (viewModel.passwordController.text.isNotEmpty &&
                        !viewModel.isLoading) {
                      viewModel.login(context, widget._formKey);
                    } else {
                      _passwordFocusNode.requestFocus();
                    }
                  },
                ),
                const SizedBox(height: 16.0),

                // Password Field
                TextFormField(
                  controller: viewModel.passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: viewModel.validatePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!viewModel.isLoading) {
                      viewModel.login(context, widget._formKey);
                    }
                  },
                ),
                const SizedBox(height: 24.0),

                // Login Button
                ElevatedButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => viewModel.login(context, widget._formKey),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40.0,
                      vertical: 12.0,
                    ),
                    child: viewModel.isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text('Login'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24.0),

        // Error Message
        if (viewModel.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              viewModel.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),

        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('OR'),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24.0),

        // Social Login Buttons
        _socialLoginButton(
          icon: Icons.login,
          label: 'Continue with Google',
          color: Colors.red,
          onPressed: viewModel.loginWithGoogle,
        ),
        const SizedBox(height: 12.0),
        _socialLoginButton(
          icon: Icons.facebook,
          label: 'Continue with Facebook',
          color: Colors.blue,
          onPressed: viewModel.loginWithFacebook,
        ),
      ],
    );
  }

  Widget _socialLoginButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          side: const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}