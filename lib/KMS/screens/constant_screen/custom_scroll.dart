import 'package:flutter/material.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/core/constants/mediaquery.dart';
import 'package:innovator/KMS/screens/constant_screen/app_drawer.dart';
import 'package:innovator/KMS/screens/constant_screen/appbar.dart';

class CustomScrolling extends StatelessWidget {
  const CustomScrolling({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppbarScreen(),
      ),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(
            top: context.screenHeight * 0.018,
            bottom: context.screenHeight * 0.02,
            right: context.screenWidth * 0.04,
            left: context.screenWidth * 0.04,
          ),
          child: child,
        ),
      ),
    );
  }
}
