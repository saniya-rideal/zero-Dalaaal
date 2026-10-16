import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../quote_detail/presentation/quote_detail_screen.dart';
import '../data/news_repository.dart';

final newsListProvider = FutureProvider.autoDispose.family<List<NewsArticle>, ({String? category, String? query, int page})>((ref, arg) async {
  final repo = ref.watch(newsRepositoryProvider);
  final cat = (arg.category != null && arg.category != 'ALL') ? arg.category : null;
  return repo.getArticles(
    category: cat,
    symbol: arg.query,
    page: arg.page,
    limit: 20,
  );
});

class NewsScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const NewsScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  NewsCategory _selectedNewsCategory = NewsCategory.ALL;
  final TextEditingController _newsSearchController = TextEditingController();
  int _newsPage = 1;

  @override
  void dispose() {
    _newsSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/news'),
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: Builder(
          builder: (ctx) {
            final canPop = Navigator.of(ctx).canPop();
            if (canPop) {
              return IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary, size: 22),
                onPressed: () => Navigator.of(ctx).pop(),
                tooltip: 'Back',
              );
            }
            return IconButton(
              icon: Icon(LucideIcons.menu, color: colors.textPrimary, size: 22),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              tooltip: 'Menu',
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'News & Insights',
              style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Real-time Market Feeds & Analysis',
              style: GoogleFonts.inter(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: _buildMarketNewsTab(colors),
    );
  }

  Widget _buildMarketNewsTab(TradingColors colors) {
    final query = _newsSearchController.text.trim();
    final catName = _selectedNewsCategory == NewsCategory.ALL ? null : _selectedNewsCategory.name;
    final articlesAsync = ref.watch(newsListProvider((
      category: catName,
      query: query.isNotEmpty ? query : null,
      page: _newsPage,
    )));

    return RefreshIndicator(
      color: const Color(0xFF1E88E5),
      onRefresh: () async {
        setState(() => _newsPage = 1);
        ref.invalidate(newsListProvider);
      },
      child: CustomScrollView(
        slivers: [
          // 1. Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.divider),
                ),
                child: TextField(
                  controller: _newsSearchController,
                  style: GoogleFonts.inter(color: colors.textPrimary, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Search news by headline, symbol, or source...',
                    hintStyle: GoogleFonts.inter(color: colors.textSecondary, fontSize: 13),
                    prefixIcon: Icon(LucideIcons.search, size: 18, color: colors.textSecondary),
                    suffixIcon: _newsSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 18),
                            onPressed: () {
                              _newsSearchController.clear();
                              setState(() => _newsPage = 1);
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => setState(() => _newsPage = 1),
                ),
              ),
            ),
          ),

          // 2. Category Chips Bar
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildNewsCategoryChip('All News', NewsCategory.ALL, colors),
                  _buildNewsCategoryChip('Equities', NewsCategory.EQUITIES, colors),
                  _buildNewsCategoryChip('F&O', NewsCategory.FNO, colors),
                  _buildNewsCategoryChip('Commodities', NewsCategory.COMMODITIES, colors),
                  _buildNewsCategoryChip('Forex', NewsCategory.FOREX, colors),
                  _buildNewsCategoryChip('Economy', NewsCategory.ECONOMY, colors),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // 3. Articles List or Empty / Error / Loading
          articlesAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.alertTriangle, size: 40, color: colors.loss),
                      const SizedBox(height: 12),
                      Text('Failed to load news', style: TextStyle(color: colors.textPrimary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(newsListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (articles) {
              if (articles.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.searchX, size: 48, color: colors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'No matching news articles found',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try searching for another keyword or switch category filter.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 12.5, color: colors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              _newsSearchController.clear();
                              setState(() {
                                _selectedNewsCategory = NewsCategory.ALL;
                                _newsPage = 1;
                              });
                            },
                            icon: const Icon(LucideIcons.rotateCcw, size: 16),
                            label: const Text('Reset Filters'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final article = articles[index];
                      return _buildArticleCard(article, colors);
                    },
                    childCount: articles.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildNewsCategoryChip(String label, NewsCategory category, TradingColors colors) {
    final isSelected = _selectedNewsCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedNewsCategory = category;
              _newsPage = 1;
            });
          }
        },
        selectedColor: const Color(0xFF1E88E5),
        backgroundColor: colors.surface,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : colors.textPrimary,
        ),
        side: BorderSide(color: isSelected ? const Color(0xFF1E88E5) : colors.divider),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }

  Widget _buildArticleCard(NewsArticle article, TradingColors colors) {
    final sentimentColor = article.sentiment == NewsSentiment.BULLISH
        ? const Color(0xFF00A854)
        : (article.sentiment == NewsSentiment.BEARISH
            ? const Color(0xFFE82B57)
            : colors.textSecondary);

    final sentimentText = article.sentiment == NewsSentiment.BULLISH
        ? 'BULLISH'
        : (article.sentiment == NewsSentiment.BEARISH ? 'BEARISH' : 'NEUTRAL');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.divider, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showArticleDetailsSheet(article, colors),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            article.source,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1E88E5),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: sentimentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sentimentText,
                            style: GoogleFonts.inter(
                              color: sentimentColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      article.timeAgo,
                      style: GoogleFonts.inter(
                        color: colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  article.title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (article.relatedSymbols.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: article.relatedSymbols.map((sym) {
                      return InkWell(
                        onTap: () => _openRelatedInstrument(sym),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: colors.divider),
                          ),
                          child: Text(
                            sym,
                            style: GoogleFonts.inter(
                              color: colors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openRelatedInstrument(String symbol) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuoteDetailScreen(token: symbol),
      ),
    );
  }

  void _showArticleDetailsSheet(NewsArticle article, TradingColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        article.source,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1E88E5),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          article.timeAgo,
                          style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(LucideIcons.share2, size: 20, color: colors.textPrimary),
                          onPressed: () => _promptShareArticle(article),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.x, size: 20, color: colors.textPrimary),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  article.title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                if (article.relatedSymbols.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Related:',
                        style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      ...article.relatedSymbols.map((sym) {
                        return ActionChip(
                          avatar: const Icon(LucideIcons.trendingUp, size: 14, color: Color(0xFF1E88E5)),
                          label: Text(sym, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _openRelatedInstrument(sym);
                          },
                          backgroundColor: colors.surface,
                          side: BorderSide(color: colors.divider),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  article.fullContent,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: colors.textPrimary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.share2, size: 16),
                        label: const Text('Share'),
                        onPressed: () => _promptShareArticle(article),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Close Article', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _promptShareArticle(NewsArticle article) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tradingColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (shareCtx) {
        final shareText = '${article.title}\n\n${article.summary}\n\nSource: ${article.source}\nRead on ZeroDalali Trading App';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share Article',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share market insights with friends and trading groups:',
                  style: GoogleFonts.inter(fontSize: 12.5, color: context.tradingColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.tradingColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.tradingColors.divider),
                  ),
                  child: Text(
                    shareText,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12, color: context.tradingColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: const Icon(LucideIcons.copy, size: 18),
                    label: const Text('Copy to Clipboard', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareText));
                      Navigator.pop(shareCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Article summary copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
