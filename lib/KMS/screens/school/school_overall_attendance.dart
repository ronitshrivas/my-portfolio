import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';
import 'package:innovator/KMS/screens/school/tutor_attendance.dart';
class SchoolAttendanceScreen extends ConsumerStatefulWidget {
  const SchoolAttendanceScreen({super.key});

  @override
  ConsumerState<SchoolAttendanceScreen> createState() =>
      _SchoolAttendanceScreenState();
}

class _SchoolAttendanceScreenState
    extends ConsumerState<SchoolAttendanceScreen> {
  String selectedClass = "All Class";
  String status = 'All Status';
    final List<Map<String, String>> gradeDate = [
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
  List<Map<String, String>> get filteredStatus {
    if (status == 'All Status') {
      return gradeDate;
    } else {
      return gradeDate.where((grade) => grade['attendance'] == status).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrolling(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance',
            style: AppStyle.bodyText.copyWith(
              fontFamily: AppStyle.fontFamilySecondary,
              color: Colors.black,

              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 5),
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
                ],
              ),
              SizedBox(width: 40),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 5),
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
                    child: DropdownButton(
                      underline: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.transparent),
                        ),
                      ),

                      value: selectedClass,
                      items:
                          [
                                'All Class',
                                'Grade 1',
                                'Grade 2',
                                'Grade 3',
                                'Grade 4',
                                'Grade 5',
                                'Grade 6',
                                'Grade 7',
                              ]
                              .map(
                                (classItem) => DropdownMenuItem(
                                  value: classItem,
                                  child: Text(
                                    classItem,
                                    style: TextStyle(
                                      // fontFamily: 'InterThin',
                                      fontFamily: AppStyle.fontFamilySecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(
                            () => selectedClass = value ?? "All Class",
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: status != 'All Class' ? 10 : 0),
          if (selectedClass != 'All Class')
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: EdgeInsets.only(
                  right: 10,
                  left: 10,
                  bottom: 0,
                  top: 0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.black),
                ),
                child: DropdownButton(
                  underline: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.transparent),
                    ),
                  ),

                  value: status,
                  items:
                      [ "All Status","Present", "Absent"]
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
                  onChanged:
                      (value) => setState(() => status = value ?? "All Status"),
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.person_outline, color: Color(0xff6A6A6A)),
                  GestureDetector(
                    onTap: () {
                      Get.to(
                        () => TutorAttendanceScreen(),
                        transition: Transition.leftToRight,
                      );
                    },
                    child: Text(
                      'Sulabh Neupane',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: status != 'All Class' ? 10 : 0),
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
            //  if the all class is selected then show the
            child:
                selectedClass == 'All Class'
                    ? _allClass()
                    : _classCategorizing(),
          ),
        ],
      ),
    );
  }

  Widget _allClass() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 35,
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
              ' Class',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Total Student',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'No.of Present',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'No. of Absent',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Week',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Ongoing Lecture',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
        ],
        rows: [
          _allClassRow(
            '1',
            'Grade 1',
            '205',
            '200',
            '5',
            '1',
            'First Module Introduction',
          ),
          _allClassRow(
            '2',
            'Grade 2',
            '310',
            '300',
            '10',
            '2',
            'Components of IoT',
          ),
          _allClassRow(
            '3',
            'Grade 3',
            '155',
            '150',
            '5',
            '3',
            'Worked on Small Project',
          ),
          _allClassRow(
            '4',
            'Grade 4',
            '141',
            '140',
            '1',
            '4',
            'Presentation of Project',
          ),
          _allClassRow(
            '5',
            'Grade 5',
            '173',
            '160',
            '13',
            '5',
            'Grading of the Project',
          ),
        ],
      ),
    );
  }

  _allClassRow(
    String sn,
    String classes,
    String totalStudent,
    String presentNumber,
    String absentNumber,
    String week,
    String status,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(sn, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
        ),
        DataCell(
          Text(
            classes,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            totalStudent,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
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
        DataCell(
          Text(
            week,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            status,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
 

  Widget _classCategorizing() {
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
 

         rows: filteredStatus
            .map<DataRow>(
              (teacher) => _classCategorizingRow(
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

  _classCategorizingRow(
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
              color:
                  todayAttendance == 'Absent'
                      ? Color(0xffF93333)
                      : Color(0xff0CC740),
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
