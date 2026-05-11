import 'package:flutter/material.dart';

class AppStyle {
  static const Color primaryColor = Color(0xff438582);
  static const Color secondaryColor = Color(0xffFEFBEA);
  static const Color  backgroundColor = Color(0xffFEFBEA);
  static const Color buttonColor = Color(0xff438582);
    // Font Families
  static const String fontFamilyPrimary = 'Roboto';
  static const String fontFamilySecondary = 'Inter';

  //Text Sizes
  static const double largeText = 30.0;
  static const double secondLargeText = 28.0;
  static const double mediumText = 16.0;
  static const double smallText = 12.0;
  static const double bodyTextSize = 14.0;
    static const Color textColor = Colors.black;
    static const Color bodyTextColor = Color(0xffFEFCE8);
  static const Color errorColor = Color(0xFFE53935);

//Icon Sizes
static const Size bigIcon = Size(50, 50);
//Searchbar color
static const Color searchBarColor = Color(0xffE8E6D3);
  
  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: largeText,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: mediumText,
    fontWeight: FontWeight.w600,
    color: textColor,
  );
  static const TextStyle errorText = TextStyle(
    fontSize: bodyTextSize,
    color: Colors.red
  );
  static const TextStyle allText = TextStyle(
    fontSize: bodyTextSize,
    color: Colors.black
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: fontFamilySecondary,
    fontSize: bodyTextSize,
    color: bodyTextColor,
  );

  static const TextStyle small = TextStyle(
    fontFamily: fontFamilySecondary,

    color: textColor,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamilySecondary,
  
    color: Colors.grey,
  );
  static const Color alertDialogColor = Colors.white;
}