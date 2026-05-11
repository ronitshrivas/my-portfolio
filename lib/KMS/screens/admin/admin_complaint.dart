import 'package:flutter/material.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

class AdminComplaintScreen extends StatefulWidget {
  const AdminComplaintScreen({super.key});

  @override
  State<AdminComplaintScreen> createState() => _AdminComplaintScreenState();
}

class _AdminComplaintScreenState extends State<AdminComplaintScreen> {
  String status = 'All Status';
  final List<Map<String, String>> complaintsData = [
    {
      'Complaint By': 'Student',
      'School Name': 'Sunrise Academy',
      'Contact': '9866308213',
      'Teacher': 'Ram Narayan Bidari',
      'Message': 'This teacher is a nonsense guy always beats us',
      'Date': "2025-12-12",
      'Status': 'Resolved',
    },
    {
      'Complaint By': 'School',
      'School Name': 'Nepatronix Engineering Institute',
      'Contact': '9877839203',
      'Teacher': 'Ram Narayan Khati',
      'Message': 'Hello this is complaint about all the students',
      'Date': "2025-01-05",
      'Status': 'Pending',
    },
    {
      'Complaint By': 'School',
      'School Name': 'Patan Multiple Campus',
      'Contact': '9866344513',
      'Teacher': 'KP Sharma Oli',
      'Message': 'KP Oli is a gangster and the murderer',
      'Date': "2025-05-13",
      'Status': 'Resolved',
    },
    {
      'Complaint By': 'Student',
      'School Name': 'Miteri School of sciences',
      'Contact': '9808523513',
      'Teacher': 'Puspa Kamal Dahal',
      'Message':
          'This man is also like  Oli  and he is also gangster and the murderer',
      'Date': "2025-09-09",
      'Status': 'Resolved',
    },
    {
      'Complaint By': 'Student',
      'School Name': 'Miteri School of sciences',
      'Contact': '9808523513',
      'Teacher': 'Puspa Kamal Dahal',
      'Message':
          'This man is also like  Oli  and he is also gangster and the murderer',
      'Date': "2025-09-09",
      'Status': 'Resolved',
    },
    {
      'Complaint By': 'Student',
      'School Name': 'Miteri School of sciences',
      'Contact': '9808523513',
      'Teacher': 'Puspa Kamal Dahal',
      'Message':
          'This man is also like  Oli  and he is also gangster and the murderer',
      'Date': "2025-09-09",
      'Status': 'Resolved',
    },
    {
      'Complaint By': 'Student',
      'School Name': 'Miteri School of sciences',
      'Contact': '9808523513',
      'Teacher': 'Puspa Kamal Dahal',
      'Message':
          'This man is also like  Oli  and he is also gangster and the murderer',
      'Date': "2025-09-09",
      'Status': 'Pending',
    },
    {
      'Complaint By': 'Student',
      'School Name': 'Miteri School of sciences',
      'Contact': '9808523513',
      'Teacher': 'Puspa Kamal Dahal',
      'Message':
          'This man is also like  Oli  and he is also gangster and the murderer',
      'Date': "2025-09-09",
      'Status': 'Resolved',
    },
  ];

  // Filter the data based on selected status
  List<Map<String, String>> get filteredStatus {
    if (status == 'All Status') {
      return complaintsData;
    } else {
      return complaintsData.where((data) => data['Status'] == status).toList();
    }
  }

 

  @override
  Widget build(BuildContext context) {
    return CustomScrolling(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complaint Management',
            style: TextStyle(
              fontFamily: AppStyle.fontFamilySecondary,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 10,),
          Text('View, file and track all complaints'),
          SizedBox(height: 20),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: EdgeInsets.only(right: 10, left: 10),
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
                items:
                    ["All Status", "Pending", "Resolved"]
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
              'Complaint By',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'School Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Contact',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Teacher',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Message',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
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
        ],
        rows:
            filteredStatus
                .map(
                  (data) => _teacherAttendanceRow(
                    data['Complaint By']!,
                    data['School Name']!,
                    data['Contact']!,
                    data['Teacher']!,
                    data['Message']!,
                    data['Date']!,
                    data['Status']!,
                  ),
                )
                .toList(),
      ),
    );
  }

  DataRow _teacherAttendanceRow(
    String complaintBy,
    String schoolName,
    String contact,
    String teacher,
    String message,
    String date,
    String status,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            complaintBy,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            schoolName,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            contact,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            teacher,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            message,

            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            date,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            status,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color:
                  status == 'Pending'
                      ? Color(0xffFB923C)
                      : AppStyle.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
