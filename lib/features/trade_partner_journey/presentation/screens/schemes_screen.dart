/// Schemes Screen
/// View active promotional schemes and eligibility

import 'package:flutter/material.dart';
import '../../../../core/models/trade_partner_models.dart';
import '../../../../core/services/trade_partner_service.dart';

class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  bool _isLoading = true;
  List<Scheme> _schemes = [];

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  Future<void> _loadSchemes() async {
    setState(() => _isLoading = true);
    try {
      final schemes = await TradePartnerService.getActiveSchemes();
      setState(() {
        _schemes = schemes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load schemes: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Schemes & Offers'),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSchemes,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _schemes.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _schemes.length,
                itemBuilder: (context, index) {
                  return _SchemeCard(scheme: _schemes[index]);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No active schemes',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new offers',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ============================================
// SCHEME CARD
// ============================================

class _SchemeCard extends StatelessWidget {
  final Scheme scheme;

  const _SchemeCard({required this.scheme});

  Color get _typeColor {
    switch (scheme.type) {
      case SchemeType.discount:
        return const Color(0xFF4CAF50);
      case SchemeType.cashback:
        return const Color(0xFF2196F3);
      case SchemeType.gift:
        return const Color(0xFFE91E63);
      case SchemeType.bonus:
        return const Color(0xFFFF9800);
      case SchemeType.combo:
        return const Color(0xFF9C27B0);
    }
  }

  IconData get _typeIcon {
    switch (scheme.type) {
      case SchemeType.discount:
        return Icons.percent;
      case SchemeType.cashback:
        return Icons.currency_exchange;
      case SchemeType.gift:
        return Icons.card_giftcard;
      case SchemeType.bonus:
        return Icons.add_box;
      case SchemeType.combo:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_typeColor, _typeColor.withOpacity(0.7)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_typeIcon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scheme.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          scheme.type.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!scheme.isEligible)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Colors.white70, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Not Eligible',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (scheme.description != null)
                  Text(
                    scheme.description!,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),

                const SizedBox(height: 16),

                // Benefits Row
                Row(
                  children: [
                    if (scheme.discountPercentage != null)
                      _BenefitChip(
                        label:
                            '${scheme.discountPercentage!.toStringAsFixed(0)}% Off',
                        color: _typeColor,
                      ),
                    if (scheme.discountAmount != null)
                      _BenefitChip(
                        label:
                            'AED ${scheme.discountAmount!.toStringAsFixed(0)} Off',
                        color: _typeColor,
                      ),
                    if (scheme.minOrderValue != null)
                      _BenefitChip(
                        label:
                            'Min. AED ${scheme.minOrderValue!.toStringAsFixed(0)}',
                        color: Colors.grey,
                      ),
                  ],
                ),

                const Divider(height: 24),

                // Validity
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Valid till ${_formatDate(scheme.endDate)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${scheme.endDate.difference(DateTime.now()).inDays} days left',
                      style: TextStyle(
                        color: _typeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                // Earned/Pending Benefits
                if (scheme.earnedBenefit != null && scheme.earnedBenefit! > 0 ||
                    scheme.pendingBenefit != null &&
                        scheme.pendingBenefit! > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        if (scheme.earnedBenefit != null &&
                            scheme.earnedBenefit! > 0)
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Earned',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'AED ${scheme.earnedBenefit!.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (scheme.pendingBenefit != null &&
                            scheme.pendingBenefit! > 0)
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Pending',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'AED ${scheme.pendingBenefit!.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Color(0xFFFF9800),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ============================================
// BENEFIT CHIP
// ============================================

class _BenefitChip extends StatelessWidget {
  final String label;
  final Color color;

  const _BenefitChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
