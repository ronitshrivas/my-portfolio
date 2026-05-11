// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
// import 'package:innovator/Innovator/widget/CustomizeFAB.dart';
// import 'package:innovator/elearning/model/course_list_model.dart';
// import 'package:innovator/elearning/provider/course_provider.dart';
// import 'package:innovator/elearning/provider/notificationProvider.dart';
// import 'package:video_player/video_player.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class CourseDetailScreen extends ConsumerStatefulWidget {
//   final CourseListModel course;
//   const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

//   @override
//   ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
// }

// class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   VideoPlayerController? _videoController;

//   bool _videoInitialized = false;
//   bool _videoError = false;
//   bool _isVideoLoading = false;
//   int _selectedIndex = 0;
//   bool _videoStarted = false;

//   bool _isVerifyingPayment = false;

//   static const List<String> _tabs = ['Lessons', 'Docs', 'About'];

//   @override
//   void initState() {
//     super.initState();
//     ref.refresh(elearningUnreadCountProvider);
//     ref.refresh(elearningNotificationListProvider);
//     _tabController = TabController(length: _tabs.length, vsync: this);
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await ref.refresh(enrollmentProvider.future);
//       _maybeStartVideo();
//     });
//   }

//   /// Silently refreshes enrollment; if now enrolled → auto-play video.
//   Future<void> _verifyAndUnlock() async {
//     if (!mounted) return;
//     setState(() => _isVerifyingPayment = true);

//     try {
//       await ref.refresh(enrollmentProvider.future);
//       if (!mounted) return;

//       final isNowEnrolled = ref
//           .read(enrolledCoursesProvider)
//           .contains(widget.course.id);

//       if (isNowEnrolled) {
//         setState(() => _isVerifyingPayment = false);
//         ref.read(elearningNotificationListProvider.notifier).refresh();
//         _videoStarted = true;
//         if (widget.course.contents.isNotEmpty) {
//           _initVideo(widget.course.contents.first);
//         }
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Payment verified! Start learning now. 🎉'),
//               backgroundColor: const Color(0xFF10B981),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } else {
//         setState(() => _isVerifyingPayment = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text(
//                 'Payment is being processed. Please wait a moment.',
//               ),
//               backgroundColor: Colors.orange,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       }
//     } catch (_) {
//       if (mounted) setState(() => _isVerifyingPayment = false);
//     }
//   }

//   void _maybeStartVideo() {
//     if (_videoStarted || !mounted) return;
//     final enrolled = ref
//         .read(enrolledCoursesProvider)
//         .contains(widget.course.id);
//     if (enrolled && widget.course.contents.isNotEmpty) {
//       _videoStarted = true;
//       _initVideo(widget.course.contents.first);
//     }
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _videoController?.dispose();
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     super.dispose();
//   }

//   // Video Init

//   void _initVideo(CourseContent content) {
//     final oldController = _videoController;

//     setState(() {
//       _videoController = null;
//       _videoInitialized = false;
//       _videoError = false;
//       _isVideoLoading = true;
//     });

//     oldController?.dispose();

//     final url =
//         (content.videoUrl != null && content.videoUrl!.isNotEmpty)
//             ? content.videoUrl!
//             : (content.videoFile != null && content.videoFile!.isNotEmpty)
//             ? content.videoFile!
//             : null;

//     if (url == null) {
//       setState(() {
//         _videoError = true;
//         _isVideoLoading = false;
//       });
//       return;
//     }

//     final controller = VideoPlayerController.networkUrl(Uri.parse(url));
//     controller
//         .initialize()
//         .then((_) {
//           if (!mounted) {
//             controller.dispose();
//             return;
//           }
//           setState(() {
//             _videoController = controller;
//             _videoInitialized = true;
//             _isVideoLoading = false;
//           });
//         })
//         .catchError((_) {
//           if (!mounted) {
//             controller.dispose();
//             return;
//           }
//           setState(() {
//             _videoError = true;
//             _isVideoLoading = false;
//           });
//         });
//   }

//   Future<void> _enroll() async {
//     final courseId = widget.course.id;
//     ref.read(enrollLoadingProvider(courseId).notifier).setLoading(true);

//     try {
//       if (widget.course.isFree) {
//         await ref.read(courseServiceProvider).enrollCourse(courseId);
//         await ref.refresh(enrollmentProvider.future);
//         ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
//         ref.read(elearningNotificationListProvider.notifier).refresh();

//         _videoStarted = true;
//         if (widget.course.contents.isNotEmpty) {
//           _initVideo(widget.course.contents.first);
//         }
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Enrolled! Start learning now. 🎉'),
//               backgroundColor: const Color(0xFF10B981),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } else {
//         // PAID: open Khalti WebView inside the app
//         final result = await ref
//             .read(courseServiceProvider)
//             .initiatePayment(courseId);
//         ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);

//         final paymentUrl = result['payment_url'] as String?;
//         if (paymentUrl == null) {
//           _showErrorSnack('Could not initiate payment. Please try again.');
//           return;
//         }

//         if (!mounted) return;

//         // Open payment WebView and wait for user to return
//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => KhaltiWebViewScreen(paymentUrl: paymentUrl),
//           ),
//         );

//         // Always verify enrollment when user returns (paid or cancelled)
//         if (mounted) _verifyAndUnlock();
//       }
//     } catch (e) {
//       ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
//     }
//   }

//   void _showErrorSnack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: Colors.redAccent,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final enrolledIds = ref.watch(enrolledCoursesProvider);
//     final isEnrolled = enrolledIds.contains(widget.course.id);
//     final unreadCount = ref.watch(chatUnreadCountProvider);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: Stack(
//         children: [
//           NestedScrollView(
//             headerSliverBuilder:
//                 (context, innerBoxIsScrolled) => [
//                   SliverToBoxAdapter(child: _buildVideoSection(isEnrolled)),
//                   SliverToBoxAdapter(child: _buildTitleBar()),
//                 ],
//             body: TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildLessonsTab(isEnrolled),
//                 _buildDocsTab(isEnrolled),
//                 _buildAboutTab(isEnrolled),
//               ],
//             ),
//           ),

//           // Payment verification overlay
//           if (_isVerifyingPayment)
//             Container(
//               color: Colors.black.withAlpha(160),
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 32,
//                     vertical: 28,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const SizedBox(
//                         height: 40,
//                         width: 40,
//                         child: CircularProgressIndicator(
//                           color: Color(0xFF2563EB),
//                           strokeWidth: 3,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       const Text(
//                         'Verifying payment...',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1E293B),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         'Please wait while we confirm your enrollment.',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: CountBadgeFAB(
//         count: unreadCount,
//         gifAsset: 'animation/chaticon.gif',
//         backgroundColor: Colors.transparent,
//         onPressed: () {
//           ref.read(mutualFriendsProvider.notifier).refresh();
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const ChatListScreen()),
//           ).then((_) {
//             ref.invalidate(mutualFriendsProvider);
//           });
//         },
//       ),
//     );
//   }

//   // Title Bar

//   Widget _buildTitleBar() {
//     return Container(
//       color: Colors.white,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF5F7FA),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: const Color(0xFFE2E8F0)),
//                     ),
//                     child: const Icon(
//                       Icons.arrow_back_ios_new,
//                       size: 14,
//                       color: Color(0xFF1E293B),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     widget.course.title,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1E293B),
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 _CourseBadge(isFree: widget.course.isFree),
//               ],
//             ),
//           ),
//           TabBar(
//             controller: _tabController,
//             tabs: _tabs.map((t) => Tab(text: t)).toList(),
//             labelColor: Colors.black,
//             unselectedLabelColor: const Color(0xFF94A3B8),
//             indicatorColor: const Color.fromRGBO(244, 135, 6, 1),
//             indicatorWeight: 2.5,
//             labelStyle: const TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Video Section

//   Widget _buildVideoSection(bool isEnrolled) {
//     final isLoading = ref.watch(enrollLoadingProvider(widget.course.id));

//     double aspectRatio = 16 / 9;
//     if (_videoInitialized && _videoController != null) {
//       final size = _videoController!.value.size;
//       if (size.width > 0 && size.height > 0) {
//         aspectRatio = size.width / size.height;
//       }
//     }
//     return Container(
//       color: Colors.black,
//       width: double.infinity,
//       child: SafeArea(
//         bottom: false,
//         child: AspectRatio(
//           // aspectRatio: 16 / 9,
//           aspectRatio: aspectRatio,
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               if (!isEnrolled)
//                 _LockedOverlay(course: widget.course)
//               else if (_isVideoLoading)
//                 _videoShimmer()
//               else if (_videoError)
//                 _videoErrorWidget()
//               else if (_videoInitialized && _videoController != null)
//                 _VideoPlayerWithControls(
//                   key: ValueKey(_videoController),
//                   controller: _videoController!,
//                   onFullscreen: _openFullscreen,
//                 )
//               else
//                 _videoShimmer(),

//               // Back button
//               Positioned(
//                 top: 10,
//                 left: 10,
//                 child: GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(7),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withAlpha(115),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.arrow_back,
//                       color: Colors.white,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//               ),

//               if (!isEnrolled)
//                 Positioned(
//                   bottom: 14,
//                   child: _EnrollButton(
//                     isFree: widget.course.isFree,
//                     isLoading: isLoading,
//                     onTap: _enroll,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _openFullscreen() {
//     if (!_videoInitialized || _videoController == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => _FullscreenVideoScreen(controller: _videoController!),
//       ),
//     );
//   }

//   Widget _videoShimmer() => Shimmer.fromColors(
//     baseColor: Colors.grey.shade800,
//     highlightColor: Colors.grey.shade700,
//     child: Container(color: Colors.grey.shade800),
//   );

//   Widget _videoErrorWidget() => Container(
//     color: Colors.grey.shade900,
//     child: const Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.videocam_off, color: Colors.white54, size: 36),
//           SizedBox(height: 8),
//           Text(
//             'Video unavailable',
//             style: TextStyle(color: Colors.white54, fontSize: 13),
//           ),
//         ],
//       ),
//     ),
//   );

//   // Lessons Tab

//   Widget _buildLessonsTab(bool isEnrolled) {
//     final contents = widget.course.contents;
//     if (contents.isEmpty) return _emptyTab('No lessons available');

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: contents.length,
//       itemBuilder: (_, i) {
//         final c = contents[i];
//         final active = _selectedIndex == i;
//         return GestureDetector(
//           onTap:
//               isEnrolled
//                   ? () {
//                     setState(() => _selectedIndex = i);
//                     _initVideo(c);
//                     _tabController.animateTo(0);
//                   }
//                   : null,
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             margin: const EdgeInsets.only(bottom: 10),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color:
//                     active
//                         ? const Color.fromRGBO(244, 135, 6, 1)
//                         : Colors.transparent,
//                 width: 1.5,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withAlpha(8),
//                   blurRadius: 6,
//                   offset: const Offset(0, 1),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: SizedBox(
//                     width: 62,
//                     height: 46,
//                     child:
//                         c.thumbnail != null
//                             ? Image.network(
//                               c.thumbnail!,
//                               fit: BoxFit.cover,
//                               errorBuilder:
//                                   (_, __, ___) => _thumbPlaceholder(c.order),
//                             )
//                             : _thumbPlaceholder(c.order),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         c.title,
//                         style: const TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1E293B),
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 5),
//                       Row(
//                         children: [
//                           const Icon(
//                             Icons.timer_outlined,
//                             size: 11,
//                             color: Color(0xFF94A3B8),
//                           ),
//                           const SizedBox(width: 3),
//                           Text(
//                             '${c.duration.toStringAsFixed(0)} min',
//                             style: const TextStyle(
//                               fontSize: 11,
//                               color: Color(0xFF94A3B8),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFF5F7FA),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               c.courseLevel.toUpperCase(),
//                               style: const TextStyle(
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF64748B),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 isEnrolled
//                     ? Icon(
//                       active
//                           ? Icons.pause_circle_filled
//                           : Icons.play_circle_outline,
//                       color:
//                           active
//                               ? const Color(0xFF2563EB)
//                               : const Color(0xFF94A3B8),
//                       size: 22,
//                     )
//                     : const Icon(
//                       Icons.lock_outline,
//                       size: 16,
//                       color: Color(0xFF94A3B8),
//                     ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _thumbPlaceholder(int order) => Container(
//     color: const Color(0xFFFEF3C7),
//     child: Center(
//       child: Text(
//         '$order',
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           color: Color(0xFFF59E0B),
//           fontSize: 16,
//         ),
//       ),
//     ),
//   );

//   // Docs Tab

//   Widget _buildDocsTab(bool isEnrolled) {
//     final docs =
//         widget.course.contents
//             .where(
//               (c) =>
//                   (c.documentUrl != null && c.documentUrl!.isNotEmpty) ||
//                   (c.documentFile != null && c.documentFile!.isNotEmpty),
//             )
//             .toList();
//     if (docs.isEmpty) return _emptyTab('No documents available');
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: docs.length,
//       itemBuilder: (_, i) => _DocItem(content: docs[i], isEnrolled: isEnrolled),
//     );
//   }

//   // About Tab

//   Widget _buildAboutTab(bool isEnrolled) {
//     final course = widget.course;
//     final instructor =
//         course.contents.isNotEmpty
//             ? course.contents.first.instructorName
//             : course.vendorName;
//     final isLoading = ref.watch(enrollLoadingProvider(course.id));

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _AboutCard(
//             icon: Icons.person_outline,
//             label: 'Instructor',
//             value: instructor,
//             iconColor: const Color(0xFF8B5CF6),
//           ),
//           const SizedBox(height: 10),
//           _AboutCard(
//             icon: Icons.category_outlined,
//             label: 'Category',
//             value: course.categoryName,
//             iconColor: const Color(0xFFF59E0B),
//           ),
//           const SizedBox(height: 10),
//           _AboutCard(
//             icon: Icons.library_books_outlined,
//             label: 'Total Lessons',
//             value: '${course.contents.length} lessons',
//             iconColor: const Color(0xFF10B981),
//           ),
//           if (!course.isFree && !isEnrolled) ...[
//             const SizedBox(height: 10),
//             _AboutCard(
//               icon: Icons.sell_outlined,
//               label: 'Price',
//               value: 'Rs. ${course.price.toStringAsFixed(0)}',
//               iconColor: const Color(0xFF2563EB),
//             ),
//           ],
//           const SizedBox(height: 16),
//           const Text(
//             'About this Course',
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1E293B),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             course.description,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade700,
//               height: 1.65,
//             ),
//           ),
//           const SizedBox(height: 24),
//           if (!isEnrolled)
//             _EnrollButton(
//               isFree: course.isFree,
//               isLoading: isLoading,
//               onTap: _enroll,
//               fullWidth: true,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _emptyTab(String msg) => Center(
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
//         const SizedBox(height: 8),
//         Text(
//           msg,
//           style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
//         ),
//       ],
//     ),
//   );
// }

// class KhaltiWebViewScreen extends StatefulWidget {
//   final String paymentUrl;

//   const KhaltiWebViewScreen({Key? key, required this.paymentUrl})
//     : super(key: key);

//   @override
//   State<KhaltiWebViewScreen> createState() => _KhaltiWebViewScreenState();
// }

// class _KhaltiWebViewScreenState extends State<KhaltiWebViewScreen> {
//   static const _khaltiPurple = Color(0xFF5C2D91);

//   late final WebViewController _controller;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _controller =
//         WebViewController()
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..setBackgroundColor(Colors.white)
//           ..setNavigationDelegate(
//             NavigationDelegate(
//               onPageStarted: (_) => setState(() => _isLoading = true),
//               onPageFinished: (_) => setState(() => _isLoading = false),
//               onNavigationRequest: (request) {
//                 final url = request.url;
//                 if (url.contains('payment-success') ||
//                     url.contains('payment-complete') ||
//                     url.contains('payment/success') ||
//                     url.contains('payment/failure') ||
//                     url.contains('payment/cancel') ||
//                     url.contains('khalti/callback') ||
//                     url.startsWith('innovator://')) {
//                   Navigator.pop(context);
//                   return NavigationDecision.prevent;
//                 }
//                 return NavigationDecision.navigate;
//               },
//             ),
//           )
//           ..loadRequest(Uri.parse(widget.paymentUrl));
//   }

//   Future<bool> _onWillPop() async {
//     if (await _controller.canGoBack()) {
//       _controller.goBack();
//       return false;
//     }
//     final exit = await showDialog<bool>(
//       context: context,
//       builder:
//           (_) => AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             title: const Text('Cancel Payment?'),
//             content: const Text(
//               'Are you sure you want to leave? Your payment will not be completed.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: const Text('Stay'),
//               ),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                 child: const Text(
//                   'Leave',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//     );
//     return exit ?? false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: _khaltiPurple,
//           foregroundColor: Colors.white,
//           automaticallyImplyLeading: false,
//           title: Row(
//             children: [
//               Image.asset(
//                 'assets/icon/khalti_logo.png',
//                 height: 22,
//                 errorBuilder:
//                     (_, __, ___) => const Icon(
//                       Icons.account_balance_wallet,
//                       color: Colors.white,
//                       size: 22,
//                     ),
//               ),
//               const SizedBox(width: 10),
//               const Text(
//                 'Pay with Khalti',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
//               ),
//             ],
//           ),
//           actions: [
//             if (_isLoading)
//               const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 ),
//               )
//             else
//               GestureDetector(
//                 onTap: () async {
//                   final exit = await showDialog<bool>(
//                     context: context,
//                     builder:
//                         (_) => AlertDialog(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           title: const Text('Cancel Payment?'),
//                           content: const Text(
//                             'Are you sure you want to leave? Your payment will not be completed.',
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.pop(context, false),
//                               child: const Text('Stay'),
//                             ),
//                             ElevatedButton(
//                               onPressed: () => Navigator.pop(context, true),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.red,
//                               ),
//                               child: const Text(
//                                 'Leave',
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             ),
//                           ],
//                         ),
//                   );
//                   if (exit == true && context.mounted) Navigator.pop(context);
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.only(right: 12),
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withAlpha(30),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.white.withAlpha(60)),
//                   ),
//                   child: const Icon(Icons.close, size: 16, color: Colors.white),
//                 ),
//               ),
//           ],
//           bottom: PreferredSize(
//             preferredSize: const Size.fromHeight(1),
//             child: Container(height: 1, color: Colors.white.withAlpha(40)),
//           ),
//         ),
//         body: Stack(
//           children: [
//             WebViewWidget(controller: _controller),
//             if (_isLoading)
//               Container(
//                 color: Colors.white.withAlpha(220),
//                 child: const Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       CircularProgressIndicator(color: _khaltiPurple),
//                       SizedBox(height: 14),
//                       Text(
//                         'Loading Khalti...',
//                         style: TextStyle(color: _khaltiPurple),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Video Player With Controls

// class _VideoPlayerWithControls extends StatefulWidget {
//   final VideoPlayerController controller;
//   final VoidCallback onFullscreen;

//   const _VideoPlayerWithControls({
//     Key? key,
//     required this.controller,
//     required this.onFullscreen,
//   }) : super(key: key);

//   @override
//   State<_VideoPlayerWithControls> createState() =>
//       _VideoPlayerWithControlsState();
// }

// class _VideoPlayerWithControlsState extends State<_VideoPlayerWithControls> {
//   bool _showControls = true;
//   bool _isDragging = false;

//   static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
//   double _currentSpeed = 1.0;
//   DateTime _lastTap = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     _scheduleHide();
//   }

//   void _scheduleHide() {
//     Future.delayed(const Duration(seconds: 3), () {
//       if (!mounted) return;
//       final elapsed = DateTime.now().difference(_lastTap).inSeconds;
//       if (elapsed >= 3 && !_isDragging) {
//         setState(() => _showControls = false);
//       }
//     });
//   }

//   void _toggleControls() {
//     setState(() {
//       _showControls = !_showControls;
//       _lastTap = DateTime.now();
//     });
//     if (_showControls) _scheduleHide();
//   }

//   void _skip(int seconds) {
//     final ctrl = widget.controller;
//     final duration = ctrl.value.duration;
//     if (duration == Duration.zero) return;
//     final current = ctrl.value.position;
//     final target = current + Duration(seconds: seconds);
//     final clamped =
//         target < Duration.zero
//             ? Duration.zero
//             : (target > duration ? duration : target);
//     ctrl.seekTo(clamped);
//   }

//   String _formatDuration(Duration d) {
//     final h = d.inHours;
//     final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return h > 0 ? '$h:$m:$s' : '$m:$s';
//   }

//   void _setSpeed(double speed) {
//     setState(() => _currentSpeed = speed);
//     widget.controller.setPlaybackSpeed(speed);
//   }

//   void _showSpeedPicker() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1E293B),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder:
//           (_) => Padding(
//             padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Playback Speed',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ..._speeds.map((s) {
//                   final selected = s == _currentSpeed;
//                   return GestureDetector(
//                     onTap: () {
//                       _setSpeed(s);
//                       Navigator.pop(context);
//                     },
//                     child: Container(
//                       margin: const EdgeInsets.only(bottom: 8),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       decoration: BoxDecoration(
//                         color:
//                             selected
//                                 ? const Color(0xFF2563EB)
//                                 : Colors.white.withAlpha(20),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Row(
//                         children: [
//                           Text(
//                             s == 1.0 ? 'Normal (1x)' : '${s}x',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight:
//                                   selected
//                                       ? FontWeight.bold
//                                       : FontWeight.normal,
//                             ),
//                           ),
//                           const Spacer(),
//                           if (selected)
//                             const Icon(
//                               Icons.check,
//                               color: Colors.white,
//                               size: 18,
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _toggleControls,
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           // Video
//           ValueListenableBuilder<VideoPlayerValue>(
//             valueListenable: widget.controller,
//             builder: (_, value, __) {
//               final w = value.size.width > 0 ? value.size.width : 16.0;
//               final h = value.size.height > 0 ? value.size.height : 9.0;
//               return FittedBox(
//                 fit: BoxFit.cover,
//                 child: SizedBox(
//                   width: w,
//                   height: h,
//                   child: VideoPlayer(widget.controller),
//                 ),
//               );
//             },
//           ),

//           // Controls overlay
//           AnimatedOpacity(
//             opacity: _showControls ? 1.0 : 0.0,
//             duration: const Duration(milliseconds: 250),
//             child: IgnorePointer(
//               ignoring: !_showControls,
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.black.withAlpha(160),
//                       Colors.transparent,
//                       Colors.transparent,
//                       Colors.black.withAlpha(200),
//                     ],
//                     stops: const [0.0, 0.3, 0.6, 1.0],
//                   ),
//                 ),
//                 child: ValueListenableBuilder<VideoPlayerValue>(
//                   valueListenable: widget.controller,
//                   builder: (_, value, __) {
//                     final isPlaying = value.isPlaying;
//                     final position = value.position;
//                     final duration = value.duration;
//                     final progress =
//                         duration.inMilliseconds > 0
//                             ? (position.inMilliseconds /
//                                     duration.inMilliseconds)
//                                 .clamp(0.0, 1.0)
//                             : 0.0;

