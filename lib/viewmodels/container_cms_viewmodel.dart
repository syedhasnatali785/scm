import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/container_spec.dart';
import '../../core/models/product_item.dart';
import '../../engine/packing/container_packer.dart';
import '../../engine/packing/packed_box.dart';

@immutable
class ContainerCmsState {
  final ContainerSpec containerSpec;
  final PackingResult? packingResult;
  final bool isPacking;
  final int activeScrubberStep;
  final String? errorMessage;

  const ContainerCmsState({
    required this.containerSpec,
    this.packingResult,
    this.isPacking = false,
    this.activeScrubberStep = 0,
    this.errorMessage,
  });

  ContainerCmsState copyWith({
    ContainerSpec? containerSpec,
    PackingResult? packingResult,
    bool? isPacking,
    int? activeScrubberStep,
    String? errorMessage,
  }) {
    return ContainerCmsState(
      containerSpec: containerSpec ?? this.containerSpec,
      packingResult: packingResult ?? this.packingResult,
      isPacking: isPacking ?? this.isPacking,
      activeScrubberStep: activeScrubberStep ?? this.activeScrubberStep,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ContainerCmsViewModel extends StateNotifier<ContainerCmsState> {
  ContainerCmsViewModel()
      : super(
          ContainerCmsState(
            containerSpec: ContainerSpec.fromPreset(ContainerPreset.fortyHC),
          ),
        );

  void selectPreset(ContainerPreset preset) {
    state = state.copyWith(
      containerSpec: ContainerSpec.fromPreset(preset),
    );
  }

  void updateDimensions({
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    double? doorWidthCm,
    double? doorHeightCm,
    double? maxPayloadKg,
    double? roadAxleLimitKg,
    double? usableVolumePct,
  }) {
    state = state.copyWith(
      containerSpec: state.containerSpec.copyWith(
        lengthCm: lengthCm,
        widthCm: widthCm,
        heightCm: heightCm,
        doorWidthCm: doorWidthCm,
        doorHeightCm: doorHeightCm,
        maxGrossPayloadKg: maxPayloadKg,
        roadAxleLimitKg: roadAxleLimitKg,
        usableVolumePct: usableVolumePct,
      ),
    );
  }

  void setScrubberStep(int step) {
    final maxSteps = state.packingResult?.boxes.length ?? 0;
    final clamped = step.clamp(0, maxSteps);
    state = state.copyWith(activeScrubberStep: clamped);
  }

  Future<void> runPacker(List<ProductItem> items) async {
    state = state.copyWith(isPacking: true);
    try {
      final result = await ContainerPacker.packAsync(
        items: items,
        container: state.containerSpec,
      );
      state = state.copyWith(
        packingResult: result,
        isPacking: false,
        activeScrubberStep: result.boxes.length,
      );
    } catch (e) {
      // Fallback to synchronous packer
      final result = ContainerPacker.pack(
        items: items,
        container: state.containerSpec,
      );
      state = state.copyWith(
        packingResult: result,
        isPacking: false,
        activeScrubberStep: result.boxes.length,
      );
    }
  }
}

final containerCmsViewModelProvider =
    StateNotifierProvider<ContainerCmsViewModel, ContainerCmsState>((ref) {
  return ContainerCmsViewModel();
});
