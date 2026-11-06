import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/product_item.dart';
import '../../../core/utils/formatters.dart';
import '../../../state/shipment_state.dart';

class SourcingQuoteCandidate {
  final String id;
  final String supplierName;
  final String productName;
  final String modelNumber;
  final double fpiOriginPriceRmb;
  final double cartonLengthCm;
  final double cartonWidthCm;
  final double cartonHeightCm;
  final double grossWeightKg;
  final int piecesPerCarton;

  SourcingQuoteCandidate({
    required this.id,
    required this.supplierName,
    required this.productName,
    required this.modelNumber,
    required this.fpiOriginPriceRmb,
    required this.cartonLengthCm,
    required this.cartonWidthCm,
    required this.cartonHeightCm,
    required this.grossWeightKg,
    this.piecesPerCarton = 1,
  });

  double get cbmPerCarton =>
      (cartonLengthCm * cartonWidthCm * cartonHeightCm) / 1000000.0;
  double get cbmPerPiece => cbmPerCarton / piecesPerCarton;
}

class SourcingSandboxDialog extends ConsumerStatefulWidget {
  const SourcingSandboxDialog({super.key});

  @override
  ConsumerState<SourcingSandboxDialog> createState() =>
      _SourcingSandboxDialogState();
}

class _SourcingSandboxDialogState extends ConsumerState<SourcingSandboxDialog> {
  // Corridor Benchmarks (e.g. Ningbo/Shenzhen to Karachi)
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
      cartonHeightCm: 52.0, // 0.526 CBM
      grossWeightKg: 28.5,
    ),
    SourcingQuoteCandidate(
      id: 'c2',
      supplierName: 'Factory B (Xingtai Speed)',
      productName: 'Ride-On Electric Jeep (Compact Pack)',
      modelNumber: 'XT-900',
      fpiOriginPriceRmb: 465.0, // Higher FOB price!
      cartonLengthCm: 122.0,
      cartonWidthCm: 68.0,
      cartonHeightCm: 45.0, // Only 0.373 CBM (much more compact packaging!)
      grossWeightKg: 26.0,
    ),
    SourcingQuoteCandidate(
      id: 'c3',
      supplierName: 'Factory C (Linyi Plastic)',
      productName: 'Ride-On Electric Jeep',
      modelNumber: 'LY-8800',
      fpiOriginPriceRmb: 430.0, // Cheapest FOB price!
      cartonLengthCm: 145.0,
      cartonWidthCm: 80.0,
      cartonHeightCm: 56.0, // 0.649 CBM (Bulky box!)
      grossWeightKg: 31.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final rates = ref.watch(currencyRatesProvider);
    final rmbRate = rates['RMB']?.effectiveRate ?? 39.20;

    // Evaluate normalized landed cost per piece for each candidate
    final scored =
        _candidates.map((c) {
          final purchasePkr = c.fpiOriginPriceRmb * rmbRate;
          final freightPkr = c.cbmPerPiece * _benchmarkFreightPerCbmPkr;
          final dutyPkr =
              (c.grossWeightKg / c.piecesPerCarton) * _benchmarkDutyPerKgPkr;
          final normalizedLandedPkr = purchasePkr + freightPkr + dutyPkr;

          return {
            'candidate': c,
            'purchasePkr': purchasePkr,
            'freightPkr': freightPkr,
            'dutyPkr': dutyPkr,
            'landedPkr': normalizedLandedPkr,
          };
        }).toList()..sort(
          (a, b) =>
              (a['landedPkr'] as double).compareTo(b['landedPkr'] as double),
        );

    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(
            Icons.compare_arrows_rounded,
            color: Color(0xFF38BDF8),
            size: 22,
          ),
          SizedBox(width: 10),
          Text(
            'Pre-Order Sourcing Sandbox (Normalized Comparison)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 800,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explanatory Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Text(
                '💡 Fair Comparison: A cheaper FOB quote can actually be MORE expensive landed if the factory uses bulky master cartons. The sandbox normalizes ocean freight & duty to reveal the true winner.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Competing Factories Comparison Table / Cards
            Expanded(
              child: ListView.separated(
                itemCount: scored.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final entry = scored[i];
                  final SourcingQuoteCandidate c =
                      entry['candidate'] as SourcingQuoteCandidate;
                  final bool isWinner = i == 0;
                  final landed = entry['landedPkr'] as double;
                  final pur = entry['purchasePkr'] as double;
                  final fr = entry['freightPkr'] as double;
                  final dt = entry['dutyPkr'] as double;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isWinner
                          ? const Color(0xFF064E3B).withOpacity(0.4)
                          : const Color(0xFF131D38),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isWinner
                            ? const Color(0xFF10B981)
                            : const Color(0xFF223154),
                        width: isWinner ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isWinner)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    c.supplierName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isWinner) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'TRUE BEST VALUE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${c.productName} (${c.modelNumber}) · Box: ${c.cartonLengthCm}×${c.cartonWidthCm}×${c.cartonHeightCm} cm (${c.cbmPerCarton.toStringAsFixed(3)} m³) · ${c.grossWeightKg} kg',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'FOB: ¥ ${c.fpiOriginPriceRmb.toStringAsFixed(0)} (${Formatters.pkr(pur)})  +  Freight: ${Formatters.pkr(fr)}  +  Duty: ${Formatters.pkr(dt)}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.pkr(landed),
                              style: TextStyle(
                                color: isWinner
                                    ? const Color(0xFF34D399)
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'true landed / pc',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isWinner
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF1E293B),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                minimumSize: const Size(60, 28),
                              ),
                              onPressed: () {
                                ref
                                    .read(productItemsProvider.notifier)
                                    .addItem(
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
                                Navigator.pop(context);
                              },
                              child: Text(
                                isWinner
                                    ? 'Promote Winner'
                                    : 'Add to Container',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }
}
