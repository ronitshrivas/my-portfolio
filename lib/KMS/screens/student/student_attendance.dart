import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

class StudentAttendanceScreen extends ConsumerWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final List<Map<String, String>> gradeDate = [
    //   {
    //     'sn': '1',
    //     'name': 'Karthik Sharma',
    //     'attendance': 'Absent',
    //     'present': '5',
    //     'absent': '5',
    //   },
    //   {
    //     'sn': '2',
    //     'name': 'Kishore Pandey',
    //     'attendance': 'Present',
    //     'present': '10',
    //     'absent': '10',
    //   },
    //   {
    //     'sn': '3',
    //     'name': 'Anubhav Khanal',
    //     'attendance': 'Present',
    //     'present': '5',
    //     'absent': '5',
    //   },
    //   {
    //     'sn': '4',
    //     'name': 'Kristina Shrestha',
    //     'attendance': 'Absent',
    //     'present': '1',
    //     'absent': '1',
    //   },
    //   {
    //     'sn': '5',
    //     'name': 'Pratistha Shrestha',
    //     'attendance': 'Present',
    //     'present': '13',
    //     'absent': '13',
    //   },
    //   {
    //     'sn': '6',
    //     'name': 'Raju Shrestha',
    //     'attendance': 'Present',
    //     'present': '11',
    //     'absent': '5',
    //   },
    //   {
    //     'sn': '7',
    //     'name': 'Ronit Shresta',
    //     'attendance': 'Present',
    //     'present': '16',
    //     'absent': '3',
    //   },
    //   {
    //     'sn': '8',
    //     'name': 'Sabin Nyaju',
    //     'attendance': 'Present',
    //     'present': '20',
    //     'absent': '5',
    //   },
    //   {
    //     'sn': '9',
    //     'name': 'John Bahun',
    //     'attendance': 'Absent',
    //     'present': '10',
    //     'absent': '3',
    //   },
    //   {
    //     'sn': '10',
    //     'name': 'Pooja Gupta',
    //     'attendance': 'Present',
    //     'present': '160',
    //     'absent': '5',
    //   },
    // ];
    return CustomScrolling(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 15),
          Container(
            height: 67,
            padding: EdgeInsets.only(left: 10, top: 10),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              border: Border.all(color: Colors.black),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Karthik Sharma',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    color: AppStyle.primaryColor,
                  ),
                ),
                Text(
                  'Grade - 1',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          GridView(
            padding: EdgeInsets.only(bottom: 20),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),

            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 10,

              mainAxisSpacing: 10,
            ),

            children: [
              overViewCard(
                'assets/kms/calender_outlined.png',
                '11/11/2025',
                'Date',
              ),
              overViewCard(
                'assets/kms/calender_filled.png',
                '75/100',
                'Total Days',
              ),
              overViewCard('assets/kms/right.png', '70 Days', 'Present'),
              overViewCard('assets/kms/cross.png', '5 Days', 'Absent'),
              overViewCard('assets/kms/graph_bar.png', '75%', 'Attendance %'),
            ],
          ),
          SizedBox(height: 10,),
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
                child: studentAttendance(),
              ),
        ],
      ),
    );
  }

  Widget overViewCard(String image, String date, String label) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.only(right: 15, left: 15, top: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(image),
            SizedBox(height: 13),
            Text(date, style: TextStyle(color: Color(0xff6A6A6A))),
            SizedBox(height: 4),
            Text(
              label,
              style: AppStyle.bodyText.copyWith(
                color: Colors.black,
                fontFamily: 'InterThin',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget studentAttendance() {
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
              'Date',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Time',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Hours',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Lecture',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
        ],

        rows: [
          studentAttendanceRow(
            '11/11/2025',
            'Absent',
            '9:30-11:30',
            '2 hrs',
            'First Module Introduction',
          ),
                    studentAttendanceRow(
            '05/11/2025',
            'Present',
            '13:00-14:00',
            '1 hrs',
            'Components of IoT',
          ),
                       studentAttendanceRow(
            '19/01/2026',
            'Absent',
            '10:00-1:00',
            '3 hrs',
            'Web Development',
          ),
                       studentAttendanceRow(
            '05/11/2025',
            'Present',
            '1:00-7:00',
            '6 hrs',
            'Flutter Training',
          ),
                       studentAttendanceRow(
            '05/1/2026',
            'Present',
            '13:00-14:00',
            '1 hrs',
            'Presentation on Team Leader',
          ),
                       studentAttendanceRow(
            '19/11/2025',
            'Absent',
            '12:00-4:00',
            '5 hrs',
            'Theory of Computation',
          ),
        ],
      ),
    );
  }

  studentAttendanceRow(
    String date,
    String status,
    String time,
    String hours,
    String lecture,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            date,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),

        DataCell(
          Container(
            padding: EdgeInsets.only(top: 5, right: 10, left: 10, bottom: 5),
            decoration: BoxDecoration(
              color: status == 'Absent' ? Color(0xffF93333) : Color(0xff0CC740),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              status,
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
            time,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            hours,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            lecture,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
