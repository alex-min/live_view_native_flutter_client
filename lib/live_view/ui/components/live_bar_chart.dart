import 'package:community_charts_flutter/community_charts_flutter.dart'
    as charts;
import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/number.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// A compact income-versus-expense bar chart driven entirely by attributes.
///
/// ```xml
/// <BarChart income="1200" expense="450" incomeLabel="Income"
///           expenseLabel="Expenses" height="130" width="150" />
/// ```
class LiveBarChart extends LiveStateWidget<LiveBarChart> {
  const LiveBarChart({super.key, required super.state});

  @override
  State<LiveBarChart> createState() => _LiveBarChartState();
}

class _ChartValue {
  final String label;
  final double amount;
  final charts.Color color;

  const _ChartValue(this.label, this.amount, this.color);
}

class _LiveBarChartState extends StateWidget<LiveBarChart> {
  final attributes = [
    'income',
    'expense',
    'incomeLabel',
    'expenseLabel',
    'height',
    'width',
  ];

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, attributes);
  }

  @override
  Widget render(BuildContext context) {
    var values = [
      _ChartValue(
        getAttribute('incomeLabel') ?? 'Income',
        _amount('income'),
        charts.MaterialPalette.green.shadeDefault,
      ),
      _ChartValue(
        getAttribute('expenseLabel') ?? 'Expenses',
        _amount('expense'),
        charts.MaterialPalette.red.shadeDefault,
      ),
    ];

    var series = [
      charts.Series<_ChartValue, String>(
        id: 'income-expense',
        data: values,
        domainFn: (value, _) => value.label,
        measureFn: (value, _) => value.amount,
        colorFn: (value, _) => value.color,
      ),
    ];

    return SizedBox(
      height: getDouble(getAttribute('height')) ?? 130,
      width: getDouble(getAttribute('width')) ?? 150,
      child: charts.BarChart(
        series,
        animate: false,
        primaryMeasureAxis: const charts.NumericAxisSpec(
          renderSpec: charts.NoneRenderSpec(),
        ),
        domainAxis: const charts.OrdinalAxisSpec(
          showAxisLine: false,
          renderSpec: charts.NoneRenderSpec(),
        ),
      ),
    );
  }

  double _amount(String attribute) =>
      double.tryParse(getAttribute(attribute) ?? '') ?? 0;
}
