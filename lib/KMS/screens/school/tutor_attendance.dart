 

import 'package:flutter/material.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/core/constants/mediaquery.dart';

class TutorAttendanceScreen extends StatefulWidget {
  const TutorAttendanceScreen({super.key});

  @override
  State<TutorAttendanceScreen> createState() => _TutorAttendanceScreenState();
}

class _TutorAttendanceScreenState extends State<TutorAttendanceScreen> {
  String status = 'All Status';

 
  final List<Map<String, String>> teachersData = [
    {'sn': '1', 'name': 'Karthik Sharma', 'attendance': 'Absent', 'present': '5', 'absent': '5'},
    {'sn': '2', 'name': 'Kishore Pandey', 'attendance': 'Present', 'present': '10', 'absent': '10'},
    {'sn': '3', 'name': 'Anubhav Khanal', 'attendance': 'Present', 'present': '5', 'absent': '5'},
    {'sn': '4', 'name': 'Kristina Shrestha', 'attendance': 'Absent', 'present': '1', 'absent': '1'},
    {'sn': '5', 'name': 'Pratistha Shrestha', 'attendance': 'Present', 'present': '13', 'absent': '13'},
    {'sn': '6', 'name': 'Raju Shrestha', 'attendance': 'Present', 'present': '11', 'absent': '5'},
    {'sn': '7', 'name': 'Ronit Shresta', 'attendance': 'Present', 'present': '16', 'absent': '3'},
    {'sn': '8', 'name': 'Sabin Nyaju', 'attendance': 'Present', 'present': '20', 'absent': '5'},
    {'sn': '9', 'name': 'John Bahun', 'attendance': 'Absent', 'present': '10', 'absent': '3'},
    {'sn': '10', 'name': 'Pooja Gupta', 'attendance': 'Present', 'present': '160', 'absent': '5'},
  ];

  // Filter the data based on selected status
  List<Map<String, String>> get filteredTeachers {
    if (status == 'All Status') {
      return teachersData;
    } else {
      return teachersData.where((teacher) => teacher['attendance'] == status).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: AppStyle.bodyTextColor,
                ),
              )
            : null,
        backgroundColor: AppStyle.primaryColor,
        title: Text(
          'Teacher Attendance',
          style: AppStyle.bodyText.copyWith(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            top: context.screenHeight * 0.001,
            bottom: context.screenHeight * 0.02,
            right: context.screenWidth * 0.04,
            left: context.screenWidth * 0.04,
          ),
          child: Column(
            children: [
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.only(
                      right: 10,
                      left: 10,
                      bottom: 14,
                      top: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Text(
                      '11/11/2025',
                      style: TextStyle(
                        fontFamily: AppStyle.fontFamilySecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(
                      right: 10,
                      left: 10,
                      bottom: 0,
                      top: 0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black),
                    ),
                    child: DropdownButton<String>(
                      underline: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.transparent),
                        ),
                      ),
                      value: status,
                      items: ["All Status", "Present", "Absent"]
                          .map(
                            (statusItem) => DropdownMenuItem(
                              value: statusItem,
                              child: Text(
                                statusItem,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => status = value ?? "All Status"),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                clipBehavior: Clip.antiAlias,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  color: Colors.white,
                ),
                child: _teacherAttendance(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teacherAttendance() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 25,
        headingRowHeight: 70,
        dataRowMaxHeight: 50,
        showBottomBorder: true,
        border: TableBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        headingRowColor: WidgetStatePropertyAll(Color(0xffDDFFE7)),
        columns: [
          DataColumn(
            label: Text(
              'SN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Today\'s Attendance',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'No.of Present Days',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'No.of Absent Days',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
        ],
        rows: filteredTeachers
            .map(
              (teacher) => _teacherAttendanceRow(
                teacher['sn']!,
                teacher['name']!,
                teacher['attendance']!,
                teacher['present']!,
                teacher['absent']!,
              ),
            )
            .toList(),
      ),
    );
  }

  DataRow _teacherAttendanceRow(
    String sn,
    String name,
    String todayAttendance,
    String presentNumber,
    String absentNumber,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(sn, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
        ),
        DataCell(
          Text(
            name,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.only(top: 5, right: 10, left: 10, bottom: 5),
            decoration: BoxDecoration(
              color: todayAttendance == 'Absent' ? Color(0xffF93333) : Color(0xff0CC740),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              todayAttendance,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xffFEFCE8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            presentNumber,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            absentNumber,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}