//                     return Stack(
//                       children: [
//                         // Top: speed + fullscreen
//                         Positioned(
//                           top: 8,
//                           right: 8,
//                           child: GestureDetector(
//                             behavior: HitTestBehavior.opaque,
//                             onTap: () {},
//                             child: Row(
//                               children: [
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     _showSpeedPicker();
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 10,
//                                       vertical: 5,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(130),
//                                       borderRadius: BorderRadius.circular(6),
//                                       border: Border.all(
//                                         color: Colors.white.withAlpha(60),
//                                       ),
//                                     ),
//                                     child: Text(
//                                       _currentSpeed == 1.0
//                                           ? '1x'
//                                           : '${_currentSpeed}x',
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     widget.onFullscreen();
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(6),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(130),
//                                       borderRadius: BorderRadius.circular(6),
//                                       border: Border.all(
//                                         color: Colors.white.withAlpha(60),
//                                       ),
//                                     ),
//                                     child: const Icon(
//                                       Icons.fullscreen,
//                                       color: Colors.white,
//                                       size: 18,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                         // Centre: skip back | play/pause | skip forward
//                         Center(
//                           child: GestureDetector(
//                             behavior: HitTestBehavior.opaque,
//                             onTap: () {},
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     _skip(-10);
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(10),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(100),
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(
//                                       Icons.replay_10,
//                                       color: Colors.white,
//                                       size: 28,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 24),
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     isPlaying
//                                         ? widget.controller.pause()
//                                         : widget.controller.play();
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(14),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(140),
//                                       shape: BoxShape.circle,
//                                       border: Border.all(
//                                         color: Colors.white.withAlpha(80),
//                                         width: 2,
//                                       ),
//                                     ),
//                                     child: Icon(
//                                       isPlaying
//                                           ? Icons.pause_rounded
//                                           : Icons.play_arrow_rounded,
//                                       color: Colors.white,
//                                       size: 36,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 24),
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     _skip(10);
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(10),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(100),
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(
//                                       Icons.forward_10,
//                                       color: Colors.white,
//                                       size: 28,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                         // Bottom: time + seek bar
//                         Positioned(
//                           bottom: 0,
//                           left: 0,
//                           right: 0,
//                           child: GestureDetector(
//                             behavior: HitTestBehavior.opaque,
//                             onTap: () {},
//                             child: Padding(
//                               padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       Text(
//                                         _formatDuration(position),
//                                         style: const TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 11,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                       const Spacer(),
//                                       Text(
//                                         _formatDuration(duration),
//                                         style: TextStyle(
//                                           color: Colors.white.withAlpha(180),
//                                           fontSize: 11,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 4),
//                                   SliderTheme(
//                                     data: SliderTheme.of(context).copyWith(
//                                       trackHeight: 3,
//                                       thumbShape: const RoundSliderThumbShape(
//                                         enabledThumbRadius: 7,
//                                       ),
//                                       overlayShape:
//                                           const RoundSliderOverlayShape(
//                                             overlayRadius: 14,
//                                           ),
//                                       activeTrackColor: const Color(0xFF2563EB),
//                                       inactiveTrackColor: Colors.white
//                                           .withAlpha(60),
//                                       thumbColor: Colors.white,
//                                       overlayColor: Colors.white.withAlpha(40),
//                                     ),
//                                     child: Slider(
//                                       value: progress,
//                                       onChangeStart: (_) {
//                                         _isDragging = true;
//                                         _lastTap = DateTime.now();
//                                       },
//                                       onChanged: (v) {
//                                         if (duration == Duration.zero) return;
//                                         widget.controller.seekTo(
//                                           Duration(
//                                             milliseconds:
//                                                 (v * duration.inMilliseconds)
//                                                     .toInt(),
//                                           ),
//                                         );
//                                       },
//                                       onChangeEnd: (_) {
//                                         _isDragging = false;
//                                         _scheduleHide();
//                                       },
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Fullscreen Video Screen

// class _FullscreenVideoScreen extends StatefulWidget {
//   final VideoPlayerController controller;
//   const _FullscreenVideoScreen({required this.controller});

//   @override
//   State<_FullscreenVideoScreen> createState() => _FullscreenVideoScreenState();
// }

// class _FullscreenVideoScreenState extends State<_FullscreenVideoScreen> {
//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//   }

//   @override
//   void dispose() {
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: _VideoPlayerWithControls(
//           key: ValueKey(widget.controller),
//           controller: widget.controller,
//           onFullscreen: () => Navigator.pop(context),
//         ),
//       ),
//     );
//   }
// }

// // Locked Overlay

// class _LockedOverlay extends StatelessWidget {
//   final CourseListModel course;
//   const _LockedOverlay({required this.course});

//   @override
//   Widget build(BuildContext context) {
//     final thumb =
//         course.contents.isNotEmpty ? course.contents.first.thumbnail : null;
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         if (thumb != null)
//           Image.network(
//             thumb,
//             fit: BoxFit.cover,
//             errorBuilder:
//                 (_, __, ___) => Container(color: Colors.grey.shade900),
//           )
//         else
//           Container(color: Colors.grey.shade900),
//         Container(color: Colors.black.withAlpha(140)),
//         Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: Colors.white.withAlpha(38),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.lock_outline,
//                 color: Colors.white,
//                 size: 34,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               course.isFree
//                   ? 'Enroll for free to watch'
//                   : 'Pay to enroll and unlock',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// // Enroll Button

// class _EnrollButton extends StatelessWidget {
//   final bool isFree;
//   final bool isLoading;
//   final VoidCallback onTap;
//   final bool fullWidth;

//   const _EnrollButton({
//     required this.isFree,
//     required this.isLoading,
//     required this.onTap,
//     this.fullWidth = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final color = isFree ? const Color(0xFF10B981) : const Color(0xFF2563EB);
//     final label = isFree ? 'Enroll for Free' : 'Pay to Enroll';
//     final icon = isFree ? Icons.school_rounded : Icons.payment_rounded;

//     return GestureDetector(
//       onTap: isLoading ? null : onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: fullWidth ? double.infinity : null,
//         padding: EdgeInsets.symmetric(
//           horizontal: fullWidth ? 0 : 26,
//           vertical: 13,
//         ),
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(fullWidth ? 12 : 30),
//           boxShadow: [
//             BoxShadow(
//               color: color.withAlpha(90),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child:
//             isLoading
//                 ? const Center(
//                   child: SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   ),
//                 )
//                 : Row(
//                   mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(icon, color: Colors.white, size: 18),
//                     const SizedBox(width: 8),
//                     Text(
//                       label,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//       ),
//     );
//   }
// }

// // Course Badge

// class _CourseBadge extends StatelessWidget {
//   final bool isFree;
//   const _CourseBadge({required this.isFree});

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//     decoration: BoxDecoration(
//       color: const Color.fromRGBO(244, 135, 6, 1),
//       borderRadius: BorderRadius.circular(20),
//     ),
//     child: Text(
//       isFree ? 'Free' : 'Paid',
//       style: const TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w600,
//         color: Colors.white,
//       ),
//     ),
//   );
// }

// // Doc Item

// class _DocItem extends StatelessWidget {
//   final CourseContent content;
//   final bool isEnrolled;
//   const _DocItem({required this.content, required this.isEnrolled});

//   String? get _url => content.documentUrl ?? content.documentFile;

//   @override
//   Widget build(BuildContext context) => Container(
//     margin: const EdgeInsets.only(bottom: 10),
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withAlpha(8),
//           blurRadius: 6,
//           offset: const Offset(0, 1),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: const Color(0xFFFEF3C7),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: const Icon(
//             Icons.picture_as_pdf,
//             color: Color(0xFFF59E0B),
//             size: 22,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 content.title,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF1E293B),
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 3),
//               Text(
//                 'Lesson ${content.order} · Document',
//                 style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 8),
//         isEnrolled
//             ? GestureDetector(
//               onTap:
//                   _url != null
//                       ? () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (_) => _PdfViewScreen(
//                                 url: _url!,
//                                 title: content.title,
//                               ),
//                         ),
//                       )
//                       : null,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFEFF6FF),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'View',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2563EB),
//                   ),
//                 ),
//               ),
//             )
//             : const Icon(
//               Icons.lock_outline,
//               size: 16,
//               color: Color(0xFF94A3B8),
//             ),
//       ],
//     ),
//   );
// }

// // PDF Viewer

// class _PdfViewScreen extends StatelessWidget {
//   final String url;
//   final String title;
//   const _PdfViewScreen({required this.url, required this.title});

//   @override
//   Widget build(BuildContext context) => Scaffold(
//     appBar: AppBar(
//       title: Text(
//         title,
//         style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//       ),
//       backgroundColor: Colors.white,
//       foregroundColor: const Color(0xFF1E293B),
//       elevation: 0,
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(1),
//         child: Container(height: 1, color: const Color(0xFFE2E8F0)),
//       ),
//     ),
//     body: SfPdfViewer.network(url),
//   );
// }

// // About Card

// class _AboutCard extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final Color iconColor;
//   const _AboutCard({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.iconColor,
//   });

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withAlpha(8),
//           blurRadius: 6,
//           offset: const Offset(0, 1),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(9),
//           decoration: BoxDecoration(
//             color: iconColor.withAlpha(25),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: iconColor, size: 20),
//         ),
//         const SizedBox(width: 12),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
//             ),
//             const SizedBox(height: 3),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
// import 'package:innovator/Innovator/widget/CustomizeFAB.dart';
// import 'package:innovator/elearning/model/course_list_model.dart';
// import 'package:innovator/elearning/provider/course_provider.dart';
// import 'package:innovator/elearning/provider/notificationProvider.dart';
// import 'package:video_player/video_player.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class CourseDetailScreen extends ConsumerStatefulWidget {
//   final CourseListModel course;
//   const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

//   @override
//   ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
// }

// class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   VideoPlayerController? _videoController;

//   bool _videoInitialized = false;
//   bool _videoError = false;
//   bool _isVideoLoading = false;
//   int _selectedIndex = -1; // -1 = nothing selected yet
//   bool _isVerifyingPayment = false;

//   /// Tracks exactly which CourseContent is currently loaded in the player.
//   /// The lock/unlock decision is based on THIS content's isPreview flag,
//   /// not the course type. This is the single source of truth.
//   CourseContent? _currentContent;

//   static const List<String> _tabs = ['Lessons', 'Docs', 'About'];

//   @override
//   void initState() {
//     super.initState();
//     ref.refresh(elearningUnreadCountProvider);
//     ref.refresh(elearningNotificationListProvider);
//     _tabController = TabController(length: _tabs.length, vsync: this);
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await ref.refresh(enrollmentProvider.future);
//       _maybeStartPreview();
//     });
//   }

//   // ─── Auto-start on open ──────────────────────────────────────────────────

//   /// Called once after enrollment state loads.
//   ///
//   /// • Enrolled  → play the first lesson normally.
//   /// • Not enrolled → find the FIRST lesson where isPreview == true and
//   ///   load ONLY that one. Never fall back to contents[0].
//   /// • No preview lessons exist + not enrolled → leave player on locked overlay.
//   void _maybeStartPreview() {
//     if (!mounted) return;

//     final enrolled = ref
//         .read(enrolledCoursesProvider)
//         .contains(widget.course.id);

//     if (enrolled) {
//       if (widget.course.contents.isNotEmpty) {
//         setState(() => _selectedIndex = 0);
//         _initVideo(widget.course.contents.first);
//       }
//     } else {
//       // Only auto-load a lesson that explicitly has isPreview == true.
//       final previewContent =
//           widget.course.contents.where((c) => c.isPreview == true).firstOrNull;
//       if (previewContent != null) {
//         final idx = widget.course.contents.indexOf(previewContent);
//         setState(() => _selectedIndex = idx);
//         _initVideo(previewContent);
//       }
//       // If there is no preview lesson: _currentContent stays null
//       // → _buildVideoSection shows the locked overlay.
//     }
//   }

//   // ─── Payment verification ────────────────────────────────────────────────

//   Future<void> _verifyAndUnlock() async {
//     if (!mounted) return;
//     setState(() => _isVerifyingPayment = true);

//     try {
//       await ref.refresh(enrollmentProvider.future);
//       if (!mounted) return;

//       final isNowEnrolled = ref
//           .read(enrolledCoursesProvider)
//           .contains(widget.course.id);

//       if (isNowEnrolled) {
//         setState(() => _isVerifyingPayment = false);
//         ref.read(elearningNotificationListProvider.notifier).refresh();

//         // Play the exact lesson the user originally tapped (stored in
//         // _currentContent), or fall back to the first lesson.
//         final target =
//             _currentContent ??
//             (widget.course.contents.isNotEmpty
//                 ? widget.course.contents.first
//                 : null);
//         if (target != null) {
//           final idx = widget.course.contents.indexOf(target);
//           setState(() => _selectedIndex = idx < 0 ? 0 : idx);
//           _initVideo(target);
//         }

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Payment verified! Start learning now. 🎉'),
//               backgroundColor: const Color(0xFF10B981),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } else {
//         setState(() => _isVerifyingPayment = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text(
//                 'Payment is being processed. Please wait a moment.',
//               ),
//               backgroundColor: Colors.orange,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       }
//     } catch (_) {
//       if (mounted) setState(() => _isVerifyingPayment = false);
//     }
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _videoController?.dispose();
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     super.dispose();
//   }

//   // ─── Video initialisation ────────────────────────────────────────────────

//   void _initVideo(CourseContent content) {
//     // Always update _currentContent so the video section re-evaluates
//     // whether to show the player or the locked overlay.
//     _currentContent = content;

//     final oldController = _videoController;
//     setState(() {
//       _videoController = null;
//       _videoInitialized = false;
//       _videoError = false;
//       _isVideoLoading = true;
//     });
//     oldController?.dispose();

//     final url =
//         (content.videoUrl != null && content.videoUrl!.isNotEmpty)
//             ? content.videoUrl!
//             : (content.videoFile != null && content.videoFile!.isNotEmpty)
//             ? content.videoFile!
//             : null;

//     if (url == null) {
//       setState(() {
//         _videoError = true;
//         _isVideoLoading = false;
//       });
//       return;
//     }

//     final controller = VideoPlayerController.networkUrl(Uri.parse(url));
//     controller
//         .initialize()
//         .then((_) {
//           if (!mounted) {
//             controller.dispose();
//             return;
//           }
//           setState(() {
//             _videoController = controller;
//             _videoInitialized = true;
//             _isVideoLoading = false;
//           });
//         })
//         .catchError((_) {
//           if (!mounted) {
//             controller.dispose();
//             return;
//           }
//           setState(() {
//             _videoError = true;
//             _isVideoLoading = false;
//           });
//         });
//   }

//   // ─── Enroll / Pay ────────────────────────────────────────────────────────

//   Future<void> _enroll() async {
//     final courseId = widget.course.id;
//     ref.read(enrollLoadingProvider(courseId).notifier).setLoading(true);

//     try {
//       if (widget.course.isFree) {
//         await ref.read(courseServiceProvider).enrollCourse(courseId);
//         await ref.refresh(enrollmentProvider.future);
//         ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
//         ref.read(elearningNotificationListProvider.notifier).refresh();

//         // Play the lesson the user was trying to watch, or first lesson.
//         final target =
//             _currentContent ??
//             (widget.course.contents.isNotEmpty
//                 ? widget.course.contents.first
//                 : null);
//         if (target != null) {
//           final idx = widget.course.contents.indexOf(target);
//           setState(() => _selectedIndex = idx < 0 ? 0 : idx);
//           _initVideo(target);
//         }

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Enrolled! Start learning now. 🎉'),
//               backgroundColor: const Color(0xFF10B981),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } else {
//         // PAID: open Khalti WebView
//         final result = await ref
//             .read(courseServiceProvider)
//             .initiatePayment(courseId);
//         ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);

//         final paymentUrl = result['payment_url'] as String?;
//         if (paymentUrl == null) {
//           _showErrorSnack('Could not initiate payment. Please try again.');
//           return;
//         }
//         if (!mounted) return;

//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => KhaltiWebViewScreen(paymentUrl: paymentUrl),
//           ),
//         );

//         if (mounted) _verifyAndUnlock();
//       }
//     } catch (e) {
//       ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
//     }
//   }

//   void _showErrorSnack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: Colors.redAccent,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   /// Bottom sheet shown when the user taps a locked (non-preview) lesson.
//   /// Stores the tapped lesson in _currentContent so after enrollment
//   /// that exact lesson is played.
//   void _showEnrollPrompt(CourseContent tappedContent) {
//     _currentContent = tappedContent;

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (_) {
//         final isLoading = ref.watch(enrollLoadingProvider(widget.course.id));
//         return Padding(
//           padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Handle bar
//               Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFF1F5F9),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   widget.course.isFree
//                       ? Icons.school_rounded
//                       : Icons.lock_outline,
//                   size: 32,
//                   color:
//                       widget.course.isFree
//                           ? const Color(0xFF10B981)
//                           : const Color(0xFF2563EB),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 widget.course.isFree
//                     ? 'Enroll to watch this lesson'
//                     : 'Unlock this lesson',
//                 style: const TextStyle(
//                   fontSize: 17,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1E293B),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 widget.course.isFree
//                     ? 'This course is free. Enroll now to access all lessons.'
//                     : 'Pay Rs. ${widget.course.price.toStringAsFixed(0)} to get full access to all lessons.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: Colors.grey.shade600,
//                   height: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: _EnrollButton(
//                   isFree: widget.course.isFree,
//                   isLoading: isLoading,
//                   onTap: () {
//                     Navigator.pop(context); // close sheet first
//                     _enroll();
//                   },
//                   fullWidth: true,
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ─── Build ───────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final enrolledIds = ref.watch(enrolledCoursesProvider);
//     final isEnrolled = enrolledIds.contains(widget.course.id);
//     final unreadCount = ref.watch(chatUnreadCountProvider);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: Stack(
//         children: [
//           NestedScrollView(
//             headerSliverBuilder:
//                 (context, _) => [
//                   SliverToBoxAdapter(child: _buildVideoSection(isEnrolled)),
//                   SliverToBoxAdapter(child: _buildTitleBar()),
//                 ],
//             body: TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildLessonsTab(isEnrolled),
//                 _buildDocsTab(isEnrolled),
//                 _buildAboutTab(isEnrolled),
//               ],
//             ),
//           ),

//           // Payment verification overlay
//           if (_isVerifyingPayment)
//             Container(
//               color: Colors.black.withAlpha(160),
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 32,
//                     vertical: 28,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const SizedBox(
//                         height: 40,
//                         width: 40,
//                         child: CircularProgressIndicator(
//                           color: Color(0xFF2563EB),
//                           strokeWidth: 3,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       const Text(
//                         'Verifying payment...',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1E293B),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         'Please wait while we confirm your enrollment.',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: CountBadgeFAB(
//         count: unreadCount,
//         gifAsset: 'animation/chaticon.gif',
//         backgroundColor: Colors.transparent,
//         onPressed: () {
//           ref.read(mutualFriendsProvider.notifier).refresh();
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const ChatListScreen()),
//           ).then((_) => ref.invalidate(mutualFriendsProvider));
//         },
//       ),
//     );
//   }

//   // ─── Title Bar ───────────────────────────────────────────────────────────

//   Widget _buildTitleBar() {
//     return Container(
//       color: Colors.white,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF5F7FA),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: const Color(0xFFE2E8F0)),
//                     ),
//                     child: const Icon(
//                       Icons.arrow_back_ios_new,
//                       size: 14,
//                       color: Color(0xFF1E293B),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     widget.course.title,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1E293B),
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 _CourseBadge(isFree: widget.course.isFree),
//               ],
//             ),
//           ),
//           TabBar(
//             controller: _tabController,
//             tabs: _tabs.map((t) => Tab(text: t)).toList(),
//             labelColor: Colors.black,
//             unselectedLabelColor: const Color(0xFF94A3B8),
//             indicatorColor: const Color.fromRGBO(244, 135, 6, 1),
//             indicatorWeight: 2.5,
//             labelStyle: const TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─── Video Section ───────────────────────────────────────────────────────

//   Widget _buildVideoSection(bool isEnrolled) {
//     final isLoading = ref.watch(enrollLoadingProvider(widget.course.id));

//     // The ONLY way to bypass the lock is:
//     //   1. User is enrolled, OR
//     //   2. The currently loaded content has isPreview == true
//     //
//     // A paid course with a preview lesson will show the video only for
//     // that lesson. All other lessons remain locked until payment.
//     final bool currentIsPreview = _currentContent?.isPreview == true;
//     final bool showVideo = isEnrolled || currentIsPreview;

//     double aspectRatio = 16 / 9;
//     if (_videoInitialized && _videoController != null) {
//       final size = _videoController!.value.size;
//       if (size.width > 0 && size.height > 0) {
//         aspectRatio = size.width / size.height;
//       }
//     }

//     return Container(
//       color: Colors.black,
//       width: double.infinity,
//       child: SafeArea(
//         bottom: false,
//         child: AspectRatio(
//           aspectRatio: aspectRatio,
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               // ── Main player area ──────────────────────────────────────
//               if (!showVideo)
//                 _LockedOverlay(course: widget.course)
//               else if (_isVideoLoading)
//                 _videoShimmer()
//               else if (_videoError)
//                 _videoErrorWidget()
//               else if (_videoInitialized && _videoController != null)
//                 _VideoPlayerWithControls(
//                   key: ValueKey(_videoController),
//                   controller: _videoController!,
//                   onFullscreen: _openFullscreen,
//                 )
//               else
//                 _videoShimmer(),

//               // ── Back button ───────────────────────────────────────────
//               Positioned(
//                 top: 10,
//                 left: 10,
//                 child: GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(7),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withAlpha(115),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.arrow_back,
//                       color: Colors.white,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//               ),

//               // ── Enroll button — only shown on locked overlay ───────────
//               if (!showVideo)
//                 Positioned(
//                   bottom: 14,
//                   child: _EnrollButton(
//                     isFree: widget.course.isFree,
//                     isLoading: isLoading,
//                     onTap: _enroll,
//                   ),
//                 ),

//               // ── PREVIEW chip — top-right when a preview is playing ─────
//               if (showVideo && currentIsPreview && !isEnrolled)
//                 Positioned(
//                   top: 10,
//                   right: 10,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF10B981),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: const Text(
//                       'PREVIEW',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 11,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _openFullscreen() {
//     if (!_videoInitialized || _videoController == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => _FullscreenVideoScreen(controller: _videoController!),
//       ),
//     );
//   }

//   Widget _videoShimmer() => Shimmer.fromColors(
//     baseColor: Colors.grey.shade800,
//     highlightColor: Colors.grey.shade700,
//     child: Container(color: Colors.grey.shade800),
//   );

//   Widget _videoErrorWidget() => Container(
//     color: Colors.grey.shade900,
//     child: const Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.videocam_off, color: Colors.white54, size: 36),
//           SizedBox(height: 8),
//           Text(
//             'Video unavailable',
//             style: TextStyle(color: Colors.white54, fontSize: 13),
//           ),
//         ],
//       ),
//     ),
//   );

//   // ─── Lessons Tab ─────────────────────────────────────────────────────────

//   Widget _buildLessonsTab(bool isEnrolled) {
//     final contents = widget.course.contents;
//     if (contents.isEmpty) return _emptyTab('No lessons available');

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: contents.length,
//       itemBuilder: (_, i) {
//         final c = contents[i];
//         final active = _selectedIndex == i;
//         final isPreview = c.isPreview == true;

//         return GestureDetector(
//           onTap: () {
//             if (isEnrolled) {
//               // Enrolled: tap any lesson → play it
//               setState(() => _selectedIndex = i);
//               _initVideo(c);
//               _tabController.animateTo(0);
//             } else if (isPreview) {
//               // Not enrolled + isPreview == true → play freely
//               setState(() => _selectedIndex = i);
//               _initVideo(c);
//               _tabController.animateTo(0);
//             } else {
//               // Not enrolled + isPreview == false → prompt enrollment
//               // Do NOT play. Do NOT change _selectedIndex.
//               _showEnrollPrompt(c);
//             }
//           },
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             margin: const EdgeInsets.only(bottom: 10),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color:
//                     active
//                         ? const Color.fromRGBO(244, 135, 6, 1)
//                         : Colors.transparent,
//                 width: 1.5,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withAlpha(8),
//                   blurRadius: 6,
//                   offset: const Offset(0, 1),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 // Thumbnail
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: SizedBox(
//                     width: 62,
//                     height: 46,
//                     child:
//                         c.thumbnail != null
//                             ? Image.network(
//                               c.thumbnail!,
//                               fit: BoxFit.cover,
//                               errorBuilder:
//                                   (_, __, ___) => _thumbPlaceholder(c.order),
//                             )
//                             : _thumbPlaceholder(c.order),
//                   ),
//                 ),
//                 const SizedBox(width: 12),

//                 // Title + meta row
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         c.title,
//                         style: const TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1E293B),
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 5),
//                       Row(
//                         children: [
//                           const Icon(
//                             Icons.timer_outlined,
//                             size: 11,
//                             color: Color(0xFF94A3B8),
//                           ),
//                           const SizedBox(width: 3),
//                           Text(
//                             '${c.duration.toStringAsFixed(0)} min',
//                             style: const TextStyle(
//                               fontSize: 11,
//                               color: Color(0xFF94A3B8),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFF5F7FA),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               c.courseLevel.toUpperCase(),
//                               style: const TextStyle(
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF64748B),
//                               ),
//                             ),
//                           ),
//                           // Green PREVIEW badge — only on preview lessons
//                           // when the user is not enrolled
//                           if (isPreview && !isEnrolled) ...[
//                             const SizedBox(width: 6),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 6,
//                                 vertical: 2,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFDCFCE7),
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: const Text(
//                                 'PREVIEW',
//                                 style: TextStyle(
//                                   fontSize: 9,
//                                   fontWeight: FontWeight.w700,
//                                   color: Color(0xFF10B981),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),

//                 // Right-side icon:
//                 // • enrolled or isPreview → play icon
//                 // • not enrolled + not preview → lock icon
//                 if (isEnrolled || isPreview)
//                   Icon(
//                     active
//                         ? Icons.pause_circle_filled
//                         : Icons.play_circle_outline,
//                     color:
//                         active
//                             ? const Color(0xFF2563EB)
//                             : const Color(0xFF94A3B8),
//                     size: 22,
//                   )
//                 else
//                   const Icon(
//                     Icons.lock_outline,
//                     size: 16,
//                     color: Color(0xFF94A3B8),
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _thumbPlaceholder(int order) => Container(
//     color: const Color(0xFFFEF3C7),
//     child: Center(
//       child: Text(
//         '$order',
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           color: Color(0xFFF59E0B),
//           fontSize: 16,
//         ),
//       ),
//     ),
//   );

//   // ─── Docs Tab ────────────────────────────────────────────────────────────

//   Widget _buildDocsTab(bool isEnrolled) {
//     final docs =
//         widget.course.contents
//             .where(
//               (c) =>
//                   (c.documentUrl != null && c.documentUrl!.isNotEmpty) ||
//                   (c.documentFile != null && c.documentFile!.isNotEmpty),
//             )
//             .toList();
//     if (docs.isEmpty) return _emptyTab('No documents available');
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: docs.length,
//       itemBuilder: (_, i) => _DocItem(content: docs[i], isEnrolled: isEnrolled),
//     );
//   }

//   // ─── About Tab ───────────────────────────────────────────────────────────

//   Widget _buildAboutTab(bool isEnrolled) {
//     final course = widget.course;
//     final instructor =
//         course.contents.isNotEmpty
//             ? course.contents.first.instructorName
//             : course.vendorName;
//     final isLoading = ref.watch(enrollLoadingProvider(course.id));

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _AboutCard(
//             icon: Icons.person_outline,
//             label: 'Instructor',
//             value: instructor,
//             iconColor: const Color(0xFF8B5CF6),
//           ),
//           const SizedBox(height: 10),
//            if (course.categoryName != null && course.categoryName!.isNotEmpty) ...[
//           _AboutCard(
//             icon: Icons.category_outlined,
//             label: 'Category',
//             value: course.categoryName!,
//             iconColor: const Color(0xFFF59E0B),
//           ),
//            ],
//           const SizedBox(height: 10),
//           _AboutCard(
//             icon: Icons.library_books_outlined,
//             label: 'Total Lessons',
//             value: '${course.contents.length} lessons',
//             iconColor: const Color(0xFF10B981),
//           ),
//           if (!course.isFree && !isEnrolled) ...[
//             const SizedBox(height: 10),
//             _AboutCard(
//               icon: Icons.sell_outlined,
//               label: 'Price',
//               value: 'Rs. ${course.price.toStringAsFixed(0)}',
//               iconColor: const Color(0xFF2563EB),
//             ),
//           ],
//           const SizedBox(height: 16),
//           const Text(
//             'About this Course',
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1E293B),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             course.description,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade700,
//               height: 1.65,
//             ),
//           ),
//           const SizedBox(height: 24),
//           if (!isEnrolled)
//             _EnrollButton(
//               isFree: course.isFree,
//               isLoading: isLoading,
//               onTap: _enroll,
//               fullWidth: true,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _emptyTab(String msg) => Center(
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
//         const SizedBox(height: 8),
//         Text(
//           msg,
//           style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
//         ),
//       ],
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Khalti WebView
// // ═══════════════════════════════════════════════════════════════════════════

// class KhaltiWebViewScreen extends StatefulWidget {
//   final String paymentUrl;
//   const KhaltiWebViewScreen({Key? key, required this.paymentUrl})
//     : super(key: key);

//   @override
//   State<KhaltiWebViewScreen> createState() => _KhaltiWebViewScreenState();
// }

// class _KhaltiWebViewScreenState extends State<KhaltiWebViewScreen> {
//   static const _khaltiPurple = Color(0xFF5C2D91);
//   late final WebViewController _controller;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _controller =
//         WebViewController()
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..setBackgroundColor(Colors.white)
//           ..setNavigationDelegate(
//             NavigationDelegate(
//               onPageStarted: (_) => setState(() => _isLoading = true),
//               onPageFinished: (_) => setState(() => _isLoading = false),
//               onNavigationRequest: (request) {
//                 final url = request.url;
//                 if (url.contains('payment-success') ||
//                     url.contains('payment-complete') ||
//                     url.contains('payment/success') ||
//                     url.contains('payment/failure') ||
//                     url.contains('payment/cancel') ||
//                     url.contains('khalti/callback') ||
//                     url.startsWith('innovator://')) {
//                   Navigator.pop(context);
//                   return NavigationDecision.prevent;
//                 }
//                 return NavigationDecision.navigate;
//               },
//             ),
//           )
//           ..loadRequest(Uri.parse(widget.paymentUrl));
//   }

//   Future<bool> _onWillPop() async {
//     if (await _controller.canGoBack()) {
//       _controller.goBack();
//       return false;
//     }
//     final exit = await _confirmLeave();
//     return exit ?? false;
//   }

//   Future<bool?> _confirmLeave() => showDialog<bool>(
//     context: context,
//     builder:
//         (_) => AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: const Text('Cancel Payment?'),
//           content: const Text(
//             'Are you sure you want to leave? Your payment will not be completed.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('Stay'),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context, true),
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//               child: const Text('Leave', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         ),
//   );

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: _khaltiPurple,
//           foregroundColor: Colors.white,
//           automaticallyImplyLeading: false,
//           title: Row(
//             children: [
//               Image.asset(
//                 'assets/icon/khalti_logo.png',
//                 height: 22,
//                 errorBuilder:
//                     (_, __, ___) => const Icon(
//                       Icons.account_balance_wallet,
//                       color: Colors.white,
//                       size: 22,
//                     ),
//               ),
//               const SizedBox(width: 10),
//               const Text(
//                 'Pay with Khalti',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
//               ),
//             ],
//           ),
//           actions: [
//             if (_isLoading)
//               const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 ),
//               )
//             else
//               GestureDetector(
//                 onTap: () async {
//                   final exit = await _confirmLeave();
//                   if (exit == true && context.mounted) Navigator.pop(context);
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.only(right: 12),
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withAlpha(30),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.white.withAlpha(60)),
//                   ),
//                   child: const Icon(Icons.close, size: 16, color: Colors.white),
//                 ),
//               ),
//           ],
//           bottom: PreferredSize(
//             preferredSize: const Size.fromHeight(1),
//             child: Container(height: 1, color: Colors.white.withAlpha(40)),
//           ),
//         ),
//         body: Stack(
//           children: [
//             WebViewWidget(controller: _controller),
//             if (_isLoading)
//               Container(
//                 color: Colors.white.withAlpha(220),
//                 child: const Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       CircularProgressIndicator(color: _khaltiPurple),
//                       SizedBox(height: 14),
//                       Text(
//                         'Loading Khalti...',
//                         style: TextStyle(color: _khaltiPurple),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Video Player With Controls
// // ═══════════════════════════════════════════════════════════════════════════

// class _VideoPlayerWithControls extends StatefulWidget {
//   final VideoPlayerController controller;
//   final VoidCallback onFullscreen;

//   const _VideoPlayerWithControls({
//     Key? key,
//     required this.controller,
//     required this.onFullscreen,
//   }) : super(key: key);

//   @override
//   State<_VideoPlayerWithControls> createState() =>
//       _VideoPlayerWithControlsState();
// }

// class _VideoPlayerWithControlsState extends State<_VideoPlayerWithControls> {
//   bool _showControls = true;
//   bool _isDragging = false;
//   static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
//   double _currentSpeed = 1.0;
//   DateTime _lastTap = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     _scheduleHide();
//   }

//   void _scheduleHide() {
//     Future.delayed(const Duration(seconds: 3), () {
//       if (!mounted) return;
//       final elapsed = DateTime.now().difference(_lastTap).inSeconds;
//       if (elapsed >= 3 && !_isDragging) {
//         setState(() => _showControls = false);
//       }
//     });
//   }

//   void _toggleControls() {
//     setState(() {
//       _showControls = !_showControls;
//       _lastTap = DateTime.now();
//     });
//     if (_showControls) _scheduleHide();
//   }

//   void _skip(int seconds) {
//     final ctrl = widget.controller;
//     final duration = ctrl.value.duration;
//     if (duration == Duration.zero) return;
//     final current = ctrl.value.position;
//     final target = current + Duration(seconds: seconds);
//     final clamped =
//         target < Duration.zero
//             ? Duration.zero
//             : (target > duration ? duration : target);
//     ctrl.seekTo(clamped);
//   }

//   String _formatDuration(Duration d) {
//     final h = d.inHours;
//     final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return h > 0 ? '$h:$m:$s' : '$m:$s';
//   }

//   void _setSpeed(double speed) {
//     setState(() => _currentSpeed = speed);
//     widget.controller.setPlaybackSpeed(speed);
//   }

//   void _showSpeedPicker() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1E293B),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder:
//           (_) => Padding(
//             padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Playback Speed',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ..._speeds.map((s) {
//                   final selected = s == _currentSpeed;
//                   return GestureDetector(
//                     onTap: () {
//                       _setSpeed(s);
//                       Navigator.pop(context);
//                     },
//                     child: Container(
//                       margin: const EdgeInsets.only(bottom: 8),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       decoration: BoxDecoration(
//                         color:
//                             selected
//                                 ? const Color(0xFF2563EB)
//                                 : Colors.white.withAlpha(20),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Row(
//                         children: [
//                           Text(
//                             s == 1.0 ? 'Normal (1x)' : '${s}x',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight:
//                                   selected
//                                       ? FontWeight.bold
//                                       : FontWeight.normal,
//                             ),
//                           ),
//                           const Spacer(),
//                           if (selected)
//                             const Icon(
//                               Icons.check,
//                               color: Colors.white,
//                               size: 18,
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _toggleControls,
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           // Video frame
//           ValueListenableBuilder<VideoPlayerValue>(
//             valueListenable: widget.controller,
//             builder: (_, value, __) {
//               final w = value.size.width > 0 ? value.size.width : 16.0;
//               final h = value.size.height > 0 ? value.size.height : 9.0;
//               return FittedBox(
//                 fit: BoxFit.cover,
//                 child: SizedBox(
//                   width: w,
//                   height: h,
//                   child: VideoPlayer(widget.controller),
//                 ),
//               );
//             },
//           ),

//           // Controls overlay
//           AnimatedOpacity(
//             opacity: _showControls ? 1.0 : 0.0,
//             duration: const Duration(milliseconds: 250),
//             child: IgnorePointer(
//               ignoring: !_showControls,
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.black.withAlpha(160),
//                       Colors.transparent,
//                       Colors.transparent,
//                       Colors.black.withAlpha(200),
//                     ],
//                     stops: const [0.0, 0.3, 0.6, 1.0],
//                   ),
//                 ),
//                 child: ValueListenableBuilder<VideoPlayerValue>(
//                   valueListenable: widget.controller,
//                   builder: (_, value, __) {
//                     final isPlaying = value.isPlaying;
//                     final position = value.position;
//                     final duration = value.duration;
//                     final progress =
//                         duration.inMilliseconds > 0
//                             ? (position.inMilliseconds /
//                                     duration.inMilliseconds)
//                                 .clamp(0.0, 1.0)
//                             : 0.0;

//                     return Stack(
//                       children: [
//                         // Top: speed + fullscreen
//                         Positioned(
//                           top: 8,
//                           right: 8,
//                           child: Row(
//                             children: [
//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () {
//                                   _lastTap = DateTime.now();
//                                   _showSpeedPicker();
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 10,
//                                     vertical: 5,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withAlpha(130),
//                                     borderRadius: BorderRadius.circular(6),
//                                     border: Border.all(
//                                       color: Colors.white.withAlpha(60),
//                                     ),
//                                   ),
//                                   child: Text(
//                                     _currentSpeed == 1.0
//                                         ? '1x'
//                                         : '${_currentSpeed}x',
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () {
//                                   _lastTap = DateTime.now();
//                                   widget.onFullscreen();
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(6),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withAlpha(130),
//                                     borderRadius: BorderRadius.circular(6),
//                                     border: Border.all(
//                                       color: Colors.white.withAlpha(60),
//                                     ),
//                                   ),
//                                   child: const Icon(
//                                     Icons.fullscreen,
//                                     color: Colors.white,
//                                     size: 18,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         // Centre: skip back | play/pause | skip forward
//                         Center(
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () {
//                                   _lastTap = DateTime.now();
//                                   _skip(-10);
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(10),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withAlpha(100),
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: const Icon(
//                                     Icons.replay_10,
//                                     color: Colors.white,
//                                     size: 28,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 24),
//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () {
//                                   _lastTap = DateTime.now();
//                                   isPlaying
//                                       ? widget.controller.pause()
//                                       : widget.controller.play();
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(14),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withAlpha(140),
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Colors.white.withAlpha(80),
//                                       width: 2,
//                                     ),
//                                   ),
//                                   child: Icon(
//                                     isPlaying
//                                         ? Icons.pause_rounded
//                                         : Icons.play_arrow_rounded,
//                                     color: Colors.white,
//                                     size: 36,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 24),
//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () {
//                                   _lastTap = DateTime.now();
//                                   _skip(10);
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(10),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withAlpha(100),
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: const Icon(
//                                     Icons.forward_10,
//                                     color: Colors.white,
//                                     size: 28,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         // Bottom: time + seek bar
//                         Positioned(
//                           bottom: 0,
//                           left: 0,
//                           right: 0,
//                           child: Padding(
//                             padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Text(
//                                       _formatDuration(position),
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 11,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                     const Spacer(),
//                                     Text(
//                                       _formatDuration(duration),
//                                       style: TextStyle(
//                                         color: Colors.white.withAlpha(180),
//                                         fontSize: 11,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 4),
//                                 SliderTheme(
//                                   data: SliderTheme.of(context).copyWith(
//                                     trackHeight: 3,
//                                     thumbShape: const RoundSliderThumbShape(
//                                       enabledThumbRadius: 7,
//                                     ),
//                                     overlayShape: const RoundSliderOverlayShape(
//                                       overlayRadius: 14,
//                                     ),
//                                     activeTrackColor: const Color(0xFF2563EB),
//                                     inactiveTrackColor: Colors.white.withAlpha(
//                                       60,
//                                     ),
//                                     thumbColor: Colors.white,
//                                     overlayColor: Colors.white.withAlpha(40),
//                                   ),
//                                   child: Slider(
//                                     value: progress,
//                                     onChangeStart: (_) {
//                                       _isDragging = true;
//                                       _lastTap = DateTime.now();
//                                     },
//                                     onChanged: (v) {
//                                       if (duration == Duration.zero) return;
//                                       widget.controller.seekTo(
//                                         Duration(
//                                           milliseconds:
//                                               (v * duration.inMilliseconds)
//                                                   .toInt(),
//                                         ),
//                                       );
//                                     },
//                                     onChangeEnd: (_) {
//                                       _isDragging = false;
//                                       _scheduleHide();
//                                     },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Fullscreen Video Screen
// // ═══════════════════════════════════════════════════════════════════════════

// class _FullscreenVideoScreen extends StatefulWidget {
//   final VideoPlayerController controller;
//   const _FullscreenVideoScreen({required this.controller});

//   @override
//   State<_FullscreenVideoScreen> createState() => _FullscreenVideoScreenState();
// }

// class _FullscreenVideoScreenState extends State<_FullscreenVideoScreen> {
//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//   }

//   @override
//   void dispose() {
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) => Scaffold(
//     backgroundColor: Colors.black,
//     body: SafeArea(
//       child: _VideoPlayerWithControls(
//         key: ValueKey(widget.controller),
//         controller: widget.controller,
//         onFullscreen: () => Navigator.pop(context),
//       ),
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Locked Overlay
// // ═══════════════════════════════════════════════════════════════════════════

// class _LockedOverlay extends StatelessWidget {
//   final CourseListModel course;
//   const _LockedOverlay({required this.course});

//   @override
//   Widget build(BuildContext context) {
//     final thumb =
//         course.contents.isNotEmpty ? course.contents.first.thumbnail : null;
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         if (thumb != null)
//           Image.network(
//             thumb,
//             fit: BoxFit.cover,
//             errorBuilder:
//                 (_, __, ___) => Container(color: Colors.grey.shade900),
//           )
//         else
//           Container(color: Colors.grey.shade900),
//         Container(color: Colors.black.withAlpha(140)),
//         Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: Colors.white.withAlpha(38),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.lock_outline,
//                 color: Colors.white,
//                 size: 34,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               course.isFree
//                   ? 'Enroll for free to watch'
//                   : 'Pay to enroll and unlock',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Enroll Button
// // ═══════════════════════════════════════════════════════════════════════════

// class _EnrollButton extends StatelessWidget {
//   final bool isFree;
//   final bool isLoading;
//   final VoidCallback onTap;
//   final bool fullWidth;

//   const _EnrollButton({
//     required this.isFree,
//     required this.isLoading,
//     required this.onTap,
//     this.fullWidth = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final color = isFree ? const Color(0xFF10B981) : const Color(0xFF2563EB);
//     final label = isFree ? 'Enroll for Free' : 'Pay to Enroll';
//     final icon = isFree ? Icons.school_rounded : Icons.payment_rounded;

//     return GestureDetector(
//       onTap: isLoading ? null : onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: fullWidth ? double.infinity : null,
//         padding: EdgeInsets.symmetric(
//           horizontal: fullWidth ? 0 : 26,
//           vertical: 13,
//         ),
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(fullWidth ? 12 : 30),
//           boxShadow: [
//             BoxShadow(
//               color: color.withAlpha(90),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child:
//             isLoading
//                 ? const Center(
//                   child: SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   ),
//                 )
//                 : Row(
//                   mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(icon, color: Colors.white, size: 18),
//                     const SizedBox(width: 8),
//                     Text(
//                       label,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Course Badge
// // ═══════════════════════════════════════════════════════════════════════════

// class _CourseBadge extends StatelessWidget {
//   final bool isFree;
//   const _CourseBadge({required this.isFree});

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//     decoration: BoxDecoration(
//       color: const Color.fromRGBO(244, 135, 6, 1),
//       borderRadius: BorderRadius.circular(20),
//     ),
//     child: Text(
//       isFree ? 'Free' : 'Paid',
//       style: const TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w600,
//         color: Colors.white,
//       ),
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Doc Item
// // ═══════════════════════════════════════════════════════════════════════════

// class _DocItem extends StatelessWidget {
//   final CourseContent content;
//   final bool isEnrolled;
//   const _DocItem({required this.content, required this.isEnrolled});

//   String? get _url => content.documentUrl ?? content.documentFile;

//   @override
//   Widget build(BuildContext context) => Container(
//     margin: const EdgeInsets.only(bottom: 10),
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withAlpha(8),
//           blurRadius: 6,
//           offset: const Offset(0, 1),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: const Color(0xFFFEF3C7),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: const Icon(
//             Icons.picture_as_pdf,
//             color: Color(0xFFF59E0B),
//             size: 22,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 content.title,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF1E293B),
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 3),
//               Text(
//                 'Lesson ${content.order} · Document',
//                 style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 8),
//         isEnrolled
//             ? GestureDetector(
//               onTap:
//                   _url != null
//                       ? () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (_) => _PdfViewScreen(
//                                 url: _url!,
//                                 title: content.title,
//                               ),
//                         ),
//                       )
//                       : null,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFEFF6FF),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'View',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2563EB),
//                   ),
//                 ),
//               ),
//             )
//             : const Icon(
//               Icons.lock_outline,
//               size: 16,
//               color: Color(0xFF94A3B8),
//             ),
//       ],
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // PDF Viewer Screen
// // ═══════════════════════════════════════════════════════════════════════════

// class _PdfViewScreen extends StatelessWidget {
//   final String url;
//   final String title;
//   const _PdfViewScreen({required this.url, required this.title});

//   @override
//   Widget build(BuildContext context) => Scaffold(
//     appBar: AppBar(
//       title: Text(
//         title,
//         style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//       ),
//       backgroundColor: Colors.white,
//       foregroundColor: const Color(0xFF1E293B),
//       elevation: 0,
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(1),
//         child: Container(height: 1, color: const Color(0xFFE2E8F0)),
//       ),
//     ),
//     body: SfPdfViewer.network(url),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // About Card
// // ═══════════════════════════════════════════════════════════════════════════

// class _AboutCard extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final Color iconColor;

//   const _AboutCard({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.iconColor,
//   });

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withAlpha(8),
//           blurRadius: 6,
//           offset: const Offset(0, 1),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(9),
//           decoration: BoxDecoration(
//             color: iconColor.withAlpha(25),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: iconColor, size: 20),
//         ),
//         const SizedBox(width: 12),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
//             ),
//             const SizedBox(height: 3),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
// import 'package:innovator/Innovator/widget/CustomizeFAB.dart';
// import 'package:innovator/elearning/model/course_list_model.dart';
// import 'package:innovator/elearning/provider/course_provider.dart';
// import 'package:innovator/elearning/provider/notificationProvider.dart';
// import 'package:video_player/video_player.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class CourseDetailScreen extends ConsumerStatefulWidget {
//   final CourseListModel course;
//   const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

//   @override
//   ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
// }

// class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   VideoPlayerController? _videoController;

//   bool _videoInitialized = false;
//   bool _videoError = false;
//   bool _isVideoLoading = false;
//   int _selectedIndex = 0;
//   bool _videoStarted = false;

//   bool _isVerifyingPayment = false;

//   static const List<String> _tabs = ['Lessons', 'Docs', 'About'];

//   @override
//   void initState() {
//     super.initState();
//     ref.refresh(elearningUnreadCountProvider);
//     ref.refresh(elearningNotificationListProvider);
//     _tabController = TabController(length: _tabs.length, vsync: this);
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await ref.refresh(enrollmentProvider.future);
//       _maybeStartVideo();
//     });
//   }

//   /// Silently refreshes enrollment; if now enrolled → auto-play video.
//   Future<void> _verifyAndUnlock() async {
//     if (!mounted) return;
//     setState(() => _isVerifyingPayment = true);

//     try {
//       await ref.refresh(enrollmentProvider.future);
//       if (!mounted) return;

//       final isNowEnrolled = ref
//           .read(enrolledCoursesProvider)
//           .contains(widget.course.id);

//       if (isNowEnrolled) {
//         setState(() => _isVerifyingPayment = false);
//         ref.read(elearningNotificationListProvider.notifier).refresh();
//         _videoStarted = true;
//         if (widget.course.contents.isNotEmpty) {
//           _initVideo(widget.course.contents.first);
//         }
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Payment verified! Start learning now. 🎉'),
//               backgroundColor: const Color(0xFF10B981),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } else {
//         setState(() => _isVerifyingPayment = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text(
//                 'Payment is being processed. Please wait a moment.',
//               ),
//               backgroundColor: Colors.orange,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       }
//     } catch (_) {
//       if (mounted) setState(() => _isVerifyingPayment = false);
//     }
//   }

//   void _maybeStartVideo() {
//     if (_videoStarted || !mounted) return;
//     final enrolled = ref
//         .read(enrolledCoursesProvider)
//         .contains(widget.course.id);
//     if (enrolled && widget.course.contents.isNotEmpty) {
//       _videoStarted = true;
//       _initVideo(widget.course.contents.first);
//     }
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _videoController?.dispose();
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     super.dispose();
//   }

//   // Video Init

//   void _initVideo(CourseContent content) {
//     final oldController = _videoController;

//     setState(() {
//       _videoController = null;
//       _videoInitialized = false;
//       _videoError = false;
//       _isVideoLoading = true;
//     });

//     oldController?.dispose();

//     final url =
//         (content.videoUrl != null && content.videoUrl!.isNotEmpty)
//             ? content.videoUrl!
//             : (content.videoFile != null && content.videoFile!.isNotEmpty)
//             ? content.videoFile!
//             : null;

//     if (url == null) {
//       setState(() {
//         _videoError = true;
//         _isVideoLoading = false;
//       });
//       return;
//     }

//     final controller = VideoPlayerController.networkUrl(Uri.parse(url));
//     controller
//         .initialize()
//         .then((_) {
//           if (!mounted) {
//             controller.dispose();
//             return;
//           }
//           setState(() {
//             _videoController = controller;
//             _videoInitialized = true;
//             _isVideoLoading = false;
//           });
//         })
//         .catchError((_) {
//           if (!mounted) {
//             controller.dispose();
//             return;
//           }
//           setState(() {
//             _videoError = true;
//             _isVideoLoading = false;
//           });
//         });
//   }

//   Future<void> _enroll() async {
//     final courseId = widget.course.id;
//     ref.read(enrollLoadingProvider(courseId).notifier).setLoading(true);

//     try {
//       if (widget.course.isFree) {
//         await ref.read(courseServiceProvider).enrollCourse(courseId);
//         await ref.refresh(enrollmentProvider.future);
//         ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
//         ref.read(elearningNotificationListProvider.notifier).refresh();

//         _videoStarted = true;
//         if (widget.course.contents.isNotEmpty) {
//           _initVideo(widget.course.contents.first);
//         }
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Enrolled! Start learning now. 🎉'),
//               backgroundColor: const Color(0xFF10B981),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } else {
//         // PAID: open Khalti WebView inside the app
//         final result = await ref
//             .read(courseServiceProvider)
//             .initiatePayment(courseId);
//         ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);

//         final paymentUrl = result['payment_url'] as String?;
//         if (paymentUrl == null) {
//           _showErrorSnack('Could not initiate payment. Please try again.');
//           return;
//         }

//         if (!mounted) return;

//         // Open payment WebView and wait for user to return
//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => KhaltiWebViewScreen(paymentUrl: paymentUrl),
//           ),
//         );

//         // Always verify enrollment when user returns (paid or cancelled)
//         if (mounted) _verifyAndUnlock();
//       }
//     } catch (e) {
//       ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
//     }
//   }

//   void _showErrorSnack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: Colors.redAccent,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final enrolledIds = ref.watch(enrolledCoursesProvider);
//     final isEnrolled = enrolledIds.contains(widget.course.id);
//     final unreadCount = ref.watch(chatUnreadCountProvider);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: Stack(
//         children: [
//           NestedScrollView(
//             headerSliverBuilder:
//                 (context, innerBoxIsScrolled) => [
//                   SliverToBoxAdapter(child: _buildVideoSection(isEnrolled)),
//                   SliverToBoxAdapter(child: _buildTitleBar()),
//                 ],
//             body: TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildLessonsTab(isEnrolled),
//                 _buildDocsTab(isEnrolled),
//                 _buildAboutTab(isEnrolled),
//               ],
//             ),
//           ),

//           // Payment verification overlay
//           if (_isVerifyingPayment)
//             Container(
//               color: Colors.black.withAlpha(160),
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 32,
//                     vertical: 28,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const SizedBox(
//                         height: 40,
//                         width: 40,
//                         child: CircularProgressIndicator(
//                           color: Color(0xFF2563EB),
//                           strokeWidth: 3,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       const Text(
//                         'Verifying payment...',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1E293B),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         'Please wait while we confirm your enrollment.',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: CountBadgeFAB(
//         count: unreadCount,
//         gifAsset: 'animation/chaticon.gif',
//         backgroundColor: Colors.transparent,
//         onPressed: () {
//           ref.read(mutualFriendsProvider.notifier).refresh();
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const ChatListScreen()),
//           ).then((_) {
//             ref.invalidate(mutualFriendsProvider);
//           });
//         },
//       ),
//     );
//   }

//   // Title Bar

//   Widget _buildTitleBar() {
//     return Container(
//       color: Colors.white,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF5F7FA),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: const Color(0xFFE2E8F0)),
//                     ),
//                     child: const Icon(
//                       Icons.arrow_back_ios_new,
//                       size: 14,
//                       color: Color(0xFF1E293B),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     widget.course.title,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1E293B),
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 _CourseBadge(isFree: widget.course.isFree),
//               ],
//             ),
//           ),
//           TabBar(
//             controller: _tabController,
//             tabs: _tabs.map((t) => Tab(text: t)).toList(),
//             labelColor: Colors.black,
//             unselectedLabelColor: const Color(0xFF94A3B8),
//             indicatorColor: const Color.fromRGBO(244, 135, 6, 1),
//             indicatorWeight: 2.5,
//             labelStyle: const TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Video Section

//   Widget _buildVideoSection(bool isEnrolled) {
//     final isLoading = ref.watch(enrollLoadingProvider(widget.course.id));

//     double aspectRatio = 16 / 9;
//     if (_videoInitialized && _videoController != null) {
//       final size = _videoController!.value.size;
//       if (size.width > 0 && size.height > 0) {
//         aspectRatio = size.width / size.height;
//       }
//     }
//     return Container(
//       color: Colors.black,
//       width: double.infinity,
//       child: SafeArea(
//         bottom: false,
//         child: AspectRatio(
//           // aspectRatio: 16 / 9,
//           aspectRatio: aspectRatio,
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               if (!isEnrolled)
//                 _LockedOverlay(course: widget.course)
//               else if (_isVideoLoading)
//                 _videoShimmer()
//               else if (_videoError)
//                 _videoErrorWidget()
//               else if (_videoInitialized && _videoController != null)
//                 _VideoPlayerWithControls(
//                   key: ValueKey(_videoController),
//                   controller: _videoController!,
//                   onFullscreen: _openFullscreen,
//                 )
//               else
//                 _videoShimmer(),

//               // Back button
//               Positioned(
//                 top: 10,
//                 left: 10,
//                 child: GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(7),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withAlpha(115),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.arrow_back,
//                       color: Colors.white,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//               ),

//               if (!isEnrolled)
//                 Positioned(
//                   bottom: 14,
//                   child: _EnrollButton(
//                     isFree: widget.course.isFree,
//                     isLoading: isLoading,
//                     onTap: _enroll,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _openFullscreen() {
//     if (!_videoInitialized || _videoController == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => _FullscreenVideoScreen(controller: _videoController!),
//       ),
//     );
//   }

//   Widget _videoShimmer() => Shimmer.fromColors(
//     baseColor: Colors.grey.shade800,
//     highlightColor: Colors.grey.shade700,
//     child: Container(color: Colors.grey.shade800),
//   );

//   Widget _videoErrorWidget() => Container(
//     color: Colors.grey.shade900,
//     child: const Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.videocam_off, color: Colors.white54, size: 36),
//           SizedBox(height: 8),
//           Text(
//             'Video unavailable',
//             style: TextStyle(color: Colors.white54, fontSize: 13),
//           ),
//         ],
//       ),
//     ),
//   );

//   // Lessons Tab

//   Widget _buildLessonsTab(bool isEnrolled) {
//     final contents = widget.course.contents;
//     if (contents.isEmpty) return _emptyTab('No lessons available');

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: contents.length,
//       itemBuilder: (_, i) {
//         final c = contents[i];
//         final active = _selectedIndex == i;
//         return GestureDetector(
//           onTap:
//               isEnrolled
//                   ? () {
//                     setState(() => _selectedIndex = i);
//                     _initVideo(c);
//                     _tabController.animateTo(0);
//                   }
//                   : null,
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             margin: const EdgeInsets.only(bottom: 10),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color:
//                     active
//                         ? const Color.fromRGBO(244, 135, 6, 1)
//                         : Colors.transparent,
//                 width: 1.5,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withAlpha(8),
//                   blurRadius: 6,
//                   offset: const Offset(0, 1),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: SizedBox(
//                     width: 62,
//                     height: 46,
//                     child:
//                         c.thumbnail != null
//                             ? Image.network(
//                               c.thumbnail!,
//                               fit: BoxFit.cover,
//                               errorBuilder:
//                                   (_, __, ___) => _thumbPlaceholder(c.order),
//                             )
//                             : _thumbPlaceholder(c.order),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         c.title,
//                         style: const TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1E293B),
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 5),
//                       Row(
//                         children: [
//                           const Icon(
//                             Icons.timer_outlined,
//                             size: 11,
//                             color: Color(0xFF94A3B8),
//                           ),
//                           const SizedBox(width: 3),
//                           Text(
//                             '${c.duration.toStringAsFixed(0)} min',
//                             style: const TextStyle(
//                               fontSize: 11,
//                               color: Color(0xFF94A3B8),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFF5F7FA),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               c.courseLevel.toUpperCase(),
//                               style: const TextStyle(
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF64748B),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 isEnrolled
//                     ? Icon(
//                       active
//                           ? Icons.pause_circle_filled
//                           : Icons.play_circle_outline,
//                       color:
//                           active
//                               ? const Color(0xFF2563EB)
//                               : const Color(0xFF94A3B8),
//                       size: 22,
//                     )
//                     : const Icon(
//                       Icons.lock_outline,
//                       size: 16,
//                       color: Color(0xFF94A3B8),
//                     ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _thumbPlaceholder(int order) => Container(
//     color: const Color(0xFFFEF3C7),
//     child: Center(
//       child: Text(
//         '$order',
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           color: Color(0xFFF59E0B),
//           fontSize: 16,
//         ),
//       ),
//     ),
//   );

//   // Docs Tab

//   Widget _buildDocsTab(bool isEnrolled) {
//     final docs =
//         widget.course.contents
//             .where(
//               (c) =>
//                   (c.documentUrl != null && c.documentUrl!.isNotEmpty) ||
//                   (c.documentFile != null && c.documentFile!.isNotEmpty),
//             )
//             .toList();
//     if (docs.isEmpty) return _emptyTab('No documents available');
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: docs.length,
//       itemBuilder: (_, i) => _DocItem(content: docs[i], isEnrolled: isEnrolled),
//     );
//   }

//   // About Tab

//   Widget _buildAboutTab(bool isEnrolled) {
//     final course = widget.course;
//     final instructor =
//         course.contents.isNotEmpty
//             ? course.contents.first.instructorName
//             : course.vendorName;
//     final isLoading = ref.watch(enrollLoadingProvider(course.id));

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _AboutCard(
//             icon: Icons.person_outline,
//             label: 'Instructor',
//             value: instructor,
//             iconColor: const Color(0xFF8B5CF6),
//           ),
//           const SizedBox(height: 10),
//           _AboutCard(
//             icon: Icons.category_outlined,
//             label: 'Category',
//             value: course.categoryName,
//             iconColor: const Color(0xFFF59E0B),
//           ),
//           const SizedBox(height: 10),
//           _AboutCard(
//             icon: Icons.library_books_outlined,
//             label: 'Total Lessons',
//             value: '${course.contents.length} lessons',
//             iconColor: const Color(0xFF10B981),
//           ),
//           if (!course.isFree && !isEnrolled) ...[
//             const SizedBox(height: 10),
//             _AboutCard(
//               icon: Icons.sell_outlined,
//               label: 'Price',
//               value: 'Rs. ${course.price.toStringAsFixed(0)}',
//               iconColor: const Color(0xFF2563EB),
//             ),
//           ],
//           const SizedBox(height: 16),
//           const Text(
//             'About this Course',
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1E293B),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             course.description,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade700,
//               height: 1.65,
//             ),
//           ),
//           const SizedBox(height: 24),
//           if (!isEnrolled)
//             _EnrollButton(
//               isFree: course.isFree,
//               isLoading: isLoading,
//               onTap: _enroll,
//               fullWidth: true,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _emptyTab(String msg) => Center(
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
//         const SizedBox(height: 8),
//         Text(
//           msg,
//           style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
//         ),
//       ],
//     ),
//   );
// }

// class KhaltiWebViewScreen extends StatefulWidget {
//   final String paymentUrl;

//   const KhaltiWebViewScreen({Key? key, required this.paymentUrl})
//     : super(key: key);

//   @override
//   State<KhaltiWebViewScreen> createState() => _KhaltiWebViewScreenState();
// }

// class _KhaltiWebViewScreenState extends State<KhaltiWebViewScreen> {
//   static const _khaltiPurple = Color(0xFF5C2D91);

//   late final WebViewController _controller;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _controller =
//         WebViewController()
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..setBackgroundColor(Colors.white)
//           ..setNavigationDelegate(
//             NavigationDelegate(
//               onPageStarted: (_) => setState(() => _isLoading = true),
//               onPageFinished: (_) => setState(() => _isLoading = false),
//               onNavigationRequest: (request) {
//                 final url = request.url;
//                 if (url.contains('payment-success') ||
//                     url.contains('payment-complete') ||
//                     url.contains('payment/success') ||
//                     url.contains('payment/failure') ||
//                     url.contains('payment/cancel') ||
//                     url.contains('khalti/callback') ||
//                     url.startsWith('innovator://')) {
//                   Navigator.pop(context);
//                   return NavigationDecision.prevent;
//                 }
//                 return NavigationDecision.navigate;
//               },
//             ),
//           )
//           ..loadRequest(Uri.parse(widget.paymentUrl));
//   }

//   Future<bool> _onWillPop() async {
//     if (await _controller.canGoBack()) {
//       _controller.goBack();
//       return false;
//     }
//     final exit = await showDialog<bool>(
//       context: context,
//       builder:
//           (_) => AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             title: const Text('Cancel Payment?'),
//             content: const Text(
//               'Are you sure you want to leave? Your payment will not be completed.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: const Text('Stay'),
//               ),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                 child: const Text(
//                   'Leave',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//     );
//     return exit ?? false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: _khaltiPurple,
//           foregroundColor: Colors.white,
//           automaticallyImplyLeading: false,
//           title: Row(
//             children: [
//               Image.asset(
//                 'assets/icon/khalti_logo.png',
//                 height: 22,
//                 errorBuilder:
//                     (_, __, ___) => const Icon(
//                       Icons.account_balance_wallet,
//                       color: Colors.white,
//                       size: 22,
//                     ),
//               ),
//               const SizedBox(width: 10),
//               const Text(
//                 'Pay with Khalti',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
//               ),
//             ],
//           ),
//           actions: [
//             if (_isLoading)
//               const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 ),
//               )
//             else
//               GestureDetector(
//                 onTap: () async {
//                   final exit = await showDialog<bool>(
//                     context: context,
//                     builder:
//                         (_) => AlertDialog(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           title: const Text('Cancel Payment?'),
//                           content: const Text(
//                             'Are you sure you want to leave? Your payment will not be completed.',
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.pop(context, false),
//                               child: const Text('Stay'),
//                             ),
//                             ElevatedButton(
//                               onPressed: () => Navigator.pop(context, true),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.red,
//                               ),
//                               child: const Text(
//                                 'Leave',
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             ),
//                           ],
//                         ),
//                   );
//                   if (exit == true && context.mounted) Navigator.pop(context);
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.only(right: 12),
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withAlpha(30),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.white.withAlpha(60)),
//                   ),
//                   child: const Icon(Icons.close, size: 16, color: Colors.white),
//                 ),
//               ),
//           ],
//           bottom: PreferredSize(
//             preferredSize: const Size.fromHeight(1),
//             child: Container(height: 1, color: Colors.white.withAlpha(40)),
//           ),
//         ),
//         body: Stack(
//           children: [
//             WebViewWidget(controller: _controller),
//             if (_isLoading)
//               Container(
//                 color: Colors.white.withAlpha(220),
//                 child: const Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       CircularProgressIndicator(color: _khaltiPurple),
//                       SizedBox(height: 14),
//                       Text(
//                         'Loading Khalti...',
//                         style: TextStyle(color: _khaltiPurple),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Video Player With Controls

