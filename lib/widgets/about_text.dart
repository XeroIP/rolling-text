import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutBodyText extends StatelessWidget {
  final String text;
  final AppColors colors;

  const AboutBodyText(this.text, {super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: colors.text,
        fontSize: 16,
        height: 1.4,
      ),
    );
  }
}

class AboutStudy extends StatelessWidget {
  final String title;
  final String body;
  final String citation;
  final AppColors colors;

  const AboutStudy({
    super.key,
    required this.title,
    required this.body,
    required this.citation,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.text,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: TextStyle(
            color: colors.text,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          citation,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
