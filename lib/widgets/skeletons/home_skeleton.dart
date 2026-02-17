import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:desperdicio_zero/theme/style_tokens.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        StyleTokens.spacingL,
        StyleTokens.spacingL,
        StyleTokens.spacingL,
        StyleTokens.spacingXL,
      ),
      children: const [
        _SkeletonBlock(height: 140),
        SizedBox(height: StyleTokens.spacingL),
        _SkeletonActionGrid(),
        SizedBox(height: StyleTokens.spacingL),
        _SkeletonBar(),
        SizedBox(height: StyleTokens.spacingM),
        _SkeletonSectionTitle(),
        SizedBox(height: StyleTokens.spacingS),
        _SkeletonGrid(),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.height,
    this.width,
    this.radius = StyleTokens.radiusXL,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Shimmer.fromColors(
      baseColor: color,
      highlightColor: color.withOpacity(0.5),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _SkeletonActionGrid extends StatelessWidget {
  const _SkeletonActionGrid();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: StyleTokens.spacingS,
      runSpacing: StyleTokens.spacingS,
      children: List.generate(4, (index) {
        return SizedBox(
          width: (MediaQuery.sizeOf(context).width - (StyleTokens.spacingL * 2) - StyleTokens.spacingS) / 2,
          child: const _SkeletonBlock(height: 80, radius: StyleTokens.radiusL),
        );
      }),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar();

  @override
  Widget build(BuildContext context) {
    return const _SkeletonBlock(height: 52, radius: StyleTokens.radiusPill);
  }
}

class _SkeletonSectionTitle extends StatelessWidget {
  const _SkeletonSectionTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _SkeletonBlock(height: 24, radius: StyleTokens.radiusM)),
        SizedBox(width: StyleTokens.spacingS),
        _SkeletonBlock(height: 32, width: 120, radius: StyleTokens.radiusM),
      ],
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1000
        ? 4
        : width >= 700
            ? 3
            : 2;
    final spacing = StyleTokens.spacingL;
    final itemWidth = (width - (StyleTokens.spacingL * 2) - ((crossAxisCount - 1) * spacing)) / crossAxisCount;
    final itemHeight = itemWidth * 1.1;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(
        6,
        (_) => SizedBox(
          width: itemWidth,
          height: itemHeight,
          child: const _SkeletonBlock(height: double.infinity, radius: StyleTokens.radiusL),
        ),
      ),
    );
  }
}
