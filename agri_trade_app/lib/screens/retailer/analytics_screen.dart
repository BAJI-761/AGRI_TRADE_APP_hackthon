import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/order_service.dart';
import '../../models/order.dart' as model;
import '../../theme/app_theme.dart';
import '../../services/language_service.dart';
import '../../widgets/navigation_helper.dart';
import '../../widgets/app_gradient_scaffold.dart';
import 'dart:math' as math;

/// Premium Trade Analytics Dashboard with visual charts,
/// revenue stats, success rate ring, and trade breakdown.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();
    final ls = Provider.of<LanguageService>(context);

    return NavigationHelper(
      child: AppGradientScaffold(
        headerHeightFraction: 0.18,
        headerChildren: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ls.getLocalizedString('analytics'),
                    style: AppTheme.headingMedium.copyWith(color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text('LIVE', style: AppTheme.bodySmall.copyWith(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        bodyChildren: [
          StreamBuilder<List<model.Order>>(
            stream: orderService.streamOrdersForRetailer(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ));
              }
              
              final orders = snapshot.data ?? [];
              final stats = _TradeStats.from(orders);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // REVENUE HERO CARD
                    _RevenueCard(stats: stats),
                    const SizedBox(height: 16),

                    // STAT GRID (4 cards)
                    _StatGrid(stats: stats),
                    const SizedBox(height: 20),

                    // SUCCESS RATE + TRADE BREAKDOWN
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _SuccessRateRing(stats: stats)),
                        const SizedBox(width: 12),
                        Expanded(child: _TradeBreakdown(stats: stats)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // REVENUE BAR CHART
                    _RevenueBarChart(stats: stats),
                    const SizedBox(height: 20),

                    // TOP CROPS SECTION
                    _TopCropsCard(stats: stats),
                    const SizedBox(height: 20),

                    // RECENT TRANSACTIONS
                    _RecentTransactions(orders: orders),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stats model
// ─────────────────────────────────────────────
class _TradeStats {
  final int total, completed, disputed, paymentHeld, accepted, pending, rejected;
  final double totalRevenue, completedRevenue, escrowAmount;
  final Map<String, double> cropRevenue; // crop name → total revenue
  final Map<String, int> cropCount;

  _TradeStats({
    required this.total, required this.completed, required this.disputed,
    required this.paymentHeld, required this.accepted, required this.pending,
    required this.rejected, required this.totalRevenue,
    required this.completedRevenue, required this.escrowAmount,
    required this.cropRevenue, required this.cropCount,
  });

  double get successRate => total == 0 ? 0 : (completed / total * 100);
  double get disputeRate => total == 0 ? 0 : (disputed / total * 100);
  int get activeOrders => accepted + paymentHeld;

  factory _TradeStats.from(List<model.Order> orders) {
    int completed = 0, disputed = 0, paymentHeld = 0, accepted = 0, pending = 0, rejected = 0;
    double totalRev = 0, completedRev = 0, escrow = 0;
    Map<String, double> cropRev = {};
    Map<String, int> cropCnt = {};

    for (final o in orders) {
      final val = o.quantity * o.pricePerUnit;
      final state = o.tradeState;

      if (state == 'completed') { completed++; completedRev += val; }
      else if (state == 'disputed') { disputed++; }
      else if (state == 'paymentHeld') { paymentHeld++; escrow += val; }
      else if (state == 'accepted') { accepted++; }
      else if (state == 'rejected') { rejected++; }
      else { pending++; }

      if (state != 'rejected') {
        totalRev += val;
        cropRev[o.crop] = (cropRev[o.crop] ?? 0) + val;
        cropCnt[o.crop] = (cropCnt[o.crop] ?? 0) + 1;
      }
    }

    return _TradeStats(
      total: orders.length, completed: completed, disputed: disputed,
      paymentHeld: paymentHeld, accepted: accepted, pending: pending,
      rejected: rejected, totalRevenue: totalRev,
      completedRevenue: completedRev, escrowAmount: escrow,
      cropRevenue: cropRev, cropCount: cropCnt,
    );
  }
}

// ─────────────────────────────────────────────
// REVENUE HERO CARD
// ─────────────────────────────────────────────
class _RevenueCard extends StatelessWidget {
  final _TradeStats stats;
  const _RevenueCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A7A3A), Color(0xFF2E9553), Color(0xFF3AAF60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text('All Time',
                      style: AppTheme.bodySmall.copyWith(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Total Trade Value', style: AppTheme.bodySmall.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            '₹${_formatAmount(stats.totalRevenue)}',
            style: AppTheme.headingLarge.copyWith(color: Colors.white, fontSize: 32),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat('Completed', '₹${_formatAmount(stats.completedRevenue)}', Icons.check_circle_outline),
              const SizedBox(width: 24),
              _miniStat('In Escrow', '₹${_formatAmount(stats.escrowAmount)}', Icons.lock_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white60, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.bodySmall.copyWith(color: Colors.white54, fontSize: 10)),
              Text(value, style: AppTheme.labelLarge.copyWith(color: Colors.white, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STAT GRID (4 cards)
// ─────────────────────────────────────────────
class _StatGrid extends StatelessWidget {
  final _TradeStats stats;
  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      children: [
        _card('Total Orders', stats.total.toString(), Icons.receipt_long_rounded, const Color(0xFF7C3AED)),
        _card('Active', stats.activeOrders.toString(), Icons.hourglass_top_rounded, const Color(0xFFF59E0B)),
        _card('Completed', stats.completed.toString(), Icons.task_alt_rounded, AppTheme.primaryGreen),
        _card('Disputed', stats.disputed.toString(), Icons.gavel_rounded, AppTheme.errorRed),
      ],
    );
  }

  Widget _card(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SUCCESS RATE RING
// ─────────────────────────────────────────────
class _SuccessRateRing extends StatelessWidget {
  final _TradeStats stats;
  const _SuccessRateRing({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text('Success Rate', style: AppTheme.labelLarge.copyWith(fontSize: 13)),
          const SizedBox(height: 12),
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _RingPainter(stats.successRate / 100, AppTheme.primaryGreen),
              child: Center(
                child: Text(
                  '${stats.successRate.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${stats.completed}/${stats.total} trades',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  _RingPainter(this.fraction, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bgPaint);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.fraction != fraction;
}

// ─────────────────────────────────────────────
// TRADE BREAKDOWN
// ─────────────────────────────────────────────
class _TradeBreakdown extends StatelessWidget {
  final _TradeStats stats;
  const _TradeBreakdown({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Breakdown', style: AppTheme.labelLarge.copyWith(fontSize: 13)),
          const SizedBox(height: 12),
          _breakdownItem('Pending', stats.pending, Colors.orange),
          _breakdownItem('Accepted', stats.accepted, const Color(0xFF3B82F6)),
          _breakdownItem('In Escrow', stats.paymentHeld, const Color(0xFF7C3AED)),
          _breakdownItem('Completed', stats.completed, AppTheme.primaryGreen),
          _breakdownItem('Disputed', stats.disputed, AppTheme.errorRed),
        ],
      ),
    );
  }

  Widget _breakdownItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTheme.bodySmall.copyWith(fontSize: 11))),
          Text(count.toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// REVENUE BAR CHART
// ─────────────────────────────────────────────
class _RevenueBarChart extends StatelessWidget {
  final _TradeStats stats;
  const _RevenueBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    // Use crop revenue for bars
    final entries = stats.cropRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(5).toList();
    final maxVal = topEntries.isEmpty ? 1.0 : topEntries.first.value;

    final barColors = [
      AppTheme.primaryGreen,
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF7C3AED),
      const Color(0xFF06B6D4),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text('Revenue by Crop', style: AppTheme.labelLarge.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          if (topEntries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('No data yet', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
              ),
            )
          else
            ...topEntries.asMap().entries.map((e) {
              final idx = e.key;
              final entry = e.value;
              final fraction = entry.value / maxVal;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
                        Text('₹${_formatAmount(entry.value)}',
                          style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700, fontSize: 12, color: barColors[idx % barColors.length])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 10,
                        backgroundColor: barColors[idx % barColors.length].withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(barColors[idx % barColors.length]),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TOP CROPS CARD
// ─────────────────────────────────────────────
class _TopCropsCard extends StatelessWidget {
  final _TradeStats stats;
  const _TopCropsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final sorted = stats.cropCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();

    final medals = ['🥇', '🥈', '🥉'];
    final colors = [const Color(0xFFFFD700), const Color(0xFFC0C0C0), const Color(0xFFCD7F32)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 8),
              Text('Top Traded Crops', style: AppTheme.labelLarge.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          if (top.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('No trades yet', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
              ),
            )
          else
            ...top.asMap().entries.map((e) {
              final idx = e.key;
              final crop = e.value;
              final rev = stats.cropRevenue[crop.key] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors[idx].withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors[idx].withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Text(medals[idx], style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(crop.key, style: AppTheme.labelLarge.copyWith(fontSize: 14)),
                          Text('${crop.value} orders • ₹${_formatAmount(rev)}',
                            style: AppTheme.bodySmall.copyWith(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RECENT TRANSACTIONS
// ─────────────────────────────────────────────
class _RecentTransactions extends StatelessWidget {
  final List<model.Order> orders;
  const _RecentTransactions({required this.orders});

  @override
  Widget build(BuildContext context) {
    final recent = orders.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: AppTheme.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text('Recent Transactions', style: AppTheme.labelLarge.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('No transactions yet', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
              ),
            )
          else
            ...recent.map((o) {
              final state = o.tradeState;
              final stateColor = _stateColor(state);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: stateColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_stateIcon(state), color: stateColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.crop, style: AppTheme.labelLarge.copyWith(fontSize: 13)),
                          Text('${o.quantity} ${o.unit}', style: AppTheme.bodySmall.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${(o.quantity * o.pricePerUnit).toStringAsFixed(0)}',
                          style: AppTheme.labelLarge.copyWith(fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: stateColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            state.toUpperCase(),
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: stateColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'completed': return AppTheme.primaryGreen;
      case 'paymentHeld': return const Color(0xFF7C3AED);
      case 'accepted': return const Color(0xFF3B82F6);
      case 'disputed': return AppTheme.errorRed;
      case 'rejected': return AppTheme.errorRed;
      default: return Colors.orange;
    }
  }

  IconData _stateIcon(String state) {
    switch (state) {
      case 'completed': return Icons.task_alt_rounded;
      case 'paymentHeld': return Icons.lock_rounded;
      case 'accepted': return Icons.handshake_rounded;
      case 'disputed': return Icons.gavel_rounded;
      case 'rejected': return Icons.cancel_rounded;
      default: return Icons.hourglass_top_rounded;
    }
  }
}

// ─── Helper ──────────────────────────────────
String _formatAmount(double amount) {
  if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
  return amount.toStringAsFixed(0);
}
