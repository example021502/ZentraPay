class Investment {
  final String investmentId;
  final String name;
  final String investmentType;
  final String? symbol;
  final String quantity;
  final String buyPrice;
  final String currentPrice;
  final String currencyCode;
  final String status;

  Investment({
    required this.investmentId,
    required this.name,
    required this.investmentType,
    this.symbol,
    required this.quantity,
    required this.buyPrice,
    required this.currentPrice,
    required this.currencyCode,
    required this.status,
  });

  factory Investment.fromJson(Map<String, dynamic> json) => Investment(
    investmentId: json['investmentId'] ?? '',
    name: json['name'] ?? '',
    investmentType: json['investmentType'] ?? 'OTHER',
    symbol: json['symbol'],
    quantity: (json['quantity'] ?? '0').toString(),
    buyPrice: (json['buyPrice'] ?? '0').toString(),
    currentPrice: (json['currentPrice'] ?? json['buyPrice'] ?? '0').toString(),
    currencyCode: json['currencyCode'] ?? '',
    status: json['status'] ?? 'ACTIVE',
  );
}

class LiquidityProfile {
  final String totalValue;
  final String totalGainLossPercent;
  final String riskProfile;

  LiquidityProfile({
    required this.totalValue,
    required this.totalGainLossPercent,
    required this.riskProfile,
  });

  factory LiquidityProfile.fromJson(Map<String, dynamic> json) =>
      LiquidityProfile(
        totalValue: (json['totalValue'] ?? '0').toString(),
        totalGainLossPercent: (json['totalGainLossPercent'] ?? '0')
            .toString(),
        riskProfile: json['riskProfile'] ?? 'MODERATE',
      );
}

class LiquidityTrendPoint {
  final String recordedAt;
  final String totalValue;

  LiquidityTrendPoint({required this.recordedAt, required this.totalValue});

  factory LiquidityTrendPoint.fromJson(Map<String, dynamic> json) =>
      LiquidityTrendPoint(
        recordedAt: json['recordedAt'] ?? '',
        totalValue: (json['totalValue'] ?? '0').toString(),
      );
}

class InvestmentRisk {
  final String investmentId;
  final String name;
  final String type;
  final String message;
  final String severity;

  InvestmentRisk({
    required this.investmentId,
    required this.name,
    required this.type,
    required this.message,
    required this.severity,
  });

  factory InvestmentRisk.fromJson(Map<String, dynamic> json) =>
      InvestmentRisk(
        investmentId: json['investmentId'] ?? '',
        name: json['name'] ?? '',
        type: json['type'] ?? '',
        message: json['message'] ?? '',
        severity: json['severity'] ?? 'LOW',
      );
}

class InvestmentAlert {
  final String investmentId;
  final String symbol;
  final String changePercent;

  InvestmentAlert({
    required this.investmentId,
    required this.symbol,
    required this.changePercent,
  });

  factory InvestmentAlert.fromJson(Map<String, dynamic> json) =>
      InvestmentAlert(
        investmentId: json['investmentId'] ?? '',
        symbol: json['symbol'] ?? '',
        changePercent: (json['changePercent'] ?? '0').toString(),
      );
}
