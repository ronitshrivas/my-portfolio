import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/core/constants/mediaquery.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return   CustomScrolling(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            
            style: AppStyle.bodyText.copyWith(
              fontFamily: AppStyle.fontFamilySecondary,
              color: Colors.black,
            
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(0),
            
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 10,
            
              mainAxisSpacing: 10,
            ),
            
            children: [
              overViewCard(
                'Total Students',
                numberText: '500',
                image: 'assets/kms/student.png',
                color: AppStyle.primaryColor,
              ),
              overViewCard(
                'Total Partners',
                numberText: '45',
                image: 'assets/kms/handshake.png',
                color: AppStyle.primaryColor,
              ),
              overViewCard(
                'Total Students',
                numberText: '12',
                image: 'assets/kms/school.png',
              ),
              overViewCard(
                'Total Students',
                description: 'No upcoming exams. Good job!',
              ),
            ],
          ),
        
        SizedBox(height: 30,),
          Text(
            'Distribution (Pie Chart)',
            style: TextStyle(
              fontSize: 15,
              fontFamily: AppStyle.fontFamilySecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black),
            ),
            child: Row(
              children: [
                CustomPaint(
                  painter: PieChartPainter(),
                  size: Size(
                    context.screenWidth * 0.6,
                    context.screenHeight * 0.4,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      distributionChart(Colors.blue, 'Attendance'),
                      distributionChart(Colors.yellow, 'Exams'),
                      distributionChart(Colors.green, 'Payments'),
                      distributionChart(Colors.red, 'Complaints'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 25),
          
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                right: 8,
                left: 8,
                top: 10,
                bottom: 8,
              ),
              child: Column(
                children: [
                  onGoingClass(
                    'Today Ongoing Classes',
                    '2025/11/05',
                    onPressed: () {},
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _todayOngoingClassesTable(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      )
    );
  }

  Widget overViewCard(
    String mainText, {
    String? description,
    String? image,
    Color? color,
    String? numberText,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.only(right: 15, left: 15, top: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              child: Text(
                mainText,
                style: AppStyle.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: AppStyle.fontFamilySecondary,
                  fontSize: 15,
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (numberText != null && numberText.isNotEmpty)
                    Flexible(
                      child: Text(
                        numberText,
                        style: TextStyle(
                          fontFamily: AppStyle.fontFamilySecondary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  SizedBox(width: 5),

                  //Replace Later With the image later
                  if (image != null && image.isNotEmpty)
                    Image.asset(image, height: 30, color: color, width: 30),
                ],
              ),
            ),

            if (description != null && description.isNotEmpty)
              Flexible(child: Text(description, textAlign: TextAlign.start)),
          ],
        ),
      ),
    );
  }

  Widget distributionChart(Color? color, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.rectangle, color: color),
        ),
        SizedBox(width: 10),
        Text(text, style: TextStyle(color: Colors.black)),
      ],
    );
  }
}

Widget onGoingClass(
  String headingText,
  String timeDate, {
  VoidCallback? onPressed,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        headingText,
        style: TextStyle(
          fontSize: 12,
          fontFamily: AppStyle.fontFamilySecondary,
        ),
      ),
      TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          Icons.calendar_month_outlined,
          color: AppStyle.primaryColor,
          size: 25,
        ),
        label: Text(
          timeDate,
          style: TextStyle(
            fontFamily: AppStyle.fontFamilySecondary,
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    ],
  );
}

Widget _todayOngoingClassesTable() {
  return SingleChildScrollView(
    child: DataTable(
      columnSpacing: 25,
      headingRowHeight: 40,
      dataRowMaxHeight: 50,

      columns: const [
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
            'Partners Name',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              fontSize: 12,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Chapters',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              fontSize: 12,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'School Contact',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              fontSize: 12,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Partner Contact',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              fontSize: 12,
            ),
          ),
        ),
      ],
      rows: [
        _todayOngoingClassesDataRow(
          'Patan Multiple Campus',
          'John Newar',
          'Robotics',
          '+9779818945678',
          '+9779868997834',
        ),
        _todayOngoingClassesDataRow(
          'Vidya Sadan',
          'John Bahun',
          'Flutter',
          '+9779810045678',
          '+9779869027834',
        ),
        _todayOngoingClassesDataRow(
          'Nepatronix Institute of Science and Technology',
          'John Magar',
          'Node.js',
          '+9779807234528',
          '+9779828597034',
        ),
        _todayOngoingClassesDataRow(
          'National InfoTech',
          'John Damai',
          'IOT',
          '+9779818645678',
          '+9779846587838',
        ),
        _todayOngoingClassesDataRow(
          'Madan Bhandari Memorial School',
          'John Damai',
          'IOT',
          '+9779818645678',
          '+9779846587838',
        ),
      ],
    ),
  );
}

DataRow _todayOngoingClassesDataRow(
  String schoolName,
  String partnerName,
  String chapters,
  String schoolContact,
  String partnerContact,
) {
  return DataRow(
    cells: [
      DataCell(
        Container(
          width: 200,
          child: Text(schoolName, style: TextStyle(fontSize: 11)),
        ),
      ),
      DataCell(Text(partnerName, style: TextStyle(fontSize: 11))),
      DataCell(Text(chapters, style: TextStyle(fontSize: 11))),
      DataCell(Text(schoolContact, style: TextStyle(fontSize: 11))),
      DataCell(Text(partnerContact, style: TextStyle(fontSize: 11))),
    ],
  );
}

//Custom Painter for the pie chart
class PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.48;
    final innerRadius = radius * 0.7;

    final paint = Paint()..style = PaintingStyle.fill;

    //Pass the value that comes later from the backend
    final segments = [
      _PieSegment(25, const Color(0xFF2196F3)),
      _PieSegment(30, const Color(0xFFF44336)),
      _PieSegment(20, const Color(0xFF4CAF50)),
      _PieSegment(25, const Color(0xFFFFEB3B)),
    ];

    final total = segments.fold(0.0, (sum, s) => sum + s.value);
    double startAngle = -pi / 2;

    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * 2 * pi;

      // Draw filled arc
      paint.color = segment.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      final textAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.88;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);

      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: '${segment.value.toInt()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );

      startAngle += sweepAngle;
    }

    canvas.drawCircle(center, innerRadius, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PieSegment {
  final double value;
  final Color color;
  _PieSegment(this.value, this.color);
}