// class _VideoPlayerWithControls extends StatefulWidget {
//   final VideoPlayerController controller;
//   final VoidCallback onFullscreen;

//   const _VideoPlayerWithControls({
//     Key? key,
//     required this.controller,
//     required this.onFullscreen,
//   }) : super(key: key);

//   @override
//   State<_VideoPlayerWithControls> createState() =>
//       _VideoPlayerWithControlsState();
// }

// class _VideoPlayerWithControlsState extends State<_VideoPlayerWithControls> {
//   bool _showControls = true;
//   bool _isDragging = false;

//   static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
//   double _currentSpeed = 1.0;
//   DateTime _lastTap = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     _scheduleHide();
//   }

//   void _scheduleHide() {
//     Future.delayed(const Duration(seconds: 3), () {
//       if (!mounted) return;
//       final elapsed = DateTime.now().difference(_lastTap).inSeconds;
//       if (elapsed >= 3 && !_isDragging) {
//         setState(() => _showControls = false);
//       }
//     });
//   }

//   void _toggleControls() {
//     setState(() {
//       _showControls = !_showControls;
//       _lastTap = DateTime.now();
//     });
//     if (_showControls) _scheduleHide();
//   }

//   void _skip(int seconds) {
//     final ctrl = widget.controller;
//     final duration = ctrl.value.duration;
//     if (duration == Duration.zero) return;
//     final current = ctrl.value.position;
//     final target = current + Duration(seconds: seconds);
//     final clamped =
//         target < Duration.zero
//             ? Duration.zero
//             : (target > duration ? duration : target);
//     ctrl.seekTo(clamped);
//   }

//   String _formatDuration(Duration d) {
//     final h = d.inHours;
//     final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return h > 0 ? '$h:$m:$s' : '$m:$s';
//   }

//   void _setSpeed(double speed) {
//     setState(() => _currentSpeed = speed);
//     widget.controller.setPlaybackSpeed(speed);
//   }

//   void _showSpeedPicker() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1E293B),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder:
//           (_) => Padding(
//             padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Playback Speed',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ..._speeds.map((s) {
//                   final selected = s == _currentSpeed;
//                   return GestureDetector(
//                     onTap: () {
//                       _setSpeed(s);
//                       Navigator.pop(context);
//                     },
//                     child: Container(
//                       margin: const EdgeInsets.only(bottom: 8),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       decoration: BoxDecoration(
//                         color:
//                             selected
//                                 ? const Color(0xFF2563EB)
//                                 : Colors.white.withAlpha(20),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Row(
//                         children: [
//                           Text(
//                             s == 1.0 ? 'Normal (1x)' : '${s}x',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight:
//                                   selected
//                                       ? FontWeight.bold
//                                       : FontWeight.normal,
//                             ),
//                           ),
//                           const Spacer(),
//                           if (selected)
//                             const Icon(
//                               Icons.check,
//                               color: Colors.white,
//                               size: 18,
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _toggleControls,
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           // Video
//           ValueListenableBuilder<VideoPlayerValue>(
//             valueListenable: widget.controller,
//             builder: (_, value, __) {
//               final w = value.size.width > 0 ? value.size.width : 16.0;
//               final h = value.size.height > 0 ? value.size.height : 9.0;
//               return FittedBox(
//                 fit: BoxFit.cover,
//                 child: SizedBox(
//                   width: w,
//                   height: h,
//                   child: VideoPlayer(widget.controller),
//                 ),
//               );
//             },
//           ),

//           // Controls overlay
//           AnimatedOpacity(
//             opacity: _showControls ? 1.0 : 0.0,
//             duration: const Duration(milliseconds: 250),
//             child: IgnorePointer(
//               ignoring: !_showControls,
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.black.withAlpha(160),
//                       Colors.transparent,
//                       Colors.transparent,
//                       Colors.black.withAlpha(200),
//                     ],
//                     stops: const [0.0, 0.3, 0.6, 1.0],
//                   ),
//                 ),
//                 child: ValueListenableBuilder<VideoPlayerValue>(
//                   valueListenable: widget.controller,
//                   builder: (_, value, __) {
//                     final isPlaying = value.isPlaying;
//                     final position = value.position;
//                     final duration = value.duration;
//                     final progress =
//                         duration.inMilliseconds > 0
//                             ? (position.inMilliseconds /
//                                     duration.inMilliseconds)
//                                 .clamp(0.0, 1.0)
//                             : 0.0;

