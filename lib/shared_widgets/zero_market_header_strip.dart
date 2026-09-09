import 'package:flutter/material.dart';
import 'news_ticker_strip.dart';
import 'script_selector_bar.dart';

/// Combined market strip providing both the news ticker and dual script selector.
class ZeroMarketHeaderStrip extends StatelessWidget {
  const ZeroMarketHeaderStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NewsTickerStrip(),
        ScriptSelectorBar(),
      ],
    );
  }
}
