import 'dart:convert';

import 'package:get/get.dart';
import 'package:neumorphic_calculator/repo/database.dart';
import 'package:neumorphic_calculator/utils/const.dart';
import 'package:neumorphic_calculator/utils/result_model.dart';

class HistoryController extends GetxController
    with StateMixin<List<ResultModel>> {
  HistoryController(this._database);
  static HistoryController get instance => Get.find<HistoryController>();

  final DatabaseRepository _database;
  RxBool isClearing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  /// Oldest entries are dropped beyond this.
  static const int maxEntries = 200;

  void _loadData() {
    final stored = _database.get<List<String>>(AppConst.historyKey);
    if (stored == null || stored.isEmpty) {
      change([], status: RxStatus.empty());
      return;
    }

    final results = <ResultModel>[];
    for (final raw in stored) {
      try {
        results.add(ResultModel.fromJson(jsonDecode(raw)));
      } catch (_) {
        // A damaged entry must not take the whole history down with it.
      }
    }
    // Drop damaged entries for good so list positions stay aligned with
    // what is stored (removeAt relies on that).
    if (results.length != stored.length) {
      _database.set<List<String>>(AppConst.historyKey,
          results.map((r) => jsonEncode(r.toJson())).toList());
    }
    change(results,
        status: results.isEmpty ? RxStatus.empty() : RxStatus.success());
  }

  void addData(ResultModel resultModel) {
    final history = List<String>.of(
        _database.get<List<String>>(AppConst.historyKey) ?? const []);
    history.insert(0, jsonEncode(resultModel.toJson()));
    if (history.length > maxEntries) {
      history.removeRange(maxEntries, history.length);
    }
    _database.set<List<String>>(AppConst.historyKey, history);
    _loadData();
  }

  void removeAt(int index) {
    final history = List<String>.of(
        _database.get<List<String>>(AppConst.historyKey) ?? const []);
    if (index < 0 || index >= history.length) return;
    history.removeAt(index);
    if (history.isEmpty) {
      _database.remove(AppConst.historyKey);
    } else {
      _database.set<List<String>>(AppConst.historyKey, history);
    }
    _loadData();
  }

  void clearData() {
    _database.remove(AppConst.historyKey);
    change([], status: RxStatus.empty());
  }
}