//                     return Stack(
//                       children: [
//                         // Top: speed + fullscreen
//                         Positioned(
//                           top: 8,
//                           right: 8,
//                           child: GestureDetector(
//                             behavior: HitTestBehavior.opaque,
//                             onTap: () {},
//                             child: Row(
//                               children: [
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     _showSpeedPicker();
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 10,
//                                       vertical: 5,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(130),
//                                       borderRadius: BorderRadius.circular(6),
//                                       border: Border.all(
//                                         color: Colors.white.withAlpha(60),
//                                       ),
//                                     ),
//                                     child: Text(
//                                       _currentSpeed == 1.0
//                                           ? '1x'
//                                           : '${_currentSpeed}x',
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     widget.onFullscreen();
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(6),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(130),
//                                       borderRadius: BorderRadius.circular(6),
//                                       border: Border.all(
//                                         color: Colors.white.withAlpha(60),
//                                       ),
//                                     ),
//                                     child: const Icon(
//                                       Icons.fullscreen,
//                                       color: Colors.white,
//                                       size: 18,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                         // Centre: skip back | play/pause | skip forward
//                         Center(
//                           child: GestureDetector(
//                             behavior: HitTestBehavior.opaque,
//                             onTap: () {},
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     _skip(-10);
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(10),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(100),
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(
//                                       Icons.replay_10,
//                                       color: Colors.white,
//                                       size: 28,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 24),
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     isPlaying
//                                         ? widget.controller.pause()
//                                         : widget.controller.play();
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(14),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(140),
//                                       shape: BoxShape.circle,
//                                       border: Border.all(
//                                         color: Colors.white.withAlpha(80),
//                                         width: 2,
//                                       ),
//                                     ),
//                                     child: Icon(
//                                       isPlaying
//                                           ? Icons.pause_rounded
//                                           : Icons.play_arrow_rounded,
//                                       color: Colors.white,
//                                       size: 36,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 24),
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     _skip(10);
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(10),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(100),
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(
//                                       Icons.forward_10,
//                                       color: Colors.white,
//                                       size: 28,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                         // Bottom: time + seek bar
//                         Positioned(
//                           bottom: 0,
//                           left: 0,
//                           right: 0,
//                           child: GestureDetector(
//                             behavior: HitTestBehavior.opaque,
//                             onTap: () {},
//                             child: Padding(
//                               padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       Text(
//                                         _formatDuration(position),
//                                         style: const TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 11,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                       const Spacer(),
//                                       Text(
//                                         _formatDuration(duration),
//                                         style: TextStyle(
//                                           color: Colors.white.withAlpha(180),
//                                           fontSize: 11,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 4),
//                                   SliderTheme(
//                                     data: SliderTheme.of(context).copyWith(
//                                       trackHeight: 3,
//                                       thumbShape: const RoundSliderThumbShape(
//                                         enabledThumbRadius: 7,
//                                       ),
//                                       overlayShape:
//                                           const RoundSliderOverlayShape(
//                                             overlayRadius: 14,
//                                           ),
//                                       activeTrackColor: const Color(0xFF2563EB),
//                                       inactiveTrackColor: Colors.white
//                                           .withAlpha(60),
//                                       thumbColor: Colors.white,
//                                       overlayColor: Colors.white.withAlpha(40),
//                                     ),
//                                     child: Slider(
//                                       value: progress,
//                                       onChangeStart: (_) {
//                                         _isDragging = true;
//                                         _lastTap = DateTime.now();
//                                       },
//                                       onChanged: (v) {
//                                         if (duration == Duration.zero) return;
//                                         widget.controller.seekTo(
//                                           Duration(
//                                             milliseconds:
//                                                 (v * duration.inMilliseconds)
//                                                     .toInt(),
//                                           ),
//                                         );
//                                       },
//                                       onChangeEnd: (_) {
//                                         _isDragging = false;
//                                         _scheduleHide();
//                                       },
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Fullscreen Video Screen

// class _FullscreenVideoScreen extends StatefulWidget {
//   final VideoPlayerController controller;
//   const _FullscreenVideoScreen({required this.controller});

//   @override
//   State<_FullscreenVideoScreen> createState() => _FullscreenVideoScreenState();
// }

// class _FullscreenVideoScreenState extends State<_FullscreenVideoScreen> {
//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//   }

//   @override
//   void dispose() {
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: _VideoPlayerWithControls(
//           key: ValueKey(widget.controller),
//           controller: widget.controller,
//           onFullscreen: () => Navigator.pop(context),
//         ),
//       ),
//     );
//   }
// }

// // Locked Overlay

// class _LockedOverlay extends StatelessWidget {
//   final CourseListModel course;
//   const _LockedOverlay({required this.course});

//   @override
//   Widget build(BuildContext context) {
//     final thumb =
//         course.contents.isNotEmpty ? course.contents.first.thumbnail : null;
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         if (thumb != null)
//           Image.network(
//             thumb,
//             fit: BoxFit.cover,
//             errorBuilder:
//                 (_, __, ___) => Container(color: Colors.grey.shade900),
//           )
//         else
//           Container(color: Colors.grey.shade900),
//         Container(color: Colors.black.withAlpha(140)),
//         Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: Colors.white.withAlpha(38),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.lock_outline,
//                 color: Colors.white,
//                 size: 34,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               course.isFree
//                   ? 'Enroll for free to watch'
//                   : 'Pay to enroll and unlock',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// // Enroll Button

// class _EnrollButton extends StatelessWidget {
//   final bool isFree;
//   final bool isLoading;
//   final VoidCallback onTap;
//   final bool fullWidth;

//   const _EnrollButton({
//     required this.isFree,
//     required this.isLoading,
//     required this.onTap,
//     this.fullWidth = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final color = isFree ? const Color(0xFF10B981) : const Color(0xFF2563EB);
//     final label = isFree ? 'Enroll for Free' : 'Pay to Enroll';
//     final icon = isFree ? Icons.school_rounded : Icons.payment_rounded;

//     return GestureDetector(
//       onTap: isLoading ? null : onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: fullWidth ? double.infinity : null,
//         padding: EdgeInsets.symmetric(
//           horizontal: fullWidth ? 0 : 26,
//           vertical: 13,
//         ),
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(fullWidth ? 12 : 30),
//           boxShadow: [
//             BoxShadow(
//               color: color.withAlpha(90),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child:
//             isLoading
//                 ? const Center(
//                   child: SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   ),
//                 )
//                 : Row(
//                   mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(icon, color: Colors.white, size: 18),
//                     const SizedBox(width: 8),
//                     Text(
//                       label,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//       ),
//     );
//   }
// }

// // Course Badge

// class _CourseBadge extends StatelessWidget {
//   final bool isFree;
//   const _CourseBadge({required this.isFree});

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//     decoration: BoxDecoration(
//       color: const Color.fromRGBO(244, 135, 6, 1),
//       borderRadius: BorderRadius.circular(20),
//     ),
//     child: Text(
//       isFree ? 'Free' : 'Paid',
//       style: const TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w600,
//         color: Colors.white,
//       ),
//     ),
//   );
// }

// // Doc Item

// class _DocItem extends StatelessWidget {
//   final CourseContent content;
//   final bool isEnrolled;
//   const _DocItem({required this.content, required this.isEnrolled});

//   String? get _url => content.documentUrl ?? content.documentFile;

//   @override
//   Widget build(BuildContext context) => Container(
//     margin: const EdgeInsets.only(bottom: 10),
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withAlpha(8),
//           blurRadius: 6,
//           offset: const Offset(0, 1),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: const Color(0xFFFEF3C7),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: const Icon(
//             Icons.picture_as_pdf,
//             color: Color(0xFFF59E0B),
//             size: 22,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 content.title,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF1E293B),
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 3),
//               Text(
//                 'Lesson ${content.order} · Document',
//                 style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 8),
//         isEnrolled
//             ? GestureDetector(
//               onTap:
//                   _url != null
//                       ? () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (_) => _PdfViewScreen(
//                                 url: _url!,
//                                 title: content.title,
//                               ),
//                         ),
//                       )
//                       : null,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFEFF6FF),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'View',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2563EB),
//                   ),
//                 ),
//               ),
//             )
//             : const Icon(
//               Icons.lock_outline,
//               size: 16,
//               color: Color(0xFF94A3B8),
//             ),
//       ],
//     ),
//   );
// }

// // PDF Viewer

// class _PdfViewScreen extends StatelessWidget {
//   final String url;
//   final String title;
//   const _PdfViewScreen({required this.url, required this.title});

//   @override
//   Widget build(BuildContext context) => Scaffold(
//     appBar: AppBar(
//       title: Text(
//         title,
//         style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//       ),
//       backgroundColor: Colors.white,
//       foregroundColor: const Color(0xFF1E293B),
//       elevation: 0,
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(1),
//         child: Container(height: 1, color: const Color(0xFFE2E8F0)),
//       ),
//     ),
//     body: SfPdfViewer.network(url),
//   );
// }

// // About Card

// class _AboutCard extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final Color iconColor;
//   const _AboutCard({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.iconColor,
//   });

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withAlpha(8),
//           blurRadius: 6,
//           offset: const Offset(0, 1),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(9),
//           decoration: BoxDecoration(
//             color: iconColor.withAlpha(25),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: iconColor, size: 20),
//         ),
//         const SizedBox(width: 12),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
//             ),
//             const SizedBox(height: 3),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
// import 'package:innovator/Innovator/widget/CustomizeFAB.dart';
// import 'package:innovator/elearning/model/course_list_model.dart';
// import 'package:innovator/elearning/provider/course_provider.dart';
// import 'package:innovator/elearning/provider/notificationProvider.dart';
// import 'package:video_player/video_player.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class CourseDetailScreen extends ConsumerStatefulWidget {
//   final CourseListModel course;
//   const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

//   @override
//   ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
// }

// class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   VideoPlayerController? _videoController;

//   bool _videoInitialized = false;
//   bool _videoError = false;
//   bool _isVideoLoading = false;
//   int _selectedIndex = -1; // -1 = nothing selected yet
//   bool _isVerifyingPayment = false;

//   // WebView-based playback (for iframe embed URLs like Bunny CDN)
//   bool _isWebViewVideo = false;
//   String? _webViewUrl;
//   WebViewController? _webViewController;

//   /// Tracks exactly which CourseContent is currently loaded in the player.
//   /// The lock/unlock decision is based on THIS content's isPreview flag,
//   /// not the course type. This is the single source of truth.
//   CourseContent? _currentContent;

//   static const List<String> _tabs = ['Lessons', 'Docs', 'About'];

//   @override
//   void initState() {
//     super.initState();
//     ref.refresh(elearningUnreadCountProvider);
//     ref.refresh(elearningNotificationListProvider);
//     _tabController = TabController(length: _tabs.length, vsync: this);
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await ref.refresh(enrollmentProvider.future);
//       _maybeStartPreview();
//     });
//   }

//   // ─── Auto-start on open ──────────────────────────────────────────────────

//   /// Called once after enrollment state loads.
//   ///
//   /// • Enrolled  → play the first lesson normally.
//   /// • Not enrolled → find the FIRST lesson where isPreview == true and
//   ///   load ONLY that one. Never fall back to contents[0].
//   /// • No preview lessons exist + not enrolled → leave player on locked overlay.
//   void _maybeStartPreview() {
//     if (!mounted) return;

//     final enrolled = ref
//         .read(enrolledCoursesProvider)
//         .contains(widget.course.id);

//     if (enrolled) {
//       if (widget.course.contents.isNotEmpty) {
//         setState(() => _selectedIndex = 0);
//         _initVideo(widget.course.contents.first);
//       }
//     } else {
//       // Only auto-load a lesson that explicitly has isPreview == true.
//       final previewContent =
//           widget.course.contents.where((c) => c.isPreview == true).firstOrNull;
//       if (previewContent != null) {
//         final idx = widget.course.contents.indexOf(previewContent);
//         setState(() => _selectedIndex = idx);
//         _initVideo(previewContent);
//       }
//       // If there is no preview lesson: _currentContent stays null
//       // → _buildVideoSection shows the locked overlay.
//     }
//   }

//   // ─── Payment verification ────────────────────────────────────────────────

//   Future<void> _verifyAndUnlock() async {
//     if (!mounted) return;
//     setState(() => _isVerifyingPayment = true);

//     try {
//       await ref.refresh(enrollmentProvider.future);
//       if (!mounted) return;

//       final isNowEnrolled = ref
//           .read(enrolledCoursesProvider)
//           .contains(widget.course.id);

//       if (isNowEnrolled) {
//         setState(() => _isVerifyingPayment = false);
//         ref.read(elearningNotificationListProvider.notifier).refresh();

//         // Play the exact lesson the user originally tapped (stored in
//         // _currentContent), or fall back to the first lesson.
//         final target =
//             _currentContent ??
//             (widget.course.contents.isNotEmpty
//                 ? widget.course.contents.first
//                 : null);
//         if (target != null) {
//           final idx = widget.course.contents.indexOf(target);
//           setState(() => _selectedIndex = idx < 0 ? 0 : idx);
//           _initVideo(target);
//         }

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Payment verified! Start learning now. 🎉'),
//               backgroundColor: const Color(0xFF10B981),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } else {
//         setState(() => _isVerifyingPayment = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text(
//                 'Payment is being processed. Please wait a moment.',
//               ),
//               backgroundColor: Colors.orange,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       }
//     } catch (_) {
//       if (mounted) setState(() => _isVerifyingPayment = false);
//     }
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _videoController?.dispose();
//     _webViewController = null;
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     super.dispose();
//   }

//   // ─── Video initialisation ────────────────────────────────────────────────

//   void _initVideo(CourseContent content) {
//     // Always update _currentContent so the video section re-evaluates
//     // whether to show the player or the locked overlay.
//     _currentContent = content;

//     final oldController = _videoController;
//     setState(() {
//       _videoController = null;
//       _videoInitialized = false;
//       _videoError = false;
//       _isVideoLoading = true;
//       _isWebViewVideo = false;
//       _webViewUrl = null;
//       _webViewController = null;
//     });
//     oldController?.dispose();

//     final url = content.effectiveVideoUrl;

//     if (url == null) {
//       setState(() {
//         _videoError = true;
//         _isVideoLoading = false;
//       });
//       return;
//     }

//     // ── Embed / iframe URL → render in WebView ──────────────────────────
//     if (content.isEmbedUrl) {
//       final wvc =
//           WebViewController()
//             ..setJavaScriptMode(JavaScriptMode.unrestricted)
//             ..setBackgroundColor(Colors.black)
//             ..setNavigationDelegate(
//               NavigationDelegate(
//                 onPageFinished: (_) {
//                   if (!mounted) return;
//                   setState(() => _isVideoLoading = false);
//                 },
//                 onWebResourceError: (_) {
//                   if (!mounted) return;
//                   setState(() {
//                     _videoError = true;
//                     _isVideoLoading = false;
//                   });
//                 },
//               ),
//             )
//             ..loadRequest(Uri.parse(url));

//       setState(() {
//         _isWebViewVideo = true;
//         _webViewUrl = url;
//         _webViewController = wvc;
//       });
//       return;
//     }

//     // ── Direct file URL (.mp4 etc.) → VideoPlayerController ────────────
//     final controller = VideoPlayerController.networkUrl(Uri.parse(url));
//     controller
//         .initialize()
//         .then((_) {
//           if (!mounted) {
//             controller.dispose();
//             return;
//           }
//           setState(() {
//             _videoController = controller;
//             _videoInitialized = true;
//             _isVideoLoading = false;
//           });
//         })
//         .catchError((_) {
//           if (!mounted) {
//             controller.dispose();
//             return;
//           }
//           setState(() {
//             _videoError = true;
//             _isVideoLoading = false;
//           });
//         });
//   }

//   // ─── Enroll / Pay ────────────────────────────────────────────────────────

//   Future<void> _enroll() async {
//     final courseId = widget.course.id;
//     ref.read(enrollLoadingProvider(courseId).notifier).setLoading(true);

//     try {
//       if (widget.course.isFree) {
//         await ref.read(courseServiceProvider).enrollCourse(courseId);
//         await ref.refresh(enrollmentProvider.future);
//         ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
//         ref.read(elearningNotificationListProvider.notifier).refresh();

//         // Play the lesson the user was trying to watch, or first lesson.
//         final target =
//             _currentContent ??
//             (widget.course.contents.isNotEmpty
//                 ? widget.course.contents.first
//                 : null);
//         if (target != null) {
//           final idx = widget.course.contents.indexOf(target);
//           setState(() => _selectedIndex = idx < 0 ? 0 : idx);
//           _initVideo(target);
//         }

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Enrolled! Start learning now. 🎉'),
//               backgroundColor: const Color(0xFF10B981),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } else {
//         // PAID: open Khalti WebView
//         final result = await ref
//             .read(courseServiceProvider)
//             .initiatePayment(courseId);
//         ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);

//         final paymentUrl = result['payment_url'] as String?;
//         if (paymentUrl == null) {
//           _showErrorSnack('Could not initiate payment. Please try again.');
//           return;
//         }
//         if (!mounted) return;

//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => KhaltiWebViewScreen(paymentUrl: paymentUrl),
//           ),
//         );

//         if (mounted) _verifyAndUnlock();
//       }
//     } catch (e) {
//       ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
//     }
//   }

//   void _showErrorSnack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: Colors.redAccent,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   /// Bottom sheet shown when the user taps a locked (non-preview) lesson.
//   /// Stores the tapped lesson in _currentContent so after enrollment
//   /// that exact lesson is played.
//   void _showEnrollPrompt(CourseContent tappedContent) {
//     _currentContent = tappedContent;

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (_) {
//         final isLoading = ref.watch(enrollLoadingProvider(widget.course.id));
//         return Padding(
//           padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Handle bar
//               Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFF1F5F9),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   widget.course.isFree
//                       ? Icons.school_rounded
//                       : Icons.lock_outline,
//                   size: 32,
//                   color:
//                       widget.course.isFree
//                           ? const Color(0xFF10B981)
//                           : const Color(0xFF2563EB),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 widget.course.isFree
//                     ? 'Enroll to watch this lesson'
//                     : 'Unlock this lesson',
//                 style: const TextStyle(
//                   fontSize: 17,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1E293B),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 widget.course.isFree
//                     ? 'This course is free. Enroll now to access all lessons.'
//                     : 'Pay Rs. ${widget.course.price.toStringAsFixed(0)} to get full access to all lessons.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: Colors.grey.shade600,
//                   height: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: _EnrollButton(
//                   isFree: widget.course.isFree,
//                   isLoading: isLoading,
//                   onTap: () {
//                     Navigator.pop(context); // close sheet first
//                     _enroll();
//                   },
//                   fullWidth: true,
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ─── Build ───────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final enrolledIds = ref.watch(enrolledCoursesProvider);
//     final isEnrolled = enrolledIds.contains(widget.course.id);
//     final unreadCount = ref.watch(chatUnreadCountProvider);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: Stack(
//         children: [
//           NestedScrollView(
//             headerSliverBuilder:
//                 (context, _) => [
//                   SliverToBoxAdapter(child: _buildVideoSection(isEnrolled)),
//                   SliverToBoxAdapter(child: _buildTitleBar()),
//                 ],
//             body: TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildLessonsTab(isEnrolled),
//                 _buildDocsTab(isEnrolled),
//                 _buildAboutTab(isEnrolled),
//               ],
//             ),
//           ),

//           // Payment verification overlay
//           if (_isVerifyingPayment)
//             Container(
//               color: Colors.black.withAlpha(160),
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 32,
//                     vertical: 28,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const SizedBox(
//                         height: 40,
//                         width: 40,
//                         child: CircularProgressIndicator(
//                           color: Color(0xFF2563EB),
//                           strokeWidth: 3,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       const Text(
//                         'Verifying payment...',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1E293B),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         'Please wait while we confirm your enrollment.',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: CountBadgeFAB(
//         count: unreadCount,
//         gifAsset: 'animation/chaticon.gif',
//         backgroundColor: Colors.transparent,
//         onPressed: () {
//           ref.read(mutualFriendsProvider.notifier).refresh();
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const ChatListScreen()),
//           ).then((_) => ref.invalidate(mutualFriendsProvider));
//         },
//       ),
//     );
//   }

//   // ─── Title Bar ───────────────────────────────────────────────────────────

//   Widget _buildTitleBar() {
//     return Container(
//       color: Colors.white,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF5F7FA),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: const Color(0xFFE2E8F0)),
//                     ),
//                     child: const Icon(
//                       Icons.arrow_back_ios_new,
//                       size: 14,
//                       color: Color(0xFF1E293B),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     widget.course.title,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1E293B),
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 _CourseBadge(isFree: widget.course.isFree),
//               ],
//             ),
//           ),
//           TabBar(
//             controller: _tabController,
//             tabs: _tabs.map((t) => Tab(text: t)).toList(),
//             labelColor: Colors.black,
//             unselectedLabelColor: const Color(0xFF94A3B8),
//             indicatorColor: const Color.fromRGBO(244, 135, 6, 1),
//             indicatorWeight: 2.5,
//             labelStyle: const TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─── Video Section ───────────────────────────────────────────────────────

//   Widget _buildVideoSection(bool isEnrolled) {
//     final isLoading = ref.watch(enrollLoadingProvider(widget.course.id));

//     final bool currentIsPreview = _currentContent?.isPreview == true;
//     final bool showVideo = isEnrolled || currentIsPreview;

//     // WebView videos always use 16:9; VideoPlayer uses actual aspect ratio.
//     double aspectRatio = 16 / 9;
//     if (!_isWebViewVideo && _videoInitialized && _videoController != null) {
//       final size = _videoController!.value.size;
//       if (size.width > 0 && size.height > 0) {
//         aspectRatio = size.width / size.height;
//       }
//     }

//     return Container(
//       color: Colors.black,
//       width: double.infinity,
//       child: SafeArea(
//         bottom: false,
//         child: AspectRatio(
//           aspectRatio: aspectRatio,
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               // ── Main player area ──────────────────────────────────────
//               if (!showVideo)
//                 _LockedOverlay(course: widget.course)
//               else if (_isVideoLoading)
//                 _videoShimmer()
//               else if (_videoError)
//                 _videoErrorWidget()
//               else if (_isWebViewVideo && _webViewController != null)
//                 // ── Embed URL → WebView ─────────────────────────────────
//                 WebViewWidget(controller: _webViewController!)
//               else if (_videoInitialized && _videoController != null)
//                 // ── Direct file → custom VideoPlayer ───────────────────
//                 _VideoPlayerWithControls(
//                   key: ValueKey(_videoController),
//                   controller: _videoController!,
//                   onFullscreen: _openFullscreen,
//                 )
//               else
//                 _videoShimmer(),

//               // ── Back button ───────────────────────────────────────────
//               Positioned(
//                 top: 10,
//                 left: 10,
//                 child: GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(7),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withAlpha(115),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.arrow_back,
//                       color: Colors.white,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//               ),

//               // ── Enroll button — only shown on locked overlay ───────────
//               if (!showVideo)
//                 Positioned(
//                   bottom: 14,
//                   child: _EnrollButton(
//                     isFree: widget.course.isFree,
//                     isLoading: isLoading,
//                     onTap: _enroll,
//                   ),
//                 ),

//               // ── PREVIEW chip — top-right when a preview is playing ─────
//               if (showVideo && currentIsPreview && !isEnrolled)
//                 Positioned(
//                   top: 10,
//                   right: 10,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF10B981),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: const Text(
//                       'PREVIEW',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 11,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _openFullscreen() {
//     // Fullscreen is only available for direct VideoPlayer videos.
//     // WebView-based embed players handle fullscreen natively inside the WebView.
//     if (_isWebViewVideo) return;
//     if (!_videoInitialized || _videoController == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => _FullscreenVideoScreen(controller: _videoController!),
//       ),
//     );
//   }

//   Widget _videoShimmer() => Shimmer.fromColors(
//     baseColor: Colors.grey.shade800,
//     highlightColor: Colors.grey.shade700,
//     child: Container(color: Colors.grey.shade800),
//   );

//   Widget _videoErrorWidget() => Container(
//     color: Colors.grey.shade900,
//     child: const Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.videocam_off, color: Colors.white54, size: 36),
//           SizedBox(height: 8),
//           Text(
//             'Video unavailable',
//             style: TextStyle(color: Colors.white54, fontSize: 13),
//           ),
//         ],
//       ),
//     ),
//   );

//   // ─── Lessons Tab ─────────────────────────────────────────────────────────

//   Widget _buildLessonsTab(bool isEnrolled) {
//     final contents = widget.course.contents;
//     if (contents.isEmpty) return _emptyTab('No lessons available');

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: contents.length,
//       itemBuilder: (_, i) {
//         final c = contents[i];
//         final active = _selectedIndex == i;
//         final isPreview = c.isPreview == true;

//         return GestureDetector(
//           onTap: () {
//             if (isEnrolled) {
//               // Enrolled: tap any lesson → play it
//               setState(() => _selectedIndex = i);
//               _initVideo(c);
//               _tabController.animateTo(0);
//             } else if (isPreview) {
//               // Not enrolled + isPreview == true → play freely
//               setState(() => _selectedIndex = i);
//               _initVideo(c);
//               _tabController.animateTo(0);
//             } else {
//               // Not enrolled + isPreview == false → prompt enrollment
//               // Do NOT play. Do NOT change _selectedIndex.
//               _showEnrollPrompt(c);
//             }
//           },
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             margin: const EdgeInsets.only(bottom: 10),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color:
//                     active
//                         ? const Color.fromRGBO(244, 135, 6, 1)
//                         : Colors.transparent,
//                 width: 1.5,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withAlpha(8),
//                   blurRadius: 6,
//                   offset: const Offset(0, 1),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 // Thumbnail
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: SizedBox(
//                     width: 62,
//                     height: 46,
//                     child:
//                         c.thumbnail != null
//                             ? Image.network(
//                               c.thumbnail!,
//                               fit: BoxFit.cover,
//                               errorBuilder:
//                                   (_, __, ___) => _thumbPlaceholder(c.order),
//                             )
//                             : _thumbPlaceholder(c.order),
//                   ),
//                 ),
//                 const SizedBox(width: 12),

//                 // Title + meta row
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         c.title,
//                         style: const TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1E293B),
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 5),
//                       Row(
//                         children: [
//                           const Icon(
//                             Icons.timer_outlined,
//                             size: 11,
//                             color: Color(0xFF94A3B8),
//                           ),
//                           const SizedBox(width: 3),
//                           Text(
//                             '${c.duration.toStringAsFixed(0)} min',
//                             style: const TextStyle(
//                               fontSize: 11,
//                               color: Color(0xFF94A3B8),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFF5F7FA),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               c.courseLevel.toUpperCase(),
//                               style: const TextStyle(
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF64748B),
//                               ),
//                             ),
//                           ),
//                           // Green PREVIEW badge — only on preview lessons
//                           // when the user is not enrolled
//                           if (isPreview && !isEnrolled) ...[
//                             const SizedBox(width: 6),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 6,
//                                 vertical: 2,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFDCFCE7),
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: const Text(
//                                 'PREVIEW',
//                                 style: TextStyle(
//                                   fontSize: 9,
//                                   fontWeight: FontWeight.w700,
//                                   color: Color(0xFF10B981),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),

//                 // Right-side icon:
//                 // • enrolled or isPreview → play icon
//                 // • not enrolled + not preview → lock icon
//                 if (isEnrolled || isPreview)
//                   Icon(
//                     active
//                         ? Icons.pause_circle_filled
//                         : Icons.play_circle_outline,
//                     color:
//                         active
//                             ? const Color(0xFF2563EB)
//                             : const Color(0xFF94A3B8),
//                     size: 22,
//                   )
//                 else
//                   const Icon(
//                     Icons.lock_outline,
//                     size: 16,
//                     color: Color(0xFF94A3B8),
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _thumbPlaceholder(int order) => Container(
//     color: const Color(0xFFFEF3C7),
//     child: Center(
//       child: Text(
//         '$order',
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           color: Color(0xFFF59E0B),
//           fontSize: 16,
//         ),
//       ),
//     ),
//   );

//   // ─── Docs Tab ────────────────────────────────────────────────────────────

//   Widget _buildDocsTab(bool isEnrolled) {
//     final docs =
//         widget.course.contents
//             .where(
//               (c) =>
//                   (c.documentUrl != null && c.documentUrl!.isNotEmpty) ||
//                   (c.documentFile != null && c.documentFile!.isNotEmpty),
//             )
//             .toList();
//     if (docs.isEmpty) return _emptyTab('No documents available');
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: docs.length,
//       itemBuilder: (_, i) => _DocItem(content: docs[i], isEnrolled: isEnrolled),
//     );
//   }

//   // ─── About Tab ───────────────────────────────────────────────────────────

//   Widget _buildAboutTab(bool isEnrolled) {
//     final course = widget.course;
//     final instructor =
//         course.contents.isNotEmpty
//             ? course.contents.first.instructorName
//             : course.vendorName;
//     final isLoading = ref.watch(enrollLoadingProvider(course.id));

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _AboutCard(
//             icon: Icons.person_outline,
//             label: 'Instructor',
//             value: instructor,
//             iconColor: const Color(0xFF8B5CF6),
//           ),
//           const SizedBox(height: 10),
//           if (course.categoryName != null &&
//               course.categoryName!.isNotEmpty) ...[
//             _AboutCard(
//               icon: Icons.category_outlined,
//               label: 'Category',
//               value: course.categoryName!,
//               iconColor: const Color(0xFFF59E0B),
//             ),
//           ],
//           const SizedBox(height: 10),
//           _AboutCard(
//             icon: Icons.library_books_outlined,
//             label: 'Total Lessons',
//             value: '${course.contents.length} lessons',
//             iconColor: const Color(0xFF10B981),
//           ),
//           if (!course.isFree && !isEnrolled) ...[
//             const SizedBox(height: 10),
//             _AboutCard(
//               icon: Icons.sell_outlined,
//               label: 'Price',
//               value: 'Rs. ${course.price.toStringAsFixed(0)}',
//               iconColor: const Color(0xFF2563EB),
//             ),
//           ],
//           const SizedBox(height: 16),
//           const Text(
//             'About this Course',
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1E293B),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             course.description,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade700,
//               height: 1.65,
//             ),
//           ),
//           const SizedBox(height: 24),
//           if (!isEnrolled)
//             _EnrollButton(
//               isFree: course.isFree,
//               isLoading: isLoading,
//               onTap: _enroll,
//               fullWidth: true,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _emptyTab(String msg) => Center(
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
//         const SizedBox(height: 8),
//         Text(
//           msg,
//           style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
//         ),
//       ],
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Khalti WebView
// // ═══════════════════════════════════════════════════════════════════════════

// class KhaltiWebViewScreen extends StatefulWidget {
//   final String paymentUrl;
//   const KhaltiWebViewScreen({Key? key, required this.paymentUrl})
//     : super(key: key);

//   @override
//   State<KhaltiWebViewScreen> createState() => _KhaltiWebViewScreenState();
// }

// class _KhaltiWebViewScreenState extends State<KhaltiWebViewScreen> {
//   static const _khaltiPurple = Color(0xFF5C2D91);
//   late final WebViewController _controller;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _controller =
//         WebViewController()
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..setBackgroundColor(Colors.white)
//           ..setNavigationDelegate(
//             NavigationDelegate(
//               onPageStarted: (_) => setState(() => _isLoading = true),
//               onPageFinished: (_) => setState(() => _isLoading = false),
//               onNavigationRequest: (request) {
//                 final url = request.url;
//                 if (url.contains('payment-success') ||
//                     url.contains('payment-complete') ||
//                     url.contains('payment/success') ||
//                     url.contains('payment/failure') ||
//                     url.contains('payment/cancel') ||
//                     url.contains('khalti/callback') ||
//                     url.startsWith('innovator://')) {
//                   Navigator.pop(context);
//                   return NavigationDecision.prevent;
//                 }
//                 return NavigationDecision.navigate;
//               },
//             ),
//           )
//           ..loadRequest(Uri.parse(widget.paymentUrl));
//   }

//   Future<bool> _onWillPop() async {
//     if (await _controller.canGoBack()) {
//       _controller.goBack();
//       return false;
//     }
//     final exit = await _confirmLeave();
//     return exit ?? false;
//   }

//   Future<bool?> _confirmLeave() => showDialog<bool>(
//     context: context,
//     builder:
//         (_) => AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: const Text('Cancel Payment?'),
//           content: const Text(
//             'Are you sure you want to leave? Your payment will not be completed.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('Stay'),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context, true),
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//               child: const Text('Leave', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         ),
//   );

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: _khaltiPurple,
//           foregroundColor: Colors.white,
//           automaticallyImplyLeading: false,
//           title: Row(
//             children: [
//               Image.asset(
//                 'assets/icon/khalti_logo.png',
//                 height: 22,
//                 errorBuilder:
//                     (_, __, ___) => const Icon(
//                       Icons.account_balance_wallet,
//                       color: Colors.white,
//                       size: 22,
//                     ),
//               ),
//               const SizedBox(width: 10),
//               const Text(
//                 'Pay with Khalti',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
//               ),
//             ],
//           ),
//           actions: [
//             if (_isLoading)
//               const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 ),
//               )
//             else
//               GestureDetector(
//                 onTap: () async {
//                   final exit = await _confirmLeave();
//                   if (exit == true && context.mounted) Navigator.pop(context);
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.only(right: 12),
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withAlpha(30),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.white.withAlpha(60)),
//                   ),
//                   child: const Icon(Icons.close, size: 16, color: Colors.white),
//                 ),
//               ),
//           ],
//           bottom: PreferredSize(
//             preferredSize: const Size.fromHeight(1),
//             child: Container(height: 1, color: Colors.white.withAlpha(40)),
//           ),
//         ),
//         body: Stack(
//           children: [
//             WebViewWidget(controller: _controller),
//             if (_isLoading)
//               Container(
//                 color: Colors.white.withAlpha(220),
//                 child: const Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       CircularProgressIndicator(color: _khaltiPurple),
//                       SizedBox(height: 14),
//                       Text(
//                         'Loading Khalti...',
//                         style: TextStyle(color: _khaltiPurple),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Video Player With Controls
// // ═══════════════════════════════════════════════════════════════════════════

// class _VideoPlayerWithControls extends StatefulWidget {
//   final VideoPlayerController controller;
//   final VoidCallback onFullscreen;

//   const _VideoPlayerWithControls({
//     Key? key,
//     required this.controller,
//     required this.onFullscreen,
//   }) : super(key: key);

//   @override
//   State<_VideoPlayerWithControls> createState() =>
//       _VideoPlayerWithControlsState();
// }

// class _VideoPlayerWithControlsState extends State<_VideoPlayerWithControls> {
//   bool _showControls = true;
//   bool _isDragging = false;
//   static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
//   double _currentSpeed = 1.0;
//   DateTime _lastTap = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     _scheduleHide();
//   }

//   void _scheduleHide() {
//     Future.delayed(const Duration(seconds: 3), () {
//       if (!mounted) return;
//       final elapsed = DateTime.now().difference(_lastTap).inSeconds;
//       if (elapsed >= 3 && !_isDragging) {
//         setState(() => _showControls = false);
//       }
//     });
//   }

//   void _toggleControls() {
//     setState(() {
//       _showControls = !_showControls;
//       _lastTap = DateTime.now();
//     });
//     if (_showControls) _scheduleHide();
//   }

//   void _skip(int seconds) {
//     final ctrl = widget.controller;
//     final duration = ctrl.value.duration;
//     if (duration == Duration.zero) return;
//     final current = ctrl.value.position;
//     final target = current + Duration(seconds: seconds);
//     final clamped =
//         target < Duration.zero
//             ? Duration.zero
//             : (target > duration ? duration : target);
//     ctrl.seekTo(clamped);
//   }

//   String _formatDuration(Duration d) {
//     final h = d.inHours;
//     final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return h > 0 ? '$h:$m:$s' : '$m:$s';
//   }

//   void _setSpeed(double speed) {
//     setState(() => _currentSpeed = speed);
//     widget.controller.setPlaybackSpeed(speed);
//   }

//   void _showSpeedPicker() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1E293B),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder:
//           (_) => Padding(
//             padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Playback Speed',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ..._speeds.map((s) {
//                   final selected = s == _currentSpeed;
//                   return GestureDetector(
//                     onTap: () {
//                       _setSpeed(s);
//                       Navigator.pop(context);
//                     },
//                     child: Container(
//                       margin: const EdgeInsets.only(bottom: 8),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       decoration: BoxDecoration(
//                         color:
//                             selected
//                                 ? const Color(0xFF2563EB)
//                                 : Colors.white.withAlpha(20),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Row(
//                         children: [
//                           Text(
//                             s == 1.0 ? 'Normal (1x)' : '${s}x',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight:
//                                   selected
//                                       ? FontWeight.bold
//                                       : FontWeight.normal,
//                             ),
//                           ),
//                           const Spacer(),
//                           if (selected)
//                             const Icon(
//                               Icons.check,
//                               color: Colors.white,
//                               size: 18,
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _toggleControls,
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           // Video frame
//           ValueListenableBuilder<VideoPlayerValue>(
//             valueListenable: widget.controller,
//             builder: (_, value, __) {
//               final w = value.size.width > 0 ? value.size.width : 16.0;
//               final h = value.size.height > 0 ? value.size.height : 9.0;
//               return FittedBox(
//                 fit: BoxFit.cover,
//                 child: SizedBox(
//                   width: w,
//                   height: h,
//                   child: VideoPlayer(widget.controller),
//                 ),
//               );
//             },
//           ),

//           // Controls overlay
//           AnimatedOpacity(
//             opacity: _showControls ? 1.0 : 0.0,
//             duration: const Duration(milliseconds: 250),
//             child: IgnorePointer(
//               ignoring: !_showControls,
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.black.withAlpha(160),
//                       Colors.transparent,
//                       Colors.transparent,
//                       Colors.black.withAlpha(200),
//                     ],
//                     stops: const [0.0, 0.3, 0.6, 1.0],
//                   ),
//                 ),
//                 child: ValueListenableBuilder<VideoPlayerValue>(
//                   valueListenable: widget.controller,
//                   builder: (_, value, __) {
//                     final isPlaying = value.isPlaying;
//                     final position = value.position;
//                     final duration = value.duration;
//                     final progress =
//                         duration.inMilliseconds > 0
//                             ? (position.inMilliseconds /
//                                     duration.inMilliseconds)
//                                 .clamp(0.0, 1.0)
//                             : 0.0;

//                     return Stack(
//                       children: [
//                         // Top: speed + fullscreen
//                         Positioned(
//                           top: 8,
//                           right: 8,
//                           child: Row(
//                             children: [
//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () {
//                                   _lastTap = DateTime.now();
//                                   _showSpeedPicker();
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 10,
//                                     vertical: 5,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withAlpha(130),
//                                     borderRadius: BorderRadius.circular(6),
//                                     border: Border.all(
//                                       color: Colors.white.withAlpha(60),
//                                     ),
//                                   ),
//                                   child: Text(
//                                     _currentSpeed == 1.0
//                                         ? '1x'
//                                         : '${_currentSpeed}x',
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () {
//                                   _lastTap = DateTime.now();
//                                   widget.onFullscreen();
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(6),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withAlpha(130),
//                                     borderRadius: BorderRadius.circular(6),
//                                     border: Border.all(
//                                       color: Colors.white.withAlpha(60),
//                                     ),
//                                   ),
//                                   child: const Icon(
//                                     Icons.fullscreen,
//                                     color: Colors.white,
//                                     size: 18,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         // Centre: skip back | play/pause | skip forward
//                         Center(
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () {
//                                   _lastTap = DateTime.now();
//                                   _skip(-10);
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(10),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withAlpha(100),
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: const Icon(
//                                     Icons.replay_10,
//                                     color: Colors.white,
//                                     size: 28,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 24),
//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () {
//                                   _lastTap = DateTime.now();
//                                   isPlaying
//                                       ? widget.controller.pause()
//                                       : widget.controller.play();
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(14),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withAlpha(140),
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Colors.white.withAlpha(80),
//                                       width: 2,
//                                     ),
//                                   ),
//                                   child: Icon(
//                                     isPlaying
//                                         ? Icons.pause_rounded
//                                         : Icons.play_arrow_rounded,
//                                     color: Colors.white,
//                                     size: 36,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 24),
//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () {
//                                   _lastTap = DateTime.now();
//                                   _skip(10);
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(10),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withAlpha(100),
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: const Icon(
//                                     Icons.forward_10,
//                                     color: Colors.white,
//                                     size: 28,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         // Bottom: time + seek bar
//                         Positioned(
//                           bottom: 0,
//                           left: 0,
//                           right: 0,
//                           child: Padding(
//                             padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Text(
//                                       _formatDuration(position),
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 11,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                     const Spacer(),
//                                     Text(
//                                       _formatDuration(duration),
//                                       style: TextStyle(
//                                         color: Colors.white.withAlpha(180),
//                                         fontSize: 11,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 4),
//                                 SliderTheme(
//                                   data: SliderTheme.of(context).copyWith(
//                                     trackHeight: 3,
//                                     thumbShape: const RoundSliderThumbShape(
//                                       enabledThumbRadius: 7,
//                                     ),
//                                     overlayShape: const RoundSliderOverlayShape(
//                                       overlayRadius: 14,
//                                     ),
//                                     activeTrackColor: const Color(0xFF2563EB),
//                                     inactiveTrackColor: Colors.white.withAlpha(
//                                       60,
//                                     ),
//                                     thumbColor: Colors.white,
//                                     overlayColor: Colors.white.withAlpha(40),
//                                   ),
//                                   child: Slider(
//                                     value: progress,
//                                     onChangeStart: (_) {
//                                       _isDragging = true;
//                                       _lastTap = DateTime.now();
//                                     },
//                                     onChanged: (v) {
//                                       if (duration == Duration.zero) return;
//                                       widget.controller.seekTo(
//                                         Duration(
//                                           milliseconds:
//                                               (v * duration.inMilliseconds)
//                                                   .toInt(),
//                                         ),
//                                       );
//                                     },
//                                     onChangeEnd: (_) {
//                                       _isDragging = false;
//                                       _scheduleHide();
//                                     },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Fullscreen Video Screen
// // ═══════════════════════════════════════════════════════════════════════════

// class _FullscreenVideoScreen extends StatefulWidget {
//   final VideoPlayerController controller;
//   const _FullscreenVideoScreen({required this.controller});

//   @override
//   State<_FullscreenVideoScreen> createState() => _FullscreenVideoScreenState();
// }

// class _FullscreenVideoScreenState extends State<_FullscreenVideoScreen> {
//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//   }

//   @override
//   void dispose() {
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) => Scaffold(
//     backgroundColor: Colors.black,
//     body: SafeArea(
//       child: _VideoPlayerWithControls(
//         key: ValueKey(widget.controller),
//         controller: widget.controller,
//         onFullscreen: () => Navigator.pop(context),
//       ),
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Locked Overlay
// // ═══════════════════════════════════════════════════════════════════════════

// class _LockedOverlay extends StatelessWidget {
//   final CourseListModel course;
//   const _LockedOverlay({required this.course});

//   @override
//   Widget build(BuildContext context) {
//     final thumb =
//         course.contents.isNotEmpty ? course.contents.first.thumbnail : null;
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         if (thumb != null)
//           Image.network(
//             thumb,
//             fit: BoxFit.cover,
//             errorBuilder:
//                 (_, __, ___) => Container(color: Colors.grey.shade900),
//           )
//         else
//           Container(color: Colors.grey.shade900),
//         Container(color: Colors.black.withAlpha(140)),
//         Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: Colors.white.withAlpha(38),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.lock_outline,
//                 color: Colors.white,
//                 size: 34,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               course.isFree
//                   ? 'Enroll for free to watch'
//                   : 'Pay to enroll and unlock',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Enroll Button
// // ═══════════════════════════════════════════════════════════════════════════

// class _EnrollButton extends StatelessWidget {
//   final bool isFree;
//   final bool isLoading;
//   final VoidCallback onTap;
//   final bool fullWidth;

//   const _EnrollButton({
//     required this.isFree,
//     required this.isLoading,
//     required this.onTap,
//     this.fullWidth = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final color = isFree ? const Color(0xFF10B981) : const Color(0xFF2563EB);
//     final label = isFree ? 'Enroll for Free' : 'Pay to Enroll';
//     final icon = isFree ? Icons.school_rounded : Icons.payment_rounded;

//     return GestureDetector(
//       onTap: isLoading ? null : onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: fullWidth ? double.infinity : null,
//         padding: EdgeInsets.symmetric(
//           horizontal: fullWidth ? 0 : 26,
//           vertical: 13,
//         ),
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(fullWidth ? 12 : 30),
//           boxShadow: [
//             BoxShadow(
//               color: color.withAlpha(90),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child:
//             isLoading
//                 ? const Center(
//                   child: SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   ),
//                 )
//                 : Row(
//                   mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(icon, color: Colors.white, size: 18),
//                     const SizedBox(width: 8),
//                     Text(
//                       label,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Course Badge
// // ═══════════════════════════════════════════════════════════════════════════

// class _CourseBadge extends StatelessWidget {
//   final bool isFree;
//   const _CourseBadge({required this.isFree});

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//     decoration: BoxDecoration(
//       color: const Color.fromRGBO(244, 135, 6, 1),
//       borderRadius: BorderRadius.circular(20),
//     ),
//     child: Text(
//       isFree ? 'Free' : 'Paid',
//       style: const TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w600,
//         color: Colors.white,
//       ),
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Doc Item
// // ═══════════════════════════════════════════════════════════════════════════

// class _DocItem extends StatelessWidget {
//   final CourseContent content;
//   final bool isEnrolled;
//   const _DocItem({required this.content, required this.isEnrolled});

//   String? get _url => content.documentUrl ?? content.documentFile;

//   @override
//   Widget build(BuildContext context) => Container(
//     margin: const EdgeInsets.only(bottom: 10),
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withAlpha(8),
//           blurRadius: 6,
//           offset: const Offset(0, 1),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: const Color(0xFFFEF3C7),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: const Icon(
//             Icons.picture_as_pdf,
//             color: Color(0xFFF59E0B),
//             size: 22,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 content.title,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF1E293B),
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 3),
//               Text(
//                 'Lesson ${content.order} · Document',
//                 style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 8),
//         isEnrolled
//             ? GestureDetector(
//               onTap:
//                   _url != null
//                       ? () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (_) => _PdfViewScreen(
//                                 url: _url!,
//                                 title: content.title,
//                               ),
//                         ),
//                       )
//                       : null,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFEFF6FF),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'View',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2563EB),
//                   ),
//                 ),
//               ),
//             )
//             : const Icon(
//               Icons.lock_outline,
//               size: 16,
//               color: Color(0xFF94A3B8),
//             ),
//       ],
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // PDF Viewer Screen
// // ═══════════════════════════════════════════════════════════════════════════

// class _PdfViewScreen extends StatelessWidget {
//   final String url;
//   final String title;
//   const _PdfViewScreen({required this.url, required this.title});

//   @override
//   Widget build(BuildContext context) => Scaffold(
//     appBar: AppBar(
//       title: Text(
//         title,
//         style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//       ),
//       backgroundColor: Colors.white,
//       foregroundColor: const Color(0xFF1E293B),
//       elevation: 0,
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(1),
//         child: Container(height: 1, color: const Color(0xFFE2E8F0)),
//       ),
//     ),
//     body: SfPdfViewer.network(url),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // About Card
// // ═══════════════════════════════════════════════════════════════════════════

// class _AboutCard extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final Color iconColor;

//   const _AboutCard({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.iconColor,
//   });

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withAlpha(8),
//           blurRadius: 6,
//           offset: const Offset(0, 1),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(9),
//           decoration: BoxDecoration(
//             color: iconColor.withAlpha(25),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: iconColor, size: 20),
//         ),
//         const SizedBox(width: 12),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
//             ),
//             const SizedBox(height: 3),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
// import 'package:innovator/Innovator/widget/CustomizeFAB.dart';
// import 'package:innovator/elearning/model/course_list_model.dart';
// import 'package:innovator/elearning/provider/course_provider.dart';
// import 'package:innovator/elearning/provider/notificationProvider.dart';
// import 'package:video_player/video_player.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class CourseDetailScreen extends ConsumerStatefulWidget {
//   final CourseListModel course;
//   const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

//   @override
//   ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
// }

// class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   VideoPlayerController? _videoController;

//   bool _videoInitialized = false;
//   bool _videoError = false;
//   bool _isVideoLoading = false;
//   int _selectedIndex = 0;
//   bool _videoStarted = false;

//   bool _isVerifyingPayment = false;

//   static const List<String> _tabs = ['Lessons', 'Docs', 'About'];

//   @override
//   void initState() {
//     super.initState();
//     ref.refresh(elearningUnreadCountProvider);
//     ref.refresh(elearningNotificationListProvider);
//     _tabController = TabController(length: _tabs.length, vsync: this);
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await ref.refresh(enrollmentProvider.future);
//       _maybeStartVideo();
//     });
//   }

//   /// Silently refreshes enrollment; if now enrolled → auto-play video.
//   Future<void> _verifyAndUnlock() async {
//     if (!mounted) return;
//     setState(() => _isVerifyingPayment = true);

//     try {
//       await ref.refresh(enrollmentProvider.future);
//       if (!mounted) return;

//       final isNowEnrolled = ref
//           .read(enrolledCoursesProvider)
//           .contains(widget.course.id);

//       if (isNowEnrolled) {
//         setState(() => _isVerifyingPayment = false);
//         ref.read(elearningNotificationListProvider.notifier).refresh();
//         _videoStarted = true;
//         if (widget.course.contents.isNotEmpty) {
//           _initVideo(widget.course.contents.first);
//         }
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Payment verified! Start learning now. 🎉'),
//               backgroundColor: const Color(0xFF10B981),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } else {
//         setState(() => _isVerifyingPayment = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text(
//                 'Payment is being processed. Please wait a moment.',
//               ),
//               backgroundColor: Colors.orange,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       }
//     } catch (_) {
//       if (mounted) setState(() => _isVerifyingPayment = false);
//     }
//   }

//   void _maybeStartVideo() {
//     if (_videoStarted || !mounted) return;
//     final enrolled = ref
//         .read(enrolledCoursesProvider)
//         .contains(widget.course.id);
//     if (enrolled && widget.course.contents.isNotEmpty) {
//       _videoStarted = true;
//       _initVideo(widget.course.contents.first);
//     }
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _videoController?.dispose();
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     super.dispose();
//   }

//   // Video Init

//   void _initVideo(CourseContent content) {
//     final oldController = _videoController;

//     setState(() {
//       _videoController = null;
//       _videoInitialized = false;
//       _videoError = false;
//       _isVideoLoading = true;
//     });

//     oldController?.dispose();

//     final url =
//         (content.videoUrl != null && content.videoUrl!.isNotEmpty)
//             ? content.videoUrl!
//             : (content.videoFile != null && content.videoFile!.isNotEmpty)
//             ? content.videoFile!
//             : null;

//     if (url == null) {
//       setState(() {
//         _videoError = true;
//         _isVideoLoading = false;
//       });
//       return;
//     }

//     final controller = VideoPlayerController.networkUrl(Uri.parse(url));
//     controller
//         .initialize()
//         .then((_) {
//           if (!mounted) {
//             controller.dispose();
//             return;
//           }
//           setState(() {
//             _videoController = controller;
//             _videoInitialized = true;
//             _isVideoLoading = false;
//           });
//         })
//         .catchError((_) {
//           if (!mounted) {
//             controller.dispose();
//             return;
//           }
//           setState(() {
//             _videoError = true;
//             _isVideoLoading = false;
//           });
//         });
//   }

//   Future<void> _enroll() async {
//     final courseId = widget.course.id;
//     ref.read(enrollLoadingProvider(courseId).notifier).setLoading(true);

//     try {
//       if (widget.course.isFree) {
//         await ref.read(courseServiceProvider).enrollCourse(courseId);
//         await ref.refresh(enrollmentProvider.future);
//         ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
//         ref.read(elearningNotificationListProvider.notifier).refresh();

//         _videoStarted = true;
//         if (widget.course.contents.isNotEmpty) {
//           _initVideo(widget.course.contents.first);
//         }
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Enrolled! Start learning now. 🎉'),
//               backgroundColor: const Color(0xFF10B981),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } else {
//         // PAID: open Khalti WebView inside the app
//         final result = await ref
//             .read(courseServiceProvider)
//             .initiatePayment(courseId);
//         ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);

//         final paymentUrl = result['payment_url'] as String?;
//         if (paymentUrl == null) {
//           _showErrorSnack('Could not initiate payment. Please try again.');
//           return;
//         }

//         if (!mounted) return;

//         // Open payment WebView and wait for user to return
//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => KhaltiWebViewScreen(paymentUrl: paymentUrl),
//           ),
//         );

//         // Always verify enrollment when user returns (paid or cancelled)
//         if (mounted) _verifyAndUnlock();
//       }
//     } catch (e) {
//       ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
//     }
//   }

//   void _showErrorSnack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: Colors.redAccent,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final enrolledIds = ref.watch(enrolledCoursesProvider);
//     final isEnrolled = enrolledIds.contains(widget.course.id);
//     final unreadCount = ref.watch(chatUnreadCountProvider);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: Stack(
//         children: [
//           NestedScrollView(
//             headerSliverBuilder:
//                 (context, innerBoxIsScrolled) => [
//                   SliverToBoxAdapter(child: _buildVideoSection(isEnrolled)),
//                   SliverToBoxAdapter(child: _buildTitleBar()),
//                 ],
//             body: TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildLessonsTab(isEnrolled),
//                 _buildDocsTab(isEnrolled),
//                 _buildAboutTab(isEnrolled),
//               ],
//             ),
//           ),

//           // Payment verification overlay
//           if (_isVerifyingPayment)
//             Container(
//               color: Colors.black.withAlpha(160),
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 32,
//                     vertical: 28,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const SizedBox(
//                         height: 40,
//                         width: 40,
//                         child: CircularProgressIndicator(
//                           color: Color(0xFF2563EB),
//                           strokeWidth: 3,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       const Text(
//                         'Verifying payment...',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1E293B),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         'Please wait while we confirm your enrollment.',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: CountBadgeFAB(
//         count: unreadCount,
//         gifAsset: 'animation/chaticon.gif',
//         backgroundColor: Colors.transparent,
//         onPressed: () {
//           ref.read(mutualFriendsProvider.notifier).refresh();
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const ChatListScreen()),
//           ).then((_) {
//             ref.invalidate(mutualFriendsProvider);
//           });
//         },
//       ),
//     );
//   }

//   // Title Bar

//   Widget _buildTitleBar() {
//     return Container(
//       color: Colors.white,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF5F7FA),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: const Color(0xFFE2E8F0)),
//                     ),
//                     child: const Icon(
//                       Icons.arrow_back_ios_new,
//                       size: 14,
//                       color: Color(0xFF1E293B),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     widget.course.title,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1E293B),
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 _CourseBadge(isFree: widget.course.isFree),
//               ],
//             ),
//           ),
//           TabBar(
//             controller: _tabController,
//             tabs: _tabs.map((t) => Tab(text: t)).toList(),
//             labelColor: Colors.black,
//             unselectedLabelColor: const Color(0xFF94A3B8),
//             indicatorColor: const Color.fromRGBO(244, 135, 6, 1),
//             indicatorWeight: 2.5,
//             labelStyle: const TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Video Section

//   Widget _buildVideoSection(bool isEnrolled) {
//     final isLoading = ref.watch(enrollLoadingProvider(widget.course.id));

//     double aspectRatio = 16 / 9;
//     if (_videoInitialized && _videoController != null) {
//       final size = _videoController!.value.size;
//       if (size.width > 0 && size.height > 0) {
//         aspectRatio = size.width / size.height;
//       }
//     }
//     return Container(
//       color: Colors.black,
//       width: double.infinity,
//       child: SafeArea(
//         bottom: false,
//         child: AspectRatio(
//           // aspectRatio: 16 / 9,
//           aspectRatio: aspectRatio,
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               if (!isEnrolled)
//                 _LockedOverlay(course: widget.course)
//               else if (_isVideoLoading)
//                 _videoShimmer()
//               else if (_videoError)
//                 _videoErrorWidget()
//               else if (_videoInitialized && _videoController != null)
//                 _VideoPlayerWithControls(
//                   key: ValueKey(_videoController),
//                   controller: _videoController!,
//                   onFullscreen: _openFullscreen,
//                 )
//               else
//                 _videoShimmer(),

//               // Back button
//               Positioned(
//                 top: 10,
//                 left: 10,
//                 child: GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(7),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withAlpha(115),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.arrow_back,
//                       color: Colors.white,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//               ),

//               if (!isEnrolled)
//                 Positioned(
//                   bottom: 14,
//                   child: _EnrollButton(
//                     isFree: widget.course.isFree,
//                     isLoading: isLoading,
//                     onTap: _enroll,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _openFullscreen() {
//     if (!_videoInitialized || _videoController == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => _FullscreenVideoScreen(controller: _videoController!),
//       ),
//     );
//   }

//   Widget _videoShimmer() => Shimmer.fromColors(
//     baseColor: Colors.grey.shade800,
//     highlightColor: Colors.grey.shade700,
//     child: Container(color: Colors.grey.shade800),
//   );

//   Widget _videoErrorWidget() => Container(
//     color: Colors.grey.shade900,
//     child: const Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.videocam_off, color: Colors.white54, size: 36),
//           SizedBox(height: 8),
//           Text(
//             'Video unavailable',
//             style: TextStyle(color: Colors.white54, fontSize: 13),
//           ),
//         ],
//       ),
//     ),
//   );

//   // Lessons Tab

//   Widget _buildLessonsTab(bool isEnrolled) {
//     final contents = widget.course.contents;
//     if (contents.isEmpty) return _emptyTab('No lessons available');

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: contents.length,
//       itemBuilder: (_, i) {
//         final c = contents[i];
//         final active = _selectedIndex == i;
//         return GestureDetector(
//           onTap:
//               isEnrolled
//                   ? () {
//                     setState(() => _selectedIndex = i);
//                     _initVideo(c);
//                     _tabController.animateTo(0);
//                   }
//                   : null,
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             margin: const EdgeInsets.only(bottom: 10),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color:
//                     active
//                         ? const Color.fromRGBO(244, 135, 6, 1)
//                         : Colors.transparent,
//                 width: 1.5,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withAlpha(8),
//                   blurRadius: 6,
//                   offset: const Offset(0, 1),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: SizedBox(
//                     width: 62,
//                     height: 46,
//                     child:
//                         c.thumbnail != null
//                             ? Image.network(
//                               c.thumbnail!,
//                               fit: BoxFit.cover,
//                               errorBuilder:
//                                   (_, __, ___) => _thumbPlaceholder(c.order),
//                             )
//                             : _thumbPlaceholder(c.order),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         c.title,
//                         style: const TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1E293B),
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 5),
//                       Row(
//                         children: [
//                           const Icon(
//                             Icons.timer_outlined,
//                             size: 11,
//                             color: Color(0xFF94A3B8),
//                           ),
//                           const SizedBox(width: 3),
//                           Text(
//                             '${c.duration.toStringAsFixed(0)} min',
//                             style: const TextStyle(
//                               fontSize: 11,
//                               color: Color(0xFF94A3B8),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFF5F7FA),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               c.courseLevel.toUpperCase(),
//                               style: const TextStyle(
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF64748B),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 isEnrolled
//                     ? Icon(
//                       active
//                           ? Icons.pause_circle_filled
//                           : Icons.play_circle_outline,
//                       color:
//                           active
//                               ? const Color(0xFF2563EB)
//                               : const Color(0xFF94A3B8),
//                       size: 22,
//                     )
//                     : const Icon(
//                       Icons.lock_outline,
//                       size: 16,
//                       color: Color(0xFF94A3B8),
//                     ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _thumbPlaceholder(int order) => Container(
//     color: const Color(0xFFFEF3C7),
//     child: Center(
//       child: Text(
//         '$order',
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           color: Color(0xFFF59E0B),
//           fontSize: 16,
//         ),
//       ),
//     ),
//   );

//   // Docs Tab

//   Widget _buildDocsTab(bool isEnrolled) {
//     final docs =
//         widget.course.contents
//             .where(
//               (c) =>
//                   (c.documentUrl != null && c.documentUrl!.isNotEmpty) ||
//                   (c.documentFile != null && c.documentFile!.isNotEmpty),
//             )
//             .toList();
//     if (docs.isEmpty) return _emptyTab('No documents available');
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: docs.length,
//       itemBuilder: (_, i) => _DocItem(content: docs[i], isEnrolled: isEnrolled),
//     );
//   }

//   // About Tab

//   Widget _buildAboutTab(bool isEnrolled) {
//     final course = widget.course;
//     final instructor =
//         course.contents.isNotEmpty
//             ? course.contents.first.instructorName
//             : course.vendorName;
//     final isLoading = ref.watch(enrollLoadingProvider(course.id));

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _AboutCard(
//             icon: Icons.person_outline,
//             label: 'Instructor',
//             value: instructor,
//             iconColor: const Color(0xFF8B5CF6),
//           ),
//           const SizedBox(height: 10),
//           _AboutCard(
//             icon: Icons.category_outlined,
//             label: 'Category',
//             value: course.categoryName,
//             iconColor: const Color(0xFFF59E0B),
//           ),
//           const SizedBox(height: 10),
//           _AboutCard(
//             icon: Icons.library_books_outlined,
//             label: 'Total Lessons',
//             value: '${course.contents.length} lessons',
//             iconColor: const Color(0xFF10B981),
//           ),
//           if (!course.isFree && !isEnrolled) ...[
//             const SizedBox(height: 10),
//             _AboutCard(
//               icon: Icons.sell_outlined,
//               label: 'Price',
//               value: 'Rs. ${course.price.toStringAsFixed(0)}',
//               iconColor: const Color(0xFF2563EB),
//             ),
//           ],
//           const SizedBox(height: 16),
//           const Text(
//             'About this Course',
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1E293B),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             course.description,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade700,
//               height: 1.65,
//             ),
//           ),
//           const SizedBox(height: 24),
//           if (!isEnrolled)
//             _EnrollButton(
//               isFree: course.isFree,
//               isLoading: isLoading,
//               onTap: _enroll,
//               fullWidth: true,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _emptyTab(String msg) => Center(
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
//         const SizedBox(height: 8),
//         Text(
//           msg,
//           style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
//         ),
//       ],
//     ),
//   );
// }

// class KhaltiWebViewScreen extends StatefulWidget {
//   final String paymentUrl;

//   const KhaltiWebViewScreen({Key? key, required this.paymentUrl})
//     : super(key: key);

//   @override
//   State<KhaltiWebViewScreen> createState() => _KhaltiWebViewScreenState();
// }

// class _KhaltiWebViewScreenState extends State<KhaltiWebViewScreen> {
//   static const _khaltiPurple = Color(0xFF5C2D91);

//   late final WebViewController _controller;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _controller =
//         WebViewController()
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..setBackgroundColor(Colors.white)
//           ..setNavigationDelegate(
//             NavigationDelegate(
//               onPageStarted: (_) => setState(() => _isLoading = true),
//               onPageFinished: (_) => setState(() => _isLoading = false),
//               onNavigationRequest: (request) {
//                 final url = request.url;
//                 if (url.contains('payment-success') ||
//                     url.contains('payment-complete') ||
//                     url.contains('payment/success') ||
//                     url.contains('payment/failure') ||
//                     url.contains('payment/cancel') ||
//                     url.contains('khalti/callback') ||
//                     url.startsWith('innovator://')) {
//                   Navigator.pop(context);
//                   return NavigationDecision.prevent;
//                 }
//                 return NavigationDecision.navigate;
//               },
//             ),
//           )
//           ..loadRequest(Uri.parse(widget.paymentUrl));
//   }

//   Future<bool> _onWillPop() async {
//     if (await _controller.canGoBack()) {
//       _controller.goBack();
//       return false;
//     }
//     final exit = await showDialog<bool>(
//       context: context,
//       builder:
//           (_) => AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             title: const Text('Cancel Payment?'),
//             content: const Text(
//               'Are you sure you want to leave? Your payment will not be completed.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: const Text('Stay'),
//               ),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                 child: const Text(
//                   'Leave',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//     );
//     return exit ?? false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: _khaltiPurple,
//           foregroundColor: Colors.white,
//           automaticallyImplyLeading: false,
//           title: Row(
//             children: [
//               Image.asset(
//                 'assets/icon/khalti_logo.png',
//                 height: 22,
//                 errorBuilder:
//                     (_, __, ___) => const Icon(
//                       Icons.account_balance_wallet,
//                       color: Colors.white,
//                       size: 22,
//                     ),
//               ),
//               const SizedBox(width: 10),
//               const Text(
//                 'Pay with Khalti',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
//               ),
//             ],
//           ),
//           actions: [
//             if (_isLoading)
//               const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 ),
//               )
//             else
//               GestureDetector(
//                 onTap: () async {
//                   final exit = await showDialog<bool>(
//                     context: context,
//                     builder:
//                         (_) => AlertDialog(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           title: const Text('Cancel Payment?'),
//                           content: const Text(
//                             'Are you sure you want to leave? Your payment will not be completed.',
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.pop(context, false),
//                               child: const Text('Stay'),
//                             ),
//                             ElevatedButton(
//                               onPressed: () => Navigator.pop(context, true),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.red,
//                               ),
//                               child: const Text(
//                                 'Leave',
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             ),
//                           ],
//                         ),
//                   );
//                   if (exit == true && context.mounted) Navigator.pop(context);
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.only(right: 12),
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withAlpha(30),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.white.withAlpha(60)),
//                   ),
//                   child: const Icon(Icons.close, size: 16, color: Colors.white),
//                 ),
//               ),
//           ],
//           bottom: PreferredSize(
//             preferredSize: const Size.fromHeight(1),
//             child: Container(height: 1, color: Colors.white.withAlpha(40)),
//           ),
//         ),
//         body: Stack(
//           children: [
//             WebViewWidget(controller: _controller),
//             if (_isLoading)
//               Container(
//                 color: Colors.white.withAlpha(220),
//                 child: const Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       CircularProgressIndicator(color: _khaltiPurple),
//                       SizedBox(height: 14),
//                       Text(
//                         'Loading Khalti...',
//                         style: TextStyle(color: _khaltiPurple),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Video Player With Controls

