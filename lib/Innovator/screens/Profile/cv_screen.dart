// import 'dart:convert';
// import 'dart:developer' as developer;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:http/http.dart' as http;
// import 'package:innovator/Innovator/App_data/App_data.dart';
// import 'package:innovator/Innovator/constant/api_constants.dart';
// import 'package:innovator/Innovator/constant/app_colors.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // Constants
// // ─────────────────────────────────────────────────────────────────────────────
// const _kPrimary = Color.fromRGBO(244, 135, 6, 1);
// const _kPrimaryLight = Color.fromRGBO(244, 135, 6, 0.10);
// const _kBg = Color(0xFFF8F9FA);

// const _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
// const _groqApiKey = 'REVOKED_GROQ_KEY';

// // ─────────────────────────────────────────────────────────────────────────────
// // Data model that holds everything needed for CV generation
// // ─────────────────────────────────────────────────────────────────────────────
// class CvData {
//   final String fullName;
//   final String email;
//   final String? phone;
//   final String? address;
//   final String? bio;
//   final String? education;
//   final String? occupation;
//   final String? hobbies;
//   final String? gender;
//   final String? dateOfBirth;
//   final String? avatarUrl;
//   final List<String> activities; // from status-type posts

//   const CvData({
//     required this.fullName,
//     required this.email,
//     this.phone,
//     this.address,
//     this.bio,
//     this.education,
//     this.occupation,
//     this.hobbies,
//     this.gender,
//     this.dateOfBirth,
//     this.avatarUrl,
//     this.activities = const [],
//   });
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // CV Template enum
// // ─────────────────────────────────────────────────────────────────────────────
// enum CvTemplate { classic, modern, minimal, creative }

// extension CvTemplateX on CvTemplate {
//   String get label {
//     switch (this) {
//       case CvTemplate.classic:
//         return 'Classic';
//       case CvTemplate.modern:
//         return 'Modern';
//       case CvTemplate.minimal:
//         return 'Minimal';
//       case CvTemplate.creative:
//         return 'Creative';
//     }
//   }

//   IconData get icon {
//     switch (this) {
//       case CvTemplate.classic:
//         return Icons.article_outlined;
//       case CvTemplate.modern:
//         return Icons.dashboard_outlined;
//       case CvTemplate.minimal:
//         return Icons.horizontal_rule_rounded;
//       case CvTemplate.creative:
//         return Icons.palette_outlined;
//     }
//   }

//   Color get accentColor {
//     switch (this) {
//       case CvTemplate.classic:
//         return const Color(0xFF1A237E);
//       case CvTemplate.modern:
//         return _kPrimary;
//       case CvTemplate.minimal:
//         return const Color(0xFF263238);
//       case CvTemplate.creative:
//         return const Color(0xFF6A1B9A);
//     }
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Provider state
// // ─────────────────────────────────────────────────────────────────────────────
// class CvState {
//   final bool loadingProfile;
//   final bool generatingAI;
//   final bool generatingPDF;
//   final CvData? cvData;
//   final CvData? aiEnhancedData;
//   final CvTemplate selectedTemplate;
//   final bool useAiVersion;
//   final String? error;

//   const CvState({
//     this.loadingProfile = false,
//     this.generatingAI = false,
//     this.generatingPDF = false,
//     this.cvData,
//     this.aiEnhancedData,
//     this.selectedTemplate = CvTemplate.modern,
//     this.useAiVersion = false,
//     this.error,
//   });

//   CvState copyWith({
//     bool? loadingProfile,
//     bool? generatingAI,
//     bool? generatingPDF,
//     CvData? cvData,
//     CvData? aiEnhancedData,
//     CvTemplate? selectedTemplate,
//     bool? useAiVersion,
//     String? error,
//   }) {
//     return CvState(
//       loadingProfile: loadingProfile ?? this.loadingProfile,
//       generatingAI: generatingAI ?? this.generatingAI,
//       generatingPDF: generatingPDF ?? this.generatingPDF,
//       cvData: cvData ?? this.cvData,
//       aiEnhancedData: aiEnhancedData ?? this.aiEnhancedData,
//       selectedTemplate: selectedTemplate ?? this.selectedTemplate,
//       useAiVersion: useAiVersion ?? this.useAiVersion,
//       error: error,
//     );
//   }

//   CvData? get activeCvData => useAiVersion ? aiEnhancedData : cvData;
// }

// class CvNotifier extends StateNotifier<CvState> {
//   CvNotifier() : super(const CvState());

//   // ── Load user profile + fetch status posts ──────────────────────────────
//   Future<void> loadProfileData() async {
//     state = state.copyWith(loadingProfile: true, error: null);
//     try {
//       final appData = AppData();
//       await appData.initialize();
//       final u = appData.currentUser ?? {};
//       final profile = u['profile'] as Map<String, dynamic>? ?? {};

//       // Resolve avatar URL
//       String? avatarUrl =
//           appData.currentUserAvatar ??
//           profile['avatar']?.toString() ??
//           u['photo_url']?.toString();
//       if (avatarUrl != null &&
//           avatarUrl.isNotEmpty &&
//           !avatarUrl.startsWith('http')) {
//         avatarUrl = '${ApiConstants.userBase}$avatarUrl';
//       }

//       // Fetch feed posts to extract status/activity posts
//       final activities = await _fetchStatusPosts(appData.accessToken ?? '');

//       final cvData = CvData(
//         fullName: u['full_name']?.toString() ?? 'Your Name',
//         email: u['email']?.toString() ?? '',
//         phone:
//             profile['phone_number']?.toString() ??
//             u['phone_number']?.toString(),
//         address: profile['address']?.toString() ?? u['address']?.toString(),
//         bio: profile['bio']?.toString() ?? u['bio']?.toString(),
//         education:
//             profile['education']?.toString() ?? u['education']?.toString(),
//         occupation:
//             profile['occupation']?.toString() ?? u['occupation']?.toString(),
//         hobbies: profile['hobbies']?.toString() ?? u['hobbies']?.toString(),
//         gender: profile['gender']?.toString() ?? u['gender']?.toString(),
//         dateOfBirth:
//             profile['date_of_birth']?.toString() ??
//             u['date_of_birth']?.toString(),
//         avatarUrl: avatarUrl,
//         activities: activities,
//       );

//       state = state.copyWith(loadingProfile: false, cvData: cvData);
//     } catch (e) {
//       developer.log('[CV] loadProfileData error: $e');
//       state = state.copyWith(
//         loadingProfile: false,
//         error: 'Failed to load profile data.',
//       );
//     }
//   }

//   Future<List<String>> _fetchStatusPosts(String token) async {
//     try {
//       final response = await http
//           .get(
//             Uri.parse('${ApiConstants.post}?type=status&page_size=50'),
//             headers: {
//               'Authorization': 'Bearer $token',
//               'Content-Type': 'application/json',
//             },
//           )
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         final body = jsonDecode(response.body);
//         final results =
//             body['results'] as List<dynamic>? ??
//             body['data'] as List<dynamic>? ??
//             [];
//         return results
//             .whereType<Map<String, dynamic>>()
//             .where(
//               (p) =>
//                   p['type'] == 'status' ||
//                   (p['status'] != null &&
//                       p['status'].toString().isNotEmpty &&
//                       p['video'] == null),
//             )
//             .map((p) {
//               final content =
//                   p['content']?.toString() ??
//                   p['status']?.toString() ??
//                   p['description']?.toString() ??
//                   '';
//               final date = p['created_at']?.toString() ?? '';
//               if (content.isEmpty) return null;
//               if (date.isNotEmpty) {
//                 try {
//                   final d = DateTime.parse(date);
//                   return '${d.year}: $content';
//                 } catch (_) {}
//               }
//               return content;
//             })
//             .whereType<String>()
//             .take(8)
//             .toList();
//       }
//     } catch (e) {
//       developer.log('[CV] fetchStatusPosts error: $e');
//     }
//     return [];
//   }

//   // ── Select template ──────────────────────────────────────────────────────
//   void selectTemplate(CvTemplate template) {
//     state = state.copyWith(selectedTemplate: template);
//   }

//   // ── Toggle AI version ────────────────────────────────────────────────────
//   void toggleAiVersion(bool useAi) {
//     state = state.copyWith(useAiVersion: useAi);
//   }

//   // ── Generate AI-enhanced CV via Groq ─────────────────────────────────────
//   Future<void> generateWithAI() async {
//     final raw = state.cvData;
//     if (raw == null) return;
//     state = state.copyWith(generatingAI: true, error: null);

//     try {
//       final prompt = _buildAIPrompt(raw);
//       final response = await http
//           .post(
//             Uri.parse(_groqApiUrl),
//             headers: {
//               'Authorization': 'Bearer $_groqApiKey',
//               'Content-Type': 'application/json',
//             },
//             body: jsonEncode({
//               'model': 'llama-3.1-8b-instant',
//               'max_tokens': 1500,
//               'temperature': 0.7,
//               'messages': [
//                 {
//                   'role': 'system',
//                   'content':
//                       'You are an expert CV/resume writer. You enhance and rewrite professional CV sections to sound polished, concise, and impactful. Always return valid JSON only — no markdown, no extra text.',
//                 },
//                 {'role': 'user', 'content': prompt},
//               ],
//             }),
//           )
//           .timeout(const Duration(seconds: 30));

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final text = data['choices'][0]['message']['content']?.toString() ?? '';
//         final cleaned =
//             text.replaceAll('```json', '').replaceAll('```', '').trim();
//         final enhanced = jsonDecode(cleaned) as Map<String, dynamic>;

//         final aiData = CvData(
//           fullName: raw.fullName,
//           email: raw.email,
//           phone: raw.phone,
//           address: raw.address,
//           gender: raw.gender,
//           dateOfBirth: raw.dateOfBirth,
//           avatarUrl: raw.avatarUrl,
//           bio: enhanced['bio']?.toString() ?? raw.bio,
//           education: enhanced['education']?.toString() ?? raw.education,
//           occupation: enhanced['occupation']?.toString() ?? raw.occupation,
//           hobbies: enhanced['hobbies']?.toString() ?? raw.hobbies,
//           activities:
//               (enhanced['activities'] as List<dynamic>?)
//                   ?.map((e) => e.toString())
//                   .toList() ??
//               raw.activities,
//         );

//         state = state.copyWith(
//           generatingAI: false,
//           aiEnhancedData: aiData,
//           useAiVersion: true,
//         );
//       } else {
//         throw Exception(
//           'Groq API error ${response.statusCode}: ${response.body}',
//         );
//       }
//     } catch (e) {
//       developer.log('[CV] generateWithAI error: $e');
//       state = state.copyWith(
//         generatingAI: false,
//         error: 'AI enhancement failed. Using original data.',
//       );
//     }
//   }

//   String _buildAIPrompt(CvData d) {
//     return '''
// Enhance the following CV data and return ONLY a JSON object with improved text for each field.
// Make the bio professional and concise (2-3 sentences max).
// Make occupation sound impressive. Education concise. Hobbies thoughtful.
// Rewrite each activity as a professional achievement bullet (start with action verb).

// Input data:
// {
//   "bio": ${jsonEncode(d.bio ?? '')},
//   "occupation": ${jsonEncode(d.occupation ?? '')},
//   "education": ${jsonEncode(d.education ?? '')},
//   "hobbies": ${jsonEncode(d.hobbies ?? '')},
//   "activities": ${jsonEncode(d.activities)}
// }

