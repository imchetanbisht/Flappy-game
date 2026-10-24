enum PowerUpType {
  shield,
  speedBoost,
}

class ActivePowerUp {
  final PowerUpType type;
  double remainingSeconds;
  final double totalSeconds;

  ActivePowerUp({
    required this.type,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  bool get isExpired => remainingSeconds <= 0;
  double get progress => (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
}
