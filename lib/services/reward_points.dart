
// 1 pt per whole $1 of pre-discount subtotal.
// Redeem: 100 pts = $1.00 
class RewardPoints {
  RewardPoints._();
  static final RewardPoints instance = RewardPoints._();

  final Map<String, int> _balances = {}; 

  Future<int> getPoints(String userEmail) async {
    return _balances[userEmail] ?? 0;
  }

  Future<void> setPoints(String userEmail, int points) async {
    _balances[userEmail] = points.clamp(0, 1 << 30);
  }

  //Returns the new balance.
  Future<int> addPoints(String userEmail, int delta) async {
    final cur = await getPoints(userEmail);
    final next = (cur + delta).clamp(0, 1 << 30);
    _balances[userEmail] = next;
    return next;
  }

  //Redeemed points.
  Future<int> redeemUpTo(String userEmail, int pointsToRedeem) async {
    final cur = await getPoints(userEmail);
    final r = pointsToRedeem.clamp(0, cur);
    _balances[userEmail] = cur - r;
    return r;
  }
}
