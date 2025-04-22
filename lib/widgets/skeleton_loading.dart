import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/dimensions.dart';
import '../core/helpers/responsive_helper.dart';

class SkeletonLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: AppColors.surface.withOpacity(0.3),
                  ),
                ),
                Positioned(
                  left: _animation.value * widget.width,
                  right: -_animation.value * widget.width,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.15),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class RecipeCardSkeleton extends StatelessWidget {
  final double width;
  final double height;

  const RecipeCardSkeleton({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.only(
        left: Dimensions.paddingS,
        bottom: Dimensions.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
      ),
      child: Stack(
        children: [
          // Background image placeholder
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusM),
              child: SkeletonLoading(
                width: width,
                height: height,
                borderRadius: Dimensions.radiusM,
              ),
            ),
          ),
          
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusM),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: EdgeInsets.all(Dimensions.paddingM),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonLoading(
                      width: width * 0.3,
                      height: 20,
                      borderRadius: Dimensions.radiusS,
                    ),
                    SkeletonLoading(
                      width: 32,
                      height: 32,
                      borderRadius: 16,
                    ),
                  ],
                ),
                // Bottom info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoading(
                      width: width * 0.8,
                      height: 20,
                      borderRadius: Dimensions.radiusS,
                    ),
                    SizedBox(height: Dimensions.paddingXS),
                    SkeletonLoading(
                      width: width * 0.6,
                      height: 16,
                      borderRadius: Dimensions.radiusS,
                    ),
                    SizedBox(height: Dimensions.paddingS),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SkeletonLoading(
                              width: 16,
                              height: 16,
                              borderRadius: 8,
                            ),
                            SizedBox(width: Dimensions.paddingXS),
                            SkeletonLoading(
                              width: 40,
                              height: 16,
                              borderRadius: Dimensions.radiusS,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            SkeletonLoading(
                              width: 16,
                              height: 16,
                              borderRadius: 8,
                            ),
                            SizedBox(width: Dimensions.paddingXS),
                            SkeletonLoading(
                              width: 20,
                              height: 16,
                              borderRadius: Dimensions.radiusS,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeFeedSkeleton extends StatelessWidget {
  const RecipeFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveHelper.screenWidth(context) - 32;
    return Container(
      height: 250,
      margin: EdgeInsets.symmetric(
        vertical: Dimensions.paddingS,
        horizontal: Dimensions.paddingM,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimensions.paddingM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonLoading(
                  width: width * 0.3,
                  height: 24,
                  borderRadius: Dimensions.radiusM,
                ),
                SkeletonLoading(
                  width: 38,
                  height: 38,
                  borderRadius: 19,
                ),
              ],
            ),
            // Spacer
            const Spacer(),
            // Bottom info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoading(
                  width: width * 0.9,
                  height: 28,
                  borderRadius: Dimensions.radiusM,
                ),
                SizedBox(height: Dimensions.paddingXS),
                SkeletonLoading(
                  width: width * 0.7,
                  height: 24,
                  borderRadius: Dimensions.radiusM,
                ),
                SizedBox(height: Dimensions.paddingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonLoading(
                      width: width * 0.4,
                      height: 20,
                      borderRadius: Dimensions.radiusM,
                    ),
                    SkeletonLoading(
                      width: width * 0.3,
                      height: 20,
                      borderRadius: Dimensions.radiusM,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeGridSkeleton extends StatelessWidget {
  const RecipeGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(Dimensions.paddingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final width = (ResponsiveHelper.screenWidth(context) - 48) / 2;
        return RecipeCardSkeleton(
          width: width,
          height: width * 1.3,
        );
      },
    );
  }
}

class PlannerSkeleton extends StatelessWidget {
  const PlannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveHelper.screenWidth(context);
    return Column(
      children: [
        // Date navigation skeleton
        Padding(
          padding: EdgeInsets.all(Dimensions.paddingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoading(
                width: 40,
                height: 40,
                borderRadius: 20,
              ),
              SkeletonLoading(
                width: width * 0.5,
                height: 24,
                borderRadius: Dimensions.radiusM,
              ),
              SkeletonLoading(
                width: 40,
                height: 40,
                borderRadius: 20,
              ),
            ],
          ),
        ),
        SizedBox(height: Dimensions.paddingM),
        
        // Daily planners
        Expanded(
          child: ListView.builder(
            itemCount: 7,
            padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingM),
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(bottom: Dimensions.paddingL),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day title
                    Padding(
                      padding: EdgeInsets.all(Dimensions.paddingM),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SkeletonLoading(
                            width: width * 0.4,
                            height: 24,
                            borderRadius: Dimensions.radiusM,
                          ),
                          SkeletonLoading(
                            width: 24,
                            height: 24,
                            borderRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    
                    // Empty state or meals
                    index % 2 == 0
                        ? SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.only(
                                left: Dimensions.paddingM,
                                right: Dimensions.paddingS,
                                bottom: Dimensions.paddingM,
                              ),
                              itemCount: 2,
                              itemBuilder: (context, mealIndex) {
                                return Container(
                                  width: width * 0.6,
                                  margin: EdgeInsets.only(right: Dimensions.paddingM),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Background
                                      Positioned.fill(
                                        child: SkeletonLoading(
                                          width: width * 0.6,
                                          height: 120,
                                          borderRadius: Dimensions.radiusM,
                                        ),
                                      ),
                                      
                                      // Content overlay
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 70,
                                          padding: EdgeInsets.all(Dimensions.paddingS),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(Dimensions.radiusM),
                                              bottomRight: Radius.circular(Dimensions.radiusM),
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.8),
                                              ],
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              SkeletonLoading(
                                                width: width * 0.4,
                                                height: 20,
                                                borderRadius: Dimensions.radiusS,
                                              ),
                                              SizedBox(height: Dimensions.paddingXS),
                                              Row(
                                                children: [
                                                  SkeletonLoading(
                                                    width: 16,
                                                    height: 16,
                                                    borderRadius: 8,
                                                  ),
                                                  SizedBox(width: Dimensions.paddingXS),
                                                  SkeletonLoading(
                                                    width: 50,
                                                    height: 16,
                                                    borderRadius: Dimensions.radiusS,
                                                  ),
                                                  SizedBox(width: Dimensions.paddingL),
                                                  SkeletonLoading(
                                                    width: 50,
                                                    height: 16,
                                                    borderRadius: Dimensions.radiusS,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      // Check button
                                      Positioned(
                                        top: Dimensions.paddingS,
                                        right: Dimensions.paddingS,
                                        child: SkeletonLoading(
                                          width: 36,
                                          height: 36,
                                          borderRadius: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.only(
                              left: Dimensions.paddingL,
                              right: Dimensions.paddingL,
                              bottom: Dimensions.paddingL,
                            ),
                            child: SkeletonLoading(
                              width: width - 64,
                              height: 24,
                              borderRadius: Dimensions.radiusM,
                            ),
                          ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveHelper.screenWidth(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: EdgeInsets.all(Dimensions.paddingM),
          child: SkeletonLoading(
            width: width * 0.4,
            height: 32,
            borderRadius: Dimensions.radiusM,
          ),
        ),
        
        // Search box
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingM),
          child: SkeletonLoading(
            width: width - 32,
            height: 56,
            borderRadius: Dimensions.radiusL,
          ),
        ),
        SizedBox(height: Dimensions.paddingM),
        
        // Popular Ingredients Section
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingM,
            vertical: Dimensions.paddingS,
          ),
          child: SkeletonLoading(
            width: width * 0.6,
            height: 24,
            borderRadius: Dimensions.radiusM,
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingM),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 100,
                margin: EdgeInsets.only(right: Dimensions.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
              );
            },
          ),
        ),
        SizedBox(height: Dimensions.paddingM),
        
        // "Recipes you may like" header with sort button
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingM,
            vertical: Dimensions.paddingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoading(
                width: width * 0.6,
                height: 24,
                borderRadius: Dimensions.radiusM,
              ),
              SkeletonLoading(
                width: 80,
                height: 32,
                borderRadius: Dimensions.radiusM,
              ),
            ],
          ),
        ),
        SizedBox(height: Dimensions.paddingS),
        
        // Recipe grid
        Expanded(
          child: RecipeGridSkeleton(),
        ),
      ],
    );
  }
}

class SavedSkeleton extends StatelessWidget {
  const SavedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return RecipeGridSkeleton();
  }
} 