// class _VideoPlayerWithControls extends StatefulWidget {
//   final VideoPlayerController controller;
//   final VoidCallback onFullscreen;

//   const _VideoPlayerWithControls({
//     Key? key,
//     required this.controller,
//     required this.onFullscreen,
//   }) : super(key: key);

//   @override
//   State<_VideoPlayerWithControls> createState() =>
//       _VideoPlayerWithControlsState();
// }

// class _VideoPlayerWithControlsState extends State<_VideoPlayerWithControls> {
//   bool _showControls = true;
//   bool _isDragging = false;

//   static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
//   double _currentSpeed = 1.0;
//   DateTime _lastTap = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     _scheduleHide();
//   }

//   void _scheduleHide() {
//     Future.delayed(const Duration(seconds: 3), () {
//       if (!mounted) return;
//       final elapsed = DateTime.now().difference(_lastTap).inSeconds;
//       if (elapsed >= 3 && !_isDragging) {
//         setState(() => _showControls = false);
//       }
//     });
//   }

//   void _toggleControls() {
//     setState(() {
//       _showControls = !_showControls;
//       _lastTap = DateTime.now();
//     });
//     if (_showControls) _scheduleHide();
//   }

//   void _skip(int seconds) {
//     final ctrl = widget.controller;
//     final duration = ctrl.value.duration;
//     if (duration == Duration.zero) return;
//     final current = ctrl.value.position;
//     final target = current + Duration(seconds: seconds);
//     final clamped =
//         target < Duration.zero
//             ? Duration.zero
//             : (target > duration ? duration : target);
//     ctrl.seekTo(clamped);
//   }

//   String _formatDuration(Duration d) {
//     final h = d.inHours;
//     final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return h > 0 ? '$h:$m:$s' : '$m:$s';
//   }

//   void _setSpeed(double speed) {
//     setState(() => _currentSpeed = speed);
//     widget.controller.setPlaybackSpeed(speed);
//   }

//   void _showSpeedPicker() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1E293B),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder:
//           (_) => Padding(
//             padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Playback Speed',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ..._speeds.map((s) {
//                   final selected = s == _currentSpeed;
//                   return GestureDetector(
//                     onTap: () {
//                       _setSpeed(s);
//                       Navigator.pop(context);
//                     },
//                     child: Container(
//                       margin: const EdgeInsets.only(bottom: 8),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       decoration: BoxDecoration(
//                         color:
//                             selected
//                                 ? const Color(0xFF2563EB)
//                                 : Colors.white.withAlpha(20),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Row(
//                         children: [
//                           Text(
//                             s == 1.0 ? 'Normal (1x)' : '${s}x',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight:
//                                   selected
//                                       ? FontWeight.bold
//                                       : FontWeight.normal,
//                             ),
//                           ),
//                           const Spacer(),
//                           if (selected)
//                             const Icon(
//                               Icons.check,
//                               color: Colors.white,
//                               size: 18,
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _toggleControls,
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           // Video
//           ValueListenableBuilder<VideoPlayerValue>(
//             valueListenable: widget.controller,
//             builder: (_, value, __) {
//               final w = value.size.width > 0 ? value.size.width : 16.0;
//               final h = value.size.height > 0 ? value.size.height : 9.0;
//               return FittedBox(
//                 fit: BoxFit.cover,
//                 child: SizedBox(
//                   width: w,
//                   height: h,
//                   child: VideoPlayer(widget.controller),
//                 ),
//               );
//             },
//           ),

//           // Controls overlay
//           AnimatedOpacity(
//             opacity: _showControls ? 1.0 : 0.0,
//             duration: const Duration(milliseconds: 250),
//             child: IgnorePointer(
//               ignoring: !_showControls,
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.black.withAlpha(160),
//                       Colors.transparent,
//                       Colors.transparent,
//                       Colors.black.withAlpha(200),
//                     ],
//                     stops: const [0.0, 0.3, 0.6, 1.0],
//                   ),
//                 ),
//                 child: ValueListenableBuilder<VideoPlayerValue>(
//                   valueListenable: widget.controller,
//                   builder: (_, value, __) {
//                     final isPlaying = value.isPlaying;
//                     final position = value.position;
//                     final duration = value.duration;
//                     final progress =
//                         duration.inMilliseconds > 0
//                             ? (position.inMilliseconds /
//                                     duration.inMilliseconds)
//                                 .clamp(0.0, 1.0)
//                             : 0.0;

