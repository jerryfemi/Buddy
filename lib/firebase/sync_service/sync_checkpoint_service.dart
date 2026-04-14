import 'package:hive/hive.dart';

class SyncCheckpointService {
  static const String _boxName = 'syncMetaBox';

  Future<Box<int>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<int>(_boxName);
    }
    return Hive.openBox<int>(_boxName);
  }

  String _key(String userId, String collection) => '${userId}_$collection';

  Future<DateTime?> getLastPullAt({
    required String userId,
    required String collection,
  }) async {
    final box = await _openBox();
    final ms = box.get(_key(userId, collection));
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> markPulledNow({
    required String userId,
    required String collection,
  }) async {
    final box = await _openBox();
    await box.put(
      _key(userId, collection),
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