// Return JSON only (no markdown, no preamble):
// {
//   "bio": "...",
//   "occupation": "...",
//   "education": "...",
//   "hobbies": "...",
//   "activities": ["...", "..."]
// }
// ''';
//   }
// }

// final cvProvider = StateNotifierProvider.autoDispose<CvNotifier, CvState>(
//   (ref) => CvNotifier(),
// );

// // ─────────────────────────────────────────────────────────────────────────────
// // PDF Generation Service
// // ─────────────────────────────────────────────────────────────────────────────
// class CvPdfService {
//   static Future<Uint8List> generate(CvData data, CvTemplate template) async {
//     final doc = pw.Document();
//     final accent = PdfColor.fromHex(
//       template.accentColor.value.toRadixString(16).padLeft(8, '0').substring(2),
//     );

//     switch (template) {
//       case CvTemplate.classic:
//         doc.addPage(_buildClassicPage(data, accent));
//         break;
//       case CvTemplate.modern:
//         doc.addPage(_buildModernPage(data, accent));
//         break;
//       case CvTemplate.minimal:
//         doc.addPage(_buildMinimalPage(data, accent));
//         break;
//       case CvTemplate.creative:
//         doc.addPage(_buildCreativePage(data, accent));
//         break;
//     }

//     return doc.save();
//   }

//   // ── Classic: two-column, dark navy header ──────────────────────────────
//   static pw.Page _buildClassicPage(CvData d, PdfColor accent) {
//     return pw.Page(
//       pageFormat: PdfPageFormat.a4,
//       margin: pw.EdgeInsets.zero,
//       build:
//           (ctx) => pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               // Header
//               pw.Container(
//                 width: double.infinity,
//                 color: accent,
//                 padding: const pw.EdgeInsets.symmetric(
//                   horizontal: 36,
//                   vertical: 28,
//                 ),
//                 child: pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text(
//                       d.fullName,
//                       style: pw.TextStyle(
//                         fontSize: 28,
//                         fontWeight: pw.FontWeight.bold,
//                         color: PdfColors.white,
//                       ),
//                     ),
//                     pw.SizedBox(height: 4),
//                     if (d.occupation != null && d.occupation!.isNotEmpty)
//                       pw.Text(
//                         d.occupation!,
//                         style: pw.TextStyle(
//                           fontSize: 14,
//                           color: PdfColors.white,
//                         ),
//                       ),
//                     pw.SizedBox(height: 12),
//                     pw.Row(
//                       children: [
//                         pw.Text(
//                           d.email,
//                           style: const pw.TextStyle(
//                             fontSize: 10,
//                             color: PdfColors.white,
//                           ),
//                         ),
//                         if (d.phone != null && d.phone!.isNotEmpty) ...[
//                           pw.Text(
//                             '  •  ',
//                             style: const pw.TextStyle(color: PdfColors.white),
//                           ),
//                           pw.Text(
//                             d.phone!,
//                             style: const pw.TextStyle(
//                               fontSize: 10,
//                               color: PdfColors.white,
//                             ),
//                           ),
//                         ],
//                         if (d.address != null && d.address!.isNotEmpty) ...[
//                           pw.Text(
//                             '  •  ',
//                             style: const pw.TextStyle(color: PdfColors.white),
//                           ),
//                           pw.Text(
//                             d.address!,
//                             style: const pw.TextStyle(
//                               fontSize: 10,
//                               color: PdfColors.white,
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               // Body
//               pw.Expanded(
//                 child: pw.Padding(
//                   padding: const pw.EdgeInsets.all(36),
//                   child: pw.Row(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       // Left column
//                       pw.SizedBox(
//                         width: 160,
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.start,
//                           children: [
//                             if (d.education != null &&
//                                 d.education!.isNotEmpty) ...[
//                               _classicSection('Education', accent),
//                               pw.Text(
//                                 d.education!,
//                                 style: const pw.TextStyle(fontSize: 10),
//                               ),
//                               pw.SizedBox(height: 16),
//                             ],
//                             if (d.hobbies != null && d.hobbies!.isNotEmpty) ...[
//                               _classicSection('Interests', accent),
//                               pw.Text(
//                                 d.hobbies!,
//                                 style: const pw.TextStyle(fontSize: 10),
//                               ),
//                               pw.SizedBox(height: 16),
//                             ],
//                             if (d.gender != null && d.gender!.isNotEmpty) ...[
//                               _classicSection('Personal', accent),
//                               if (d.gender != null)
//                                 pw.Text(
//                                   'Gender: ${d.gender}',
//                                   style: const pw.TextStyle(fontSize: 10),
//                                 ),
//                               if (d.dateOfBirth != null &&
//                                   d.dateOfBirth!.isNotEmpty)
//                                 pw.Text(
//                                   'DOB: ${d.dateOfBirth}',
//                                   style: const pw.TextStyle(fontSize: 10),
//                                 ),
//                             ],
//                           ],
//                         ),
//                       ),
//                       pw.SizedBox(width: 24),
//                       // Right column
//                       pw.Expanded(
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.start,
//                           children: [
//                             if (d.bio != null && d.bio!.isNotEmpty) ...[
//                               _classicSection('Profile', accent),
//                               pw.Text(
//                                 d.bio!,
//                                 style: const pw.TextStyle(fontSize: 10),
//                               ),
//                               pw.SizedBox(height: 16),
//                             ],
//                             if (d.activities.isNotEmpty) ...[
//                               _classicSection(
//                                 'Activities & Achievements',
//                                 accent,
//                               ),
//                               ...d.activities.map(
//                                 (a) => pw.Padding(
//                                   padding: const pw.EdgeInsets.only(bottom: 4),
//                                   child: pw.Row(
//                                     crossAxisAlignment:
//                                         pw.CrossAxisAlignment.start,
//                                     children: [
//                                       pw.Text(
//                                         '• ',
//                                         style: pw.TextStyle(
//                                           color: accent,
//                                           fontWeight: pw.FontWeight.bold,
//                                         ),
//                                       ),
//                                       pw.Expanded(
//                                         child: pw.Text(
//                                           a,
//                                           style: const pw.TextStyle(
//                                             fontSize: 10,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//     );
//   }

//   static pw.Widget _classicSection(String title, PdfColor accent) {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text(
//           title.toUpperCase(),
//           style: pw.TextStyle(
//             fontSize: 9,
//             fontWeight: pw.FontWeight.bold,
//             color: accent,
//             letterSpacing: 1.2,
//           ),
//         ),
//         pw.Divider(color: accent, thickness: 1.5),
//         pw.SizedBox(height: 6),
//       ],
//     );
//   }

//   // ── Modern: orange sidebar ─────────────────────────────────────────────
//   static pw.Page _buildModernPage(CvData d, PdfColor accent) {
//     return pw.Page(
//       pageFormat: PdfPageFormat.a4,
//       margin: pw.EdgeInsets.zero,
//       build:
//           (ctx) => pw.Row(
//             children: [
//               // Sidebar
//               pw.Container(
//                 width: 180,
//                 color: accent,
//                 padding: const pw.EdgeInsets.all(24),
//                 child: pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.SizedBox(height: 10),
//                     pw.Text(
//                       d.fullName,
//                       style: pw.TextStyle(
//                         fontSize: 18,
//                         fontWeight: pw.FontWeight.bold,
//                         color: PdfColors.white,
//                       ),
//                     ),
//                     pw.SizedBox(height: 4),
//                     if (d.occupation != null && d.occupation!.isNotEmpty)
//                       pw.Text(
//                         d.occupation!,
//                         style: pw.TextStyle(
//                           fontSize: 10,
//                           color: PdfColors.white,
//                         ),
//                       ),
//                     pw.SizedBox(height: 20),
//                     pw.Divider(color: PdfColors.white),
//                     pw.SizedBox(height: 14),
//                     _sidebarLabel('CONTACT'),
//                     pw.SizedBox(height: 6),
//                     _sidebarInfo(Icons.email, d.email),
//                     if (d.phone != null && d.phone!.isNotEmpty)
//                       _sidebarInfo(Icons.phone, d.phone!),
//                     if (d.address != null && d.address!.isNotEmpty)
//                       _sidebarInfo(Icons.location_on, d.address!),
//                     pw.SizedBox(height: 16),
//                     if (d.education != null && d.education!.isNotEmpty) ...[
//                       _sidebarLabel('EDUCATION'),
//                       pw.SizedBox(height: 6),
//                       pw.Text(
//                         d.education!,
//                         style: const pw.TextStyle(
//                           fontSize: 9,
//                           color: PdfColors.white,
//                         ),
//                       ),
//                       pw.SizedBox(height: 16),
//                     ],
//                     if (d.hobbies != null && d.hobbies!.isNotEmpty) ...[
//                       _sidebarLabel('INTERESTS'),
//                       pw.SizedBox(height: 6),
//                       pw.Text(
//                         d.hobbies!,
//                         style: const pw.TextStyle(
//                           fontSize: 9,
//                           color: PdfColors.white,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//               // Main content
//               pw.Expanded(
//                 child: pw.Padding(
//                   padding: const pw.EdgeInsets.all(32),
//                   child: pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       if (d.bio != null && d.bio!.isNotEmpty) ...[
//                         _modernSection('ABOUT ME', accent),
//                         pw.Text(
//                           d.bio!,
//                           style: const pw.TextStyle(
//                             fontSize: 10,
//                             color: PdfColors.grey800,
//                           ),
//                         ),
//                         pw.SizedBox(height: 20),
//                       ],
//                       if (d.activities.isNotEmpty) ...[
//                         _modernSection('ACTIVITIES & ACHIEVEMENTS', accent),
//                         ...d.activities.map(
//                           (a) => pw.Padding(
//                             padding: const pw.EdgeInsets.only(bottom: 8),
//                             child: pw.Row(
//                               crossAxisAlignment: pw.CrossAxisAlignment.start,
//                               children: [
//                                 pw.Container(
//                                   width: 6,
//                                   height: 6,
//                                   margin: const pw.EdgeInsets.only(
//                                     top: 3,
//                                     right: 10,
//                                   ),
//                                   decoration: pw.BoxDecoration(
//                                     shape: pw.BoxShape.circle,
//                                     color: accent,
//                                   ),
//                                 ),
//                                 pw.Expanded(
//                                   child: pw.Text(
//                                     a,
//                                     style: const pw.TextStyle(fontSize: 10),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//     );
//   }

//   static pw.Widget _sidebarLabel(String label) {
//     return pw.Text(
//       label,
//       style: pw.TextStyle(
//         fontSize: 8,
//         fontWeight: pw.FontWeight.bold,
//         color: PdfColors.white,
//         letterSpacing: 1.5,
//       ),
//     );
//   }

//   static pw.Widget _sidebarInfo(IconData _, String text) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.only(bottom: 4),
//       child: pw.Text(
//         text,
//         style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
//       ),
//     );
//   }

//   static pw.Widget _modernSection(String title, PdfColor accent) {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text(
//           title,
//           style: pw.TextStyle(
//             fontSize: 10,
//             fontWeight: pw.FontWeight.bold,
//             color: accent,
//             letterSpacing: 1.2,
//           ),
//         ),
//         pw.SizedBox(height: 2),
//         pw.Container(height: 2, width: 40, color: accent),
//         pw.SizedBox(height: 10),
//       ],
//     );
//   }

