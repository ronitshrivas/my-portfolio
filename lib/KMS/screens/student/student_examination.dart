import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

class StudentExaminationScreen extends ConsumerStatefulWidget {
  const StudentExaminationScreen({super.key});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _StudentExaminationScreen();
}

class _StudentExaminationScreen extends ConsumerState<StudentExaminationScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrolling(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Examination',
            style: TextStyle(fontFamily: 'Inter', fontSize: 16),
          ),
          Text('View Upcoming exam, attempt quizzes and check your result.'),
          SizedBox(height: 15),

          listTile('Upcoming Exams', '4', 'assets/kms/upcoming_exams.png'),
          listTile(
            'Completed',
            '1',
            'assets/kms/right.png',
            color: Colors.green,
          ),
          listTile('Current Score', '8/10', 'assets/kms/current_score.png'),
          listTile('Average', '80.0 %', 'assets/kms/average.png'),
          SizedBox(height: 20),
          Container(
            height: 500,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                TabBar(
                  tabAlignment: TabAlignment.center,
                  isScrollable: true,
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  indicatorColor: AppStyle.primaryColor,
                  controller: tabController,

                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Schedule'),
                    Tab(text: 'Marks'),
                    Tab(text: 'Instructions'),
                    Tab(text: 'Results'),
                  ],
                ),
                SizedBox(height: 40),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      overViewTab(),
                      overViewTab(),
                      overViewTab(),
                      overViewTab(),
                      overViewTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20,),
          Card(
            color: Colors.white,
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)
            ),
            child: Padding(
             padding: EdgeInsets.only(top: 15,bottom: 25,right: 15,left: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Important Notes:', style: TextStyle(fontFamily: 'Inter',fontSize: 16.4)),
                  SizedBox(height: 10,),
                  Text(
                    '''1. Keep checking this page regularly for updates and announcements\n2. Contact the instructor if you have any queries regarding examinations\n3. Make sure to review the syllabus and grading criteria\n4. Results will be published within 2 weeks of examination''',
               style: TextStyle(fontSize: 14.8,fontStyle: FontStyle.normal,fontWeight: FontWeight.w500,color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget listTile(
    String title,
    String subtitle,
    String trailingImage, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          borderRadius: BorderRadius.circular(19),
          elevation: 5,
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(19),
            ),
            tileColor: Colors.white,

            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.black,
                fontSize: 14,
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 10, left: 85, bottom: 5),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ),
            trailing: Image.asset(trailingImage, color: color),
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget overViewTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(left: 15, right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Material(
                    color: Color(0xffF8BD00),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(20),
                      bottomLeft: Radius.circular(10),
                    ),
                    child: Container(
                      height: 90,
                      margin: EdgeInsets.only(left: 10, bottom: 1),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 20, left: 13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset('assets/kms/assignment.png'),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Next Exam Alert',
                                      style: TextStyle(
                                        color: Color(0xff7A2721),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Mid-term MCQ scheduled on 2024-12-15 at 10:00 AM',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Column(
              children: [
                completionIndicator(20, 25, 'MCQs (Mid term + Quizzes)'),
                completionIndicator(2, 10, 'Pratical Project'),
                completionIndicator(10, 10, 'Theoretical'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget completionIndicator(
    int obtainedMarks,
    int totalMarks,
    String headingText,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(top: 20, bottom: 20, right: 10, left: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Color(0xffD9D9D9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    headingText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                      color: Color(0xff000000),
                    ),
                  ),

                  Text(
                    '${totalMarks.toString()} Marks',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,

                      color: AppStyle.primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final int obtained = obtainedMarks;
                  final int pending = (totalMarks - obtained).clamp(
                    0,
                    totalMarks,
                  );
                  final int total = obtained + pending;
                  final double completedRatio =
                      total == 0 ? 0.0 : obtained / total;
                  final int completedFlex = (completedRatio * 1000).round();
                  final int pendingFlex = 1000 - completedFlex;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppStyle.primaryColor,
                      ),
                      child: Row(
                        children: [
                          if (completedFlex > 0)
                            Expanded(
                              flex: completedFlex,
                              child: Container(color: AppStyle.primaryColor),
                            ),
                          if (pendingFlex > 0)
                            Expanded(
                              flex: pendingFlex,
                              child: Container(color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 5),
              Text(
                'Obtained: $obtainedMarks/$totalMarks',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xff000000),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 25),
      ],
    );
  }
}
