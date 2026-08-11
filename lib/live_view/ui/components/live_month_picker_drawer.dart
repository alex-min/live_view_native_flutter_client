import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// Mavio-style month picker content for use inside a modal bottom sheet.
///
/// Each [LiveMonthPickerYear] becomes a pinned year header followed by the
/// server-rendered month rows for that year.
class LiveMonthPickerDrawer extends LiveStateWidget<LiveMonthPickerDrawer> {
  const LiveMonthPickerDrawer({super.key, required super.state});

  @override
  State<LiveMonthPickerDrawer> createState() => _LiveMonthPickerDrawerState();
}

class _LiveMonthPickerDrawerState extends StateWidget<LiveMonthPickerDrawer> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  HandleClickState handleClickState() => HandleClickState.manual;

  @override
  Widget render(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(slivers: multipleChildren()),
        Positioned(
          right: 15,
          top: 15,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            shape: const CircleBorder(),
            elevation: 1,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: executeTapEventsManually,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LiveMonthPickerYear extends LiveStateWidget<LiveMonthPickerYear> {
  const LiveMonthPickerYear({super.key, required super.state});

  @override
  State<LiveMonthPickerYear> createState() => _LiveMonthPickerYearState();
}

class _LiveMonthPickerYearState extends StateWidget<LiveMonthPickerYear> {
  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['year']);
  }

  @override
  Widget render(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _YearHeaderDelegate(
            year: getAttribute('year') ?? '',
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        SliverList.list(children: multipleChildren()),
      ],
    );
  }
}

class _YearHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String year;
  final Color backgroundColor;
  final Color foregroundColor;

  const _YearHeaderDelegate({
    required this.year,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      color: backgroundColor,
      child: Text(
        year,
        key: Key('month-picker-year-$year'),
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: foregroundColor),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _YearHeaderDelegate oldDelegate) =>
      year != oldDelegate.year ||
      backgroundColor != oldDelegate.backgroundColor ||
      foregroundColor != oldDelegate.foregroundColor;
}
