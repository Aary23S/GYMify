import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _onDone(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (context.mounted) {
      context.go('/login');
    }
  }

  PageViewModel _buildPage({
    required String title,
    required String body,
    required IconData icon,
    required Color circleColor,
  }) {
    return PageViewModel(
      title: title,
      body: body,
      image: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: circleColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Container(
            margin: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
      ),
      decoration: const PageDecoration(
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        bodyTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        pageColor: Colors.white,
        imagePadding: EdgeInsets.only(top: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        _buildPage(
          title: "Manage Members Effortlessly",
          body: "Add, track and manage all your gym members from one place",
          icon: Icons.people_alt,
          circleColor: Colors.blue,
        ),
        _buildPage(
          title: "Schedule Classes & Trainers",
          body: "Create class schedules, assign trainers, manage bookings",
          icon: Icons.calendar_month,
          circleColor: Colors.teal,
        ),
        _buildPage(
          title: "Track Revenue & Growth",
          body: "Real-time insights into your gym's performance and revenue",
          icon: Icons.bar_chart,
          circleColor: Colors.purple,
        ),
      ],
      onDone: () => _onDone(context),
      onSkip: () => _onDone(context),
      showSkipButton: true,
      skip: const Text("Skip",
          style:
              TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward, color: AppColors.primary),
      done: const Text("Done",
          style:
              TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: AppColors.primary,
        color: Colors.black26,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }
}
