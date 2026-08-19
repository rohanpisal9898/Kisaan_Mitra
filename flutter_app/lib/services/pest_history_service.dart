import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Local & Remote Pest Report History Manager.
/// Ensures diagnosis reports and image references remain accessible after app restarts.
class PestHistoryService {
  static const String _storageKey = 'pest_report_history_v1';

  /// Saves a scan report record locally and attempts backend sync.
  static Future<void> saveReport(Map<String, dynamic> scanDoc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> reports = await getLocalReports();

      final String scanId = scanDoc['scan_id']?.toString() ?? 'scan_${DateTime.now().millisecondsSinceEpoch}';
      
      // Remove duplicate if scan_id already exists
      reports.removeWhere((item) => item['scan_id']?.toString() == scanId);

      // Prepend newest scan at top
      reports.insert(0, scanDoc);

      // Keep up to 50 reports locally
      if (reports.length > 50) {
        reports = reports.sublist(0, 50);
      }

      final String jsonStr = jsonEncode(reports);
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      print('[PEST HISTORY SAVE ERROR] $e');
    }
  }

  /// Retrieves local saved reports, merging with remote backend reports when online.
  static Future<List<Map<String, dynamic>>> getReports({String userId = 'guest'}) async {
    List<Map<String, dynamic>> localReports = await getLocalReports();

    try {
      final remoteReports = await ApiService.fetchPestHistory(userId: userId);
      if (remoteReports.isNotEmpty) {
        // Merge remote with local avoiding duplicates
        final Set<String> existingIds = localReports.map((e) => e['scan_id']?.toString() ?? '').toSet();
        for (var remote in remoteReports) {
          final String rId = remote['scan_id']?.toString() ?? '';
          if (rId.isNotEmpty && !existingIds.contains(rId)) {
            localReports.add(remote);
          }
        }
      }
    } catch (e) {
      print('[PEST HISTORY FETCH REMOTE ERROR] $e');
    }

    return localReports;
  }

  /// Retrieves local reports from SharedPreferences.
  static Future<List<Map<String, dynamic>>> getLocalReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List decoded = jsonDecode(jsonStr);
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      print('[PEST HISTORY GET LOCAL ERROR] $e');
    }
    return [];
  }

  /// Finds a specific scan report by scan ID.
  static Future<Map<String, dynamic>?> getReportById(String scanId) async {
    final reports = await getLocalReports();
    for (var r in reports) {
      if (r['scan_id']?.toString() == scanId) {
        return r;
      }
    }

    try {
      return await ApiService.fetchPestReportById(scanId);
    } catch (_) {}

    return null;
  }
}
