import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/section_card.dart';
import '../../../shared_widgets/zero_drawer.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _ticketController = TextEditingController();
  final String _category = 'Trading & Orders';

  @override
  void dispose() {
    _ticketController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    final faqs = [
      {
        'q': 'What is Zero equity brokerage?',
        'a':
            'Zero charges ₹0 brokerage on all Equity Delivery (CNC) investments. For Intraday (MIS) and F&O, flat ₹20 or 0.03% is charged per executed order.',
      },
      {
        'q': 'How does GTT (Good Till Triggered) work?',
        'a':
            'A GTT order remains active for 1 year until your specified trigger price is crossed on the exchange. Once triggered, the limit order is automatically routed.',
      },
      {
        'q': 'What are market trading hours in India?',
        'a':
            'Regular equity market sessions run from 09:15 AM to 03:30 PM IST on weekdays. Pre-market session is 09:00 AM to 09:08 AM.',
      },
      {
        'q': 'How do I add funds using UPI?',
        'a':
            'Navigate to Funds -> Add Funds, enter the amount, select UPI, and approve the instant mandate request on your UPI app with zero transfer fees.',
      },
    ];

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/help'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (innerContext) => IconButton(
            icon: Icon(Icons.menu, color: colors.textPrimary, size: 26),
            onPressed: () => Scaffold.of(innerContext).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: Text('Help & Support',
            style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ),
      body: Column(
        children: [
          // Public & Private News Ticker Strip
          const NewsTickerStrip(),

          // Dual Script Selector Bar
          const ScriptSelectorBar(),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // FAQs Section
                  SectionCard(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Frequently Asked Questions',
                            style: GoogleFonts.inter(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        const SizedBox(height: 10),
                        ...faqs.map((faq) {
                          return ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(faq['q']!,
                                style: GoogleFonts.inter(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Text(faq['a']!,
                                    style: GoogleFonts.inter(
                                        color: colors.textSecondary,
                                        fontSize: 12.5,
                                        height: 1.4)),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Raise a Ticket
                  SectionCard(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Raise a Support Ticket',
                            style: GoogleFonts.inter(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          dropdownColor: colors.cardBackground,
                          style: TextStyle(color: colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Category',
                            labelStyle:
                                TextStyle(color: colors.textSecondary),
                          ),
                          items: [
                            'Trading & Orders',
                            'Funds & Payments',
                            'Account & KYC',
                            'Technical Issues'
                          ].map((c) {
                            return DropdownMenuItem(
                                value: c, child: Text(c));
                          }).toList(),
                          onChanged: (v) {},
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _ticketController,
                          maxLines: 4,
                          style: TextStyle(color: colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Describe your issue in detail',
                            labelStyle:
                                TextStyle(color: colors.textSecondary),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_ticketController.text.isNotEmpty) {
                                _ticketController.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Support Ticket #TK-84920 created. Our desk will respond within 2 hours.')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('SUBMIT TICKET',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