//   // ── Minimal: clean, typographic, black & white ─────────────────────────
//   static pw.Page _buildMinimalPage(CvData d, PdfColor accent) {
//     return pw.Page(
//       pageFormat: PdfPageFormat.a4,
//       margin: const pw.EdgeInsets.all(52),
//       build:
//           (ctx) => pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: pw.CrossAxisAlignment.end,
//                 children: [
//                   pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text(
//                         d.fullName,
//                         style: pw.TextStyle(
//                           fontSize: 32,
//                           fontWeight: pw.FontWeight.bold,
//                           color: PdfColors.black,
//                         ),
//                       ),
//                       if (d.occupation != null && d.occupation!.isNotEmpty)
//                         pw.Text(
//                           d.occupation!,
//                           style: const pw.TextStyle(
//                             fontSize: 12,
//                             color: PdfColors.grey600,
//                           ),
//                         ),
//                     ],
//                   ),
//                   pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.end,
//                     children: [
//                       pw.Text(
//                         d.email,
//                         style: const pw.TextStyle(
//                           fontSize: 9,
//                           color: PdfColors.grey700,
//                         ),
//                       ),
//                       if (d.phone != null && d.phone!.isNotEmpty)
//                         pw.Text(
//                           d.phone!,
//                           style: const pw.TextStyle(
//                             fontSize: 9,
//                             color: PdfColors.grey700,
//                           ),
//                         ),
//                       if (d.address != null && d.address!.isNotEmpty)
//                         pw.Text(
//                           d.address!,
//                           style: const pw.TextStyle(
//                             fontSize: 9,
//                             color: PdfColors.grey700,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//               pw.SizedBox(height: 16),
//               pw.Divider(thickness: 0.5, color: PdfColors.black),
//               pw.SizedBox(height: 20),
//               if (d.bio != null && d.bio!.isNotEmpty) ...[
//                 _minimalSection('PROFILE', accent),
//                 pw.Text(
//                   d.bio!,
//                   style: const pw.TextStyle(
//                     fontSize: 10,
//                     color: PdfColors.grey800,
//                     lineSpacing: 2,
//                   ),
//                 ),
//                 pw.SizedBox(height: 18),
//               ],
//               pw.Row(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Expanded(
//                     child: pw.Column(
//                       crossAxisAlignment: pw.CrossAxisAlignment.start,
//                       children: [
//                         if (d.education != null && d.education!.isNotEmpty) ...[
//                           _minimalSection('EDUCATION', accent),
//                           pw.Text(
//                             d.education!,
//                             style: const pw.TextStyle(fontSize: 10),
//                           ),
//                           pw.SizedBox(height: 16),
//                         ],
//                         if (d.hobbies != null && d.hobbies!.isNotEmpty) ...[
//                           _minimalSection('INTERESTS', accent),
//                           pw.Text(
//                             d.hobbies!,
//                             style: const pw.TextStyle(fontSize: 10),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                   pw.SizedBox(width: 30),
//                   if (d.activities.isNotEmpty)
//                     pw.Expanded(
//                       flex: 2,
//                       child: pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           _minimalSection('ACTIVITIES', accent),
//                           ...d.activities.map(
//                             (a) => pw.Padding(
//                               padding: const pw.EdgeInsets.only(bottom: 5),
//                               child: pw.Text(
//                                 '— $a',
//                                 style: const pw.TextStyle(fontSize: 10),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//             ],
//           ),
//     );
//   }

//   static pw.Widget _minimalSection(String title, PdfColor accent) {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text(
//           title,
//           style: pw.TextStyle(
//             fontSize: 8,
//             fontWeight: pw.FontWeight.bold,
//             color: accent,
//             letterSpacing: 2.0,
//           ),
//         ),
//         pw.SizedBox(height: 6),
//       ],
//     );
//   }

//   // ── Creative: purple gradient header, bold typography ──────────────────
//   static pw.Page _buildCreativePage(CvData d, PdfColor accent) {
//     return pw.Page(
//       pageFormat: PdfPageFormat.a4,
//       margin: pw.EdgeInsets.zero,
//       build:
//           (ctx) => pw.Column(
//             children: [
//               // Header band
//               pw.Container(
//                 width: double.infinity,
//                 color: accent,
//                 padding: const pw.EdgeInsets.fromLTRB(40, 32, 40, 28),
//                 child: pw.Row(
//                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                   children: [
//                     pw.Column(
//                       crossAxisAlignment: pw.CrossAxisAlignment.start,
//                       children: [
//                         pw.Text(
//                           d.fullName.toUpperCase(),
//                           style: pw.TextStyle(
//                             fontSize: 24,
//                             fontWeight: pw.FontWeight.bold,
//                             color: PdfColors.white,
//                             letterSpacing: 2,
//                           ),
//                         ),
//                         pw.SizedBox(height: 6),
//                         if (d.occupation != null && d.occupation!.isNotEmpty)
//                           pw.Text(
//                             d.occupation!,
//                             style: pw.TextStyle(
//                               fontSize: 12,
//                               color: PdfColors.white,
//                             ),
//                           ),
//                       ],
//                     ),
//                     pw.Column(
//                       crossAxisAlignment: pw.CrossAxisAlignment.end,
//                       children: [
//                         pw.Text(
//                           d.email,
//                           style: const pw.TextStyle(
//                             fontSize: 9,
//                             color: PdfColors.white,
//                           ),
//                         ),
//                         if (d.phone != null && d.phone!.isNotEmpty)
//                           pw.Text(
//                             d.phone!,
//                             style: const pw.TextStyle(
//                               fontSize: 9,
//                               color: PdfColors.white,
//                             ),
//                           ),
//                         if (d.address != null && d.address!.isNotEmpty)
//                           pw.Text(
//                             d.address!,
//                             style: const pw.TextStyle(
//                               fontSize: 9,
//                               color: PdfColors.white,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               // Decorative stripe
//               pw.Container(height: 6, color: PdfColor.fromHex('F48706')),
//               // Body
//               pw.Expanded(
//                 child: pw.Padding(
//                   padding: const pw.EdgeInsets.all(36),
//                   child: pw.Row(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.SizedBox(
//                         width: 150,
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.start,
//                           children: [
//                             if (d.education != null &&
//                                 d.education!.isNotEmpty) ...[
//                               _creativeSection('Education', accent),
//                               pw.Text(
//                                 d.education!,
//                                 style: const pw.TextStyle(fontSize: 10),
//                               ),
//                               pw.SizedBox(height: 18),
//                             ],
//                             if (d.hobbies != null && d.hobbies!.isNotEmpty) ...[
//                               _creativeSection('Interests', accent),
//                               pw.Text(
//                                 d.hobbies!,
//                                 style: const pw.TextStyle(fontSize: 10),
//                               ),
//                               pw.SizedBox(height: 18),
//                             ],
//                             if (d.gender != null && d.gender!.isNotEmpty) ...[
//                               _creativeSection('Personal', accent),
//                               pw.Text(
//                                 'Gender: ${d.gender}',
//                                 style: const pw.TextStyle(fontSize: 10),
//                               ),
//                               if (d.dateOfBirth != null &&
//                                   d.dateOfBirth!.isNotEmpty)
//                                 pw.Text(
//                                   'DOB: ${d.dateOfBirth}',
//                                   style: const pw.TextStyle(fontSize: 10),
//                                 ),
//                             ],
//                           ],
//                         ),
//                       ),
//                       pw.SizedBox(width: 24),
//                       pw.Expanded(
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.start,
//                           children: [
//                             if (d.bio != null && d.bio!.isNotEmpty) ...[
//                               _creativeSection('About', accent),
//                               pw.Text(
//                                 d.bio!,
//                                 style: const pw.TextStyle(
//                                   fontSize: 10,
//                                   color: PdfColors.grey800,
//                                   lineSpacing: 2,
//                                 ),
//                               ),
//                               pw.SizedBox(height: 18),
//                             ],
//                             if (d.activities.isNotEmpty) ...[
//                               _creativeSection('Highlights', accent),
//                               ...d.activities.map(
//                                 (a) => pw.Padding(
//                                   padding: const pw.EdgeInsets.only(bottom: 7),
//                                   child: pw.Row(
//                                     crossAxisAlignment:
//                                         pw.CrossAxisAlignment.start,
//                                     children: [
//                                       pw.Container(
//                                         width: 4,
//                                         height: 4,
//                                         margin: const pw.EdgeInsets.only(
//                                           top: 4,
//                                           right: 8,
//                                         ),
//                                         color: accent,
//                                       ),
//                                       pw.Expanded(
//                                         child: pw.Text(
//                                           a,
//                                           style: const pw.TextStyle(
//                                             fontSize: 10,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//     );
//   }

//   static pw.Widget _creativeSection(String title, PdfColor accent) {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Row(
//           children: [
//             pw.Container(width: 3, height: 14, color: accent),
//             pw.SizedBox(width: 8),
//             pw.Text(
//               title.toUpperCase(),
//               style: pw.TextStyle(
//                 fontSize: 9,
//                 fontWeight: pw.FontWeight.bold,
//                 color: accent,
//                 letterSpacing: 1.5,
//               ),
//             ),
//           ],
//         ),
//         pw.SizedBox(height: 8),
//       ],
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // CV Screen  (entry point — navigate here from UserProfileScreen)
// // ─────────────────────────────────────────────────────────────────────────────
// class CvScreen extends ConsumerStatefulWidget {
//   const CvScreen({Key? key}) : super(key: key);

//   @override
//   ConsumerState<CvScreen> createState() => _CvScreenState();
// }

// class _CvScreenState extends ConsumerState<CvScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(cvProvider.notifier).loadProfileData();
//     });
//   }

//   Future<void> _downloadPdf(CvData data, CvTemplate template) async {
//     try {
//       final bytes = await CvPdfService.generate(data, template);
//       await Printing.sharePdf(
//         bytes: bytes,
//         filename: 'cv_${data.fullName.replaceAll(' ', '_').toLowerCase()}.pdf',
//       );
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to generate PDF: $e'),
//             backgroundColor: Colors.red,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state = ref.watch(cvProvider);

//     return Scaffold(
//       backgroundColor: _kBg,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.arrow_back_ios_new),
//             onPressed: () => Navigator.pop(context),
//           ),
//           if (state.activeCvData != null)
//             IconButton(
//               icon: const Icon(Icons.download_rounded),
//               tooltip: 'Download PDF',
//               onPressed:
//                   () =>
//                       _downloadPdf(state.activeCvData!, state.selectedTemplate),
//             ),
//         ],
//       ),
//       body:
//           state.loadingProfile
//               ? const _LoadingView()
//               : state.cvData == null
//               ? _ErrorView(
//                 message: state.error ?? 'Could not load profile data.',
//                 onRetry: () => ref.read(cvProvider.notifier).loadProfileData(),
//               )
//               : _CvBody(onDownload: _downloadPdf),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Main body when data is loaded
// // ─────────────────────────────────────────────────────────────────────────────
// class _CvBody extends ConsumerWidget {
//   final Future<void> Function(CvData, CvTemplate) onDownload;

//   const _CvBody({required this.onDownload});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final state = ref.watch(cvProvider);
//     final notifier = ref.read(cvProvider.notifier);

