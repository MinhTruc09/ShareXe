import 'package:flutter/material.dart';

class SkeletonLoader extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const SkeletonLoader({
    Key? key,
    this.height = 20,
    this.width = double.infinity,
    this.borderRadius = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const ShimmerEffect(),
    );
  }
}

class ShimmerEffect extends StatefulWidget {
  const ShimmerEffect({Key? key}) : super(key: key);

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _controller.repeat();
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
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                0.0,
                0.5,
                1.0,
              ],
              transform: GradientRotation(_animation.value),
            ).createShader(bounds);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}

// Pre-built skeleton layouts for common screens
class RideCardSkeleton extends StatelessWidget {
  const RideCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(width: 80, height: 24, borderRadius: 12),
              SkeletonLoader(width: 100, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 12),
          
          // Time
          SkeletonLoader(width: 150, height: 16),
          const SizedBox(height: 16),
          
          // Departure
          Row(
            children: [
              SkeletonLoader(width: 40, height: 40, borderRadius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLoader(width: 60, height: 12),
                    SizedBox(height: 4),
                    SkeletonLoader(height: 18),
                  ],
                ),
              ),
            ],
          ),
          
          // Divider
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: SizedBox(
              height: 20,
              child: VerticalDivider(
                color: Colors.grey[300],
                thickness: 2,
                width: 20,
              ),
            ),
          ),
          
          // Destination
          Row(
            children: [
              SkeletonLoader(width: 40, height: 40, borderRadius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLoader(width: 60, height: 12),
                    SizedBox(height: 4),
                    SkeletonLoader(height: 18),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonLoader(width: 100, height: 16),
              SkeletonLoader(width: 120, height: 16),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: const [
              Expanded(child: SkeletonLoader(height: 40, borderRadius: 8)),
              SizedBox(width: 12),
              Expanded(child: SkeletonLoader(height: 40, borderRadius: 8)),
            ],
          ),
        ],
      ),
    );
  }
}

class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(width: 100, height: 24, borderRadius: 12),
              SkeletonLoader(width: 120, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 16),
          
          // User info
          Row(
            children: [
              SkeletonLoader(width: 36, height: 36, borderRadius: 18),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLoader(width: 120, height: 16),
                  SizedBox(height: 4),
                  SkeletonLoader(width: 80, height: 14),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Ride details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: const [
                    SkeletonLoader(width: 20, height: 20, borderRadius: 10),
                    SizedBox(width: 8),
                    Expanded(child: SkeletonLoader(height: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    SkeletonLoader(width: 20, height: 20, borderRadius: 10),
                    SizedBox(width: 8),
                    Expanded(child: SkeletonLoader(height: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    SkeletonLoader(width: 20, height: 20, borderRadius: 10),
                    SizedBox(width: 8),
                    Expanded(child: SkeletonLoader(height: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    SkeletonLoader(width: 20, height: 20, borderRadius: 10),
                    SizedBox(width: 8),
                    Expanded(child: SkeletonLoader(height: 16)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Divider
          const Divider(),
          const SizedBox(height: 8),
          
          // View details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonLoader(width: 140, height: 16),
              SkeletonLoader(width: 20, height: 16),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: const [
              Expanded(child: SkeletonLoader(height: 40, borderRadius: 8)),
              SizedBox(width: 12),
              Expanded(child: SkeletonLoader(height: 40, borderRadius: 8)),
            ],
          ),
        ],
      ),
    );
  }
} 