import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/product_item.dart';
import '../../core/utils/formatters.dart';
import '../../state/shipment_state.dart';
import '../widgets/sourcing_sandbox/sourcing_sandbox_dialog.dart';

class SourcingSandboxView extends ConsumerStatefulWidget {
  const SourcingSandboxView({super.key});

  @override
  ConsumerState<SourcingSandboxView> createState() => _SourcingSandboxViewState();
}

class _SourcingSandboxViewState extends ConsumerState<SourcingSandboxView> {
  final double _benchmarkFreightPerCbmPkr = 16500.0;
  final double _benchmarkDutyPerKgPkr = 220.0;

  final List<SourcingQuoteCandidate> _candidates = [
    SourcingQuoteCandidate(
      id: 'c1',
      supplierName: 'Factory A (Pinghu Toys)',
      productName: 'Ride-On Electric Jeep',
      modelNumber: 'JJ-2188',
      fpiOriginPriceRmb: 450.0,
      cartonLengthCm: 135.0,
      cartonWidthCm: 75.0,
      cartonHeightCm: 52.0,
      grossWeightKg: 28.5,
    ),
    SourcingQuoteCandidate(
      id: 'c2',
      supplierName: 'Factory B (Xingtai Speed)',
      productName: 'Ride-On Electric Jeep (Compact Pack)',
      modelNumber: 'XT-900',
      fpiOriginPriceRmb: 465.0,
      cartonLengthCm: 122.0,
      cartonWidthCm: 68.0,
      cartonHeightCm: 45.0,
      grossWeightKg: 26.0,
    ),
    SourcingQuoteCandidate(
      id: 'c3',
      supplierName: 'Factory C (Linyi Plastic)',
      productName: 'Ride-On Electric Jeep',
      modelNumber: 'LY-8800',
      fpiOriginPriceRmb: 430.0,
      cartonLengthCm: 145.0,
      cartonWidthCm: 80.0,
      cartonHeightCm: 56.0,
      grossWeightKg: 31.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final rates = ref.watch(currencyRatesProvider);
    final rmbRate = rates['RMB']?.effectiveRate ?? 39.20;

    final scored = _candidates.map((c) {
      final purchasePkr = c.fpiOriginPriceRmb * rmbRate;
      final freightPkr = c.cbmPerPiece * _benchmarkFreightPerCbmPkr;
      final dutyPkr = (c.grossWeightKg / c.piecesPerCarton) * _benchmarkDutyPerKgPkr;
      final normalizedLandedPkr = purchasePkr + freightPkr + dutyPkr;

      return {
        'candidate': c,
        'purchasePkr': purchasePkr,
        'freightPkr': freightPkr,
        'dutyPkr': dutyPkr,
        'normalizedLandedPkr': normalizedLandedPkr,
      };
    }).toList();

    scored.sort((a, b) => ((a['normalizedLandedPkr'] as double).compareTo(b['normalizedLandedPkr'] as double)));
    final lowestLanded = (scored.first['normalizedLandedPkr'] as double);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOURCING SANDBOX: MULTI-SUPPLIER QUOTE BENCHMARKING',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Simulate true Unit Landed Cost (ULC) before issuing purchase orders. Discovers hidden packing bulkiness penalties.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  'Live RMB: PKR ${rmbRate.toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cards Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 950;
              final cardWidth = isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (int i = 0; i < scored.length; i++)
                    _buildCandidateCard(
                      scored[i],
                      i == 0,
                      lowestLanded,
                      cardWidth,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(
    Map<String, dynamic> data,
    bool isWinner,
    double lowestLanded,
    double cardWidth,
  ) {
    final c = data['candidate'] as SourcingQuoteCandidate;
    final purchasePkr = data['purchasePkr'] as double;
    final freightPkr = data['freightPkr'] as double;
    final dutyPkr = data['dutyPkr'] as double;
    final landedPkr = data['normalizedLandedPkr'] as double;
    final penalty = landedPkr - lowestLanded;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner ? const Color(0xFF10B981) : const Color(0xFF1E293B),
          width: isWinner ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  c.supplierName,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isWinner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '★ WINNER (BEST ULC)',
                    style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${Formatters.pkr(penalty)} / pc penalty',
                    style: const TextStyle(color: Color(0xFFF87171), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(c.productName, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          const SizedBox(height: 16),

          // Total Landed Cost Display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Normalized Landed Cost:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                Text(
                  Formatters.pkr(landedPkr),
                  style: TextStyle(
                    color: isWinner ? const Color(0xFF34D399) : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Cost Breakdown Anatomy
          _costRow('FOB Purchase', '¥ ${c.fpiOriginPriceRmb.toStringAsFixed(0)}', Formatters.pkr(purchasePkr)),
          const SizedBox(height: 6),
          _costRow('Est. Ocean Freight (${c.cbmPerPiece.toStringAsFixed(3)} m³)', 'PKR 16,500/m³', Formatters.pkr(freightPkr)),
          const SizedBox(height: 6),
          _costRow('Customs & Duty (${c.grossWeightKg.toStringAsFixed(1)} kg)', 'PKR 220/kg', Formatters.pkr(dutyPkr)),
          const SizedBox(height: 14),

          // Carton Packaging Specs
          Text(
            'Box Dimensions: ${c.cartonLengthCm.toStringAsFixed(0)}*${c.cartonWidthCm.toStringAsFixed(0)}*${c.cartonHeightCm.toStringAsFixed(0)} cm (${c.cbmPerCarton.toStringAsFixed(3)} CBM)',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isWinner ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
              ),
              icon: Icon(isWinner ? Icons.check_circle_rounded : Icons.add_rounded, size: 16),
              label: Text(
                isWinner ? 'Promote Winner to Shipment' : 'Add to Container',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                ref.read(productItemsProvider.notifier).addItem(
                      ProductItem(
                        id: const Uuid().v4(),
                        name: c.productName,
                        modelNumber: c.modelNumber,
                        supplierName: c.supplierName,
                        cartonLength: c.cartonLengthCm,
                        cartonWidth: c.cartonWidthCm,
                        cartonHeight: c.cartonHeightCm,
                        orderedCartons: 60,
                        gwPerCartonKg: c.grossWeightKg,
                        nwPerCartonKg: c.grossWeightKg * 0.9,
                        unitPriceOrigin: c.fpiOriginPriceRmb,
                        originCurrency: 'RMB',
                      ),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${c.productName} (${c.modelNumber}) to container.'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _costRow(String label, String sub, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
            Text(sub, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
          ],
        ),
        Text(amount, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