//                     return Stack(
//                       children: [
//                         // Top: speed + fullscreen
//                         Positioned(
//                           top: 8,
//                           right: 8,
//                           child: GestureDetector(
//                             behavior: HitTestBehavior.opaque,
//                             onTap: () {},
//                             child: Row(
//                               children: [
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     _showSpeedPicker();
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 10,
//                                       vertical: 5,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(130),
//                                       borderRadius: BorderRadius.circular(6),
//                                       border: Border.all(
//                                         color: Colors.white.withAlpha(60),
//                                       ),
//                                     ),
//                                     child: Text(
//                                       _currentSpeed == 1.0
//                                           ? '1x'
//                                           : '${_currentSpeed}x',
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     widget.onFullscreen();
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(6),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(130),
//                                       borderRadius: BorderRadius.circular(6),
//                                       border: Border.all(
//                                         color: Colors.white.withAlpha(60),
//                                       ),
//                                     ),
//                                     child: const Icon(
//                                       Icons.fullscreen,
//                                       color: Colors.white,
//                                       size: 18,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                         // Centre: skip back | play/pause | skip forward
//                         Center(
//                           child: GestureDetector(
//                             behavior: HitTestBehavior.opaque,
//                             onTap: () {},
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     _skip(-10);
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(10),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(100),
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(
//                                       Icons.replay_10,
//                                       color: Colors.white,
//                                       size: 28,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 24),
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     isPlaying
//                                         ? widget.controller.pause()
//                                         : widget.controller.play();
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(14),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(140),
//                                       shape: BoxShape.circle,
//                                       border: Border.all(
//                                         color: Colors.white.withAlpha(80),
//                                         width: 2,
//                                       ),
//                                     ),
//                                     child: Icon(
//                                       isPlaying
//                                           ? Icons.pause_rounded
//                                           : Icons.play_arrow_rounded,
//                                       color: Colors.white,
//                                       size: 36,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 24),
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     _skip(10);
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(10),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(100),
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(
//                                       Icons.forward_10,
//                                       color: Colors.white,
//                                       size: 28,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                         // Bottom: time + seek bar
//                         Positioned(
//                           bottom: 0,
//                           left: 0,
//                           right: 0,
//                           child: GestureDetector(
//                             behavior: HitTestBehavior.opaque,
//                             onTap: () {},
//                             child: Padding(
//                               padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       Text(
//                                         _formatDuration(position),
//                                         style: const TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 11,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                       const Spacer(),
//                                       Text(
//                                         _formatDuration(duration),
//                                         style: TextStyle(
//                                           color: Colors.white.withAlpha(180),
//                                           fontSize: 11,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 4),
//                                   SliderTheme(
//                                     data: SliderTheme.of(context).copyWith(
//                                       trackHeight: 3,
//                                       thumbShape: const RoundSliderThumbShape(
//                                         enabledThumbRadius: 7,
//                                       ),
//                                       overlayShape:
//                                           const RoundSliderOverlayShape(
//                                             overlayRadius: 14,
//                                           ),
//                                       activeTrackColor: const Color(0xFF2563EB),
//                                       inactiveTrackColor: Colors.white
//                                           .withAlpha(60),
//                                       thumbColor: Colors.white,
//                                       overlayColor: Colors.white.withAlpha(40),
//                                     ),
//                                     child: Slider(
//                                       value: progress,
//                                       onChangeStart: (_) {
//                                         _isDragging = true;
//                                         _lastTap = DateTime.now();
//                                       },
//                                       onChanged: (v) {
//                                         if (duration == Duration.zero) return;
//                                         widget.controller.seekTo(
//                                           Duration(
//                                             milliseconds:
//                                                 (v * duration.inMilliseconds)
//                                                     .toInt(),
//                                           ),
//                                         );
//                                       },
//                                       onChangeEnd: (_) {
//                                         _isDragging = false;
//                                         _scheduleHide();
//                                       },
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Fullscreen Video Screen

// class _FullscreenVideoScreen extends StatefulWidget {
//   final VideoPlayerController controller;
//   const _FullscreenVideoScreen({required this.controller});

//   @override
//   State<_FullscreenVideoScreen> createState() => _FullscreenVideoScreenState();
// }

// class _FullscreenVideoScreenState extends State<_FullscreenVideoScreen> {
//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//   }

//   @override
//   void dispose() {
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: _VideoPlayerWithControls(
//           key: ValueKey(widget.controller),
//           controller: widget.controller,
//           onFullscreen: () => Navigator.pop(context),
//         ),
//       ),
//     );
//   }
// }

// // Locked Overlay

// class _LockedOverlay extends StatelessWidget {
//   final CourseListModel course;
//   const _LockedOverlay({required this.course});

//   @override
//   Widget build(BuildContext context) {
//     final thumb =
//         course.contents.isNotEmpty ? course.contents.first.thumbnail : null;
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         if (thumb != null)
//           Image.network(
//             thumb,
//             fit: BoxFit.cover,
//             errorBuilder:
//                 (_, __, ___) => Container(color: Colors.grey.shade900),
//           )
//         else
//           Container(color: Colors.grey.shade900),
//         Container(color: Colors.black.withAlpha(140)),
//         Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: Colors.white.withAlpha(38),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.lock_outline,
//                 color: Colors.white,
//                 size: 34,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               course.isFree
//                   ? 'Enroll for free to watch'
//                   : 'Pay to enroll and unlock',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// // Enroll Button

// class _EnrollButton extends StatelessWidget {
//   final bool isFree;
//   final bool isLoading;
//   final VoidCallback onTap;
//   final bool fullWidth;

//   const _EnrollButton({
//     required this.isFree,
//     required this.isLoading,
//     required this.onTap,
//     this.fullWidth = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final color = isFree ? const Color(0xFF10B981) : const Color(0xFF2563EB);
//     final label = isFree ? 'Enroll for Free' : 'Pay to Enroll';
//     final icon = isFree ? Icons.school_rounded : Icons.payment_rounded;

//     return GestureDetector(
//       onTap: isLoading ? null : onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: fullWidth ? double.infinity : null,
//         padding: EdgeInsets.symmetric(
//           horizontal: fullWidth ? 0 : 26,
//           vertical: 13,
//         ),
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(fullWidth ? 12 : 30),
//           boxShadow: [
//             BoxShadow(
//               color: color.withAlpha(90),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child:
//             isLoading
//                 ? const Center(
//                   child: SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   ),
//                 )
//                 : Row(
//                   mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(icon, color: Colors.white, size: 18),
//                     const SizedBox(width: 8),
//                     Text(
//                       label,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//       ),
//     );
//   }
// }

// // Course Badge

// class _CourseBadge extends StatelessWidget {
//   final bool isFree;
//   const _CourseBadge({required this.isFree});

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//     decoration: BoxDecoration(
//       color: const Color.fromRGBO(244, 135, 6, 1),
//       borderRadius: BorderRadius.circular(20),
//     ),
//     child: Text(
//       isFree ? 'Free' : 'Paid',
//       style: const TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w600,
//         color: Colors.white,
//       ),
//     ),
//   );
// }

// // Doc Item

// class _DocItem extends StatelessWidget {
//   final CourseContent content;
//   final bool isEnrolled;
//   const _DocItem({required this.content, required this.isEnrolled});

//   String? get _url => content.documentUrl ?? content.documentFile;

//   @override
//   Widget build(BuildContext context) => Container(
//     margin: const EdgeInsets.only(bottom: 10),
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withAlpha(8),
//           blurRadius: 6,
//           offset: const Offset(0, 1),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: const Color(0xFFFEF3C7),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: const Icon(
//             Icons.picture_as_pdf,
//             color: Color(0xFFF59E0B),
//             size: 22,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 content.title,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF1E293B),
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 3),
//               Text(
//                 'Lesson ${content.order} · Document',
//                 style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 8),
//         isEnrolled
//             ? GestureDetector(
//               onTap:
//                   _url != null
//                       ? () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (_) => _PdfViewScreen(
//                                 url: _url!,
//                                 title: content.title,
//                               ),
//                         ),
//                       )
//                       : null,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFEFF6FF),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'View',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2563EB),
//                   ),
//                 ),
//               ),
//             )
//             : const Icon(
//               Icons.lock_outline,
//               size: 16,
//               color: Color(0xFF94A3B8),
//             ),
//       ],
//     ),
//   );
// }

// // PDF Viewer

// class _PdfViewScreen extends StatelessWidget {
//   final String url;
//   final String title;
//   const _PdfViewScreen({required this.url, required this.title});

//   @override
//   Widget build(BuildContext context) => Scaffold(
//     appBar: AppBar(
//       title: Text(
//         title,
//         style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//       ),
//       backgroundColor: Colors.white,
//       foregroundColor: const Color(0xFF1E293B),
//       elevation: 0,
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(1),
//         child: Container(height: 1, color: const Color(0xFFE2E8F0)),
//       ),
//     ),
//     body: SfPdfViewer.network(url),
//   );
// }

// // About Card

// class _AboutCard extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final Color iconColor;
//   const _AboutCard({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.iconColor,
//   });

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withAlpha(8),
//           blurRadius: 6,
//           offset: const Offset(0, 1),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(9),
//           decoration: BoxDecoration(
//             color: iconColor.withAlpha(25),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: iconColor, size: 20),
//         ),
//         const SizedBox(width: 12),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
//             ),
//             const SizedBox(height: 3),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
// import 'package:innovator/Innovator/widget/CustomizeFAB.dart';
// import 'package:innovator/elearning/model/course_list_model.dart';
// import 'package:innovator/elearning/provider/course_provider.dart';
// import 'package:innovator/elearning/provider/notificationProvider.dart';
// import 'package:video_player/video_player.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class CourseDetailScreen extends ConsumerStatefulWidget {
//   final CourseListModel course;
//   const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

//   @override
//   ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
// }

// class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   VideoPlayerController? _videoController;

//   bool _videoInitialized = false;
//   bool _videoError = false;
//   bool _isVideoLoading = false;
//   int _selectedIndex = -1; // -1 = nothing selected yet
//   bool _isVerifyingPayment = false;

//   /// Tracks exactly which CourseContent is currently loaded in the player.
//   /// The lock/unlock decision is based on THIS content's isPreview flag,
//   /// not the course type. This is the single source of truth.
//   CourseContent? _currentContent;

//   static const List<String> _tabs = ['Lessons', 'Docs', 'About'];

//   @override
//   void initState() {
//     super.initState();
//     ref.refresh(elearningUnreadCountProvider);
//     ref.refresh(elearningNotificationListProvider);
//     _tabController = TabController(length: _tabs.length, vsync: this);
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await ref.refresh(enrollmentProvider.future);
//       _maybeStartPreview();
//     });
//   }

//   // ─── Auto-start on open ──────────────────────────────────────────────────

//   /// Called once after enrollment state loads.
//   ///
//   /// • Enrolled  → play the first lesson normally.
//   /// • Not enrolled → find the FIRST lesson where isPreview == true and
//   ///   load ONLY that one. Never fall back to contents[0].
//   /// • No preview lessons exist + not enrolled → leave player on locked overlay.
//   void _maybeStartPreview() {
//     if (!mounted) return;

//     final enrolled = ref
//         .read(enrolledCoursesProvider)
//         .contains(widget.course.id);

//     if (enrolled) {
//       if (widget.course.contents.isNotEmpty) {
//         setState(() => _selectedIndex = 0);
//         _initVideo(widget.course.contents.first);
//       }
//     } else {
//       // Only auto-load a lesson that explicitly has isPreview == true.
//       final previewContent =
//           widget.course.contents.where((c) => c.isPreview == true).firstOrNull;
//       if (previewContent != null) {
//         final idx = widget.course.contents.indexOf(previewContent);
//         setState(() => _selectedIndex = idx);
//         _initVideo(previewContent);
//       }
//       // If there is no preview lesson: _currentContent stays null
//       // → _buildVideoSection shows the locked overlay.
//     }
//   }

//   // ─── Payment verification ────────────────────────────────────────────────

//   Future<void> _verifyAndUnlock() async {
//     if (!mounted) return;
//     setState(() => _isVerifyingPayment = true);

//     try {
//       await ref.refresh(enrollmentProvider.future);
//       if (!mounted) return;

//       final isNowEnrolled = ref
//           .read(enrolledCoursesProvider)
//           .contains(widget.course.id);

//       if (isNowEnrolled) {
//         setState(() => _isVerifyingPayment = false);
//         ref.read(elearningNotificationListProvider.notifier).refresh();

//         // Play the exact lesson the user originally tapped (stored in
//         // _currentContent), or fall back to the first lesson.
//         final target =
//             _currentContent ??
//             (widget.course.contents.isNotEmpty
//                 ? widget.course.contents.first
//                 : null);
//         if (target != null) {
//           final idx = widget.course.contents.indexOf(target);
//           setState(() => _selectedIndex = idx < 0 ? 0 : idx);
//           _initVideo(target);
//         }

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Payment verified! Start learning now. 🎉'),
//               backgroundColor: const Color(0xFF10B981),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } else {
//         setState(() => _isVerifyingPayment = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text(
//                 'Payment is being processed. Please wait a moment.',
//               ),
//               backgroundColor: Colors.orange,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       }
//     } catch (_) {
//       if (mounted) setState(() => _isVerifyingPayment = false);
//     }
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _videoController?.dispose();
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     super.dispose();
//   }

//   // ─── Video initialisation ────────────────────────────────────────────────

//   void _initVideo(CourseContent content) {
//     // Always update _currentContent so the video section re-evaluates
//     // whether to show the player or the locked overlay.
//     _currentContent = content;

//     final oldController = _videoController;
//     setState(() {
//       _videoController = null;
//       _videoInitialized = false;
//       _videoError = false;
//       _isVideoLoading = true;
//     });
//     oldController?.dispose();

//     final url =
//         (content.videoUrl != null && content.videoUrl!.isNotEmpty)
//             ? content.videoUrl!
//             : (content.videoFile != null && content.videoFile!.isNotEmpty)
//             ? content.videoFile!
//             : null;

//     if (url == null) {
//       setState(() {
//         _videoError = true;
//         _isVideoLoading = false;
//       });
//       return;
//     }

//     final controller = VideoPlayerController.networkUrl(Uri.parse(url));
//     controller
//         .initialize()
//         .then((_) {
//           if (!mounted) {
//             controller.dispose();
//             return;
//           }
//           setState(() {
//             _videoController = controller;
//             _videoInitialized = true;
//             _isVideoLoading = false;
//           });
//         })
//         .catchError((_) {
//           if (!mounted) {
//             controller.dispose();
//             return;
//           }
//           setState(() {
//             _videoError = true;
//             _isVideoLoading = false;
//           });
//         });
//   }

//   // ─── Enroll / Pay ────────────────────────────────────────────────────────

//   Future<void> _enroll() async {
//     final courseId = widget.course.id;
//     ref.read(enrollLoadingProvider(courseId).notifier).setLoading(true);

//     try {
//       if (widget.course.isFree) {
//         await ref.read(courseServiceProvider).enrollCourse(courseId);
//         await ref.refresh(enrollmentProvider.future);
//         ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
//         ref.read(elearningNotificationListProvider.notifier).refresh();

//         // Play the lesson the user was trying to watch, or first lesson.
//         final target =
//             _currentContent ??
//             (widget.course.contents.isNotEmpty
//                 ? widget.course.contents.first
//                 : null);
//         if (target != null) {
//           final idx = widget.course.contents.indexOf(target);
//           setState(() => _selectedIndex = idx < 0 ? 0 : idx);
//           _initVideo(target);
//         }

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Enrolled! Start learning now. 🎉'),
//               backgroundColor: const Color(0xFF10B981),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } else {
//         // PAID: open Khalti WebView
//         final result = await ref
//             .read(courseServiceProvider)
//             .initiatePayment(courseId);
//         ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);

//         final paymentUrl = result['payment_url'] as String?;
//         if (paymentUrl == null) {
//           _showErrorSnack('Could not initiate payment. Please try again.');
//           return;
//         }
//         if (!mounted) return;

//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => KhaltiWebViewScreen(paymentUrl: paymentUrl),
//           ),
//         );

//         if (mounted) _verifyAndUnlock();
//       }
//     } catch (e) {
//       ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
//     }
//   }

//   void _showErrorSnack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: Colors.redAccent,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   /// Bottom sheet shown when the user taps a locked (non-preview) lesson.
//   /// Stores the tapped lesson in _currentContent so after enrollment
//   /// that exact lesson is played.
//   void _showEnrollPrompt(CourseContent tappedContent) {
//     _currentContent = tappedContent;

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (_) {
//         final isLoading = ref.watch(enrollLoadingProvider(widget.course.id));
//         return Padding(
//           padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Handle bar
//               Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFF1F5F9),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   widget.course.isFree
//                       ? Icons.school_rounded
//                       : Icons.lock_outline,
//                   size: 32,
//                   color:
//                       widget.course.isFree
//                           ? const Color(0xFF10B981)
//                           : const Color(0xFF2563EB),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 widget.course.isFree
//                     ? 'Enroll to watch this lesson'
//                     : 'Unlock this lesson',
//                 style: const TextStyle(
//                   fontSize: 17,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1E293B),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 widget.course.isFree
//                     ? 'This course is free. Enroll now to access all lessons.'
//                     : 'Pay Rs. ${widget.course.price.toStringAsFixed(0)} to get full access to all lessons.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: Colors.grey.shade600,
//                   height: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: _EnrollButton(
//                   isFree: widget.course.isFree,
//                   isLoading: isLoading,
//                   onTap: () {
//                     Navigator.pop(context); // close sheet first
//                     _enroll();
//                   },
//                   fullWidth: true,
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ─── Build ───────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final enrolledIds = ref.watch(enrolledCoursesProvider);
//     final isEnrolled = enrolledIds.contains(widget.course.id);
//     final unreadCount = ref.watch(chatUnreadCountProvider);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: Stack(
//         children: [
//           NestedScrollView(
//             headerSliverBuilder:
//                 (context, _) => [
//                   SliverToBoxAdapter(child: _buildVideoSection(isEnrolled)),
//                   SliverToBoxAdapter(child: _buildTitleBar()),
//                 ],
//             body: TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildLessonsTab(isEnrolled),
//                 _buildDocsTab(isEnrolled),
//                 _buildAboutTab(isEnrolled),
//               ],
//             ),
//           ),

//           // Payment verification overlay
//           if (_isVerifyingPayment)
//             Container(
//               color: Colors.black.withAlpha(160),
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 32,
//                     vertical: 28,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const SizedBox(
//                         height: 40,
//                         width: 40,
//                         child: CircularProgressIndicator(
//                           color: Color(0xFF2563EB),
//                           strokeWidth: 3,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       const Text(
//                         'Verifying payment...',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1E293B),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         'Please wait while we confirm your enrollment.',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: CountBadgeFAB(
//         count: unreadCount,
//         gifAsset: 'animation/chaticon.gif',
//         backgroundColor: Colors.transparent,
//         onPressed: () {
//           ref.read(mutualFriendsProvider.notifier).refresh();
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const ChatListScreen()),
//           ).then((_) => ref.invalidate(mutualFriendsProvider));
//         },
//       ),
//     );
//   }

//   // ─── Title Bar ───────────────────────────────────────────────────────────

//   Widget _buildTitleBar() {
//     return Container(
//       color: Colors.white,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF5F7FA),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: const Color(0xFFE2E8F0)),
//                     ),
//                     child: const Icon(
//                       Icons.arrow_back_ios_new,
//                       size: 14,
//                       color: Color(0xFF1E293B),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     widget.course.title,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1E293B),
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 _CourseBadge(isFree: widget.course.isFree),
//               ],
//             ),
//           ),
//           TabBar(
//             controller: _tabController,
//             tabs: _tabs.map((t) => Tab(text: t)).toList(),
//             labelColor: Colors.black,
//             unselectedLabelColor: const Color(0xFF94A3B8),
//             indicatorColor: const Color.fromRGBO(244, 135, 6, 1),
//             indicatorWeight: 2.5,
//             labelStyle: const TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─── Video Section ───────────────────────────────────────────────────────

//   Widget _buildVideoSection(bool isEnrolled) {
//     final isLoading = ref.watch(enrollLoadingProvider(widget.course.id));

//     // The ONLY way to bypass the lock is:
//     //   1. User is enrolled, OR
//     //   2. The currently loaded content has isPreview == true
//     //
//     // A paid course with a preview lesson will show the video only for
//     // that lesson. All other lessons remain locked until payment.
//     final bool currentIsPreview = _currentContent?.isPreview == true;
//     final bool showVideo = isEnrolled || currentIsPreview;

//     double aspectRatio = 16 / 9;
//     if (_videoInitialized && _videoController != null) {
//       final size = _videoController!.value.size;
//       if (size.width > 0 && size.height > 0) {
//         aspectRatio = size.width / size.height;
//       }
//     }

//     return Container(
//       color: Colors.black,
//       width: double.infinity,
//       child: SafeArea(
//         bottom: false,
//         child: AspectRatio(
//           aspectRatio: aspectRatio,
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               // ── Main player area ──────────────────────────────────────
//               if (!showVideo)
//                 _LockedOverlay(course: widget.course)
//               else if (_isVideoLoading)
//                 _videoShimmer()
//               else if (_videoError)
//                 _videoErrorWidget()
//               else if (_videoInitialized && _videoController != null)
//                 _VideoPlayerWithControls(
//                   key: ValueKey(_videoController),
//                   controller: _videoController!,
//                   onFullscreen: _openFullscreen,
//                 )
//               else
//                 _videoShimmer(),

//               // ── Back button ───────────────────────────────────────────
//               Positioned(
//                 top: 10,
//                 left: 10,
//                 child: GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(7),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withAlpha(115),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.arrow_back,
//                       color: Colors.white,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//               ),

//               // ── Enroll button — only shown on locked overlay ───────────
//               if (!showVideo)
//                 Positioned(
//                   bottom: 14,
//                   child: _EnrollButton(
//                     isFree: widget.course.isFree,
//                     isLoading: isLoading,
//                     onTap: _enroll,
//                   ),
//                 ),

//               // ── PREVIEW chip — top-right when a preview is playing ─────
//               if (showVideo && currentIsPreview && !isEnrolled)
//                 Positioned(
//                   top: 10,
//                   right: 10,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF10B981),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: const Text(
//                       'PREVIEW',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 11,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _openFullscreen() {
//     if (!_videoInitialized || _videoController == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => _FullscreenVideoScreen(controller: _videoController!),
//       ),
//     );
//   }

//   Widget _videoShimmer() => Shimmer.fromColors(
//     baseColor: Colors.grey.shade800,
//     highlightColor: Colors.grey.shade700,
//     child: Container(color: Colors.grey.shade800),
//   );

//   Widget _videoErrorWidget() => Container(
//     color: Colors.grey.shade900,
//     child: const Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.videocam_off, color: Colors.white54, size: 36),
//           SizedBox(height: 8),
//           Text(
//             'Video unavailable',
//             style: TextStyle(color: Colors.white54, fontSize: 13),
//           ),
//         ],
//       ),
//     ),
//   );

//   // ─── Lessons Tab ─────────────────────────────────────────────────────────

//   Widget _buildLessonsTab(bool isEnrolled) {
//     final contents = widget.course.contents;
//     if (contents.isEmpty) return _emptyTab('No lessons available');

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: contents.length,
//       itemBuilder: (_, i) {
//         final c = contents[i];
//         final active = _selectedIndex == i;
//         final isPreview = c.isPreview == true;

//         return GestureDetector(
//           onTap: () {
//             if (isEnrolled) {
//               // Enrolled: tap any lesson → play it
//               setState(() => _selectedIndex = i);
//               _initVideo(c);
//               _tabController.animateTo(0);
//             } else if (isPreview) {
//               // Not enrolled + isPreview == true → play freely
//               setState(() => _selectedIndex = i);
//               _initVideo(c);
//               _tabController.animateTo(0);
//             } else {
//               // Not enrolled + isPreview == false → prompt enrollment
//               // Do NOT play. Do NOT change _selectedIndex.
//               _showEnrollPrompt(c);
//             }
//           },
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             margin: const EdgeInsets.only(bottom: 10),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color:
//                     active
//                         ? const Color.fromRGBO(244, 135, 6, 1)
//                         : Colors.transparent,
//                 width: 1.5,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withAlpha(8),
//                   blurRadius: 6,
//                   offset: const Offset(0, 1),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 // Thumbnail
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: SizedBox(
//                     width: 62,
//                     height: 46,
//                     child:
//                         c.thumbnail != null
//                             ? Image.network(
//                               c.thumbnail!,
//                               fit: BoxFit.cover,
//                               errorBuilder:
//                                   (_, __, ___) => _thumbPlaceholder(c.order),
//                             )
//                             : _thumbPlaceholder(c.order),
//                   ),
//                 ),
//                 const SizedBox(width: 12),

//                 // Title + meta row
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         c.title,
//                         style: const TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1E293B),
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 5),
//                       Row(
//                         children: [
//                           const Icon(
//                             Icons.timer_outlined,
//                             size: 11,
//                             color: Color(0xFF94A3B8),
//                           ),
//                           const SizedBox(width: 3),
//                           Text(
//                             '${c.duration.toStringAsFixed(0)} min',
//                             style: const TextStyle(
//                               fontSize: 11,
//                               color: Color(0xFF94A3B8),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFF5F7FA),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               c.courseLevel.toUpperCase(),
//                               style: const TextStyle(
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF64748B),
//                               ),
//                             ),
//                           ),
//                           // Green PREVIEW badge — only on preview lessons
//                           // when the user is not enrolled
//                           if (isPreview && !isEnrolled) ...[
//                             const SizedBox(width: 6),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 6,
//                                 vertical: 2,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFDCFCE7),
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: const Text(
//                                 'PREVIEW',
//                                 style: TextStyle(
//                                   fontSize: 9,
//                                   fontWeight: FontWeight.w700,
//                                   color: Color(0xFF10B981),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),

//                 // Right-side icon:
//                 // • enrolled or isPreview → play icon
//                 // • not enrolled + not preview → lock icon
//                 if (isEnrolled || isPreview)
//                   Icon(
//                     active
//                         ? Icons.pause_circle_filled
//                         : Icons.play_circle_outline,
//                     color:
//                         active
//                             ? const Color(0xFF2563EB)
//                             : const Color(0xFF94A3B8),
//                     size: 22,
//                   )
//                 else
//                   const Icon(
//                     Icons.lock_outline,
//                     size: 16,
//                     color: Color(0xFF94A3B8),
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _thumbPlaceholder(int order) => Container(
//     color: const Color(0xFFFEF3C7),
//     child: Center(
//       child: Text(
//         '$order',
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           color: Color(0xFFF59E0B),
//           fontSize: 16,
//         ),
//       ),
//     ),
//   );

//   // ─── Docs Tab ────────────────────────────────────────────────────────────

//   Widget _buildDocsTab(bool isEnrolled) {
//     final docs =
//         widget.course.contents
//             .where(
//               (c) =>
//                   (c.documentUrl != null && c.documentUrl!.isNotEmpty) ||
//                   (c.documentFile != null && c.documentFile!.isNotEmpty),
//             )
//             .toList();
//     if (docs.isEmpty) return _emptyTab('No documents available');
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: docs.length,
//       itemBuilder: (_, i) => _DocItem(content: docs[i], isEnrolled: isEnrolled),
//     );
//   }

//   // ─── About Tab ───────────────────────────────────────────────────────────

//   Widget _buildAboutTab(bool isEnrolled) {
//     final course = widget.course;
//     final instructor =
//         course.contents.isNotEmpty
//             ? course.contents.first.instructorName
//             : course.vendorName;
//     final isLoading = ref.watch(enrollLoadingProvider(course.id));

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _AboutCard(
//             icon: Icons.person_outline,
//             label: 'Instructor',
//             value: instructor,
//             iconColor: const Color(0xFF8B5CF6),
//           ),
//           const SizedBox(height: 10),
//            if (course.categoryName != null && course.categoryName!.isNotEmpty) ...[
//           _AboutCard(
//             icon: Icons.category_outlined,
//             label: 'Category',
//             value: course.categoryName!,
//             iconColor: const Color(0xFFF59E0B),
//           ),
//            ],
//           const SizedBox(height: 10),
//           _AboutCard(
//             icon: Icons.library_books_outlined,
//             label: 'Total Lessons',
//             value: '${course.contents.length} lessons',
//             iconColor: const Color(0xFF10B981),
//           ),
//           if (!course.isFree && !isEnrolled) ...[
//             const SizedBox(height: 10),
//             _AboutCard(
//               icon: Icons.sell_outlined,
//               label: 'Price',
//               value: 'Rs. ${course.price.toStringAsFixed(0)}',
//               iconColor: const Color(0xFF2563EB),
//             ),
//           ],
//           const SizedBox(height: 16),
//           const Text(
//             'About this Course',
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1E293B),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             course.description,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade700,
//               height: 1.65,
//             ),
//           ),
//           const SizedBox(height: 24),
//           if (!isEnrolled)
//             _EnrollButton(
//               isFree: course.isFree,
//               isLoading: isLoading,
//               onTap: _enroll,
//               fullWidth: true,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _emptyTab(String msg) => Center(
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
//         const SizedBox(height: 8),
//         Text(
//           msg,
//           style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
//         ),
//       ],
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Khalti WebView
// // ═══════════════════════════════════════════════════════════════════════════

// class KhaltiWebViewScreen extends StatefulWidget {
//   final String paymentUrl;
//   const KhaltiWebViewScreen({Key? key, required this.paymentUrl})
//     : super(key: key);

//   @override
//   State<KhaltiWebViewScreen> createState() => _KhaltiWebViewScreenState();
// }

// class _KhaltiWebViewScreenState extends State<KhaltiWebViewScreen> {
//   static const _khaltiPurple = Color(0xFF5C2D91);
//   late final WebViewController _controller;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _controller =
//         WebViewController()
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..setBackgroundColor(Colors.white)
//           ..setNavigationDelegate(
//             NavigationDelegate(
//               onPageStarted: (_) => setState(() => _isLoading = true),
//               onPageFinished: (_) => setState(() => _isLoading = false),
//               onNavigationRequest: (request) {
//                 final url = request.url;
//                 if (url.contains('payment-success') ||
//                     url.contains('payment-complete') ||
//                     url.contains('payment/success') ||
//                     url.contains('payment/failure') ||
//                     url.contains('payment/cancel') ||
//                     url.contains('khalti/callback') ||
//                     url.startsWith('innovator://')) {
//                   Navigator.pop(context);
//                   return NavigationDecision.prevent;
//                 }
//                 return NavigationDecision.navigate;
//               },
//             ),
//           )
//           ..loadRequest(Uri.parse(widget.paymentUrl));
//   }

//   Future<bool> _onWillPop() async {
//     if (await _controller.canGoBack()) {
//       _controller.goBack();
//       return false;
//     }
//     final exit = await _confirmLeave();
//     return exit ?? false;
//   }

//   Future<bool?> _confirmLeave() => showDialog<bool>(
//     context: context,
//     builder:
//         (_) => AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: const Text('Cancel Payment?'),
//           content: const Text(
//             'Are you sure you want to leave? Your payment will not be completed.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('Stay'),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context, true),
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//               child: const Text('Leave', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         ),
//   );

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: _khaltiPurple,
//           foregroundColor: Colors.white,
//           automaticallyImplyLeading: false,
//           title: Row(
//             children: [
//               Image.asset(
//                 'assets/icon/khalti_logo.png',
//                 height: 22,
//                 errorBuilder:
//                     (_, __, ___) => const Icon(
//                       Icons.account_balance_wallet,
//                       color: Colors.white,
//                       size: 22,
//                     ),
//               ),
//               const SizedBox(width: 10),
//               const Text(
//                 'Pay with Khalti',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
//               ),
//             ],
//           ),
//           actions: [
//             if (_isLoading)
//               const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 ),
//               )
//             else
//               GestureDetector(
//                 onTap: () async {
//                   final exit = await _confirmLeave();
//                   if (exit == true && context.mounted) Navigator.pop(context);
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.only(right: 12),
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withAlpha(30),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.white.withAlpha(60)),
//                   ),
//                   child: const Icon(Icons.close, size: 16, color: Colors.white),
//                 ),
//               ),
//           ],
//           bottom: PreferredSize(
//             preferredSize: const Size.fromHeight(1),
//             child: Container(height: 1, color: Colors.white.withAlpha(40)),
//           ),
//         ),
//         body: Stack(
//           children: [
//             WebViewWidget(controller: _controller),
//             if (_isLoading)
//               Container(
//                 color: Colors.white.withAlpha(220),
//                 child: const Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       CircularProgressIndicator(color: _khaltiPurple),
//                       SizedBox(height: 14),
//                       Text(
//                         'Loading Khalti...',
//                         style: TextStyle(color: _khaltiPurple),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Video Player With Controls
// // ═══════════════════════════════════════════════════════════════════════════

// class _VideoPlayerWithControls extends StatefulWidget {
//   final VideoPlayerController controller;
//   final VoidCallback onFullscreen;

//   const _VideoPlayerWithControls({
//     Key? key,
//     required this.controller,
//     required this.onFullscreen,
//   }) : super(key: key);

//   @override
//   State<_VideoPlayerWithControls> createState() =>
//       _VideoPlayerWithControlsState();
// }

// class _VideoPlayerWithControlsState extends State<_VideoPlayerWithControls> {
//   bool _showControls = true;
//   bool _isDragging = false;
//   static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
//   double _currentSpeed = 1.0;
//   DateTime _lastTap = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     _scheduleHide();
//   }

//   void _scheduleHide() {
//     Future.delayed(const Duration(seconds: 3), () {
//       if (!mounted) return;
//       final elapsed = DateTime.now().difference(_lastTap).inSeconds;
//       if (elapsed >= 3 && !_isDragging) {
//         setState(() => _showControls = false);
//       }
//     });
//   }

//   void _toggleControls() {
//     setState(() {
//       _showControls = !_showControls;
//       _lastTap = DateTime.now();
//     });
//     if (_showControls) _scheduleHide();
//   }

//   void _skip(int seconds) {
//     final ctrl = widget.controller;
//     final duration = ctrl.value.duration;
//     if (duration == Duration.zero) return;
//     final current = ctrl.value.position;
//     final target = current + Duration(seconds: seconds);
//     final clamped =
//         target < Duration.zero
//             ? Duration.zero
//             : (target > duration ? duration : target);
//     ctrl.seekTo(clamped);
//   }

//   String _formatDuration(Duration d) {
//     final h = d.inHours;
//     final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return h > 0 ? '$h:$m:$s' : '$m:$s';
//   }

//   void _setSpeed(double speed) {
//     setState(() => _currentSpeed = speed);
//     widget.controller.setPlaybackSpeed(speed);
//   }

//   void _showSpeedPicker() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1E293B),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder:
//           (_) => Padding(
//             padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Playback Speed',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ..._speeds.map((s) {
//                   final selected = s == _currentSpeed;
//                   return GestureDetector(
//                     onTap: () {
//                       _setSpeed(s);
//                       Navigator.pop(context);
//                     },
//                     child: Container(
//                       margin: const EdgeInsets.only(bottom: 8),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       decoration: BoxDecoration(
//                         color:
//                             selected
//                                 ? const Color(0xFF2563EB)
//                                 : Colors.white.withAlpha(20),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Row(
//                         children: [
//                           Text(
//                             s == 1.0 ? 'Normal (1x)' : '${s}x',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight:
//                                   selected
//                                       ? FontWeight.bold
//                                       : FontWeight.normal,
//                             ),
//                           ),
//                           const Spacer(),
//                           if (selected)
//                             const Icon(
//                               Icons.check,
//                               color: Colors.white,
//                               size: 18,
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _toggleControls,
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           // Video frame
//           ValueListenableBuilder<VideoPlayerValue>(
//             valueListenable: widget.controller,
//             builder: (_, value, __) {
//               final w = value.size.width > 0 ? value.size.width : 16.0;
//               final h = value.size.height > 0 ? value.size.height : 9.0;
//               return FittedBox(
//                 fit: BoxFit.cover,
//                 child: SizedBox(
//                   width: w,
//                   height: h,
//                   child: VideoPlayer(widget.controller),
//                 ),
//               );
//             },
//           ),

//           // Controls overlay
//           AnimatedOpacity(
//             opacity: _showControls ? 1.0 : 0.0,
//             duration: const Duration(milliseconds: 250),
//             child: IgnorePointer(
//               ignoring: !_showControls,
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.black.withAlpha(160),
//                       Colors.transparent,
//                       Colors.transparent,
//                       Colors.black.withAlpha(200),
//                     ],
//                     stops: const [0.0, 0.3, 0.6, 1.0],
//                   ),
//                 ),
//                 child: ValueListenableBuilder<VideoPlayerValue>(
//                   valueListenable: widget.controller,
//                   builder: (_, value, __) {
//                     final isPlaying = value.isPlaying;
//                     final position = value.position;
//                     final duration = value.duration;
//                     final progress =
//                         duration.inMilliseconds > 0
//                             ? (position.inMilliseconds /
//                                     duration.inMilliseconds)
//                                 .clamp(0.0, 1.0)
//                             : 0.0;

//                     return Stack(
//                       children: [
//                         // Top: speed + fullscreen
//                         Positioned(
//                           top: 8,
//                           right: 8,
//                           child: Row(
//                             children: [
//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () {
//                                   _lastTap = DateTime.now();
//                                   _showSpeedPicker();
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 10,
//                                     vertical: 5,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withAlpha(130),
//                                     borderRadius: BorderRadius.circular(6),
//                                     border: Border.all(
//                                       color: Colors.white.withAlpha(60),
//                                     ),
//                                   ),
//                                   child: Text(
//                                     _currentSpeed == 1.0
//                                         ? '1x'
//                                         : '${_currentSpeed}x',
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () {
//                                   _lastTap = DateTime.now();
//                                   widget.onFullscreen();
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(6),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withAlpha(130),
//                                     borderRadius: BorderRadius.circular(6),
//                                     border: Border.all(
//                                       color: Colors.white.withAlpha(60),
//                                     ),
//                                   ),
//                                   child: const Icon(
//                                     Icons.fullscreen,
//                                     color: Colors.white,
//                                     size: 18,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         // Centre: skip back | play/pause | skip forward
//                         Center(
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () {
//                                   _lastTap = DateTime.now();
//                                   _skip(-10);
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(10),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withAlpha(100),
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: const Icon(
//                                     Icons.replay_10,
//                                     color: Colors.white,
//                                     size: 28,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 24),
//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () {
//                                   _lastTap = DateTime.now();
//                                   isPlaying
//                                       ? widget.controller.pause()
//                                       : widget.controller.play();
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(14),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withAlpha(140),
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Colors.white.withAlpha(80),
//                                       width: 2,
//                                     ),
//                                   ),
//                                   child: Icon(
//                                     isPlaying
//                                         ? Icons.pause_rounded
//                                         : Icons.play_arrow_rounded,
//                                     color: Colors.white,
//                                     size: 36,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 24),
//                               GestureDetector(
//                                 behavior: HitTestBehavior.opaque,
//                                 onTap: () {
//                                   _lastTap = DateTime.now();
//                                   _skip(10);
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(10),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withAlpha(100),
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: const Icon(
//                                     Icons.forward_10,
//                                     color: Colors.white,
//                                     size: 28,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         // Bottom: time + seek bar
//                         Positioned(
//                           bottom: 0,
//                           left: 0,
//                           right: 0,
//                           child: Padding(
//                             padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Text(
//                                       _formatDuration(position),
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 11,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                     const Spacer(),
//                                     Text(
//                                       _formatDuration(duration),
//                                       style: TextStyle(
//                                         color: Colors.white.withAlpha(180),
//                                         fontSize: 11,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 4),
//                                 SliderTheme(
//                                   data: SliderTheme.of(context).copyWith(
//                                     trackHeight: 3,
//                                     thumbShape: const RoundSliderThumbShape(
//                                       enabledThumbRadius: 7,
//                                     ),
//                                     overlayShape: const RoundSliderOverlayShape(
//                                       overlayRadius: 14,
//                                     ),
//                                     activeTrackColor: const Color(0xFF2563EB),
//                                     inactiveTrackColor: Colors.white.withAlpha(
//                                       60,
//                                     ),
//                                     thumbColor: Colors.white,
//                                     overlayColor: Colors.white.withAlpha(40),
//                                   ),
//                                   child: Slider(
//                                     value: progress,
//                                     onChangeStart: (_) {
//                                       _isDragging = true;
//                                       _lastTap = DateTime.now();
//                                     },
//                                     onChanged: (v) {
//                                       if (duration == Duration.zero) return;
//                                       widget.controller.seekTo(
//                                         Duration(
//                                           milliseconds:
//                                               (v * duration.inMilliseconds)
//                                                   .toInt(),
//                                         ),
//                                       );
//                                     },
//                                     onChangeEnd: (_) {
//                                       _isDragging = false;
//                                       _scheduleHide();
//                                     },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Fullscreen Video Screen
// // ═══════════════════════════════════════════════════════════════════════════

// class _FullscreenVideoScreen extends StatefulWidget {
//   final VideoPlayerController controller;
//   const _FullscreenVideoScreen({required this.controller});

//   @override
//   State<_FullscreenVideoScreen> createState() => _FullscreenVideoScreenState();
// }

// class _FullscreenVideoScreenState extends State<_FullscreenVideoScreen> {
//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//   }

//   @override
//   void dispose() {
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) => Scaffold(
//     backgroundColor: Colors.black,
//     body: SafeArea(
//       child: _VideoPlayerWithControls(
//         key: ValueKey(widget.controller),
//         controller: widget.controller,
//         onFullscreen: () => Navigator.pop(context),
//       ),
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Locked Overlay
// // ═══════════════════════════════════════════════════════════════════════════

// class _LockedOverlay extends StatelessWidget {
//   final CourseListModel course;
//   const _LockedOverlay({required this.course});

//   @override
//   Widget build(BuildContext context) {
//     final thumb =
//         course.contents.isNotEmpty ? course.contents.first.thumbnail : null;
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         if (thumb != null)
//           Image.network(
//             thumb,
//             fit: BoxFit.cover,
//             errorBuilder:
//                 (_, __, ___) => Container(color: Colors.grey.shade900),
//           )
//         else
//           Container(color: Colors.grey.shade900),
//         Container(color: Colors.black.withAlpha(140)),
//         Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: Colors.white.withAlpha(38),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.lock_outline,
//                 color: Colors.white,
//                 size: 34,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               course.isFree
//                   ? 'Enroll for free to watch'
//                   : 'Pay to enroll and unlock',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Enroll Button
// // ═══════════════════════════════════════════════════════════════════════════

// class _EnrollButton extends StatelessWidget {
//   final bool isFree;
//   final bool isLoading;
//   final VoidCallback onTap;
//   final bool fullWidth;

//   const _EnrollButton({
//     required this.isFree,
//     required this.isLoading,
//     required this.onTap,
//     this.fullWidth = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final color = isFree ? const Color(0xFF10B981) : const Color(0xFF2563EB);
//     final label = isFree ? 'Enroll for Free' : 'Pay to Enroll';
//     final icon = isFree ? Icons.school_rounded : Icons.payment_rounded;

//     return GestureDetector(
//       onTap: isLoading ? null : onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: fullWidth ? double.infinity : null,
//         padding: EdgeInsets.symmetric(
//           horizontal: fullWidth ? 0 : 26,
//           vertical: 13,
//         ),
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(fullWidth ? 12 : 30),
//           boxShadow: [
//             BoxShadow(
//               color: color.withAlpha(90),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child:
//             isLoading
//                 ? const Center(
//                   child: SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   ),
//                 )
//                 : Row(
//                   mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(icon, color: Colors.white, size: 18),
//                     const SizedBox(width: 8),
//                     Text(
//                       label,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Course Badge
// // ═══════════════════════════════════════════════════════════════════════════

// class _CourseBadge extends StatelessWidget {
//   final bool isFree;
//   const _CourseBadge({required this.isFree});

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//     decoration: BoxDecoration(
//       color: const Color.fromRGBO(244, 135, 6, 1),
//       borderRadius: BorderRadius.circular(20),
//     ),
//     child: Text(
//       isFree ? 'Free' : 'Paid',
//       style: const TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w600,
//         color: Colors.white,
//       ),
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // Doc Item
// // ═══════════════════════════════════════════════════════════════════════════

// class _DocItem extends StatelessWidget {
//   final CourseContent content;
//   final bool isEnrolled;
//   const _DocItem({required this.content, required this.isEnrolled});

//   String? get _url => content.documentUrl ?? content.documentFile;

//   @override
//   Widget build(BuildContext context) => Container(
//     margin: const EdgeInsets.only(bottom: 10),
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withAlpha(8),
//           blurRadius: 6,
//           offset: const Offset(0, 1),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: const Color(0xFFFEF3C7),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: const Icon(
//             Icons.picture_as_pdf,
//             color: Color(0xFFF59E0B),
//             size: 22,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 content.title,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF1E293B),
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 3),
//               Text(
//                 'Lesson ${content.order} · Document',
//                 style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 8),
//         isEnrolled
//             ? GestureDetector(
//               onTap:
//                   _url != null
//                       ? () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (_) => _PdfViewScreen(
//                                 url: _url!,
//                                 title: content.title,
//                               ),
//                         ),
//                       )
//                       : null,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFEFF6FF),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'View',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2563EB),
//                   ),
//                 ),
//               ),
//             )
//             : const Icon(
//               Icons.lock_outline,
//               size: 16,
//               color: Color(0xFF94A3B8),
//             ),
//       ],
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // PDF Viewer Screen
// // ═══════════════════════════════════════════════════════════════════════════

// class _PdfViewScreen extends StatelessWidget {
//   final String url;
//   final String title;
//   const _PdfViewScreen({required this.url, required this.title});

//   @override
//   Widget build(BuildContext context) => Scaffold(
//     appBar: AppBar(
//       title: Text(
//         title,
//         style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//       ),
//       backgroundColor: Colors.white,
//       foregroundColor: const Color(0xFF1E293B),
//       elevation: 0,
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(1),
//         child: Container(height: 1, color: const Color(0xFFE2E8F0)),
//       ),
//     ),
//     body: SfPdfViewer.network(url),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════
// // About Card
// // ═══════════════════════════════════════════════════════════════════════════

// class _AboutCard extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final Color iconColor;

//   const _AboutCard({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.iconColor,
//   });

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withAlpha(8),
//           blurRadius: 6,
//           offset: const Offset(0, 1),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(9),
//           decoration: BoxDecoration(
//             color: iconColor.withAlpha(25),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: iconColor, size: 20),
//         ),
//         const SizedBox(width: 12),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
//             ),
//             const SizedBox(height: 3),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
// import 'package:innovator/Innovator/widget/CustomizeFAB.dart';
// import 'package:innovator/elearning/model/course_list_model.dart';
// import 'package:innovator/elearning/provider/course_provider.dart';
// import 'package:innovator/elearning/provider/notificationProvider.dart';
// import 'package:video_player/video_player.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class CourseDetailScreen extends ConsumerStatefulWidget {
//   final CourseListModel course;
//   const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

//   @override
//   ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
// }

// class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   VideoPlayerController? _videoController;

//   bool _videoInitialized = false;
//   bool _videoError = false;
//   bool _isVideoLoading = false;
//   int _selectedIndex = 0;
//   bool _videoStarted = false;

//   bool _isVerifyingPayment = false;

//   static const List<String> _tabs = ['Lessons', 'Docs', 'About'];

//   @override
//   void initState() {
//     super.initState();
//     ref.refresh(elearningUnreadCountProvider);
//     ref.refresh(elearningNotificationListProvider);
//     _tabController = TabController(length: _tabs.length, vsync: this);
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await ref.refresh(enrollmentProvider.future);
//       _maybeStartVideo();
//     });
//   }

//   /// Silently refreshes enrollment; if now enrolled → auto-play video.
//   Future<void> _verifyAndUnlock() async {
//     if (!mounted) return;
//     setState(() => _isVerifyingPayment = true);

//     try {
//       await ref.refresh(enrollmentProvider.future);
//       if (!mounted) return;

//       final isNowEnrolled = ref
//           .read(enrolledCoursesProvider)
//           .contains(widget.course.id);

//       if (isNowEnrolled) {
//         setState(() => _isVerifyingPayment = false);
//         ref.read(elearningNotificationListProvider.notifier).refresh();
//         _videoStarted = true;
//         if (widget.course.contents.isNotEmpty) {
//           _initVideo(widget.course.contents.first);
//         }
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Payment verified! Start learning now. 🎉'),
//               backgroundColor: const Color(0xFF10B981),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } else {
//         setState(() => _isVerifyingPayment = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text(
//                 'Payment is being processed. Please wait a moment.',
//               ),
//               backgroundColor: Colors.orange,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       }
//     } catch (_) {
//       if (mounted) setState(() => _isVerifyingPayment = false);
//     }
//   }

//   void _maybeStartVideo() {
//     if (_videoStarted || !mounted) return;
//     final enrolled = ref
//         .read(enrolledCoursesProvider)
//         .contains(widget.course.id);
//     if (enrolled && widget.course.contents.isNotEmpty) {
//       _videoStarted = true;
//       _initVideo(widget.course.contents.first);
//     }
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _videoController?.dispose();
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     super.dispose();
//   }

//   // Video Init

//   void _initVideo(CourseContent content) {
//     final oldController = _videoController;

//     setState(() {
//       _videoController = null;
//       _videoInitialized = false;
//       _videoError = false;
//       _isVideoLoading = true;
//     });

//     oldController?.dispose();

//     final url =
//         (content.videoUrl != null && content.videoUrl!.isNotEmpty)
//             ? content.videoUrl!
//             : (content.videoFile != null && content.videoFile!.isNotEmpty)
//             ? content.videoFile!
//             : null;

//     if (url == null) {
//       setState(() {
//         _videoError = true;
//         _isVideoLoading = false;
//       });
//       return;
//     }

//     final controller = VideoPlayerController.networkUrl(Uri.parse(url));
//     controller
//         .initialize()
//         .then((_) {
//           if (!mounted) {
//             controller.dispose();
//             return;
//           }
//           setState(() {
//             _videoController = controller;
//             _videoInitialized = true;
//             _isVideoLoading = false;
//           });
//         })
//         .catchError((_) {
//           if (!mounted) {
//             controller.dispose();
//             return;
//           }
//           setState(() {
//             _videoError = true;
//             _isVideoLoading = false;
//           });
//         });
//   }

//   Future<void> _enroll() async {
//     final courseId = widget.course.id;
//     ref.read(enrollLoadingProvider(courseId).notifier).setLoading(true);

//     try {
//       if (widget.course.isFree) {
//         await ref.read(courseServiceProvider).enrollCourse(courseId);
//         await ref.refresh(enrollmentProvider.future);
//         ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
//         ref.read(elearningNotificationListProvider.notifier).refresh();

//         _videoStarted = true;
//         if (widget.course.contents.isNotEmpty) {
//           _initVideo(widget.course.contents.first);
//         }
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Enrolled! Start learning now. 🎉'),
//               backgroundColor: const Color(0xFF10B981),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } else {
//         // PAID: open Khalti WebView inside the app
//         final result = await ref
//             .read(courseServiceProvider)
//             .initiatePayment(courseId);
//         ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);

//         final paymentUrl = result['payment_url'] as String?;
//         if (paymentUrl == null) {
//           _showErrorSnack('Could not initiate payment. Please try again.');
//           return;
//         }

//         if (!mounted) return;

//         // Open payment WebView and wait for user to return
//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => KhaltiWebViewScreen(paymentUrl: paymentUrl),
//           ),
//         );

//         // Always verify enrollment when user returns (paid or cancelled)
//         if (mounted) _verifyAndUnlock();
//       }
//     } catch (e) {
//       ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
//     }
//   }

//   void _showErrorSnack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: Colors.redAccent,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final enrolledIds = ref.watch(enrolledCoursesProvider);
//     final isEnrolled = enrolledIds.contains(widget.course.id);
//     final unreadCount = ref.watch(chatUnreadCountProvider);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: Stack(
//         children: [
//           NestedScrollView(
//             headerSliverBuilder:
//                 (context, innerBoxIsScrolled) => [
//                   SliverToBoxAdapter(child: _buildVideoSection(isEnrolled)),
//                   SliverToBoxAdapter(child: _buildTitleBar()),
//                 ],
//             body: TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildLessonsTab(isEnrolled),
//                 _buildDocsTab(isEnrolled),
//                 _buildAboutTab(isEnrolled),
//               ],
//             ),
//           ),

//           // Payment verification overlay
//           if (_isVerifyingPayment)
//             Container(
//               color: Colors.black.withAlpha(160),
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 32,
//                     vertical: 28,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const SizedBox(
//                         height: 40,
//                         width: 40,
//                         child: CircularProgressIndicator(
//                           color: Color(0xFF2563EB),
//                           strokeWidth: 3,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       const Text(
//                         'Verifying payment...',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1E293B),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         'Please wait while we confirm your enrollment.',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: CountBadgeFAB(
//         count: unreadCount,
//         gifAsset: 'animation/chaticon.gif',
//         backgroundColor: Colors.transparent,
//         onPressed: () {
//           ref.read(mutualFriendsProvider.notifier).refresh();
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const ChatListScreen()),
//           ).then((_) {
//             ref.invalidate(mutualFriendsProvider);
//           });
//         },
//       ),
//     );
//   }

//   // Title Bar

//   Widget _buildTitleBar() {
//     return Container(
//       color: Colors.white,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF5F7FA),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: const Color(0xFFE2E8F0)),
//                     ),
//                     child: const Icon(
//                       Icons.arrow_back_ios_new,
//                       size: 14,
//                       color: Color(0xFF1E293B),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     widget.course.title,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1E293B),
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 _CourseBadge(isFree: widget.course.isFree),
//               ],
//             ),
//           ),
//           TabBar(
//             controller: _tabController,
//             tabs: _tabs.map((t) => Tab(text: t)).toList(),
//             labelColor: Colors.black,
//             unselectedLabelColor: const Color(0xFF94A3B8),
//             indicatorColor: const Color.fromRGBO(244, 135, 6, 1),
//             indicatorWeight: 2.5,
//             labelStyle: const TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Video Section

//   Widget _buildVideoSection(bool isEnrolled) {
//     final isLoading = ref.watch(enrollLoadingProvider(widget.course.id));

//     double aspectRatio = 16 / 9;
//     if (_videoInitialized && _videoController != null) {
//       final size = _videoController!.value.size;
//       if (size.width > 0 && size.height > 0) {
//         aspectRatio = size.width / size.height;
//       }
//     }
//     return Container(
//       color: Colors.black,
//       width: double.infinity,
//       child: SafeArea(
//         bottom: false,
//         child: AspectRatio(
//           // aspectRatio: 16 / 9,
//           aspectRatio: aspectRatio,
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               if (!isEnrolled)
//                 _LockedOverlay(course: widget.course)
//               else if (_isVideoLoading)
//                 _videoShimmer()
//               else if (_videoError)
//                 _videoErrorWidget()
//               else if (_videoInitialized && _videoController != null)
//                 _VideoPlayerWithControls(
//                   key: ValueKey(_videoController),
//                   controller: _videoController!,
//                   onFullscreen: _openFullscreen,
//                 )
//               else
//                 _videoShimmer(),

//               // Back button
//               Positioned(
//                 top: 10,
//                 left: 10,
//                 child: GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(7),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withAlpha(115),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.arrow_back,
//                       color: Colors.white,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//               ),

//               if (!isEnrolled)
//                 Positioned(
//                   bottom: 14,
//                   child: _EnrollButton(
//                     isFree: widget.course.isFree,
//                     isLoading: isLoading,
//                     onTap: _enroll,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _openFullscreen() {
//     if (!_videoInitialized || _videoController == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => _FullscreenVideoScreen(controller: _videoController!),
//       ),
//     );
//   }

//   Widget _videoShimmer() => Shimmer.fromColors(
//     baseColor: Colors.grey.shade800,
//     highlightColor: Colors.grey.shade700,
//     child: Container(color: Colors.grey.shade800),
//   );

//   Widget _videoErrorWidget() => Container(
//     color: Colors.grey.shade900,
//     child: const Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.videocam_off, color: Colors.white54, size: 36),
//           SizedBox(height: 8),
//           Text(
//             'Video unavailable',
//             style: TextStyle(color: Colors.white54, fontSize: 13),
//           ),
//         ],
//       ),
//     ),
//   );

//   // Lessons Tab

//   Widget _buildLessonsTab(bool isEnrolled) {
//     final contents = widget.course.contents;
//     if (contents.isEmpty) return _emptyTab('No lessons available');

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: contents.length,
//       itemBuilder: (_, i) {
//         final c = contents[i];
//         final active = _selectedIndex == i;
//         return GestureDetector(
//           onTap:
//               isEnrolled
//                   ? () {
//                     setState(() => _selectedIndex = i);
//                     _initVideo(c);
//                     _tabController.animateTo(0);
//                   }
//                   : null,
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             margin: const EdgeInsets.only(bottom: 10),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color:
//                     active
//                         ? const Color.fromRGBO(244, 135, 6, 1)
//                         : Colors.transparent,
//                 width: 1.5,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withAlpha(8),
//                   blurRadius: 6,
//                   offset: const Offset(0, 1),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: SizedBox(
//                     width: 62,
//                     height: 46,
//                     child:
//                         c.thumbnail != null
//                             ? Image.network(
//                               c.thumbnail!,
//                               fit: BoxFit.cover,
//                               errorBuilder:
//                                   (_, __, ___) => _thumbPlaceholder(c.order),
//                             )
//                             : _thumbPlaceholder(c.order),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         c.title,
//                         style: const TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1E293B),
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 5),
//                       Row(
//                         children: [
//                           const Icon(
//                             Icons.timer_outlined,
//                             size: 11,
//                             color: Color(0xFF94A3B8),
//                           ),
//                           const SizedBox(width: 3),
//                           Text(
//                             '${c.duration.toStringAsFixed(0)} min',
//                             style: const TextStyle(
//                               fontSize: 11,
//                               color: Color(0xFF94A3B8),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFF5F7FA),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               c.courseLevel.toUpperCase(),
//                               style: const TextStyle(
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF64748B),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 isEnrolled
//                     ? Icon(
//                       active
//                           ? Icons.pause_circle_filled
//                           : Icons.play_circle_outline,
//                       color:
//                           active
//                               ? const Color(0xFF2563EB)
//                               : const Color(0xFF94A3B8),
//                       size: 22,
//                     )
//                     : const Icon(
//                       Icons.lock_outline,
//                       size: 16,
//                       color: Color(0xFF94A3B8),
//                     ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _thumbPlaceholder(int order) => Container(
//     color: const Color(0xFFFEF3C7),
//     child: Center(
//       child: Text(
//         '$order',
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           color: Color(0xFFF59E0B),
//           fontSize: 16,
//         ),
//       ),
//     ),
//   );

//   // Docs Tab

//   Widget _buildDocsTab(bool isEnrolled) {
//     final docs =
//         widget.course.contents
//             .where(
//               (c) =>
//                   (c.documentUrl != null && c.documentUrl!.isNotEmpty) ||
//                   (c.documentFile != null && c.documentFile!.isNotEmpty),
//             )
//             .toList();
//     if (docs.isEmpty) return _emptyTab('No documents available');
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: docs.length,
//       itemBuilder: (_, i) => _DocItem(content: docs[i], isEnrolled: isEnrolled),
//     );
//   }

//   // About Tab

//   Widget _buildAboutTab(bool isEnrolled) {
//     final course = widget.course;
//     final instructor =
//         course.contents.isNotEmpty
//             ? course.contents.first.instructorName
//             : course.vendorName;
//     final isLoading = ref.watch(enrollLoadingProvider(course.id));

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _AboutCard(
//             icon: Icons.person_outline,
//             label: 'Instructor',
//             value: instructor,
//             iconColor: const Color(0xFF8B5CF6),
//           ),
//           const SizedBox(height: 10),
//           _AboutCard(
//             icon: Icons.category_outlined,
//             label: 'Category',
//             value: course.categoryName,
//             iconColor: const Color(0xFFF59E0B),
//           ),
//           const SizedBox(height: 10),
//           _AboutCard(
//             icon: Icons.library_books_outlined,
//             label: 'Total Lessons',
//             value: '${course.contents.length} lessons',
//             iconColor: const Color(0xFF10B981),
//           ),
//           if (!course.isFree && !isEnrolled) ...[
//             const SizedBox(height: 10),
//             _AboutCard(
//               icon: Icons.sell_outlined,
//               label: 'Price',
//               value: 'Rs. ${course.price.toStringAsFixed(0)}',
//               iconColor: const Color(0xFF2563EB),
//             ),
//           ],
//           const SizedBox(height: 16),
//           const Text(
//             'About this Course',
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1E293B),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             course.description,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade700,
//               height: 1.65,
//             ),
//           ),
//           const SizedBox(height: 24),
//           if (!isEnrolled)
//             _EnrollButton(
//               isFree: course.isFree,
//               isLoading: isLoading,
//               onTap: _enroll,
//               fullWidth: true,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _emptyTab(String msg) => Center(
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
//         const SizedBox(height: 8),
//         Text(
//           msg,
//           style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
//         ),
//       ],
//     ),
//   );
// }

// class KhaltiWebViewScreen extends StatefulWidget {
//   final String paymentUrl;

//   const KhaltiWebViewScreen({Key? key, required this.paymentUrl})
//     : super(key: key);

//   @override
//   State<KhaltiWebViewScreen> createState() => _KhaltiWebViewScreenState();
// }

// class _KhaltiWebViewScreenState extends State<KhaltiWebViewScreen> {
//   static const _khaltiPurple = Color(0xFF5C2D91);

//   late final WebViewController _controller;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _controller =
//         WebViewController()
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..setBackgroundColor(Colors.white)
//           ..setNavigationDelegate(
//             NavigationDelegate(
//               onPageStarted: (_) => setState(() => _isLoading = true),
//               onPageFinished: (_) => setState(() => _isLoading = false),
//               onNavigationRequest: (request) {
//                 final url = request.url;
//                 if (url.contains('payment-success') ||
//                     url.contains('payment-complete') ||
//                     url.contains('payment/success') ||
//                     url.contains('payment/failure') ||
//                     url.contains('payment/cancel') ||
//                     url.contains('khalti/callback') ||
//                     url.startsWith('innovator://')) {
//                   Navigator.pop(context);
//                   return NavigationDecision.prevent;
//                 }
//                 return NavigationDecision.navigate;
//               },
//             ),
//           )
//           ..loadRequest(Uri.parse(widget.paymentUrl));
//   }

//   Future<bool> _onWillPop() async {
//     if (await _controller.canGoBack()) {
//       _controller.goBack();
//       return false;
//     }
//     final exit = await showDialog<bool>(
//       context: context,
//       builder:
//           (_) => AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             title: const Text('Cancel Payment?'),
//             content: const Text(
//               'Are you sure you want to leave? Your payment will not be completed.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: const Text('Stay'),
//               ),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                 child: const Text(
//                   'Leave',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//     );
//     return exit ?? false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: _khaltiPurple,
//           foregroundColor: Colors.white,
//           automaticallyImplyLeading: false,
//           title: Row(
//             children: [
//               Image.asset(
//                 'assets/icon/khalti_logo.png',
//                 height: 22,
//                 errorBuilder:
//                     (_, __, ___) => const Icon(
//                       Icons.account_balance_wallet,
//                       color: Colors.white,
//                       size: 22,
//                     ),
//               ),
//               const SizedBox(width: 10),
//               const Text(
//                 'Pay with Khalti',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
//               ),
//             ],
//           ),
//           actions: [
//             if (_isLoading)
//               const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 ),
//               )
//             else
//               GestureDetector(
//                 onTap: () async {
//                   final exit = await showDialog<bool>(
//                     context: context,
//                     builder:
//                         (_) => AlertDialog(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           title: const Text('Cancel Payment?'),
//                           content: const Text(
//                             'Are you sure you want to leave? Your payment will not be completed.',
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.pop(context, false),
//                               child: const Text('Stay'),
//                             ),
//                             ElevatedButton(
//                               onPressed: () => Navigator.pop(context, true),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.red,
//                               ),
//                               child: const Text(
//                                 'Leave',
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             ),
//                           ],
//                         ),
//                   );
//                   if (exit == true && context.mounted) Navigator.pop(context);
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.only(right: 12),
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withAlpha(30),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.white.withAlpha(60)),
//                   ),
//                   child: const Icon(Icons.close, size: 16, color: Colors.white),
//                 ),
//               ),
//           ],
//           bottom: PreferredSize(
//             preferredSize: const Size.fromHeight(1),
//             child: Container(height: 1, color: Colors.white.withAlpha(40)),
//           ),
//         ),
//         body: Stack(
//           children: [
//             WebViewWidget(controller: _controller),
//             if (_isLoading)
//               Container(
//                 color: Colors.white.withAlpha(220),
//                 child: const Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       CircularProgressIndicator(color: _khaltiPurple),
//                       SizedBox(height: 14),
//                       Text(
//                         'Loading Khalti...',
//                         style: TextStyle(color: _khaltiPurple),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Video Player With Controls

