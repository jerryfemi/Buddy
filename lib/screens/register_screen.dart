import 'package:buddy/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/auth_provider.dart';
import '../widgets/my_alert_dialog.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final void Function()? onTap;

  const RegisterScreen({super.key, required this.onTap});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  bool showPassword = false;
  bool showConfirmPassword = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _confirmPasswordController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false,),
      body: Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w),
        child: SingleChildScrollView(
          child:
              Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Logo
                      Center(
                            child: Image.asset(
                              'lib/assets/images/buddy_logo.png',
                              width: context.adaptSize(150.w, tab: 130.w),
                              height: context.adaptSize(130.h, tab: 110.h),
                            ),
                          )
                          .animate()
                          .slide(
                            begin: Offset(1, 0),
                            end: Offset.zero,
                            curve: Curves.easeInOut,
                          )
                          .fade(duration: 1.seconds),
                      SizedBox(height: 20.h),

                      // HEADER
                      Text(
                        'Welcome',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),

                      // SUBTITLE
                      Text(
                        'Create your account',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      SizedBox(height: 25.h),

                      // Form Fields
                      Form(
                        autovalidateMode: AutovalidateMode.onUserInteraction,

                        key: _formKey,
                        child: Column(
                          children: [
                            //EMAIL TEXT FIELD
                            TextFormField(
                              keyboardType: TextInputType.emailAddress,
                              controller: _emailController,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              decoration: _decoration(context, 'Email'),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains('@')) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 7.h),

                            // PASSWORD TEXT FIELD
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !showPassword,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              decoration: _decoration(context, 'Password')
                                  .copyWith(
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          showPassword = !showPassword;
                                        });
                                      },
                                      icon: Icon(
                                        showPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        size: 16.sp,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.tertiary,
                                      ),
                                    ),
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (value.trim().length < 6) {
                                  return 'Password must be 6 characters long';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 7.h),

                            // CONFIRM PASSWORD TEXT FIELD
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !showConfirmPassword,
                              decoration: _decoration(
                                context,
                                'Confirm password',
                              ).copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      showConfirmPassword = !showConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    showConfirmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    size: 16.sp,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ), // Form
                      SizedBox(height: 25.h),

                      // SIGN UP BUTTON
                      InkWell(
                        onTap: () async {
                          if (!_formKey.currentState!.validate() ||
                              _passwordController.text.trim() !=
                                  _confirmPasswordController.text.trim()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Passwords do not match')),
                            );
                            return;
                          }
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();

                          try {
                            await ref
                                .read(authNotifierProvider.notifier)
                                .signUpWithEmail(email, password);
                          } catch (e) {
                            // show error dialog
                            if (!context.mounted) return;
                            showDialog(
                              context: context,
                              builder: (context) => MyAlertDialog(
                                content: e is String
                                    ? e
                                    : 'Sign up failed. Please try again.',
                                title: Text('Sign Up failed!'), text: 'ok',
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.adaptPadding(25.w,tab: 20.w),
                            vertical: context.adaptPadding(15.h,tab: 10.h),
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.r),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          child: Center(
                            child: Text(
                              'Sign up',
                              style: TextStyle(fontSize: context.adaptSize(13.sp,tab:10.sp)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 25.h),

                      // GOOGLE SIGN UP BUTTON
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .signInWithGoogle();
                            } catch (e) {
                              // show error dialog
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                builder: (context) => MyAlertDialog(
                                  content: e is String ? e : e.toString(),
                                  title: Text('Sign Up failed!'), text: 'ok',
                                ),
                              );
                            }
                          },
                          label: Text('Sign Up with Google'),
                          icon: Image.asset(
                            'lib/assets/images/search.png',
                            width: context.adaptSize(22.w, tab: 15.w),
                            height: context.adaptSize(22.h, tab: 15.h),
                          ),
                        ),
                      ),
                      SizedBox(height: 15.h),
                      // SignUp option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account?'),
                          TextButton(
                            onPressed: widget.onTap,
                            child: Text('Log in'),
                          ),
                        ],
                      ),
                    ],
                  )
                  .animate()
                  .fade(duration: 1.seconds)
                  .slide(
                    begin: Offset(0, 0.02),
                    end: Offset.zero,
                    curve: Curves.easeInOut,
                  ),
        ),
      ),
    );
  }
}

InputDecoration _decoration(BuildContext context, String hint) {
  return InputDecoration(
    filled: true,
    fillColor: Theme.of(context).colorScheme.secondary,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.secondary,
        width: 2,
      ),
    ),
    hintText: hint,
    hintStyle: TextStyle(color: Theme.of(context).colorScheme.tertiary),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.secondary,
        width: 2,
      ),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}

// // Or divider option
// Expanded(
//   child: Row(
//     mainAxisAlignment: MainAxisAlignment.center,
//     children: [
//       Divider(
//         indent: 25.w,thickness: 2,
//         endIndent: 25.w,
//         color: Colors.black
//       ),
//       Text('or'),
//       Divider(
//         indent: 25.w,
//         endIndent: 25.w,
//         color: Theme.of(context).colorScheme.tertiary,
//       ),
//     ],
//   ),
// ),
