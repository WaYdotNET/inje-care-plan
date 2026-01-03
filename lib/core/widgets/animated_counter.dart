import 'package:flutter/material.dart';

/// Widget per animare contatori numerici
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
  });

  final double value;
  final Duration duration;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final formattedValue = decimals > 0
            ? animatedValue.toStringAsFixed(decimals)
            : animatedValue.toInt().toString();
        return Text(
          '$prefix$formattedValue$suffix',
          style: style,
        );
      },
    );
  }
}

/// Widget per animare progressi circolari
class AnimatedCircularProgress extends StatelessWidget {
  const AnimatedCircularProgress({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1000),
    this.size = 100,
    this.strokeWidth = 8,
    this.color,
    this.backgroundColor,
    this.child,
  });

  final double value;
  final Duration duration;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    final effectiveBgColor = backgroundColor ?? effectiveColor.withValues(alpha: 0.2);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, widget) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background
              CircularProgressIndicator(
                value: 1,
                strokeWidth: strokeWidth,
                color: effectiveBgColor,
              ),
              // Progress
              CircularProgressIndicator(
                value: animatedValue,
                strokeWidth: strokeWidth,
                color: effectiveColor,
                strokeCap: StrokeCap.round,
              ),
              if (child != null) child!,
            ],
          ),
        );
      },
    );
  }
}

/// Widget per fade-in con delay
class FadeInWidget extends StatefulWidget {
  const FadeInWidget({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOut,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _offset = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

/// Widget per staggered animations (lista animata)
class StaggeredList extends StatelessWidget {
  const StaggeredList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.initialDelay = Duration.zero,
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final Duration initialDelay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        final delay = initialDelay + (staggerDelay * index);

        return FadeInWidget(
          delay: delay,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Bounce animation per successo
class BounceAnimation extends StatefulWidget {
  const BounceAnimation({
    super.key,
    required this.child,
    this.animate = true,
    this.duration = const Duration(milliseconds: 400),
  });

  final Widget child;
  final bool animate;
  final Duration duration;

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(BounceAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}

/// Pulse animation per attenzione
class PulseAnimation extends StatefulWidget {
  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  final Widget child;
  final Duration duration;
  final bool enabled;

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + (_controller.value * 0.05),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