//     return SingleChildScrollView(
//       padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ── Template Selector ──────────────────────────────────────────
//           _SectionLabel(icon: Icons.style_rounded, label: 'Choose Template'),
//           const SizedBox(height: 12),
//           SizedBox(
//             height: 96,
//             child: ListView(
//               scrollDirection: Axis.horizontal,
//               children:
//                   CvTemplate.values.map((t) {
//                     final selected = state.selectedTemplate == t;
//                     return _TemplateCard(
//                       template: t,
//                       selected: selected,
//                       onTap: () => notifier.selectTemplate(t),
//                     );
//                   }).toList(),
//             ),
//           ),

//           const SizedBox(height: 24),

//           // ── AI Enhancement Toggle ──────────────────────────────────────
//           _AiEnhancementCard(
//             hasAiVersion: state.aiEnhancedData != null,
//             isGenerating: state.generatingAI,
//             useAiVersion: state.useAiVersion,
//             error: state.error,
//             onGenerate: () => notifier.generateWithAI(),
//             onToggle: (v) => notifier.toggleAiVersion(v),
//           ),

//           const SizedBox(height: 24),

//           // ── CV Preview ────────────────────────────────────────────────
//           _SectionLabel(icon: Icons.preview_rounded, label: 'CV Preview'),
//           const SizedBox(height: 12),

//           _CvPreview(
//             data: state.activeCvData!,
//             template: state.selectedTemplate,
//           ),

//           const SizedBox(height: 28),

//           // ── Download Button ───────────────────────────────────────────
//           _DownloadButton(
//             onPressed:
//                 () => onDownload(state.activeCvData!, state.selectedTemplate),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Template Card
// // ─────────────────────────────────────────────────────────────────────────────
// class _TemplateCard extends StatelessWidget {
//   final CvTemplate template;
//   final bool selected;
//   final VoidCallback onTap;

//   const _TemplateCard({
//     required this.template,
//     required this.selected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final color = template.accentColor;
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: 90,
//         margin: const EdgeInsets.only(right: 12),
//         decoration: BoxDecoration(
//           color: selected ? color : Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: selected ? color : Colors.grey.shade200,
//             width: selected ? 2 : 1,
//           ),
//           boxShadow:
//               selected
//                   ? [
//                     BoxShadow(
//                       color: color.withOpacity(0.3),
//                       blurRadius: 12,
//                       offset: const Offset(0, 4),
//                     ),
//                   ]
//                   : [],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               template.icon,
//               color: selected ? Colors.white : color,
//               size: 28,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               template.label,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: selected ? Colors.white : Colors.grey.shade700,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // AI Enhancement Card
// // ─────────────────────────────────────────────────────────────────────────────
// class _AiEnhancementCard extends StatelessWidget {
//   final bool hasAiVersion;
//   final bool isGenerating;
//   final bool useAiVersion;
//   final String? error;
//   final VoidCallback onGenerate;
//   final ValueChanged<bool> onToggle;

//   const _AiEnhancementCard({
//     required this.hasAiVersion,
//     required this.isGenerating,
//     required this.useAiVersion,
//     required this.error,
//     required this.onGenerate,
//     required this.onToggle,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF1A237E), Color(0xFF283593)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF1A237E).withOpacity(0.3),
//             blurRadius: 14,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(
//                   Icons.auto_awesome,
//                   color: Colors.amber,
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'AI Enhancement',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 15,
//                       ),
//                     ),
//                     Text(
//                       'Powered by Groq AI',
//                       style: TextStyle(color: Colors.white70, fontSize: 11),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           const Text(
//             'Let AI rewrite your bio, occupation, and activities to sound more professional and impactful.',
//             style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
//           ),
//           if (error != null)
//             Padding(
//               padding: const EdgeInsets.only(top: 8),
//               child: Text(
//                 error!,
//                 style: const TextStyle(
//                   color: Colors.orangeAccent,
//                   fontSize: 11,
//                 ),
//               ),
//             ),
//           const SizedBox(height: 14),
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: isGenerating ? null : onGenerate,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     foregroundColor: const Color(0xFF1A237E),
//                     disabledBackgroundColor: Colors.white38,
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   icon:
//                       isGenerating
//                           ? const SizedBox(
//                             width: 16,
//                             height: 16,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               color: Color(0xFF1A237E),
//                             ),
//                           )
//                           : const Icon(Icons.auto_fix_high, size: 18),
//                   label: Text(
//                     isGenerating
//                         ? 'Enhancing...'
//                         : hasAiVersion
//                         ? 'Re-enhance'
//                         : 'Enhance with AI',
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//               if (hasAiVersion) ...[
//                 const SizedBox(width: 12),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     const Text(
//                       'Use AI',
//                       style: TextStyle(color: Colors.white70, fontSize: 11),
//                     ),
//                     Switch(
//                       value: useAiVersion,
//                       onChanged: onToggle,
//                       activeColor: Colors.amber,
//                       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                     ),
//                   ],
//                 ),
//               ],
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // CV Preview Widget
// // ─────────────────────────────────────────────────────────────────────────────
// class _CvPreview extends StatelessWidget {
//   final CvData data;
//   final CvTemplate template;

//   const _CvPreview({required this.data, required this.template});

//   @override
//   Widget build(BuildContext context) {
//     final accent = template.accentColor;

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: accent.withOpacity(0.15),
//             blurRadius: 20,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: _buildTemplatePreview(accent),
//     );
//   }

//   Widget _buildTemplatePreview(Color accent) {
//     switch (template) {
//       case CvTemplate.classic:
//         return _ClassicPreview(data: data, accent: accent);
//       case CvTemplate.modern:
//         return _ModernPreview(data: data, accent: accent);
//       case CvTemplate.minimal:
//         return _MinimalPreview(data: data, accent: accent);
//       case CvTemplate.creative:
//         return _CreativePreview(data: data, accent: accent);
//     }
//   }
// }

// // Classic Preview
// class _ClassicPreview extends StatelessWidget {
//   final CvData data;
//   final Color accent;
//   const _ClassicPreview({required this.data, required this.accent});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header
//         Container(
//           width: double.infinity,
//           color: accent,
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 data.fullName,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               if (data.occupation != null && data.occupation!.isNotEmpty)
//                 Text(
//                   data.occupation!,
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.8),
//                     fontSize: 13,
//                   ),
//                 ),
//               const SizedBox(height: 8),
//               Wrap(
//                 spacing: 16,
//                 children: [
//                   _contactChip(Icons.email, data.email),
//                   if (data.phone != null && data.phone!.isNotEmpty)
//                     _contactChip(Icons.phone, data.phone!),
//                   if (data.address != null && data.address!.isNotEmpty)
//                     _contactChip(Icons.location_on, data.address!),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         // Body
//         Padding(
//           padding: const EdgeInsets.all(20),
//           child: IntrinsicHeight(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Left
//                 SizedBox(
//                   width: 120,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       if (data.education != null && data.education!.isNotEmpty)
//                         _previewSection('Education', data.education!, accent),
//                       if (data.hobbies != null && data.hobbies!.isNotEmpty)
//                         _previewSection('Interests', data.hobbies!, accent),
//                     ],
//                   ),
//                 ),
//                 VerticalDivider(
//                   color: Colors.grey.shade200,
//                   width: 24,
//                   thickness: 1,
//                 ),
//                 // Right
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       if (data.bio != null && data.bio!.isNotEmpty)
//                         _previewSection('Profile', data.bio!, accent),
//                       if (data.activities.isNotEmpty) ...[
//                         _previewSectionTitle('Activities', accent),
//                         ...data.activities
//                             .take(4)
//                             .map(
//                               (a) => Padding(
//                                 padding: const EdgeInsets.only(bottom: 4),
//                                 child: Row(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Icon(Icons.circle, size: 6, color: accent),
//                                     const SizedBox(width: 6),
//                                     Expanded(
//                                       child: Text(
//                                         a,
//                                         style: const TextStyle(fontSize: 11),
//                                         maxLines: 2,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _contactChip(IconData icon, String text) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, color: Colors.white70, size: 12),
//         const SizedBox(width: 4),
//         Text(
//           text,
//           style: const TextStyle(color: Colors.white70, fontSize: 10),
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//       ],
//     );
//   }
// }

// // Modern Preview
// class _ModernPreview extends StatelessWidget {
//   final CvData data;
//   final Color accent;
//   const _ModernPreview({required this.data, required this.accent});

