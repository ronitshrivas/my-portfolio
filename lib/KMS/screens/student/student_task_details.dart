import 'package:dotted_border/dotted_border.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/core/constants/mediaquery.dart'; 

class StudentTaskDetailsScreen extends ConsumerWidget {
  const StudentTaskDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppStyle.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,
        leading:
            Navigator.canPop(context)
                ? IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: AppStyle.backgroundColor,
                  ),
                )
                : null,
        title: Text(
          'Task Details',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            color: AppStyle.bodyTextColor,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: context.screenHeight * 0.018,
          bottom: context.screenHeight * 0.02,
          right: context.screenWidth * 0.04,
          left: context.screenWidth * 0.04,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chapter 1: Basics of Electronics',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Task- 1',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Analyze the concept of Resistor, Capacitor, Inductors, Diodes,Transistors',
              ),
              SizedBox(height: 20),
              completionIndicator('80', 80, 20),
              SizedBox(height: 15),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),

                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 10,

                  mainAxisSpacing: 7,
                ),

                children: [
                  FittedBox(
                    child: overViewCard(
                      'assets/kms/time.png',
                      '2 Days, 48 hours',
                      'Time Remaining',
                      Color(0xffFEEFD7),
                    ),
                  ),
                  FittedBox(
                    child: overViewCard(
                      'assets/kms/star.png',
                      '100 points, 20% of grade',
                      'Points',
                      Color(0xffDDFFE7),
                    ),
                  ),
                ],
              ),
              overViewCard(
                'assets/kms/calender_outlined.png',
                colors: AppStyle.primaryColor,
                'November 25, 2025- 11:59 P.M',
                'Time Remaining',
                Color(0xfffff7d6),
              ),
              SizedBox(height: 10),
              Divider(thickness: 1.3, color: Color(0xffD9D9D9)),
              SizedBox(height: 16),
              Text(
                'Task Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 14),
              Container(
                padding: EdgeInsets.only(
                  right: 10,
                  left: 10,
                  top: 15,
                  bottom: 15,
                ),
                decoration: BoxDecoration(
                  // color:Color(0xffD9D9D9)
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Color(0xffD9D9D9)),
                ),
                child: Row(
                  children: [
                    Image.asset('assets/kms/progress.png'),
                    Text('In Progress'),
                  ],
                ),
              ),
              SizedBox(height: 25),
              Divider(color: Color(0xffD9D9D9)),
              dropDown(
                image: 'assets/kms/task_description.png',
                'Task Description',
                'Will be updated soon',
              ),
              dropDown(
                image: 'assets/kms/requirement.png',
                'Requirements',
                'Will be updated soon',
              ),
              dropDown('Resources', 'Will be updated soon'),
              SizedBox(height: 25),
              Row(
                children: [
                  Image.asset('assets/kms/submit.png'),
                  SizedBox(width: 10),
                  Text(
                    'Submit Your Work',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                  ),
                ],
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: (){},
                child: DottedBorder(
                  options: RoundedRectDottedBorderOptions(
                    dashPattern: [10, 5],
                    strokeWidth: 2,
                
                    radius: Radius.circular(10),
                  ),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    padding: EdgeInsets.only(bottom: 10),
                
                    decoration: BoxDecoration(color: Colors.white),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/kms/upload.png'),
                
                        Text(
                          'Click to upload or drag and drop',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text('PDF or DOCX (Max 10MB)', style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),),
                      ],
                    ),
                  ),
                ),
              ),
               SizedBox(height: 40),
               Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Cancel', style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),),
                        SizedBox(width:50,),
                       ElevatedButton(
                        
                        style: ElevatedButton.styleFrom(
                          elevation: 3,
                          backgroundColor: AppStyle.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)
                          )
                        ),
                        onPressed: (){}, child: Text('Submit',style: TextStyle(
                      color: AppStyle.bodyTextColor
                       ),))
                ],
               )
            ],
          ),
        ),
      ),
    );
  }

  Widget completionIndicator(
    String completionPercentage,
    int completedPercentage,
    int pendingPercentage,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completion',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${completionPercentage}%',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 6),
        Builder(
          builder: (context) {
            final completed = completedPercentage;
            final pending = pendingPercentage;
            final total = completed + pending;
            final double completedRatio = total == 0 ? 0.0 : completed / total;
            final int completedFlex = (completedRatio * 1000).round();
            final int pendingFlex = (1000 - completedFlex).round();
            return ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(10),
              child: Container(
                width: double.infinity,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppStyle.primaryColor,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: completedFlex,
                      child: Container(color: AppStyle.primaryColor),
                    ),

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
      ],
    );
  }

  Widget overViewCard(
    String image,
    String value,
    String label,
    Color color, {
    Color? colors,
  }) {
    return Card(
      elevation: 5,
      child: Container(
        decoration: BoxDecoration(
          color: color,

          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Image.asset(image, color: colors),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: AppStyle.bodyText.copyWith(
                            color: Colors.black,
                            fontFamily: 'InterThin',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          value,
                          style: TextStyle(
                            color: Color(0xff6A6A6A),
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
    );
  }

  Widget dropDown(String question, String answer, {String? image}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpansionTile(
          shape: Border.all(color: Colors.transparent),
          expansionAnimationStyle: AnimationStyle(
            curve: Curves.easeIn,
            reverseCurve: Curves.decelerate,
          ),
          expandedAlignment: Alignment.bottomLeft,
          backgroundColor: Colors.white,
          title: Text(
            question,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          ),
          // leading: image != null? Image.asset(  image ):null,
          leading:
              image != null ? Image.asset(image) : const SizedBox(width: 26),
          children: [
            GestureDetector(
              onTap: () {
                // Incase for navigating
              },
              child: Text(answer),
            ),
          ],
        ),
        Divider(thickness: 1, color: Color(0xffD9D9D9)),
      ],
    );
  }
}
