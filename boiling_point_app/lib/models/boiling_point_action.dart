class BoingPointAction {
  final String action;
  final int rewardPoints;
  final String status;
  final String targetDate;

  BoingPointAction({
    required this.action,
    required this.rewardPoints,
    required this.status,
    required this.targetDate,
  });

  factory BoingPointAction.fromJson(Map<String, dynamic> json) {
    return BoingPointAction(
      action: json['action'],
      rewardPoints: json['reward_points'],
      status: json['status'],
      targetDate: json['target_date'],
    );
  }
}