// class _VideoPlayerWithControls extends StatefulWidget {
//   final VideoPlayerController controller;
//   final VoidCallback onFullscreen;

//   const _VideoPlayerWithControls({
//     Key? key,
//     required this.controller,
//     required this.onFullscreen,
//   }) : super(key: key);

//   @override
//   State<_VideoPlayerWithControls> createState() =>
//       _VideoPlayerWithControlsState();
// }

// class _VideoPlayerWithControlsState extends State<_VideoPlayerWithControls> {
//   bool _showControls = true;
//   bool _isDragging = false;

//   static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
//   double _currentSpeed = 1.0;
//   DateTime _lastTap = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     _scheduleHide();
//   }

//   void _scheduleHide() {
//     Future.delayed(const Duration(seconds: 3), () {
//       if (!mounted) return;
//       final elapsed = DateTime.now().difference(_lastTap).inSeconds;
//       if (elapsed >= 3 && !_isDragging) {
//         setState(() => _showControls = false);
//       }
//     });
//   }

//   void _toggleControls() {
//     setState(() {
//       _showControls = !_showControls;
//       _lastTap = DateTime.now();
//     });
//     if (_showControls) _scheduleHide();
//   }

//   void _skip(int seconds) {
//     final ctrl = widget.controller;
//     final duration = ctrl.value.duration;
//     if (duration == Duration.zero) return;
//     final current = ctrl.value.position;
//     final target = current + Duration(seconds: seconds);
//     final clamped =
//         target < Duration.zero
//             ? Duration.zero
//             : (target > duration ? duration : target);
//     ctrl.seekTo(clamped);
//   }

//   String _formatDuration(Duration d) {
//     final h = d.inHours;
//     final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return h > 0 ? '$h:$m:$s' : '$m:$s';
//   }

//   void _setSpeed(double speed) {
//     setState(() => _currentSpeed = speed);
//     widget.controller.setPlaybackSpeed(speed);
//   }

//   void _showSpeedPicker() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1E293B),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder:
//           (_) => Padding(
//             padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Playback Speed',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ..._speeds.map((s) {
//                   final selected = s == _currentSpeed;
//                   return GestureDetector(
//                     onTap: () {
//                       _setSpeed(s);
//                       Navigator.pop(context);
//                     },
//                     child: Container(
//                       margin: const EdgeInsets.only(bottom: 8),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       decoration: BoxDecoration(
//                         color:
//                             selected
//                                 ? const Color(0xFF2563EB)
//                                 : Colors.white.withAlpha(20),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Row(
//                         children: [
//                           Text(
//                             s == 1.0 ? 'Normal (1x)' : '${s}x',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight:
//                                   selected
//                                       ? FontWeight.bold
//                                       : FontWeight.normal,
//                             ),
//                           ),
//                           const Spacer(),
//                           if (selected)
//                             const Icon(
//                               Icons.check,
//                               color: Colors.white,
//                               size: 18,
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _toggleControls,
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           // Video
//           ValueListenableBuilder<VideoPlayerValue>(
//             valueListenable: widget.controller,
//             builder: (_, value, __) {
//               final w = value.size.width > 0 ? value.size.width : 16.0;
//               final h = value.size.height > 0 ? value.size.height : 9.0;
//               return FittedBox(
//                 fit: BoxFit.cover,
//                 child: SizedBox(
//                   width: w,
//                   height: h,
//                   child: VideoPlayer(widget.controller),
//                 ),
//               );
//             },
//           ),

//           // Controls overlay
//           AnimatedOpacity(
//             opacity: _showControls ? 1.0 : 0.0,
//             duration: const Duration(milliseconds: 250),
//             child: IgnorePointer(
//               ignoring: !_showControls,
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.black.withAlpha(160),
//                       Colors.transparent,
//                       Colors.transparent,
//                       Colors.black.withAlpha(200),
//                     ],
//                     stops: const [0.0, 0.3, 0.6, 1.0],
//                   ),
//                 ),
//                 child: ValueListenableBuilder<VideoPlayerValue>(
//                   valueListenable: widget.controller,
//                   builder: (_, value, __) {
//                     final isPlaying = value.isPlaying;
//                     final position = value.position;
//                     final duration = value.duration;
//                     final progress =
//                         duration.inMilliseconds > 0
//                             ? (position.inMilliseconds /
//                                     duration.inMilliseconds)
//                                 .clamp(0.0, 1.0)
//                             : 0.0;

