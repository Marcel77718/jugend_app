import 'package:flutter/material.dart';
import 'package:jugend_app/core/performance_monitor.dart';

class WidgetOptimizer {
  /// Erstellt ein optimiertes ListView mit automatischer Performance-Überwachung
  static Widget optimizedListView({
    required List<Widget> children,
    ScrollController? controller,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    String? name,
  }) {
    return PerformanceWidget(
      name: name ?? 'OptimizedListView',
      child: ListView.builder(
        controller: controller,
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: padding,
        itemCount: children.length,
        itemBuilder: (context, index) {
          return PerformanceWidget(
            name: '${name ?? "ListView"}_Item_$index',
            child: children[index],
          );
        },
      ),
    );
  }

  /// Erstellt ein optimiertes GridView mit automatischer Performance-Überwachung
  static Widget optimizedGridView({
    required List<Widget> children,
    required int crossAxisCount,
    double? mainAxisSpacing,
    double? crossAxisSpacing,
    ScrollController? controller,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    String? name,
  }) {
    return PerformanceWidget(
      name: name ?? 'OptimizedGridView',
      child: GridView.builder(
        controller: controller,
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing ?? 0,
          crossAxisSpacing: crossAxisSpacing ?? 0,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) {
          return PerformanceWidget(
            name: '${name ?? "GridView"}_Item_$index',
            child: children[index],
          );
        },
      ),
    );
  }

  /// Erstellt ein optimiertes AnimatedContainer mit Performance-Überwachung
  static Widget optimizedAnimatedContainer({
    required Widget child,
    Duration? duration,
    Curve? curve,
    String? name,
  }) {
    return PerformanceWidget(
      name: name ?? 'OptimizedAnimatedContainer',
      child: AnimatedContainer(
        duration: duration ?? const Duration(milliseconds: 300),
        curve: curve ?? Curves.easeInOut,
        child: child,
      ),
    );
  }

  /// Erstellt ein optimiertes FutureBuilder mit Performance-Überwachung
  static Widget optimizedFutureBuilder<T>({
    required Future<T> future,
    required Widget Function(BuildContext, AsyncSnapshot<T>) builder,
    Widget? loading,
    String? name,
  }) {
    return PerformanceWidget(
      name: name ?? 'OptimizedFutureBuilder',
      child: FutureBuilder<T>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return loading ?? const Center(child: CircularProgressIndicator());
          }
          return builder(context, snapshot);
        },
      ),
    );
  }

  /// Erstellt ein optimiertes StreamBuilder mit Performance-Überwachung
  static Widget optimizedStreamBuilder<T>({
    required Stream<T> stream,
    required Widget Function(BuildContext, AsyncSnapshot<T>) builder,
    T? initialData,
    String? name,
  }) {
    return PerformanceWidget(
      name: name ?? 'OptimizedStreamBuilder',
      child: StreamBuilder<T>(
        stream: stream,
        initialData: initialData,
        builder: builder,
      ),
    );
  }

  /// Erstellt ein optimiertes Image mit Performance-Überwachung
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit? fit,
    Widget? placeholder,
    Widget? errorWidget,
    String? name,
  }) {
    return PerformanceWidget(
      name: name ?? 'OptimizedImage',
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              const Icon(Icons.error_outline, color: Colors.red);
        },
      ),
    );
  }
}