//   @override
//   Widget build(BuildContext context) {
//     return IntrinsicHeight(
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Sidebar
//           Container(
//             width: 130,
//             color: accent,
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   data.fullName,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),
//                 if (data.occupation != null && data.occupation!.isNotEmpty)
//                   Text(
//                     data.occupation!,
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.75),
//                       fontSize: 10,
//                     ),
//                   ),
//                 const SizedBox(height: 14),
//                 Divider(color: Colors.white30),
//                 const SizedBox(height: 10),
//                 _sideItem('Email', data.email),
//                 if (data.phone != null && data.phone!.isNotEmpty)
//                   _sideItem('Phone', data.phone!),
//                 if (data.address != null && data.address!.isNotEmpty)
//                   _sideItem('Location', data.address!),
//                 if (data.education != null && data.education!.isNotEmpty)
//                   _sideItem('Education', data.education!),
//                 if (data.hobbies != null && data.hobbies!.isNotEmpty)
//                   _sideItem('Interests', data.hobbies!),
//               ],
//             ),
//           ),
//           // Content
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (data.bio != null && data.bio!.isNotEmpty) ...[
//                     _previewSectionTitle('About Me', accent),
//                     const SizedBox(height: 6),
//                     Text(
//                       data.bio!,
//                       style: const TextStyle(
//                         fontSize: 11,
//                         color: Colors.black87,
//                         height: 1.5,
//                       ),
//                       maxLines: 4,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 12),
//                   ],
//                   if (data.activities.isNotEmpty) ...[
//                     _previewSectionTitle('Activities', accent),
//                     const SizedBox(height: 6),
//                     ...data.activities
//                         .take(4)
//                         .map(
//                           (a) => Padding(
//                             padding: const EdgeInsets.only(bottom: 5),
//                             child: Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Container(
//                                   margin: const EdgeInsets.only(
//                                     top: 5,
//                                     right: 8,
//                                   ),
//                                   width: 5,
//                                   height: 5,
//                                   decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     color: accent,
//                                   ),
//                                 ),
//                                 Expanded(
//                                   child: Text(
//                                     a,
//                                     style: const TextStyle(fontSize: 11),
//                                     maxLines: 2,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _sideItem(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label.toUpperCase(),
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.5),
//               fontSize: 8,
//               letterSpacing: 1,
//             ),
//           ),
//           Text(
//             value,
//             style: const TextStyle(color: Colors.white, fontSize: 9),
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Minimal Preview
// class _MinimalPreview extends StatelessWidget {
//   final CvData data;
//   final Color accent;
//   const _MinimalPreview({required this.data, required this.accent});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     data.fullName,
//                     style: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   if (data.occupation != null && data.occupation!.isNotEmpty)
//                     Text(
//                       data.occupation!,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                 ],
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(
//                     data.email,
//                     style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
//                   ),
//                   if (data.phone != null && data.phone!.isNotEmpty)
//                     Text(
//                       data.phone!,
//                       style: TextStyle(
//                         fontSize: 9,
//                         color: Colors.grey.shade700,
//                       ),
//                     ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Divider(color: Colors.grey.shade300, thickness: 0.5),
//           const SizedBox(height: 14),
//           if (data.bio != null && data.bio!.isNotEmpty) ...[
//             _previewSectionTitle('PROFILE', accent, letterSpacing: 2.0),
//             const SizedBox(height: 6),
//             Text(
//               data.bio!,
//               style: const TextStyle(fontSize: 11, height: 1.6),
//               maxLines: 3,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 14),
//           ],
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (data.education != null && data.education!.isNotEmpty)
//                       _minimalItem('EDUCATION', data.education!, accent),
//                     if (data.hobbies != null && data.hobbies!.isNotEmpty)
//                       _minimalItem('INTERESTS', data.hobbies!, accent),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 16),
//               if (data.activities.isNotEmpty)
//                 Expanded(
//                   flex: 2,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _previewSectionTitle(
//                         'ACTIVITIES',
//                         accent,
//                         letterSpacing: 2.0,
//                       ),
//                       const SizedBox(height: 6),
//                       ...data.activities
//                           .take(3)
//                           .map(
//                             (a) => Padding(
//                               padding: const EdgeInsets.only(bottom: 4),
//                               child: Text(
//                                 '— $a',
//                                 style: const TextStyle(fontSize: 10),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                           ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _minimalItem(String label, String value, Color accent) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 8,
//               letterSpacing: 2,
//               fontWeight: FontWeight.bold,
//               color: accent,
//             ),
//           ),
//           const SizedBox(height: 3),
//           Text(
//             value,
//             style: const TextStyle(fontSize: 10),
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Creative Preview
// class _CreativePreview extends StatelessWidget {
//   final CvData data;
//   final Color accent;
//   const _CreativePreview({required this.data, required this.accent});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header
//         Container(
//           width: double.infinity,
//           color: accent,
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     data.fullName.toUpperCase(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                       letterSpacing: 2,
//                     ),
//                   ),
//                   if (data.occupation != null && data.occupation!.isNotEmpty)
//                     Text(
//                       data.occupation!,
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.75),
//                         fontSize: 11,
//                       ),
//                     ),
//                 ],
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(
//                     data.email,
//                     style: const TextStyle(color: Colors.white70, fontSize: 9),
//                   ),
//                   if (data.phone != null && data.phone!.isNotEmpty)
//                     Text(
//                       data.phone!,
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 9,
//                       ),
//                     ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         // Stripe
//         Container(height: 4, color: _kPrimary),
//         // Body
//         Padding(
//           padding: const EdgeInsets.all(20),
//           child: IntrinsicHeight(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Left
//                 SizedBox(
//                   width: 110,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       if (data.education != null && data.education!.isNotEmpty)
//                         _creativeSide('Education', data.education!, accent),
//                       if (data.hobbies != null && data.hobbies!.isNotEmpty)
//                         _creativeSide('Interests', data.hobbies!, accent),
//                     ],
//                   ),
//                 ),
//                 VerticalDivider(
//                   color: Colors.grey.shade200,
//                   width: 24,
//                   thickness: 1,
//                 ),
//                 // Right
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       if (data.bio != null && data.bio!.isNotEmpty) ...[
//                         _creativeTitle('About', accent),
//                         Text(
//                           data.bio!,
//                           style: const TextStyle(fontSize: 10, height: 1.5),
//                           maxLines: 3,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 12),
//                       ],
//                       if (data.activities.isNotEmpty) ...[
//                         _creativeTitle('Highlights', accent),
//                         ...data.activities
//                             .take(3)
//                             .map(
//                               (a) => Padding(
//                                 padding: const EdgeInsets.only(bottom: 5),
//                                 child: Row(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Container(
//                                       width: 4,
//                                       height: 4,
//                                       margin: const EdgeInsets.only(
//                                         top: 4,
//                                         right: 6,
//                                       ),
//                                       color: accent,
//                                     ),
//                                     Expanded(
//                                       child: Text(
//                                         a,
//                                         style: const TextStyle(fontSize: 10),
//                                         maxLines: 2,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _creativeSide(String label, String value, Color accent) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(width: 3, height: 12, color: accent),
//               const SizedBox(width: 6),
//               Text(
//                 label.toUpperCase(),
//                 style: TextStyle(
//                   fontSize: 8,
//                   letterSpacing: 1.5,
//                   fontWeight: FontWeight.bold,
//                   color: accent,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: const TextStyle(fontSize: 10),
//             maxLines: 3,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _creativeTitle(String label, Color accent) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Row(
//         children: [
//           Container(width: 3, height: 12, color: accent),
//           const SizedBox(width: 6),
//           Text(
//             label.toUpperCase(),
//             style: TextStyle(
//               fontSize: 8,
//               letterSpacing: 1.5,
//               fontWeight: FontWeight.bold,
//               color: accent,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Shared preview helpers
// // ─────────────────────────────────────────────────────────────────────────────
// Widget _previewSection(String title, String content, Color accent) {
//   return Padding(
//     padding: const EdgeInsets.only(bottom: 14),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _previewSectionTitle(title, accent),
//         const SizedBox(height: 4),
//         Text(
//           content,
//           style: const TextStyle(fontSize: 11, height: 1.4),
//           maxLines: 4,
//           overflow: TextOverflow.ellipsis,
//         ),
//       ],
//     ),
//   );
// }

// Widget _previewSectionTitle(
//   String title,
//   Color accent, {
//   double letterSpacing = 0.5,
// }) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(
//         title,
//         style: TextStyle(
//           fontSize: 10,
//           fontWeight: FontWeight.bold,
//           color: accent,
//           letterSpacing: letterSpacing,
//         ),
//       ),
//       const SizedBox(height: 2),
//       Container(height: 1.5, width: 30, color: accent),
//     ],
//   );
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Download Button
// // ─────────────────────────────────────────────────────────────────────────────
// class _DownloadButton extends StatelessWidget {
//   final VoidCallback onPressed;

//   const _DownloadButton({required this.onPressed});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       height: 54,
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [_kPrimary, Color.fromRGBO(255, 131, 90, 1)],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: _kPrimary.withOpacity(0.4),
//             blurRadius: 14,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: ElevatedButton.icon(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           shadowColor: Colors.transparent,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//         ),
//         icon: const Icon(Icons.download_rounded, color: Colors.white),
//         label: const Text(
//           'Download CV as PDF',
//           style: TextStyle(
//             fontSize: 17,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Section label helper
// // ─────────────────────────────────────────────────────────────────────────────
// class _SectionLabel extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _SectionLabel({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(6),
//           decoration: BoxDecoration(
//             color: _kPrimaryLight,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: _kPrimary, size: 18),
//         ),
//         const SizedBox(width: 10),
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.black87,
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Loading / Error views
// // ─────────────────────────────────────────────────────────────────────────────
// class _LoadingView extends StatelessWidget {
//   const _LoadingView();

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(color: _kPrimary),
//           const SizedBox(height: 16),
//           Text(
//             'Loading your profile...',
//             style: TextStyle(color: Colors.grey.shade600),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ErrorView extends StatelessWidget {
//   final String message;
//   final VoidCallback onRetry;

//   const _ErrorView({required this.message, required this.onRetry});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
//             const SizedBox(height: 16),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey.shade700),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: onRetry,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: _kPrimary,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('Retry'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────
const _kPrimary = Color.fromRGBO(244, 135, 6, 1);
const _kPrimaryLight = Color.fromRGBO(244, 135, 6, 0.10);
const _kBg = Color(0xFFF8F9FA);

const _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
const _groqApiKey = 'REVOKED_GROQ_KEY';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────
class CvData {
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final String? bio;
  final String? education;
  final String? occupation;
  final String? hobbies;
  final String? gender;
  final String? dateOfBirth;
  final String? avatarUrl;
  final List<String> activities;

  const CvData({
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    this.bio,
    this.education,
    this.occupation,
    this.hobbies,
    this.gender,
    this.dateOfBirth,
    this.avatarUrl,
    this.activities = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Templates
// ─────────────────────────────────────────────────────────────────────────────
enum CvTemplate { classic, modern, minimal, creative }

extension CvTemplateX on CvTemplate {
  String get label {
    switch (this) {
      case CvTemplate.classic:
        return 'Classic';
      case CvTemplate.modern:
        return 'Modern';
      case CvTemplate.minimal:
        return 'Minimal';
      case CvTemplate.creative:
        return 'Creative';
    }
  }

  IconData get icon {
    switch (this) {
      case CvTemplate.classic:
        return Icons.article_outlined;
      case CvTemplate.modern:
        return Icons.dashboard_outlined;
      case CvTemplate.minimal:
        return Icons.horizontal_rule_rounded;
      case CvTemplate.creative:
        return Icons.palette_outlined;
    }
  }

  Color get accentColor {
    switch (this) {
      case CvTemplate.classic:
        return const Color(0xFF1A237E);
      case CvTemplate.modern:
        return _kPrimary;
      case CvTemplate.minimal:
        return const Color(0xFF263238);
      case CvTemplate.creative:
        return const Color(0xFF6A1B9A);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────
class CvState {
  final bool loadingProfile;
  final bool generatingAI;
  final CvData? cvData;
  final CvData? aiEnhancedData;
  final CvTemplate selectedTemplate;
  final bool useAiVersion;
  final String? error;

  const CvState({
    this.loadingProfile = false,
    this.generatingAI = false,
    this.cvData,
    this.aiEnhancedData,
    this.selectedTemplate = CvTemplate.modern,
    this.useAiVersion = false,
    this.error,
  });

  CvState copyWith({
    bool? loadingProfile,
    bool? generatingAI,
    CvData? cvData,
    CvData? aiEnhancedData,
    CvTemplate? selectedTemplate,
    bool? useAiVersion,
    String? error,
  }) => CvState(
    loadingProfile: loadingProfile ?? this.loadingProfile,
    generatingAI: generatingAI ?? this.generatingAI,
    cvData: cvData ?? this.cvData,
    aiEnhancedData: aiEnhancedData ?? this.aiEnhancedData,
    selectedTemplate: selectedTemplate ?? this.selectedTemplate,
    useAiVersion: useAiVersion ?? this.useAiVersion,
    error: error,
  );

  CvData? get activeCvData => useAiVersion ? aiEnhancedData : cvData;
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────
class CvNotifier extends StateNotifier<CvState> {
  CvNotifier() : super(const CvState());

  Future<void> loadProfileData() async {
    state = state.copyWith(loadingProfile: true, error: null);
    try {
      final appData = AppData();
      await appData.initialize();
      final u = appData.currentUser ?? {};
      final profile = u['profile'] as Map<String, dynamic>? ?? {};

      String? avatarUrl =
          appData.currentUserAvatar ??
          profile['avatar']?.toString() ??
          u['photo_url']?.toString();
      if (avatarUrl != null &&
          avatarUrl.isNotEmpty &&
          !avatarUrl.startsWith('http')) {
        avatarUrl = '${ApiConstants.userBase}$avatarUrl';
      }

      final activities = await _fetchStatusPosts(appData.accessToken ?? '');

      state = state.copyWith(
        loadingProfile: false,
        cvData: CvData(
          fullName: u['full_name']?.toString() ?? 'Your Name',
          email: u['email']?.toString() ?? '',
          phone:
              profile['phone_number']?.toString() ??
              u['phone_number']?.toString(),
          address: profile['address']?.toString() ?? u['address']?.toString(),
          bio: profile['bio']?.toString() ?? u['bio']?.toString(),
          education:
              profile['education']?.toString() ?? u['education']?.toString(),
          occupation:
              profile['occupation']?.toString() ?? u['occupation']?.toString(),
          hobbies: profile['hobbies']?.toString() ?? u['hobbies']?.toString(),
          gender: profile['gender']?.toString() ?? u['gender']?.toString(),
          dateOfBirth:
              profile['date_of_birth']?.toString() ??
              u['date_of_birth']?.toString(),
          avatarUrl: avatarUrl,
          activities: activities,
        ),
      );
    } catch (e) {
      developer.log('[CV] loadProfileData error: $e');
      state = state.copyWith(
        loadingProfile: false,
        error: 'Failed to load profile data.',
      );
    }
  }

  Future<List<String>> _fetchStatusPosts(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstants.post}?type=status&page_size=50'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final results =
            body['results'] as List<dynamic>? ??
            body['data'] as List<dynamic>? ??
            [];
        return results
            .whereType<Map<String, dynamic>>()
            .where(
              (p) =>
                  p['type'] == 'status' ||
                  (p['status'] != null &&
                      p['status'].toString().isNotEmpty &&
                      p['video'] == null),
            )
            .map((p) {
              final content =
                  p['content']?.toString() ??
                  p['status']?.toString() ??
                  p['description']?.toString() ??
                  '';
              final date = p['created_at']?.toString() ?? '';
              if (content.isEmpty) return null;
              if (date.isNotEmpty) {
                try {
                  final d = DateTime.parse(date);
                  return '${d.year}: $content';
                } catch (_) {}
              }
              return content;
            })
            .whereType<String>()
            .take(8)
            .toList();
      }
    } catch (e) {
      developer.log('[CV] fetchStatusPosts error: $e');
    }
    return [];
  }

  void selectTemplate(CvTemplate t) =>
      state = state.copyWith(selectedTemplate: t);
  void toggleAiVersion(bool v) => state = state.copyWith(useAiVersion: v);

  Future<void> generateWithAI() async {
    final raw = state.cvData;
    if (raw == null) return;
    state = state.copyWith(generatingAI: true, error: null);
    try {
      final response = await http
          .post(
            Uri.parse(_groqApiUrl),
            headers: {
              'Authorization': 'Bearer $_groqApiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'llama-3.1-8b-instant',
              'max_tokens': 1500,
              'temperature': 0.7,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are an expert CV/resume writer. '
                      'Enhance CV sections to sound polished and impactful. '
                      'Return ONLY valid JSON — no markdown, no extra text.',
                },
                {'role': 'user', 'content': _buildAIPrompt(raw)},
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content']?.toString() ?? '';
        final cleaned =
            text.replaceAll('```json', '').replaceAll('```', '').trim();
        final enhanced = jsonDecode(cleaned) as Map<String, dynamic>;

        state = state.copyWith(
          generatingAI: false,
          useAiVersion: true,
          aiEnhancedData: CvData(
            fullName: raw.fullName,
            email: raw.email,
            phone: raw.phone,
            address: raw.address,
            gender: raw.gender,
            dateOfBirth: raw.dateOfBirth,
            avatarUrl: raw.avatarUrl,
            bio: enhanced['bio']?.toString() ?? raw.bio,
            education: enhanced['education']?.toString() ?? raw.education,
            occupation: enhanced['occupation']?.toString() ?? raw.occupation,
            hobbies: enhanced['hobbies']?.toString() ?? raw.hobbies,
            activities:
                (enhanced['activities'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                raw.activities,
          ),
        );
      } else {
        throw Exception('Groq ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      developer.log('[CV] generateWithAI error: $e');
      state = state.copyWith(
        generatingAI: false,
        error: 'AI enhancement failed. Using original data.',
      );
    }
  }

  String _buildAIPrompt(CvData d) => '''
Enhance the following CV data and return ONLY a JSON object with improved text.
Make bio professional and concise (2-3 sentences).
Make occupation impressive. Education concise. Hobbies thoughtful.
Rewrite each activity as a professional achievement (start with action verb).

Input:
{
  "bio": ${jsonEncode(d.bio ?? '')},
  "occupation": ${jsonEncode(d.occupation ?? '')},
  "education": ${jsonEncode(d.education ?? '')},
  "hobbies": ${jsonEncode(d.hobbies ?? '')},
  "activities": ${jsonEncode(d.activities)}
}

Return JSON only (no markdown, no preamble):
{
  "bio": "...",
  "occupation": "...",
  "education": "...",
  "hobbies": "...",
  "activities": ["...", "..."]
}
''';
}

final cvProvider = StateNotifierProvider.autoDispose<CvNotifier, CvState>(
  (ref) => CvNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// PDF Generation — syncfusion_flutter_pdf
// ─────────────────────────────────────────────────────────────────────────────
class CvPdfService {
  static PdfColor _c(int r, int g, int b, [int a = 255]) =>
      PdfColor(r, g, b, a);
  static PdfColor _fromFlutter(Color c) =>
      PdfColor(c.red, c.green, c.blue, c.alpha);

  static PdfColor get _white => _c(255, 255, 255);
  static PdfColor get _black => _c(0, 0, 0);
  static PdfColor get _grey6 => _c(102, 102, 102);
  static PdfColor get _grey2 => _c(230, 230, 230);

  static Future<Uint8List> generate(CvData d, CvTemplate tpl) async {
    final doc = PdfDocument();
    final page = doc.pages.add();
    final bounds = page.getClientSize();
    final accent = _fromFlutter(tpl.accentColor);
    switch (tpl) {
      case CvTemplate.classic:
        _classic(page, bounds, d, accent);
        break;
      case CvTemplate.modern:
        _modern(page, bounds, d, accent);
        break;
      case CvTemplate.minimal:
        _minimal(page, bounds, d, accent);
        break;
      case CvTemplate.creative:
        _creative(page, bounds, d, accent);
        break;
    }
    final bytes = await doc.save();
    doc.dispose();
    return Uint8List.fromList(bytes);
  }

  static void _rect(
    PdfPage p,
    double x,
    double y,
    double w,
    double h,
    PdfColor c,
  ) => p.graphics.drawRectangle(
    brush: PdfSolidBrush(c),
    bounds: Rect.fromLTWH(x, y, w, h),
  );

  static void _text(
    PdfPage p,
    String txt,
    double x,
    double y,
    double w,
    PdfFont f,
    PdfColor c, {
    PdfTextAlignment align = PdfTextAlignment.left,
    double mh = 800,
  }) {
    if (txt.isEmpty) return;
    p.graphics.drawString(
      txt,
      f,
      brush: PdfSolidBrush(c),
      bounds: Rect.fromLTWH(x, y, w, mh),
      format: PdfStringFormat(
        alignment: align,
        lineAlignment: PdfVerticalAlignment.top,
        wordWrap: PdfWordWrapType.word,
      ),
    );
  }

  static double _th(String txt, PdfFont f, double w) {
    if (txt.isEmpty) return 0;
    return f.measureString(txt, layoutArea: Size(w, 0)).height + 2;
  }

  /// Draws a section heading + underline, returns Y after the underline gap.
  static double _heading(
    PdfPage p,
    String title,
    double x,
    double y,
    double w,
    PdfColor accent,
  ) {
    final f = PdfStandardFont(
      PdfFontFamily.helvetica,
      9,
      style: PdfFontStyle.bold,
    );
    _text(p, title.toUpperCase(), x, y, w, f, accent);
    final lineY = y + 14;
    p.graphics.drawLine(
      PdfPen(accent, width: 1.5),
      Offset(x, lineY),
      Offset(x + w, lineY),
    );
    return lineY + 6;
  }

  // ── Classic ──────────────────────────────────────────────────────────────
  static void _classic(PdfPage p, Size b, CvData d, PdfColor accent) {
    const hH = 90.0;
    const pad = 36.0;
    const lW = 160.0;
    const gut = 20.0;

    _rect(p, 0, 0, b.width, hH, accent);

    final bold24 = PdfStandardFont(
      PdfFontFamily.helvetica,
      24,
      style: PdfFontStyle.bold,
    );
    final reg12 = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final reg8 = PdfStandardFont(PdfFontFamily.helvetica, 8);
    final body = PdfStandardFont(PdfFontFamily.helvetica, 10);

    _text(p, d.fullName, pad, 16, b.width - pad * 2, bold24, _white);
    if (d.occupation?.isNotEmpty == true)
      _text(p, d.occupation!, pad, 46, b.width - pad * 2, reg12, _white);
    final contact = [
      d.email,
      if (d.phone?.isNotEmpty == true) d.phone!,
      if (d.address?.isNotEmpty == true) d.address!,
    ].join('  •  ');
    _text(p, contact, pad, 68, b.width - pad * 2, reg8, _white);

    double lY = hH + pad, rY = hH + pad;
    final rX = pad + lW + gut;
    final rW = b.width - rX - pad;

    // LEFT
    if (d.education?.isNotEmpty == true) {
      lY = _heading(p, 'Education', pad, lY, lW, accent);
      _text(p, d.education!, pad, lY, lW, body, _black, mh: 60);
      lY += _th(d.education!, body, lW) + 16;
    }
    if (d.hobbies?.isNotEmpty == true) {
      lY = _heading(p, 'Interests', pad, lY, lW, accent);
      _text(p, d.hobbies!, pad, lY, lW, body, _black, mh: 60);
      lY += _th(d.hobbies!, body, lW) + 16;
    }
    final personal = [
      if (d.gender?.isNotEmpty == true) 'Gender: ${d.gender}',
      if (d.dateOfBirth?.isNotEmpty == true) 'DOB: ${d.dateOfBirth}',
    ];
    if (personal.isNotEmpty) {
      lY = _heading(p, 'Personal', pad, lY, lW, accent);
      _text(p, personal.join('\n'), pad, lY, lW, body, _black, mh: 40);
    }

    // RIGHT
    if (d.bio?.isNotEmpty == true) {
      rY = _heading(p, 'Profile', rX, rY, rW, accent);
      _text(p, d.bio!, rX, rY, rW, body, _black, mh: 80);
      rY += _th(d.bio!, body, rW) + 16;
    }
    if (d.activities.isNotEmpty) {
      rY = _heading(p, 'Activities & Achievements', rX, rY, rW, accent);
      for (final a in d.activities) {
        final bullet = '•  $a';
        _text(p, bullet, rX, rY, rW, body, _black, mh: 30);
        rY += _th(bullet, body, rW) + 6;
      }
    }

    p.graphics.drawLine(
      PdfPen(_grey2, width: 1),
      Offset(pad + lW + gut / 2, hH + pad),
      Offset(pad + lW + gut / 2, b.height - pad),
    );
  }

  // ── Modern ───────────────────────────────────────────────────────────────
  static void _modern(PdfPage p, Size b, CvData d, PdfColor accent) {
    const sW = 175.0;
    const pS = 20.0;
    const pM = 26.0;

    _rect(p, 0, 0, sW, b.height, accent);

    double sy = 30.0;
    final bold = PdfStandardFont(
      PdfFontFamily.helvetica,
      15,
      style: PdfFontStyle.bold,
    );
    final small = PdfStandardFont(PdfFontFamily.helvetica, 9);
    final tiny = PdfStandardFont(PdfFontFamily.helvetica, 8);
    final body = PdfStandardFont(PdfFontFamily.helvetica, 10);

    _text(p, d.fullName, pS, sy, sW - pS * 2, bold, _white, mh: 40);
    sy += _th(d.fullName, bold, sW - pS * 2) + 4;
    if (d.occupation?.isNotEmpty == true) {
      _text(
        p,
        d.occupation!,
        pS,
        sy,
        sW - pS * 2,
        small,
        _c(220, 220, 220),
        mh: 30,
      );
      sy += _th(d.occupation!, small, sW - pS * 2) + 10;
    }
    p.graphics.drawLine(
      PdfPen(_c(255, 255, 255, 80), width: 0.8),
      Offset(pS, sy),
      Offset(sW - pS, sy),
    );
    sy += 14;

    void sLabel(String t) {
      _text(p, t.toUpperCase(), pS, sy, sW - pS * 2, tiny, _c(180, 180, 180));
      sy += 12;
    }

    void sVal(String v) {
      _text(p, v, pS, sy, sW - pS * 2, tiny, _white, mh: 28);
      sy += _th(v, tiny, sW - pS * 2) + 6;
    }

    sLabel('Contact');
    sVal(d.email);
    if (d.phone?.isNotEmpty == true) sVal(d.phone!);
    if (d.address?.isNotEmpty == true) sVal(d.address!);
    sy += 4;
    if (d.education?.isNotEmpty == true) {
      sLabel('Education');
      sVal(d.education!);
      sy += 4;
    }
    if (d.hobbies?.isNotEmpty == true) {
      sLabel('Interests');
      sVal(d.hobbies!);
    }

    final mX = sW + pM;
    final mW = b.width - mX - pM;
    double my = 30.0;

    if (d.bio?.isNotEmpty == true) {
      my = _heading(p, 'About Me', mX, my, mW, accent);
      _text(p, d.bio!, mX, my, mW, body, _black, mh: 80);
      my += _th(d.bio!, body, mW) + 18;
    }
    if (d.activities.isNotEmpty) {
      my = _heading(p, 'Activities & Achievements', mX, my, mW, accent);
      for (final a in d.activities) {
        p.graphics.drawRectangle(
          brush: PdfSolidBrush(accent),
          bounds: Rect.fromLTWH(mX, my + 4, 5, 5),
        );
        _text(p, a, mX + 12, my, mW - 12, body, _black, mh: 28);
        my += _th(a, body, mW - 12) + 7;
      }
    }
  }

  // ── Minimal ──────────────────────────────────────────────────────────────
  static void _minimal(PdfPage p, Size b, CvData d, PdfColor accent) {
    const pad = 52.0;
    const lW = 155.0;
    const gut = 30.0;

    final title = PdfStandardFont(
      PdfFontFamily.helvetica,
      28,
      style: PdfFontStyle.bold,
    );
    final sub = PdfStandardFont(PdfFontFamily.helvetica, 11);
    final body = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final tiny = PdfStandardFont(PdfFontFamily.helvetica, 8);
    final lbl = PdfStandardFont(
      PdfFontFamily.helvetica,
      8,
      style: PdfFontStyle.bold,
    );

    _text(p, d.fullName, pad, 28, 280, title, _black);
    if (d.occupation?.isNotEmpty == true)
      _text(p, d.occupation!, pad, 64, 280, sub, _grey6);

    final contacts = [
      d.email,
      if (d.phone?.isNotEmpty == true) d.phone!,
      if (d.address?.isNotEmpty == true) d.address!,
    ];
    double cy = 28.0;
    for (final c in contacts) {
      _text(
        p,
        c,
        b.width - pad - 160,
        cy,
        160,
        tiny,
        _grey6,
        align: PdfTextAlignment.right,
      );
      cy += 13;
    }

    p.graphics.drawLine(
      PdfPen(_black, width: 0.6),
      Offset(pad, 84),
      Offset(b.width - pad, 84),
    );
    double y = 98.0;

    if (d.bio?.isNotEmpty == true) {
      y = _heading(p, 'Profile', pad, y, b.width - pad * 2, accent);
      _text(p, d.bio!, pad, y, b.width - pad * 2, body, _black, mh: 80);
      y += _th(d.bio!, body, b.width - pad * 2) + 18;
    }

    final rX = pad + lW + gut;
    final rW = b.width - rX - pad;
    double lY = y, rY = y;

    void minLeft(String label, String value) {
      _text(p, label.toUpperCase(), pad, lY, lW, lbl, accent);
      lY += 12;
      _text(p, value, pad, lY, lW, body, _black, mh: 50);
      lY += _th(value, body, lW) + 14;
    }

    if (d.education?.isNotEmpty == true) minLeft('Education', d.education!);
    if (d.hobbies?.isNotEmpty == true) minLeft('Interests', d.hobbies!);

    if (d.activities.isNotEmpty) {
      rY = _heading(p, 'Activities', rX, rY, rW, accent);
      for (final a in d.activities) {
        _text(p, '— $a', rX, rY, rW, body, _black, mh: 28);
        rY += _th('— $a', body, rW) + 5;
      }
    }
  }

  // ── Creative ─────────────────────────────────────────────────────────────
  static void _creative(PdfPage p, Size b, CvData d, PdfColor accent) {
    const hH = 88.0;
    const stH = 5.0;
    const pad = 36.0;
    const lW = 145.0;
    const gut = 22.0;

    _rect(p, 0, 0, b.width, hH, accent);
    _rect(p, 0, hH, b.width, stH, _c(244, 135, 6));

    final bold20 = PdfStandardFont(
      PdfFontFamily.helvetica,
      20,
      style: PdfFontStyle.bold,
    );
    final reg11 = PdfStandardFont(PdfFontFamily.helvetica, 11);
    final reg8 = PdfStandardFont(PdfFontFamily.helvetica, 8);
    final body = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final lbl8 = PdfStandardFont(
      PdfFontFamily.helvetica,
      8,
      style: PdfFontStyle.bold,
    );

    _text(
      p,
      d.fullName.toUpperCase(),
      pad,
      20,
      b.width - pad * 2 - 160,
      bold20,
      _white,
    );
    if (d.occupation?.isNotEmpty == true)
      _text(p, d.occupation!, pad, 52, b.width - pad * 2 - 160, reg11, _white);

    final contacts = [
      d.email,
      if (d.phone?.isNotEmpty == true) d.phone!,
      if (d.address?.isNotEmpty == true) d.address!,
    ];
    double cy = 24.0;
    for (final c in contacts) {
      _text(
        p,
        c,
        b.width - pad - 155,
        cy,
        155,
        reg8,
        _white,
        align: PdfTextAlignment.right,
      );
      cy += 13;
    }

    final bT = hH + stH + pad;
    double lY = bT, rY = bT;
    final rX = pad + lW + gut;
    final rW = b.width - rX - pad;

    void creLeft(String label, String value) {
      _rect(p, pad, lY, 3, 13, accent);
      _text(p, label.toUpperCase(), pad + 9, lY, lW - 9, lbl8, accent);
      lY += 16;
      _text(p, value, pad, lY, lW, body, _black, mh: 50);
      lY += _th(value, body, lW) + 14;
    }

    if (d.education?.isNotEmpty == true) creLeft('Education', d.education!);
    if (d.hobbies?.isNotEmpty == true) creLeft('Interests', d.hobbies!);
    final personal = [
      if (d.gender?.isNotEmpty == true) 'Gender: ${d.gender}',
      if (d.dateOfBirth?.isNotEmpty == true) 'DOB: ${d.dateOfBirth}',
    ];
    if (personal.isNotEmpty) creLeft('Personal', personal.join('\n'));

    p.graphics.drawLine(
      PdfPen(_grey2, width: 1),
      Offset(pad + lW + gut / 2, bT),
      Offset(pad + lW + gut / 2, b.height - pad),
    );

    void creRight(String label) {
      _rect(p, rX, rY, 3, 13, accent);
      _text(p, label.toUpperCase(), rX + 9, rY, rW - 9, lbl8, accent);
      rY += 18;
    }

    if (d.bio?.isNotEmpty == true) {
      creRight('About');
      _text(p, d.bio!, rX, rY, rW, body, _black, mh: 70);
      rY += _th(d.bio!, body, rW) + 16;
    }
    if (d.activities.isNotEmpty) {
      creRight('Highlights');
      for (final a in d.activities) {
        _rect(p, rX, rY + 4, 4, 4, accent);
        _text(p, a, rX + 10, rY, rW - 10, body, _black, mh: 28);
        rY += _th(a, body, rW - 10) + 7;
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Save / Share helpers
// ─────────────────────────────────────────────────────────────────────────────
class _PdfSaver {
  static Future<void> share(Uint8List bytes, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([
      XFile(file.path, mimeType: 'application/pdf'),
    ], subject: name);
  }

  static Future<void> saveAndOpen(Uint8List bytes, String name) async {
    late Directory dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync())
        dir =
            await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CV Screen
// ─────────────────────────────────────────────────────────────────────────────
class CvScreen extends ConsumerStatefulWidget {
  const CvScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CvScreen> createState() => _CvScreenState();
}

class _CvScreenState extends ConsumerState<CvScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(cvProvider.notifier).loadProfileData(),
    );
  }

  Future<void> _onDownload(CvData data, CvTemplate template) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DownloadSheet(data: data, template: template),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cvProvider);
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Make a CV'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (state.activeCvData != null)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Download PDF',
              onPressed:
                  () =>
                      _onDownload(state.activeCvData!, state.selectedTemplate),
            ),
        ],
      ),
      body:
          state.loadingProfile
              ? const _LoadingView()
              : state.cvData == null
              ? _ErrorView(
                message: state.error ?? 'Could not load profile data.',
                onRetry: () => ref.read(cvProvider.notifier).loadProfileData(),
              )
              : _CvBody(onDownload: _onDownload),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Download Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _DownloadSheet extends StatefulWidget {
  final CvData data;
  final CvTemplate template;
  const _DownloadSheet({required this.data, required this.template});

  @override
  State<_DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends State<_DownloadSheet> {
  bool _busy = false;
  String? _msg;

  Future<void> _act(Future<void> Function(Uint8List, String) action) async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final bytes = await CvPdfService.generate(widget.data, widget.template);
      final name =
          'cv_${widget.data.fullName.replaceAll(' ', '_').toLowerCase()}.pdf';
      await action(bytes, name);
      if (mounted)
        setState(() {
          _busy = false;
          _msg = 'Done! CV saved successfully.';
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _busy = false;
          _msg = 'Error: $e';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Download CV',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how you\'d like to get your CV',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: _kPrimary),
            )
          else ...[
            _tile(
              Icons.save_alt_rounded,
              'Save to Device',
              Platform.isIOS
                  ? 'Saves to Files app'
                  : 'Saves to Downloads folder',
              _kPrimary,
              () => _act(_PdfSaver.saveAndOpen),
            ),
            const SizedBox(height: 12),
            _tile(
              Icons.share_rounded,
              'Share PDF',
              'Send via WhatsApp, email, or any app',
              const Color(0xFF1A237E),
              () => _act(_PdfSaver.share),
            ),
          ],
          if (_msg != null) ...[
            const SizedBox(height: 14),
            Text(
              _msg!,
              style: TextStyle(
                color:
                    _msg!.startsWith('Error')
                        ? Colors.red
                        : Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    String sub,
    Color color,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Main body
// ─────────────────────────────────────────────────────────────────────────────
class _CvBody extends ConsumerWidget {
  final Future<void> Function(CvData, CvTemplate) onDownload;
  const _CvBody({required this.onDownload});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cvProvider);
    final notifier = ref.read(cvProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(icon: Icons.style_rounded, label: 'Choose Template'),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  CvTemplate.values
                      .map(
                        (t) => _TemplateCard(
                          template: t,
                          selected: state.selectedTemplate == t,
                          onTap: () => notifier.selectTemplate(t),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 24),
          _AiCard(
            hasAi: state.aiEnhancedData != null,
            generating: state.generatingAI,
            useAi: state.useAiVersion,
            error: state.error,
            onGenerate: () => notifier.generateWithAI(),
            onToggle: notifier.toggleAiVersion,
          ),
          const SizedBox(height: 24),
          _SectionLabel(icon: Icons.preview_rounded, label: 'CV Preview'),
          const SizedBox(height: 12),
          _CvPreview(
            data: state.activeCvData!,
            template: state.selectedTemplate,
          ),
          const SizedBox(height: 28),
          _DownloadBtn(
            onPressed:
                () => onDownload(state.activeCvData!, state.selectedTemplate),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Template Card
// ─────────────────────────────────────────────────────────────────────────────
class _TemplateCard extends StatelessWidget {
  final CvTemplate template;
  final bool selected;
  final VoidCallback onTap;
  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = template.accentColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: selected ? c : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? c : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: c.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(template.icon, color: selected ? Colors.white : c, size: 28),
            const SizedBox(height: 8),
            Text(
              template.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Card
// ─────────────────────────────────────────────────────────────────────────────
class _AiCard extends StatelessWidget {
  final bool hasAi, generating, useAi;
  final String? error;
  final VoidCallback onGenerate;
  final ValueChanged<bool> onToggle;
  const _AiCard({
    required this.hasAi,
    required this.generating,
    required this.useAi,
    required this.error,
    required this.onGenerate,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Enhancement',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    // Text(
                    //   'Powered by Groq AI',
                    //   style: TextStyle(color: Colors.white70, fontSize: 11),
                    // ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Let AI rewrite your bio, occupation & activities to sound professional and impactful.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error!,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 11,
                ),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: generating ? null : onGenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A237E),
                    disabledBackgroundColor: Colors.white38,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon:
                      generating
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1A237E),
                            ),
                          )
                          : const Icon(Icons.auto_fix_high, size: 18),
                  label: Text(
                    generating
                        ? 'Enhancing...'
                        : hasAi
                        ? 'Re-enhance'
                        : 'Enhance with AI',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (hasAi) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Use AI',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Switch(
                      value: useAi,
                      onChanged: onToggle,
                      activeColor: Colors.amber,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CV Preview dispatcher
// ─────────────────────────────────────────────────────────────────────────────
class _CvPreview extends StatelessWidget {
  final CvData data;
  final CvTemplate template;
  const _CvPreview({required this.data, required this.template});

  @override
  Widget build(BuildContext context) {
    final accent = template.accentColor;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: switch (template) {
        CvTemplate.classic => _ClassicPreview(data: data, accent: accent),
        CvTemplate.modern => _ModernPreview(data: data, accent: accent),
        CvTemplate.minimal => _MinimalPreview(data: data, accent: accent),
        CvTemplate.creative => _CreativePreview(data: data, accent: accent),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared preview helpers
// ─────────────────────────────────────────────────────────────────────────────
Widget _pvSection(String title, String body, Color accent) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _pvTitle(title, accent),
      const SizedBox(height: 4),
      Text(
        body,
        style: const TextStyle(fontSize: 10, height: 1.4),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  ),
);

Widget _pvTitle(String title, Color accent, {double ls = 0.5}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      title,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: accent,
        letterSpacing: ls,
      ),
    ),
    const SizedBox(height: 2),
    Container(height: 1.5, width: 28, color: accent),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// CLASSIC preview
// ─────────────────────────────────────────────────────────────────────────────
class _ClassicPreview extends StatelessWidget {
  final CvData data;
  final Color accent;
  const _ClassicPreview({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ── Header ──────────────────────────────────────────────────────────
      Container(
        width: double.infinity,
        color: accent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (data.occupation?.isNotEmpty == true)
              Text(
                data.occupation!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            const SizedBox(height: 6),
            // FIX: Use Wrap so chips never overflow
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                _chip(Icons.email, data.email),
                if (data.phone?.isNotEmpty == true)
                  _chip(Icons.phone, data.phone!),
                if (data.address?.isNotEmpty == true)
                  _chip(Icons.location_on, data.address!),
              ],
            ),
          ],
        ),
      ),
      // ── Body ────────────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.all(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column — fixed width to prevent overflow
              SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.education?.isNotEmpty == true)
                      _pvSection('Education', data.education!, accent),
                    if (data.hobbies?.isNotEmpty == true)
                      _pvSection('Interests', data.hobbies!, accent),
                  ],
                ),
              ),
              VerticalDivider(
                color: Colors.grey.shade200,
                width: 18,
                thickness: 1,
              ),
              // Right column — Expanded to fill remaining space
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.bio?.isNotEmpty == true)
                      _pvSection('Profile', data.bio!, accent),
                    if (data.activities.isNotEmpty) ...[
                      _pvTitle('Activities', accent),
                      const SizedBox(height: 4),
                      ...data.activities
                          .take(4)
                          .map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.circle, size: 5, color: accent),
                                  const SizedBox(width: 5),
                                  // FIX: Expanded so long text wraps instead of overflowing
                                  Expanded(
                                    child: Text(
                                      a,
                                      style: const TextStyle(fontSize: 10),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _chip(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.white70, size: 10),
      const SizedBox(width: 3),
      // FIX: constrain chip text to prevent Row overflow
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 9),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MODERN preview
// ─────────────────────────────────────────────────────────────────────────────
class _ModernPreview extends StatelessWidget {
  final CvData data;
  final Color accent;
  const _ModernPreview({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar — fixed width
        SizedBox(
          width: 120,
          child: Container(
            color: accent,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (data.occupation?.isNotEmpty == true)
                  Text(
                    data.occupation!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 9,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 10),
                Divider(color: Colors.white30),
                const SizedBox(height: 6),
                _side('Email', data.email),
                if (data.phone?.isNotEmpty == true) _side('Phone', data.phone!),
                if (data.address?.isNotEmpty == true)
                  _side('Location', data.address!),
                if (data.education?.isNotEmpty == true)
                  _side('Education', data.education!),
                if (data.hobbies?.isNotEmpty == true)
                  _side('Interests', data.hobbies!),
              ],
            ),
          ),
        ),
        // Main — Expanded
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.bio?.isNotEmpty == true) ...[
                  _pvTitle('About Me', accent),
                  const SizedBox(height: 4),
                  Text(
                    data.bio!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                ],
                if (data.activities.isNotEmpty) ...[
                  _pvTitle('Activities', accent),
                  const SizedBox(height: 4),
                  ...data.activities
                      .take(4)
                      .map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4, right: 6),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  a,
                                  style: const TextStyle(fontSize: 10),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _side(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 7,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 8),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MINIMAL preview
// FIX: Wrap both Column children in Expanded/Flexible inside the header Row
// ─────────────────────────────────────────────────────────────────────────────
class _MinimalPreview extends StatelessWidget {
  final CvData data;
  final Color accent;
  const _MinimalPreview({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── FIX: both sides wrapped in Expanded to prevent overflow ─────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Name + occupation — takes as much space as it needs, shrinks if needed
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (data.occupation?.isNotEmpty == true)
                    Text(
                      data.occupation!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Contact — takes remaining space, right-aligned
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.email,
                    style: TextStyle(fontSize: 8, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                  if (data.phone?.isNotEmpty == true)
                    Text(
                      data.phone!,
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(color: Colors.grey.shade300, thickness: 0.5),
        const SizedBox(height: 10),
        if (data.bio?.isNotEmpty == true) ...[
          _pvTitle('PROFILE', accent, ls: 2),
          const SizedBox(height: 4),
          Text(
            data.bio!,
            style: const TextStyle(fontSize: 10, height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
        ],
        // ── FIX: both columns in Expanded ──────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.education?.isNotEmpty == true)
                    _minItem('EDUCATION', data.education!, accent),
                  if (data.hobbies?.isNotEmpty == true)
                    _minItem('INTERESTS', data.hobbies!, accent),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (data.activities.isNotEmpty)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pvTitle('ACTIVITIES', accent, ls: 2),
                    const SizedBox(height: 4),
                    ...data.activities
                        .take(3)
                        .map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '— $a',
                              style: const TextStyle(fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _minItem(String label, String value, Color accent) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 7,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 9),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATIVE preview
// ─────────────────────────────────────────────────────────────────────────────
class _CreativePreview extends StatelessWidget {
  final CvData data;
  final Color accent;
  const _CreativePreview({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header
      Container(
        width: double.infinity,
        color: accent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        // FIX: both sides in Expanded
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.fullName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (data.occupation?.isNotEmpty == true)
                    Text(
                      data.occupation!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.email,
                    style: const TextStyle(color: Colors.white70, fontSize: 8),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                  if (data.phone?.isNotEmpty == true)
                    Text(
                      data.phone!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      Container(height: 4, color: _kPrimary),
      Padding(
        padding: const EdgeInsets.all(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left — fixed width
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.education?.isNotEmpty == true)
                      _creLeft('Education', data.education!, accent),
                    if (data.hobbies?.isNotEmpty == true)
                      _creLeft('Interests', data.hobbies!, accent),
                  ],
                ),
              ),
              VerticalDivider(
                color: Colors.grey.shade200,
                width: 18,
                thickness: 1,
              ),
              // Right — Expanded
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.bio?.isNotEmpty == true) ...[
                      _creTitle('About', accent),
                      Text(
                        data.bio!,
                        style: const TextStyle(fontSize: 9, height: 1.5),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (data.activities.isNotEmpty) ...[
                      _creTitle('Highlights', accent),
                      ...data.activities
                          .take(3)
                          .map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                      top: 3,
                                      right: 5,
                                    ),
                                    width: 4,
                                    height: 4,
                                    color: accent,
                                  ),
                                  Expanded(
                                    child: Text(
                                      a,
                                      style: const TextStyle(fontSize: 9),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _creLeft(String label, String value, Color accent) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 2, height: 10, color: accent),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 7,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 9),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  Widget _creTitle(String label, Color accent) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Container(width: 2, height: 10, color: accent),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 7,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Download Button
// ─────────────────────────────────────────────────────────────────────────────
class _DownloadBtn extends StatelessWidget {
  final VoidCallback onPressed;
  const _DownloadBtn({required this.onPressed});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: 54,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_kPrimary, Color.fromRGBO(255, 131, 90, 1)],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: _kPrimary.withOpacity(0.4),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.download_rounded, color: Colors.white),
      label: const Text(
        'Download CV as PDF',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _kPrimaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _kPrimary, size: 18),
      ),
      const SizedBox(width: 10),
      Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / Error
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: _kPrimary),
        const SizedBox(height: 16),
        Text(
          'Loading your profile…',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
