import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';
import 'package:innovator/KMS/screens/student/student_task_details.dart';

class StudentTaskScreen extends ConsumerWidget {
  const StudentTaskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrolling(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasks',
                style: TextStyle(fontFamily: 'Inter', fontSize: 16),
              ),
              Text(
                'View All',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  fontFamily: 'Inter',
                  fontSize: 16,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),
          taskHistory(
            'Chapter 1 :Basic of Electronics',
            'Task- 1',
            'Analyze the concept of Resistor, Capacitor, Inductors, Diodes,Transistors',
            'November 25, 2025- 11:59 P.M.,Tuesday',
            40, //completedvalue
            60, //pendingValue
          ),
          taskHistory(
            'Chapter 2 :Basic of Flutter',
            'Task- 2',
            'Installation of Flutter',
            'November 25, 2025- 11:59 P.M.,Tuesday',
            77, //completedvalue
            23, //pendingValue
      
          ),
        ],
      ),
    );
  }

  Widget taskHistory(
    String title,
    String taksNumber,
    String description,
    String date,
    int completedPercentage,
    int pendingPercentage,
   
  ) {
    return GestureDetector(
      onTap: () {
        Get.to(()=> StudentTaskDetailsScreen(),transition: Transition.leftToRight);
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => StudentTaskDetailsScreen()),
        // );
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(right: 10, left: 10, top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Color(0xffD9D9D9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontFamily: 'InterThin',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 3.5),
                      child: Text(taksNumber, style: TextStyle(fontSize: 12)),
                    ),
                    Builder(
                      builder: (context) {
                        final completed = completedPercentage;
                        final pending = pendingPercentage;
                        final total = completed + pending;
                        final double completedRatio =
                            total == 0 ? 0.0 : completed / total;
                        final int completedFlex =
                            (completedRatio * 1000).round();
                        final int pendingFlex = (1000 - completedFlex).round();
                        return ClipRRect(
                          borderRadius: BorderRadiusGeometry.circular(10),
                          child: Container(
                            width: 100,
                            height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppStyle.primaryColor,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: completedFlex,
                                  child: Container(
                                    color: AppStyle.primaryColor,
                                  ),
                                ),

                                Expanded(
                                  flex: pendingFlex,
                                  child: Container(
                                    height: double.infinity,
                                    color: Colors.grey,
                                    child: Center(
                                      child: FittedBox(
                                        child: Text(
                                          '${completedPercentage.toString()}%',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(description, style: TextStyle(fontSize: 12)),
                SizedBox(height: 8),
                FittedBox(
                  child: Container(
                    padding: EdgeInsets.only(
                      right: 10,
                      bottom: 10,
                      left: 10,
                      top: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Color(0xffFFF9E0),
                    ),
                    child: Row(
                      children: [
                        Image.asset('assets/kms/time.png', height: 20, width: 20),
                        SizedBox(width: 20),
                        Text(
                          date,
                          style: TextStyle(color: Colors.grey, fontSize: 13.3),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 4),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
