import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/provider/auth_provider.dart';
import 'package:innovator/KMS/provider/notificationProvider.dart';
import 'package:innovator/KMS/provider/teacher_provider.dart';
import 'package:innovator/KMS/provider/user_provider.dart';
import 'package:innovator/KMS/screens/auth/login_screen.dart';
import 'package:innovator/KMS/screens/constant_screen/notifications_screen.dart';

class AppbarScreen extends ConsumerWidget {
  const AppbarScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      iconTheme: IconThemeData(color: AppStyle.primaryColor),
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppStyle.backgroundColor,
      title: SearchBar(
        padding: WidgetStatePropertyAll(EdgeInsets.only(left: 15)),
        leading: Icon(Icons.search, color: Colors.grey),
        hintStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: AppStyle.bodyTextSize,
            color: Colors.grey,
            fontFamily: 'InterThin',
          ),
        ),
        hintText: 'Search',
        backgroundColor: WidgetStatePropertyAll(AppStyle.searchBarColor),
        elevation: WidgetStatePropertyAll(0),
      ),
      actions: [
        InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KMSNotificationScreen(),
                ),
              ),
          child: Consumer(
            builder: (context, ref, _) {
              final unreadAsync = ref.watch(kmsUnreadCountProvider);
              final count = unreadAsync;
              return count > 0
                  ? Badge.count(
                    count: count,
                    child: const Icon(Icons.notifications_outlined, size: 25),
                  )
                  : const Icon(Icons.notifications_outlined, size: 25);
            },
          ),
        ),
        SizedBox(width: 15),
        Container(
          height: 40,
          width: 80,
          margin: EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: AppStyle.primaryColor,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,

            children: [
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: Container(
                  width: 20,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {},
                    icon: const Icon(
                      Icons.person,
                      size: 20,
                      color: AppStyle.primaryColor,
                    ),
                  ),
                ),
              ),
              PopupMenuButton(
                color: Colors.white,
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.white),
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry>[
                      // PopupMenuItem(
                      //   value: 'profile',
                      //   child: Text(
                      //     'Profile',
                      //     style: TextStyle(color: Colors.black),
                      //   ),
                      // ),
                      // PopupMenuItem(
                      //   value: 'settings',
                      //   child: Text(
                      //     'Settings',
                      //     style: TextStyle(color: Colors.black),
                      //   ),
                      // ),
                      PopupMenuItem(
                        value: 'logout',
                        child: Text(
                          'Logout',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      Navigator.pushNamed(context, '/profile');
                      break;
                    case 'settings':
                      Navigator.pushNamed(context, '/settings');
                      break;
                    case 'logout':
                      showAdaptiveDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: AppStyle.alertDialogColor,
                            title: Icon(Icons.logout, size: 50),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: 10),
                                Text(
                                  'Comeback Soon!',
                                  style: AppStyle.heading2,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Are you sure you want to Logout?',
                                  style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        if (Navigator.canPop(context)) {
                                          Navigator.pop(context);
                                        } else {
                                          return;
                                        }
                                      },
                                      child: Text(
                                        'Cancel',
                                        style: AppStyle.errorText,
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        minimumSize: Size(20, 40),
                                        backgroundColor: AppStyle.buttonColor,
                                      ),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await ref.read(authProvider).logout();
                                        ref.invalidate(userDetailsProvider);
                                        ref.invalidate(teacherProfileProvider);
                                        ref.invalidate(kycStatusProvider);
                                        ref.invalidate(salarySlipsProvider);
                                        if (context.mounted) {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => KmsLoginScreen(),
                                            ),
                                            (route) => false,
                                          );
                                        }
                                      },
                                      child: Text(
                                        'Yes Logout',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                      break;
                  }
                  ;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