//                     return Stack(
//                       children: [
//                         // Top: speed + fullscreen
//                         Positioned(
//                           top: 8,
//                           right: 8,
//                           child: GestureDetector(
//                             behavior: HitTestBehavior.opaque,
//                             onTap: () {},
//                             child: Row(
//                               children: [
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     _showSpeedPicker();
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 10,
//                                       vertical: 5,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(130),
//                                       borderRadius: BorderRadius.circular(6),
//                                       border: Border.all(
//                                         color: Colors.white.withAlpha(60),
//                                       ),
//                                     ),
//                                     child: Text(
//                                       _currentSpeed == 1.0
//                                           ? '1x'
//                                           : '${_currentSpeed}x',
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     widget.onFullscreen();
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(6),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(130),
//                                       borderRadius: BorderRadius.circular(6),
//                                       border: Border.all(
//                                         color: Colors.white.withAlpha(60),
//                                       ),
//                                     ),
//                                     child: const Icon(
//                                       Icons.fullscreen,
//                                       color: Colors.white,
//                                       size: 18,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                         // Centre: skip back | play/pause | skip forward
//                         Center(
//                           child: GestureDetector(
//                             behavior: HitTestBehavior.opaque,
//                             onTap: () {},
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     _skip(-10);
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(10),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(100),
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(
//                                       Icons.replay_10,
//                                       color: Colors.white,
//                                       size: 28,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 24),
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     isPlaying
//                                         ? widget.controller.pause()
//                                         : widget.controller.play();
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(14),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(140),
//                                       shape: BoxShape.circle,
//                                       border: Border.all(
//                                         color: Colors.white.withAlpha(80),
//                                         width: 2,
//                                       ),
//                                     ),
//                                     child: Icon(
//                                       isPlaying
//                                           ? Icons.pause_rounded
//                                           : Icons.play_arrow_rounded,
//                                       color: Colors.white,
//                                       size: 36,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 24),
//                                 GestureDetector(
//                                   behavior: HitTestBehavior.opaque,
//                                   onTap: () {
//                                     _lastTap = DateTime.now();
//                                     _skip(10);
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(10),
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withAlpha(100),
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(
//                                       Icons.forward_10,
//                                       color: Colors.white,
//                                       size: 28,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                         // Bottom: time + seek bar
//                         Positioned(
//                           bottom: 0,
//                           left: 0,
//                           right: 0,
//                           child: GestureDetector(
//                             behavior: HitTestBehavior.opaque,
//                             onTap: () {},
//                             child: Padding(
//                               padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       Text(
//                                         _formatDuration(position),
//                                         style: const TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 11,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                       const Spacer(),
//                                       Text(
//                                         _formatDuration(duration),
//                                         style: TextStyle(
//                                           color: Colors.white.withAlpha(180),
//                                           fontSize: 11,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 4),
//                                   SliderTheme(
//                                     data: SliderTheme.of(context).copyWith(
//                                       trackHeight: 3,
//                                       thumbShape: const RoundSliderThumbShape(
//                                         enabledThumbRadius: 7,
//                                       ),
//                                       overlayShape:
//                                           const RoundSliderOverlayShape(
//                                             overlayRadius: 14,
//                                           ),
//                                       activeTrackColor: const Color(0xFF2563EB),
//                                       inactiveTrackColor: Colors.white
//                                           .withAlpha(60),
//                                       thumbColor: Colors.white,
//                                       overlayColor: Colors.white.withAlpha(40),
//                                     ),
//                                     child: Slider(
//                                       value: progress,
//                                       onChangeStart: (_) {
//                                         _isDragging = true;
//                                         _lastTap = DateTime.now();
//                                       },
//                                       onChanged: (v) {
//                                         if (duration == Duration.zero) return;
//                                         widget.controller.seekTo(
//                                           Duration(
//                                             milliseconds:
//                                                 (v * duration.inMilliseconds)
//                                                     .toInt(),
//                                           ),
//                                         );
//                                       },
//                                       onChangeEnd: (_) {
//                                         _isDragging = false;
//                                         _scheduleHide();
//                                       },
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Fullscreen Video Screen

// class _FullscreenVideoScreen extends StatefulWidget {
//   final VideoPlayerController controller;
//   const _FullscreenVideoScreen({required this.controller});

//   @override
//   State<_FullscreenVideoScreen> createState() => _FullscreenVideoScreenState();
// }

// class _FullscreenVideoScreenState extends State<_FullscreenVideoScreen> {
//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//   }

//   @override
//   void dispose() {
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: _VideoPlayerWithControls(
//           key: ValueKey(widget.controller),
//           controller: widget.controller,
//           onFullscreen: () => Navigator.pop(context),
//         ),
//       ),
//     );
//   }
// }

// // Locked Overlay

// class _LockedOverlay extends StatelessWidget {
//   final CourseListModel course;
//   const _LockedOverlay({required this.course});

//   @override
//   Widget build(BuildContext context) {
//     final thumb =
//         course.contents.isNotEmpty ? course.contents.first.thumbnail : null;
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         if (thumb != null)
//           Image.network(
//             thumb,
//             fit: BoxFit.cover,
//             errorBuilder:
//                 (_, __, ___) => Container(color: Colors.grey.shade900),
//           )
//         else
//           Container(color: Colors.grey.shade900),
//         Container(color: Colors.black.withAlpha(140)),
//         Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: Colors.white.withAlpha(38),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.lock_outline,
//                 color: Colors.white,
//                 size: 34,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               course.isFree
//                   ? 'Enroll for free to watch'
//                   : 'Pay to enroll and unlock',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// // Enroll Button

// class _EnrollButton extends StatelessWidget {
//   final bool isFree;
//   final bool isLoading;
//   final VoidCallback onTap;
//   final bool fullWidth;

//   const _EnrollButton({
//     required this.isFree,
//     required this.isLoading,
//     required this.onTap,
//     this.fullWidth = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final color = isFree ? const Color(0xFF10B981) : const Color(0xFF2563EB);
//     final label = isFree ? 'Enroll for Free' : 'Pay to Enroll';
//     final icon = isFree ? Icons.school_rounded : Icons.payment_rounded;

//     return GestureDetector(
//       onTap: isLoading ? null : onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: fullWidth ? double.infinity : null,
//         padding: EdgeInsets.symmetric(
//           horizontal: fullWidth ? 0 : 26,
//           vertical: 13,
//         ),
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(fullWidth ? 12 : 30),
//           boxShadow: [
//             BoxShadow(
//               color: color.withAlpha(90),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child:
//             isLoading
//                 ? const Center(
//                   child: SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   ),
//                 )
//                 : Row(
//                   mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(icon, color: Colors.white, size: 18),
//                     const SizedBox(width: 8),
//                     Text(
//                       label,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//       ),
//     );
//   }
// }

// // Course Badge

// class _CourseBadge extends StatelessWidget {
//   final bool isFree;
//   const _CourseBadge({required this.isFree});

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//     decoration: BoxDecoration(
//       color: const Color.fromRGBO(244, 135, 6, 1),
//       borderRadius: BorderRadius.circular(20),
//     ),
//     child: Text(
//       isFree ? 'Free' : 'Paid',
//       style: const TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w600,
//         color: Colors.white,
//       ),
//     ),
//   );
// }

// // Doc Item

// class _DocItem extends StatelessWidget {
//   final CourseContent content;
//   final bool isEnrolled;
//   const _DocItem({required this.content, required this.isEnrolled});

//   String? get _url => content.documentUrl ?? content.documentFile;

//   @override
//   Widget build(BuildContext context) => Container(
//     margin: const EdgeInsets.only(bottom: 10),
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withAlpha(8),
//           blurRadius: 6,
//           offset: const Offset(0, 1),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: const Color(0xFFFEF3C7),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: const Icon(
//             Icons.picture_as_pdf,
//             color: Color(0xFFF59E0B),
//             size: 22,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 content.title,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF1E293B),
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 3),
//               Text(
//                 'Lesson ${content.order} · Document',
//                 style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 8),
//         isEnrolled
//             ? GestureDetector(
//               onTap:
//                   _url != null
//                       ? () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (_) => _PdfViewScreen(
//                                 url: _url!,
//                                 title: content.title,
//                               ),
//                         ),
//                       )
//                       : null,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFEFF6FF),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'View',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2563EB),
//                   ),
//                 ),
//               ),
//             )
//             : const Icon(
//               Icons.lock_outline,
//               size: 16,
//               color: Color(0xFF94A3B8),
//             ),
//       ],
//     ),
//   );
// }

// // PDF Viewer

// class _PdfViewScreen extends StatelessWidget {
//   final String url;
//   final String title;
//   const _PdfViewScreen({required this.url, required this.title});

//   @override
//   Widget build(BuildContext context) => Scaffold(
//     appBar: AppBar(
//       title: Text(
//         title,
//         style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//       ),
//       backgroundColor: Colors.white,
//       foregroundColor: const Color(0xFF1E293B),
//       elevation: 0,
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(1),
//         child: Container(height: 1, color: const Color(0xFFE2E8F0)),
//       ),
//     ),
//     body: SfPdfViewer.network(url),
//   );
// }

// // About Card

// class _AboutCard extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final Color iconColor;
//   const _AboutCard({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.iconColor,
//   });

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withAlpha(8),
//           blurRadius: 6,
//           offset: const Offset(0, 1),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(9),
//           decoration: BoxDecoration(
//             color: iconColor.withAlpha(25),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: iconColor, size: 20),
//         ),
//         const SizedBox(width: 12),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
//             ),
//             const SizedBox(height: 3),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
import 'package:innovator/Innovator/widget/CustomizeFAB.dart';
import 'package:innovator/elearning/model/course_list_model.dart';
import 'package:innovator/elearning/provider/course_provider.dart';
import 'package:innovator/elearning/provider/notificationProvider.dart';
import 'package:video_player/video_player.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final CourseListModel course;
  const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VideoPlayerController? _videoController;

  bool _videoInitialized = false;
  bool _videoError = false;
  bool _isVideoLoading = false;
  int _selectedIndex = -1; // -1 = nothing selected yet
  bool _isVerifyingPayment = false;

  // WebView-based playback (for iframe embed URLs like Bunny CDN)
  bool _isWebViewVideo = false;
  String? _webViewUrl;
  WebViewController? _webViewController;

  /// Tracks exactly which CourseContent is currently loaded in the player.
  /// The lock/unlock decision is based on THIS content's isPreview flag,
  /// not the course type. This is the single source of truth.
  CourseContent? _currentContent;

  static const List<String> _tabs = ['Lessons', 'Docs', 'About'];

  @override
  void initState() {
    super.initState();
    ref.refresh(elearningUnreadCountProvider);
    ref.refresh(elearningNotificationListProvider);
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.refresh(enrollmentProvider.future);
      _maybeStartPreview();
    });
  }

  // ─── Auto-start on open ──────────────────────────────────────────────────

  /// Called once after enrollment state loads.
  ///
  /// • Enrolled  → play the first lesson normally.
  /// • Not enrolled → find the FIRST lesson where isPreview == true and
  ///   load ONLY that one. Never fall back to contents[0].
  /// • No preview lessons exist + not enrolled → leave player on locked overlay.
  void _maybeStartPreview() {
    if (!mounted) return;

    final enrolled = ref
        .read(enrolledCoursesProvider)
        .contains(widget.course.id);

    if (enrolled) {
      if (widget.course.contents.isNotEmpty) {
        setState(() => _selectedIndex = 0);
        _initVideo(widget.course.contents.first);
      }
    } else {
      // Only auto-load a lesson that explicitly has isPreview == true.
      final previewContent =
          widget.course.contents.where((c) => c.isPreview == true).firstOrNull;
      if (previewContent != null) {
        final idx = widget.course.contents.indexOf(previewContent);
        setState(() => _selectedIndex = idx);
        _initVideo(previewContent);
      }
      // If there is no preview lesson: _currentContent stays null
      // → _buildVideoSection shows the locked overlay.
    }
  }

  // ─── Payment verification ────────────────────────────────────────────────

  Future<void> _verifyAndUnlock() async {
    if (!mounted) return;
    setState(() => _isVerifyingPayment = true);

    try {
      await ref.refresh(enrollmentProvider.future);
      if (!mounted) return;

      final isNowEnrolled = ref
          .read(enrolledCoursesProvider)
          .contains(widget.course.id);

      if (isNowEnrolled) {
        setState(() => _isVerifyingPayment = false);
        ref.read(elearningNotificationListProvider.notifier).refresh();

        // Play the exact lesson the user originally tapped (stored in
        // _currentContent), or fall back to the first lesson.
        final target =
            _currentContent ??
            (widget.course.contents.isNotEmpty
                ? widget.course.contents.first
                : null);
        if (target != null) {
          final idx = widget.course.contents.indexOf(target);
          setState(() => _selectedIndex = idx < 0 ? 0 : idx);
          _initVideo(target);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payment verified! Start learning now. 🎉'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        setState(() => _isVerifyingPayment = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Payment is being processed. Please wait a moment.',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isVerifyingPayment = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoController?.dispose();
    _webViewController = null;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  // ─── Video initialisation ────────────────────────────────────────────────

  void _initVideo(CourseContent content) {
    // Always update _currentContent so the video section re-evaluates
    // whether to show the player or the locked overlay.
    _currentContent = content;

    final oldController = _videoController;
    setState(() {
      _videoController = null;
      _videoInitialized = false;
      _videoError = false;
      _isVideoLoading = true;
      _isWebViewVideo = false;
      _webViewUrl = null;
      _webViewController = null;
    });
    oldController?.dispose();

    final url = content.effectiveVideoUrl;

    if (url == null) {
      setState(() {
        _videoError = true;
        _isVideoLoading = false;
      });
      return;
    }

    // ── Embed / iframe URL → render in WebView ──────────────────────────
    if (content.isEmbedUrl) {
      // Wrap the embed URL inside a full HTML page so Bunny CDN (and other
      // iframe-based players) don't block playback due to missing referer /
      // direct-URL restrictions.  Loading the raw URL with loadRequest() causes
      // "video unavailable" because the player checks it is embedded in a page.
      final embedHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
    iframe {
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 100%;
      border: none;
    }
  </style>
</head>
<body>
  <iframe
    src="$url"
    frameborder="0"
    scrolling="no"
    allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture; fullscreen"
    allowfullscreen>
  </iframe>
</body>
</html>
''';

      final wvc =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(Colors.black)
            // Mimic a real mobile browser so CDN player scripts don't block playback.
            ..setUserAgent(
              'Mozilla/5.0 (Linux; Android 12; Mobile) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/120.0.0.0 Mobile Safari/537.36',
            )
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageFinished: (_) {
                  if (!mounted) return;
                  setState(() => _isVideoLoading = false);
                },
                onWebResourceError: (error) {
                  // Ignore sub-resource errors (analytics, ads) – only fail on
                  // main-frame errors to avoid false positives.
                  if (error.isForMainFrame == true) {
                    if (!mounted) return;
                    setState(() {
                      _videoError = true;
                      _isVideoLoading = false;
                    });
                  }
                },
              ),
            )
            // Load the wrapper HTML string (not the raw embed URL) so the
            // iframe has a proper page context and the video plays correctly.
            ..loadHtmlString(embedHtml, baseUrl: url);

      setState(() {
        _isWebViewVideo = true;
        _webViewUrl = url;
        _webViewController = wvc;
      });
      return;
    }

    // ── Direct file URL (.mp4 etc.) → VideoPlayerController ────────────
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    controller
        .initialize()
        .then((_) {
          if (!mounted) {
            controller.dispose();
            return;
          }
          setState(() {
            _videoController = controller;
            _videoInitialized = true;
            _isVideoLoading = false;
          });
        })
        .catchError((_) {
          if (!mounted) {
            controller.dispose();
            return;
          }
          setState(() {
            _videoError = true;
            _isVideoLoading = false;
          });
        });
  }

  // ─── Enroll / Pay ────────────────────────────────────────────────────────

  Future<void> _enroll() async {
    final courseId = widget.course.id;
    ref.read(enrollLoadingProvider(courseId).notifier).setLoading(true);

    try {
      if (widget.course.isFree) {
        await ref.read(courseServiceProvider).enrollCourse(courseId);
        await ref.refresh(enrollmentProvider.future);
        ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
        ref.read(elearningNotificationListProvider.notifier).refresh();

        // Play the lesson the user was trying to watch, or first lesson.
        final target =
            _currentContent ??
            (widget.course.contents.isNotEmpty
                ? widget.course.contents.first
                : null);
        if (target != null) {
          final idx = widget.course.contents.indexOf(target);
          setState(() => _selectedIndex = idx < 0 ? 0 : idx);
          _initVideo(target);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Enrolled! Start learning now. 🎉'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        // PAID: open Khalti WebView
        final result = await ref
            .read(courseServiceProvider)
            .initiatePayment(courseId);
        ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);

        final paymentUrl = result['payment_url'] as String?;
        if (paymentUrl == null) {
          _showErrorSnack('Could not initiate payment. Please try again.');
          return;
        }
        if (!mounted) return;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KhaltiWebViewScreen(paymentUrl: paymentUrl),
          ),
        );

        if (mounted) _verifyAndUnlock();
      }
    } catch (e) {
      ref.read(enrollLoadingProvider(courseId).notifier).setLoading(false);
    }
  }

  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Bottom sheet shown when the user taps a locked (non-preview) lesson.
  /// Stores the tapped lesson in _currentContent so after enrollment
  /// that exact lesson is played.
  void _showEnrollPrompt(CourseContent tappedContent) {
    _currentContent = tappedContent;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final isLoading = ref.watch(enrollLoadingProvider(widget.course.id));
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.course.isFree
                      ? Icons.school_rounded
                      : Icons.lock_outline,
                  size: 32,
                  color:
                      widget.course.isFree
                          ? const Color(0xFF10B981)
                          : const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.course.isFree
                    ? 'Enroll to watch this lesson'
                    : 'Unlock this lesson',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.course.isFree
                    ? 'This course is free. Enroll now to access all lessons.'
                    : 'Pay Rs. ${widget.course.price.toStringAsFixed(0)} to get full access to all lessons.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _EnrollButton(
                  isFree: widget.course.isFree,
                  isLoading: isLoading,
                  onTap: () {
                    Navigator.pop(context); // close sheet first
                    _enroll();
                  },
                  fullWidth: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final enrolledIds = ref.watch(enrolledCoursesProvider);
    final isEnrolled = enrolledIds.contains(widget.course.id);
    final unreadCount = ref.watch(chatUnreadCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder:
                (context, _) => [
                  SliverToBoxAdapter(child: _buildVideoSection(isEnrolled)),
                  SliverToBoxAdapter(child: _buildTitleBar()),
                ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildLessonsTab(isEnrolled),
                _buildDocsTab(isEnrolled),
                _buildAboutTab(isEnrolled),
              ],
            ),
          ),

          // Payment verification overlay
          if (_isVerifyingPayment)
            Container(
              color: Colors.black.withAlpha(160),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(
                          color: Color(0xFF2563EB),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Verifying payment...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Please wait while we confirm your enrollment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: CountBadgeFAB(
        count: unreadCount,
        gifAsset: 'animation/chaticon.gif',
        backgroundColor: Colors.transparent,
        onPressed: () {
          ref.read(mutualFriendsProvider.notifier).refresh();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatListScreen()),
          ).then((_) => ref.invalidate(mutualFriendsProvider));
        },
      ),
    );
  }

  // ─── Title Bar ───────────────────────────────────────────────────────────

  Widget _buildTitleBar() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.course.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _CourseBadge(isFree: widget.course.isFree),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
            labelColor: Colors.black,
            unselectedLabelColor: const Color(0xFF94A3B8),
            indicatorColor: const Color.fromRGBO(244, 135, 6, 1),
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Video Section ───────────────────────────────────────────────────────

  Widget _buildVideoSection(bool isEnrolled) {
    final isLoading = ref.watch(enrollLoadingProvider(widget.course.id));

    final bool currentIsPreview = _currentContent?.isPreview == true;
    final bool showVideo = isEnrolled || currentIsPreview;

    // WebView videos always use 16:9; VideoPlayer uses actual aspect ratio.
    double aspectRatio = 16 / 9;
    if (!_isWebViewVideo && _videoInitialized && _videoController != null) {
      final size = _videoController!.value.size;
      if (size.width > 0 && size.height > 0) {
        aspectRatio = size.width / size.height;
      }
    }

    return Container(
      color: Colors.black,
      width: double.infinity,
      child: SafeArea(
        bottom: false,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Main player area ──────────────────────────────────────
              if (!showVideo)
                _LockedOverlay(course: widget.course)
              else if (_isVideoLoading)
                _videoShimmer()
              else if (_videoError)
                _videoErrorWidget()
              else if (_isWebViewVideo && _webViewController != null)
                // ── Embed URL → WebView ─────────────────────────────────
                WebViewWidget(controller: _webViewController!)
              else if (_videoInitialized && _videoController != null)
                // ── Direct file → custom VideoPlayer ───────────────────
                _VideoPlayerWithControls(
                  key: ValueKey(_videoController),
                  controller: _videoController!,
                  onFullscreen: _openFullscreen,
                )
              else
                _videoShimmer(),

              // ── Back button ───────────────────────────────────────────
              Positioned(
                top: 10,
                left: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(115),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),

              // ── Enroll button — only shown on locked overlay ───────────
              if (!showVideo)
                Positioned(
                  bottom: 14,
                  child: _EnrollButton(
                    isFree: widget.course.isFree,
                    isLoading: isLoading,
                    onTap: _enroll,
                  ),
                ),

              // ── PREVIEW chip — top-right when a preview is playing ─────
              if (showVideo && currentIsPreview && !isEnrolled)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PREVIEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullscreen() {
    // Fullscreen is only available for direct VideoPlayer videos.
    // WebView-based embed players handle fullscreen natively inside the WebView.
    if (_isWebViewVideo) return;
    if (!_videoInitialized || _videoController == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenVideoScreen(controller: _videoController!),
      ),
    );
  }

  Widget _videoShimmer() => Shimmer.fromColors(
    baseColor: Colors.grey.shade800,
    highlightColor: Colors.grey.shade700,
    child: Container(color: Colors.grey.shade800),
  );

  Widget _videoErrorWidget() => Container(
    color: Colors.grey.shade900,
    child: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off, color: Colors.white54, size: 36),
          SizedBox(height: 8),
          Text(
            'Video unavailable',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    ),
  );

  // ─── Lessons Tab ─────────────────────────────────────────────────────────

  Widget _buildLessonsTab(bool isEnrolled) {
    final contents = widget.course.contents;
    if (contents.isEmpty) return _emptyTab('No lessons available');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contents.length,
      itemBuilder: (_, i) {
        final c = contents[i];
        final active = _selectedIndex == i;
        final isPreview = c.isPreview == true;

        return GestureDetector(
          onTap: () {
            if (isEnrolled) {
              // Enrolled: tap any lesson → play it
              setState(() => _selectedIndex = i);
              _initVideo(c);
              _tabController.animateTo(0);
            } else if (isPreview) {
              // Not enrolled + isPreview == true → play freely
              setState(() => _selectedIndex = i);
              _initVideo(c);
              _tabController.animateTo(0);
            } else {
              // Not enrolled + isPreview == false → prompt enrollment
              // Do NOT play. Do NOT change _selectedIndex.
              _showEnrollPrompt(c);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    active
                        ? const Color.fromRGBO(244, 135, 6, 1)
                        : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 62,
                    height: 46,
                    child:
                        c.thumbnail != null
                            ? Image.network(
                              c.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => _thumbPlaceholder(c.order),
                            )
                            : _thumbPlaceholder(c.order),
                  ),
                ),
                const SizedBox(width: 12),

                // Title + meta row
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 11,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${c.duration.toStringAsFixed(0)} min',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              c.courseLevel.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          // Green PREVIEW badge — only on preview lessons
                          // when the user is not enrolled
                          if (isPreview && !isEnrolled) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PREVIEW',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right-side icon:
                // • enrolled or isPreview → play icon
                // • not enrolled + not preview → lock icon
                if (isEnrolled || isPreview)
                  Icon(
                    active
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_outline,
                    color:
                        active
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
                    size: 22,
                  )
                else
                  const Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _thumbPlaceholder(int order) => Container(
    color: const Color(0xFFFEF3C7),
    child: Center(
      child: Text(
        '$order',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFFF59E0B),
          fontSize: 16,
        ),
      ),
    ),
  );

  // ─── Docs Tab ────────────────────────────────────────────────────────────

  Widget _buildDocsTab(bool isEnrolled) {
    final docs =
        widget.course.contents
            .where(
              (c) =>
                  (c.documentUrl != null && c.documentUrl!.isNotEmpty) ||
                  (c.documentFile != null && c.documentFile!.isNotEmpty),
            )
            .toList();
    if (docs.isEmpty) return _emptyTab('No documents available');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (_, i) => _DocItem(content: docs[i], isEnrolled: isEnrolled),
    );
  }

  // ─── About Tab ───────────────────────────────────────────────────────────

  Widget _buildAboutTab(bool isEnrolled) {
    final course = widget.course;
    final instructor =
        course.contents.isNotEmpty
            ? course.contents.first.instructorName
            : course.vendorName;
    final isLoading = ref.watch(enrollLoadingProvider(course.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AboutCard(
            icon: Icons.person_outline,
            label: 'Instructor',
            value: instructor,
            iconColor: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 10),
          if (course.categoryName != null &&
              course.categoryName!.isNotEmpty) ...[
            _AboutCard(
              icon: Icons.category_outlined,
              label: 'Category',
              value: course.categoryName!,
              iconColor: const Color(0xFFF59E0B),
            ),
          ],
          const SizedBox(height: 10),
          _AboutCard(
            icon: Icons.library_books_outlined,
            label: 'Total Lessons',
            value: '${course.contents.length} lessons',
            iconColor: const Color(0xFF10B981),
          ),
          if (!course.isFree && !isEnrolled) ...[
            const SizedBox(height: 10),
            _AboutCard(
              icon: Icons.sell_outlined,
              label: 'Price',
              value: 'Rs. ${course.price.toStringAsFixed(0)}',
              iconColor: const Color(0xFF2563EB),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'About this Course',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            course.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 24),
          if (!isEnrolled)
            _EnrollButton(
              isFree: course.isFree,
              isLoading: isLoading,
              onTap: _enroll,
              fullWidth: true,
            ),
        ],
      ),
    );
  }

  Widget _emptyTab(String msg) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text(
          msg,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Khalti WebView
// ═══════════════════════════════════════════════════════════════════════════

class KhaltiWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  const KhaltiWebViewScreen({Key? key, required this.paymentUrl})
    : super(key: key);

  @override
  State<KhaltiWebViewScreen> createState() => _KhaltiWebViewScreenState();
}

class _KhaltiWebViewScreenState extends State<KhaltiWebViewScreen> {
  static const _khaltiPurple = Color(0xFF5C2D91);
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) => setState(() => _isLoading = true),
              onPageFinished: (_) => setState(() => _isLoading = false),
              onNavigationRequest: (request) {
                final url = request.url;
                if (url.contains('payment-success') ||
                    url.contains('payment-complete') ||
                    url.contains('payment/success') ||
                    url.contains('payment/failure') ||
                    url.contains('payment/cancel') ||
                    url.contains('khalti/callback') ||
                    url.startsWith('innovator://')) {
                  Navigator.pop(context);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    final exit = await _confirmLeave();
    return exit ?? false;
  }

  Future<bool?> _confirmLeave() => showDialog<bool>(
    context: context,
    builder:
        (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Cancel Payment?'),
          content: const Text(
            'Are you sure you want to leave? Your payment will not be completed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Leave', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
  );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _khaltiPurple,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Image.asset(
                'assets/icon/khalti_logo.png',
                height: 22,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 22,
                    ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Pay with Khalti',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () async {
                  final exit = await _confirmLeave();
                  if (exit == true && context.mounted) Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withAlpha(60)),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: Colors.white.withAlpha(40)),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white.withAlpha(220),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _khaltiPurple),
                      SizedBox(height: 14),
                      Text(
                        'Loading Khalti...',
                        style: TextStyle(color: _khaltiPurple),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Video Player With Controls
// ═══════════════════════════════════════════════════════════════════════════

class _VideoPlayerWithControls extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onFullscreen;

  const _VideoPlayerWithControls({
    Key? key,
    required this.controller,
    required this.onFullscreen,
  }) : super(key: key);

  @override
  State<_VideoPlayerWithControls> createState() =>
      _VideoPlayerWithControlsState();
}

class _VideoPlayerWithControlsState extends State<_VideoPlayerWithControls> {
  bool _showControls = true;
  bool _isDragging = false;
  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  double _currentSpeed = 1.0;
  DateTime _lastTap = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  void _scheduleHide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(_lastTap).inSeconds;
      if (elapsed >= 3 && !_isDragging) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      _lastTap = DateTime.now();
    });
    if (_showControls) _scheduleHide();
  }

  void _skip(int seconds) {
    final ctrl = widget.controller;
    final duration = ctrl.value.duration;
    if (duration == Duration.zero) return;
    final current = ctrl.value.position;
    final target = current + Duration(seconds: seconds);
    final clamped =
        target < Duration.zero
            ? Duration.zero
            : (target > duration ? duration : target);
    ctrl.seekTo(clamped);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _setSpeed(double speed) {
    setState(() => _currentSpeed = speed);
    widget.controller.setPlaybackSpeed(speed);
  }

  void _showSpeedPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Playback Speed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._speeds.map((s) {
                  final selected = s == _currentSpeed;
                  return GestureDetector(
                    onTap: () {
                      _setSpeed(s);
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            selected
                                ? const Color(0xFF2563EB)
                                : Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            s == 1.0 ? 'Normal (1x)' : '${s}x',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          if (selected)
                            const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video frame
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: widget.controller,
            builder: (_, value, __) {
              final w = value.size.width > 0 ? value.size.width : 16.0;
              final h = value.size.height > 0 ? value.size.height : 9.0;
              return FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: w,
                  height: h,
                  child: VideoPlayer(widget.controller),
                ),
              );
            },
          ),

          // Controls overlay
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(160),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withAlpha(200),
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: widget.controller,
                  builder: (_, value, __) {
                    final isPlaying = value.isPlaying;
                    final position = value.position;
                    final duration = value.duration;
                    final progress =
                        duration.inMilliseconds > 0
                            ? (position.inMilliseconds /
                                    duration.inMilliseconds)
                                .clamp(0.0, 1.0)
                            : 0.0;

                    return Stack(
                      children: [
                        // Top: speed + fullscreen
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _lastTap = DateTime.now();
                                  _showSpeedPicker();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(130),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(60),
                                    ),
                                  ),
                                  child: Text(
                                    _currentSpeed == 1.0
                                        ? '1x'
                                        : '${_currentSpeed}x',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _lastTap = DateTime.now();
                                  widget.onFullscreen();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(130),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(60),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Centre: skip back | play/pause | skip forward
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _lastTap = DateTime.now();
                                  _skip(-10);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(100),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.replay_10,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _lastTap = DateTime.now();
                                  isPlaying
                                      ? widget.controller.pause()
                                      : widget.controller.play();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(140),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withAlpha(80),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _lastTap = DateTime.now();
                                  _skip(10);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(100),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.forward_10,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom: time + seek bar
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDuration(duration),
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(180),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 7,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14,
                                    ),
                                    activeTrackColor: const Color(0xFF2563EB),
                                    inactiveTrackColor: Colors.white.withAlpha(
                                      60,
                                    ),
                                    thumbColor: Colors.white,
                                    overlayColor: Colors.white.withAlpha(40),
                                  ),
                                  child: Slider(
                                    value: progress,
                                    onChangeStart: (_) {
                                      _isDragging = true;
                                      _lastTap = DateTime.now();
                                    },
                                    onChanged: (v) {
                                      if (duration == Duration.zero) return;
                                      widget.controller.seekTo(
                                        Duration(
                                          milliseconds:
                                              (v * duration.inMilliseconds)
                                                  .toInt(),
                                        ),
                                      );
                                    },
                                    onChangeEnd: (_) {
                                      _isDragging = false;
                                      _scheduleHide();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Fullscreen Video Screen
// ═══════════════════════════════════════════════════════════════════════════

class _FullscreenVideoScreen extends StatefulWidget {
  final VideoPlayerController controller;
  const _FullscreenVideoScreen({required this.controller});

  @override
  State<_FullscreenVideoScreen> createState() => _FullscreenVideoScreenState();
}

class _FullscreenVideoScreenState extends State<_FullscreenVideoScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: _VideoPlayerWithControls(
        key: ValueKey(widget.controller),
        controller: widget.controller,
        onFullscreen: () => Navigator.pop(context),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Locked Overlay
// ═══════════════════════════════════════════════════════════════════════════

class _LockedOverlay extends StatelessWidget {
  final CourseListModel course;
  const _LockedOverlay({required this.course});

  @override
  Widget build(BuildContext context) {
    final thumb =
        course.contents.isNotEmpty ? course.contents.first.thumbnail : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumb != null)
          Image.network(
            thumb,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => Container(color: Colors.grey.shade900),
          )
        else
          Container(color: Colors.grey.shade900),
        Container(color: Colors.black.withAlpha(140)),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              course.isFree
                  ? 'Enroll for free to watch'
                  : 'Pay to enroll and unlock',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Enroll Button
// ═══════════════════════════════════════════════════════════════════════════

class _EnrollButton extends StatelessWidget {
  final bool isFree;
  final bool isLoading;
  final VoidCallback onTap;
  final bool fullWidth;

  const _EnrollButton({
    required this.isFree,
    required this.isLoading,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isFree ? const Color(0xFF10B981) : const Color(0xFF2563EB);
    final label = isFree ? 'Enroll for Free' : 'Pay to Enroll';
    final icon = isFree ? Icons.school_rounded : Icons.payment_rounded;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: fullWidth ? 0 : 26,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(fullWidth ? 12 : 30),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(90),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child:
            isLoading
                ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
                : Row(
                  mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Course Badge
// ═══════════════════════════════════════════════════════════════════════════

class _CourseBadge extends StatelessWidget {
  final bool isFree;
  const _CourseBadge({required this.isFree});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color.fromRGBO(244, 135, 6, 1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      isFree ? 'Free' : 'Paid',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Doc Item
// ═══════════════════════════════════════════════════════════════════════════

class _DocItem extends StatelessWidget {
  final CourseContent content;
  final bool isEnrolled;
  const _DocItem({required this.content, required this.isEnrolled});

  String? get _url => content.documentUrl ?? content.documentFile;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(8),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.picture_as_pdf,
            color: Color(0xFFF59E0B),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                'Lesson ${content.order} · Document',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        isEnrolled
            ? GestureDetector(
              onTap:
                  _url != null
                      ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => _PdfViewScreen(
                                url: _url!,
                                title: content.title,
                              ),
                        ),
                      )
                      : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'View',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            )
            : const Icon(
              Icons.lock_outline,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// PDF Viewer Screen
// ═══════════════════════════════════════════════════════════════════════════

class _PdfViewScreen extends StatelessWidget {
  final String url;
  final String title;
  const _PdfViewScreen({required this.url, required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1E293B),
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE2E8F0)),
      ),
    ),
    body: SfPdfViewer.network(url),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// About Card
// ═══════════════════════════════════════════════════════════════════════════

class _AboutCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _AboutCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(8),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
