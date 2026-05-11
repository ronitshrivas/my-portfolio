import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/core/constants/mediaquery.dart';
import 'package:innovator/KMS/provider/constant_provider.dart';
import 'package:innovator/KMS/screens/auth/login_screen.dart'; 

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ForgotPasswordScreen();
}

class _ForgotPasswordScreen extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/kms/auth_backgroundimage.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(
                      top: context.screenHeight*0.02,
                bottom: context.screenHeight*.05,
                right: context.screenWidth*0.05,
               left:   context.screenWidth*0.05,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ColorFilter.mode(
                    Color(0xffC3C9CD),

                    BlendMode.dstOver,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white60,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Put the logo here after logo is designed
                            Image.asset(
                              'assets/kms/key.png',
                              width: 60,
                              height: 60,
                              color: AppStyle.primaryColor,
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              'Reset Password',
                              style: AppStyle.heading1.copyWith(
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // ),
                            const SizedBox(height: 16),

                            // Email / Username
                            textFormField(
                              formFieldTopText: 'EMAIL',
                              controller: emailController,

                              icon: Icons.mail_outline,
                            ),
                              SizedBox(height: context.screenHeight*0.03),

               
                           

                            //Password Reset Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    isLoading
                                        ? null
                                        : () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            //Handle Password Reset
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppStyle.buttonColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    isLoading
                                        ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                        : Text(
                                          'Reset Password',
                                          style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                            SizedBox(height: context.screenHeight*0.03,),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Remembered Your Password? ',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => KmsLoginScreen(),
                                      ),
                                    );
                                  },
                                  child:  Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: AppStyle.mediumText,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: context.screenHeight*0.07,)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget textFormField({
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    required String formFieldTopText,
    String? fieldId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formFieldTopText,
          style: TextStyle(
            fontSize: AppStyle.mediumText,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 5,),
        Consumer(
          builder: (context, ref, child) {
            final obscureText =
                isPassword && fieldId != null
                    ? ref.watch(obscureProvider(fieldId))
                    : false;

            return TextFormField(
              controller: controller,
              obscureText: obscureText,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelStyle: const TextStyle(color: Colors.black),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                suffixIcon:
                    isPassword && fieldId != null
                        ? IconButton(
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            // Toggle the obscure state
                            ref.read(obscureProvider(fieldId).notifier).state =
                                !obscureText;
                          },
                        )
                        : null,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $formFieldTopText';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }
}
