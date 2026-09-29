import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:exim_graphics_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:exim_graphics_lms/features/courses/presentation/providers/database_provider.dart';
import 'package:exim_graphics_lms/core/providers/notification_provider.dart';
import 'package:exim_graphics_lms/models/course_model.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_app_bar.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';
import '../../../../core/presentation/widgets/app_drawer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:exim_graphics_lms/features/courses/presentation/widgets/stripe_payment_sheet.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<CourseModel> _filteredCourses = [];
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    
    // Initialize BannerAd (Mobile only)
    if (!kIsWeb) {
      _bannerAd = BannerAd(
        adUnitId: 'ca-app-pub-1267014580635785/8448906002',
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) {
              setState(() {
                _isBannerAdReady = true;
              });
            }
          },
          onAdFailedToLoad: (ad, err) {
            debugPrint('Failed to load a banner ad: ${err.message}');
            if (mounted) {
              setState(() {
                _isBannerAdReady = false;
              });
            }
            ad.dispose();
          },
        ),
      );
      _bannerAd!.load();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DatabaseProvider>().fetchMyCourses();
      context.read<NotificationProvider>().reload();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _hideOverlay();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    final dbProvider = context.read<DatabaseProvider>();
    if (query.isEmpty) {
      setState(() {
        _filteredCourses = [];
      });
      _hideOverlay();
    } else {
      setState(() {
        _filteredCourses = dbProvider.courses
            .where((course) => course.title.toLowerCase().contains(query))
            .toList();
      });
      if (_searchFocusNode.hasFocus) {
        _showOverlay();
      }
    }
  }

  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      _showOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          _hideOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width - (DesignConstants.horizontalPadding * 2),
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  gradient: DesignConstants.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: DesignConstants.primaryCyan.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _filteredCourses.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No matching courses',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _filteredCourses.length,
                          separatorBuilder: (context, index) => const Divider(
                            color: Colors.white10,
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final course = _filteredCourses[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.school,
                                color: DesignConstants.primaryCyan,
                              ),
                              title: Text(
                                course.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${course.date}, ${course.time}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              onTap: () {
                                _searchFocusNode.unfocus();
                                _searchController.clear();
                                _hideOverlay();
                                _showCourseDetailsDialog(course);
                              },
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCourseDetailsDialog(CourseModel course) {
    showDialog(
      context: context,
      builder: (context) {
        final db = context.read<DatabaseProvider>();
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: DesignConstants.cardGradient,
              borderRadius: BorderRadius.circular(DesignConstants.borderRadius),
              border: Border.all(
                color: DesignConstants.primaryCyan.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Course Details',
                        style: TextStyle(
                          color: DesignConstants.primaryCyan,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    course.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Next Class: ${course.date} at ${course.time}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.sell_outlined, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Monthly Price: ${course.formattedMonthlyPrice}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white12, thickness: 1),
                  const SizedBox(height: 16),
                  FutureBuilder<String>(
                    future: db.getEnrollmentStatusForCourse(course.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(DesignConstants.primaryCyan),
                          ),
                        );
                      }
                      final status = snapshot.data ?? 'available';
                      
                      if (status == 'purchased') {
                        return Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final url = Uri.parse(course.zoomLink);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  }
                                },
                                icon: const Icon(Icons.videocam),
                                label: const Text('Join Zoom'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DesignConstants.primaryBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.push('/studypacks');
                                },
                                icon: const Icon(Icons.library_books),
                                label: const Text('Materials'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else if (status == 'pending') {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Your payment is being verified by admin. Please check back later.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.orange, fontSize: 13),
                          ),
                        );
                      } else if (status == 'expired') {
                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: DesignConstants.notificationRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: DesignConstants.notificationRed.withOpacity(0.3)),
                              ),
                              child: const Text(
                                'Your monthly subscription has expired. Renew to access classes & materials.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: DesignConstants.notificationRed, fontSize: 12),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  showDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                      child: StripePaymentSheet(
                                        course: course,
                                        onSuccess: () {},
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.autorenew, color: Colors.black),
                                label: Text('Pay Fees (${course.formattedMonthlyPrice})'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DesignConstants.primaryCyan,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context); // Close details dialog
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                  child: StripePaymentSheet(
                                    course: course,
                                    onSuccess: () {},
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.payment, color: Colors.black),
                            label: Text('Pay Fees (${course.formattedMonthlyPrice})'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DesignConstants.primaryCyan,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.horizontalPadding,
        vertical: 8.0,
      ),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _searchFocusNode.hasFocus
                  ? DesignConstants.primaryCyan.withOpacity(0.5)
                  : Colors.white12,
              width: 1.5,
            ),
            boxShadow: [
              if (_searchFocusNode.hasFocus)
                BoxShadow(
                  color: DesignConstants.primaryCyan.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search classes/courses...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 15),
              prefixIcon: const Icon(
                Icons.search,
                color: DesignConstants.primaryCyan,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        _searchController.clear();
                        _filteredCourses.clear();
                        _hideOverlay();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Shilpa Sena',
        showDrawerButton: true,
      ),
      drawer: const AppDrawer(),
      body: CustomBackground(
        child: Consumer<DatabaseProvider>(
          builder: (context, dbProvider, _) {
            final courses = dbProvider.courses;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeBanner(context),
                _buildMainCarousel(context),
                if (_isBannerAdReady && _bannerAd != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: SizedBox(
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                _buildSearchBar(context),
                const SizedBox(height: 12),
                
                // Static Section Header
                if (courses.isNotEmpty)
                  _buildSectionHeader(
                    context,
                    title: 'Available Courses',
                    onSeeAll: () => context.push('/courses'),
                  ),
                
                // Scrollable Cards Only
                Expanded(
                  child: courses.isEmpty
                      ? const Center(
                          child: Text(
                            'No courses available',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(
                            left: DesignConstants.horizontalPadding - 8,
                            right: DesignConstants.horizontalPadding - 8,
                            bottom: 30,
                          ),
                          itemCount: courses.length,
                          itemBuilder: (context, index) => _buildCourseCard(context, courses[index]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignConstants.horizontalPadding),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final userName = authProvider.user?.displayName ?? 'Student';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $userName!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Text(
                'Ready to learn something new?',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainCarousel(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, dbProvider, child) {
        final imgUrls = dbProvider.promoImageUrls;
        final List<String> banners = imgUrls.isEmpty
            ? ['assets/images/promo_banner_1.png', 'assets/images/promo_banner_2.png']
            : imgUrls;

        return CarouselSlider(
          options: CarouselOptions(
            height: 180.0,
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            viewportFraction: 0.9,
          ),
          items: banners.map((url) {
            final isNetwork = url.startsWith('http') || url.startsWith('https');
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: isNetwork 
                      ? NetworkImage(url) as ImageProvider
                      : AssetImage(url) as ImageProvider,
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignConstants.horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'See All',
                style: TextStyle(color: DesignConstants.primaryCyan),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: DesignConstants.cardGradient,
        borderRadius: BorderRadius.circular(DesignConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/courses'),
          borderRadius: BorderRadius.circular(DesignConstants.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DesignConstants.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school, color: DesignConstants.primaryCyan, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${course.date}, ${course.time}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
