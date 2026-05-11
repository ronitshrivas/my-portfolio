import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';
import 'package:innovator/KMS/screens/school/school_complain_history.dart';

enum ComplaintStatus { fromStudent, toAdmin }

class SchoolComplaintBoxStudentScreen extends ConsumerStatefulWidget {
  const SchoolComplaintBoxStudentScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SchoolComplaintBoxStudentScreenState();
}

class _SchoolComplaintBoxStudentScreenState
    extends ConsumerState<SchoolComplaintBoxStudentScreen> {
  ComplaintStatus _selected = ComplaintStatus.fromStudent;
  TextEditingController complaintController = TextEditingController();
  String? _selectedStatus = "All Status";

  @override
  Widget build(BuildContext context) {
    return CustomScrolling(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complaint Management',
            style: AppStyle.bodyText.copyWith(color: Colors.black),
          ),
          SizedBox(height: 5),
          Text(
            'View, file and track all complaints within your school',
            style: TextStyle(fontSize: 10, color: Colors.black),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              _statusElevatedButton(
                label:
                    'From Student (3)', //Give the actual length of the complaint from the school instead of 3
                thisStatus: ComplaintStatus.fromStudent,
              ),
              SizedBox(width: 40),
              _statusElevatedButton(
                label: 'To Admin',

                thisStatus: ComplaintStatus.toAdmin,
              ),
            ],
          ),

          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: 40,
                padding: EdgeInsets.only(right: 20, left: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: DropdownButton(
                  underline: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.transparent),
                    ),
                  ),

                  value: _selectedStatus,
                  items:
                      ["All Status", "Pending", "Solved"]
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _selectedStatus = value),
                ),
              ),
              IconButton(  
                onPressed: () {
                  Get.to(
                    () => SchoolComplainHistoryScreen(),
                    transition: Transition.leftToRight,
                  );
                },
                icon: Icon(Icons.history, color: Colors.black),
              ),
            ],
          ),

          SizedBox(height: 10),
          if (_selected == ComplaintStatus.fromStudent)
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(10),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: AppStyle.backgroundColor,
              child: Column(
                children: [
                  _complaintFromStudent(
                    'Alex Johnson (Grade 5-A)',
                    Icons.person_outline,

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
                  _complaintFromStudent(
                    'Enna Chen (Grade 4-A)',
                    Icons.person_outline,

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
                  _complaintFromStudent(
                    'Marcus Wilson (Grade 5-B)',
                    Icons.person_outline,

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
            )
          else
            _complaintToAdmin(
              'Describe your Complaint in Details',
              'Please Provide as much detail as possible',
              () {},
            ),
        ],
      ),
    );
  }

  Widget _statusElevatedButton({
    required String label,
    required ComplaintStatus thisStatus,
  }) {
    final bool isSelected = _selected == thisStatus;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 1.5,
          ),
        ),
        backgroundColor: isSelected ? Colors.white : AppStyle.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: isSelected ? 10 : 0,
      ),
      onPressed: () => setState(() => _selected = thisStatus),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : AppStyle.bodyTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _complaintToAdmin(
    String heading,
    String hintText,
    VoidCallback onPressed,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: AppStyle.backgroundColor,
      child: Padding(
        padding: EdgeInsets.only(top: 20, right: 20, left: 20, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading, style: TextStyle(fontFamily: 'Inter', fontSize: 15)),
            SizedBox(height: 4),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(20),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: TextFormField(
                controller: complaintController,
                cursorColor: AppStyle.primaryColor,
                maxLines: 15,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  focusColor: Colors.white,

                  hintText: hintText,
                  fillColor: Colors.white,
                  filled: true,

                  hintStyle: TextStyle(
                    // fontFamily: 'Inter',
                    color: Color(0xff6A6A6A),
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  backgroundColor: AppStyle.buttonColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: onPressed,
                child: Text(
                  'Submit',
                  style: TextStyle(
                    color: AppStyle.bodyTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _complaintFromStudent(
    String name,
    IconData personIcon,
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
                          Icon(personIcon),
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
                          SizedBox(width: 10),
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
