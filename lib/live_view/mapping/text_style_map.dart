import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/css.dart';

Map<String, TextStyle?> getTextStyleMap(BuildContext context) => {
      'headlineLarge': Theme.of(context).textTheme.headlineLarge,
      'headlineMedium': Theme.of(context).textTheme.headlineSmall,
      'headlineSmall': Theme.of(context).textTheme.headlineMedium,
      'bodyLarge': Theme.of(context).textTheme.bodyLarge,
      'bodyMedium': Theme.of(context).textTheme.bodyMedium,
      'bodySmall': Theme.of(context).textTheme.bodySmall,
      'displayLarge': Theme.of(context).textTheme.displayLarge,
      'displayMedium': Theme.of(context).textTheme.displayMedium,
      'displaySmall': Theme.of(context).textTheme.displaySmall,
      'titleLarge': Theme.of(context).textTheme.titleLarge,
      'titleMedium': Theme.of(context).textTheme.titleMedium,
      'titleSmall': Theme.of(context).textTheme.titleSmall,
    };

Map<String, FontWeight?> getFontWeightMap(BuildContext context) => {
      'bold': FontWeight.bold,
      'w100': FontWeight.w100,
      'w200': FontWeight.w200,
      'w300': FontWeight.w300,
      'w400': FontWeight.w400,
      'w500': FontWeight.w500,
      'w600': FontWeight.w600,
      'w700': FontWeight.w700,
      'w800': FontWeight.w800,
      'w900': FontWeight.w900,
    };

Map<String, FontStyle?> getFontStyleMap(BuildContext context) => {
      'italic': FontStyle.italic,
      'normal': FontStyle.normal,
    };

TextStyle? textStyle(String? style, BuildContext context) {
  if (style != null) {
    var finalStyle = const TextStyle();
    var textThemeMap = getTextStyleMap(context);
    var textFontMap = getFontWeightMap(context);
    var fontStyleMap = getFontStyleMap(context);

    for (var (styleKey, styleValue) in parseCss(style)) {
      switch (styleKey) {
        case 'textTheme':
          if (textThemeMap.containsKey(styleValue)) {
            finalStyle = finalStyle.merge(
              textThemeMap[styleValue],
            );
          } else {
            debugPrint(
                "Unknown textTheme: $styleValue, supported text styles: ${textThemeMap.keys.join(', ')}");
          }
        case 'fontStyle':
          if (fontStyleMap.containsKey(styleValue)) {
            finalStyle = finalStyle.merge(TextStyle(
              fontStyle: fontStyleMap[styleValue],
              debugLabel: "fontStyle ${fontStyleMap[styleValue]}",
            ));
          } else {
            debugPrint(
                "Unknown fontStyle: $styleValue, supported text styles: ${fontStyleMap.keys.join(', ')}");
          }
        case 'fontWeight':
          if (textFontMap.containsKey(styleValue)) {
            finalStyle = finalStyle.merge(TextStyle(
              fontWeight: textFontMap[styleValue],
              debugLabel: "fontWeight ${textFontMap[styleValue]}",
            ));
          } else {
            debugPrint(
                "Unknown fontWeight: $styleValue, supported text styles: ${textFontMap.keys.join(', ')}");
          }
        default:
          debugPrint("Unknown property $styleKey");
      }
    }
    return finalStyle;
  }
  return null;
}
