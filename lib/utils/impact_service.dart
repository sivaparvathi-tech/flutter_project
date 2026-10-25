import '../models/product.dart';

/// Estimated environmental impact of re-using a product instead of buying
/// new. Values are mock estimates derived from the product price and shown to
/// illustrate the circular-economy benefit; they are clearly labelled as
/// estimates in the UI.
class ImpactEstimate {
  final double co2Kg;
  final double wasteKg;
  final double waterLitres;

  const ImpactEstimate({
    required this.co2Kg,
    required this.wasteKg,
    required this.waterLitres,
  });
}

ImpactEstimate estimatedImpactFor(Product product) {
  // Deterministic mock scale tied to the product so values feel stable.
  final base = product.price.clamp(10, 5000).toDouble();
  return ImpactEstimate(
    co2Kg: (base * 0.042).roundToDouble(),
    wasteKg: (base * 0.008).roundToDouble(),
    waterLitres: (base * 3.4).roundToDouble(),
  );
}