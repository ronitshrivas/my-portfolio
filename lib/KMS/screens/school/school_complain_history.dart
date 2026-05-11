import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/core/constants/mediaquery.dart';

class SchoolComplainHistoryScreen extends ConsumerWidget {
  const SchoolComplainHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppStyle.backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back_ios, color: AppStyle.bodyTextColor),
              )
            : null,
      
        // backgroundColor: AppStyle.backgroundColor,
        backgroundColor: AppStyle.primaryColor,
        title: Text(
          'My Complaints',
          style: AppStyle.bodyText.copyWith(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            top: context.screenHeight * 0.018,
            bottom: context.screenHeight * 0.02,
            right: context.screenWidth * 0.04,
            left: context.screenWidth * 0.04,
          ),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(10),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            color: AppStyle.backgroundColor,
            child: Column(
              children: [
                _myComplaint(
                  'Alex Johnson ',

                  Icons.calendar_today_outlined,

                  () {
                    // Navigation for clicking the reply button
                  },

                  '2025-01-08 14:30', //Time later from the backend
                  'PENDING', //give the status according to the backend result
                  'HIGH', //priority from the backend
                  'Technical Issue with Robotics Module', //title of the complaint later from the backend

                  'The robotics simulation software keeps crashing during the programming exercise. I\'ve tried refreshing multiple times but the issue persists.',
                  //description of the complaint later from the backend
                  'Admin', // message given by position later from the backend
                  'Thank you for reporting this issue. Our IT team is looking into the robotics simulation problem.',
                  //actual message  given by will come from the backend
                ),
                _myComplaint(
                  'Enna Chen',

                  Icons.calendar_today_outlined,

                  () {
                    // Navigation for clicking the reply button
                  },

                  '2025-03-08 12:30', //Time later from the backend
                  'RESOLVED', //give the status according to the backend result
                  'MEDIUM', //priority from the backend
                  'Difficulty Understanding 3D Design ', //title of the complaint later from the backend

                  'The robotics simulation software keeps crashing during the programming exercise. I\'ve tried refreshing multiple times but the issue persists.',
                  //description of the complaint later from the backend
                  'Admin', // message given by position later from the backend
                  'Thank you for reporting this issue. Our IT team is looking into the robotics simulation problem.',
                  //actual message  given by will come from the backend
                ),
                _myComplaint(
                  'Marcus Wilson',

                  Icons.calendar_today_outlined,

                  () {
                    // Navigation for clicking the reply button
                  },

                  '2025-6-08 1:00', //Time later from the backend
                  'IN PROGRESS', //give the status according to the backend result
                  'MEDIUM', //priority from the backend
                  'Tutor Not Available for Scheduled Session', //title of the complaint later from the backend

                  'My mathematics tutor didn\'t show up for our scheduled session yesterday. This is the second time this month',
                  //description of the complaint later from the backend
                  'Admin', // message given by position later from the backend
                  'Thank you for reporting this issue. Our IT team is looking into the robotics simulation problem.',
                  //actual message  given by will come from the backend
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _myComplaint(
    String name,

    IconData timeIcon,

    VoidCallback reply,
    String time,
    String status,
    String priority,
    String title,
    String description,
    String messageBy,
    String message,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: 20, right: 20, left: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: 0,
                  right: 20,
                  left: 20,
                  bottom: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12),
                    Text(
                      title,
                      style: AppStyle.bodyText.copyWith(
                        color: Colors.black,
                        fontFamily: 'InterThin',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    FittedBox(
                      child: Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(width: 16),
                          Icon(timeIcon),
                          SizedBox(width: 5),
                          Text(
                            time,
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(width: 50),
                          ElevatedButton.icon(
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                Color(0xffDDFFE7),
                              ),
                            ),
                            icon: Icon(Icons.reply, color: Colors.black),
                            onPressed: reply,
                            label: Text(
                              'Reply',
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: AppStyle.fontFamilySecondary,
                                height: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.only(
                            right: 25,
                            left: 25,
                            top: 5,
                            bottom: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                status == 'PENDING'
                                    ? const Color(0xffFFF4C2)
                                    : status == 'RESOLVED'
                                    ? AppStyle.primaryColor
                                    : const Color(0xffC2F0FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color:
                                  status == 'RESOLVED'
                                      ? AppStyle.bodyTextColor
                                      : Colors.black,
                              fontSize: 10,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        SizedBox(width: 22),
                        Container(
                          padding: EdgeInsets.only(
                            right: 25,
                            left: 25,
                            top: 5,
                            bottom: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                priority == 'HIGH'
                                    ? const Color(0xffFFD9D9)
                                    : priority == 'MEDIUM'
                                    ? Color(0xffFB923C).withAlpha(100)
                                    : AppStyle.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            priority,

                            style: TextStyle(
                              color:
                                  priority == 'HIGH'
                                      ? Colors.black
                                      : priority == 'MEDIUM'
                                      ? Colors.black
                                      : AppStyle.bodyTextColor,

                              fontSize: 10,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      description,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),

                    if (status == 'IN PROGRESS' || status == "RESOLVED")
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(color: Colors.grey),

                          Text(
                            'Conversation:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (status == 'IN PROGRESS' || status == "RESOLVED")
                            SizedBox(height: 13)
                          else
                            SizedBox.shrink(),
                          Card(
                            shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(30),
                                topLeft: Radius.elliptical(75, 20),
                                bottomRight: Radius.circular(35),
                                bottomLeft: Radius.circular(20),
                              ),
                            ),
                            margin: EdgeInsets.all(0),
                            color: AppStyle.primaryColor,
                            child: Card(
                              margin: EdgeInsets.only(
                                top: 0,
                                bottom: 10,
                                left: 15,
                              ),
                              color: Color(0xffDDFFE7),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: 10,
                                  bottom: 10,
                                  left: 10,
                                  right: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        time,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      messageBy,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily:
                                            AppStyle.fontFamilySecondary,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      message,
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
