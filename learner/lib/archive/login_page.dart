// import 'package:flutter/material.dart';
// import 'home_page.dart';
// import 'backend/services/dependencies.dart';
// import 'backend/services/auth_service.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   AuthService get _authService => getIt<AuthService>();

//   void _loginWithGoogle() {
//     // TODO: Implement Google SSO
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Google login will be implemented soon')),
//     );
//   }

//   void _loginWithFacebook() {
//     // TODO: Implement Facebook SSO
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Facebook login will be implemented soon')),
//     );
//   }

//   void _login() {
//     if (_formKey.currentState!.validate()) {
//       String email = _emailController.text.trim();
//       String password = _passwordController.text;

//       if (email.isEmpty || password.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Email and password cannot be empty')),
//         );
//         return;
//       }

//       _authService
//           .login(
//         email: email,
//         password: password,
//       )
//           .then((_) {
//         // Navigate to home page on successful login
//         if (!mounted) return; // Check if the widget is still mounted
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const HomePage()),
//         );
//       }).catchError((error) {
//         // Show error message on failed login
//         if (!mounted) return; // Check if the widget is still mounted
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Login failed: $error')),
//         );
//       });

//       // // Example login validation
//       // if (email == 'test@example.com' && password == 'password') {
//       //   Navigator.pushReplacement(
//       //     context,
//       //     MaterialPageRoute(builder: (context) => const HomePage()),
//       //   );
//       // } else {
//       //   ScaffoldMessenger.of(
//       //     context,
//       //   ).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
//       // }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.lock, size: 72.0, color: Colors.blue),
//               const SizedBox(height: 24.0),
//               const Text(
//                 'Login',
//                 style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 24.0),
//               Form(
//                 key: _formKey,
//                 child: AutofillGroup(
//                   child: Column(
//                     children: [
//                       TextFormField(
//                         controller: _emailController,
//                         keyboardType: TextInputType.emailAddress,
//                         autofillHints: const [AutofillHints.username],
//                         decoration: const InputDecoration(
//                           labelText: 'Email',
//                           border: OutlineInputBorder(),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.trim().isEmpty) {
//                             return 'Email is required';
//                           }
//                           if (!RegExp(
//                             r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
//                           ).hasMatch(value)) {
//                             return 'Enter a valid email';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16.0),
//                       TextFormField(
//                         controller: _passwordController,
//                         obscureText: true,
//                         autofillHints: const [AutofillHints.password],
//                         decoration: const InputDecoration(
//                           labelText: 'Password',
//                           border: OutlineInputBorder(),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Password is required';
//                           }
//                           if (value.length < 6) {
//                             return 'Password must be at least 6 characters';
//                           }
//                           return null;
//                         },
//                         onFieldSubmitted: (_) => _login(),
//                       ),
//                       const SizedBox(height: 24.0),
//                       ElevatedButton(
//                         onPressed: _login,
//                         child: const Padding(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: 40.0,
//                             vertical: 12.0,
//                           ),
//                           child: Text('Login'),
//                         ),
//                       ),
//                       const SizedBox(height: 24.0),
//                       const Row(
//                         children: [
//                           Expanded(child: Divider()),
//                           Padding(
//                             padding: EdgeInsets.symmetric(horizontal: 16.0),
//                             child: Text('OR'),
//                           ),
//                           Expanded(child: Divider()),
//                         ],
//                       ),
//                       const SizedBox(height: 24.0),
//                       SizedBox(
//                         width: double.infinity,
//                         child: OutlinedButton.icon(
//                           onPressed: _loginWithGoogle,
//                           icon: const Icon(
//                             Icons.login,
//                             color: Colors.red,
//                           ),
//                           label: const Text('Continue with Google'),
//                           style: OutlinedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 12.0),
//                             side: const BorderSide(color: Colors.grey),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 12.0),
//                       SizedBox(
//                         width: double.infinity,
//                         child: OutlinedButton.icon(
//                           onPressed: _loginWithFacebook,
//                           icon: const Icon(
//                             Icons.facebook,
//                             color: Colors.blue,
//                           ),
//                           label: const Text('Continue with Facebook'),
//                           style: OutlinedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 12.0),
//                             side: const BorderSide(color: Colors.grey),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
