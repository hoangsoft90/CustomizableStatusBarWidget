import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/widget_design.dart';

/// CRUD service for [WidgetDesign] persistence.
///
/// - Designs list is stored in SharedPreferences as JSON.
/// - Source images are stored in app documents directory under `designs/`.
/// - Free tier: max 3 designs. Premium: unlimited (checked externally).
class DesignStorageService {
  static const String _designsKey = 'widget_designs';
  static const String _designsDir = 'designs';

  /// Maximum number of designs for free users.
  static const int freeQuota = 3;

  final SharedPreferences _prefs;

  DesignStorageService(this._prefs);

  /// Initialise by loading the prefs instance. Call once at app start.
  static Future<DesignStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return DesignStorageService(prefs);
  }

  // ── Directory helpers ──────────────────────────────────

  /// Get the app documents directory.
  Future<Directory> get _designsDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_designsDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Get the full path for a design file.
  Future<String> _designFilePath(String designId, String extension) async {
    final dir = await _designsDirectory;
    return '${dir.path}/$designId.$extension';
  }

  /// Get the path for a design's source image.
  Future<String> sourceImagePath(String designId) =>
      _designFilePath(designId, 'jpg');

  /// Get the path for a baked widget bitmap.
  Future<String> bakedBitmapPath(String designId, int widgetId) async {
    final dir = await _designsDirectory;
    return '${dir.path}/${designId}_$widgetId.png';
  }

  // ── CRUD ───────────────────────────────────────────────

  /// Load all saved designs.
  List<WidgetDesign> loadAll() {
    final jsonString = _prefs.getString(_designsKey);
    if (jsonString == null) return [];
    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((e) => WidgetDesign.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Save the full list of designs.
  Future<bool> _saveAll(List<WidgetDesign> designs) {
    final jsonList = designs.map((d) => d.toJson()).toList();
    return _prefs.setString(_designsKey, jsonEncode(jsonList));
  }

  /// Load a single design by ID.
  WidgetDesign? loadById(String id) {
    try {
      return loadAll().firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Save or update a design. If a design with the same [id] exists,
  /// it is replaced. Returns true on success.
  Future<bool> save(WidgetDesign design) async {
    final designs = loadAll();
    final index = designs.indexWhere((d) => d.id == design.id);
    if (index >= 0) {
      designs[index] = design;
    } else {
      designs.add(design);
    }
    return _saveAll(designs);
  }

  /// Delete a design by ID and remove all associated image files
  /// (source image + any baked bitmaps).
  Future<bool> delete(String id) async {
    final designs = loadAll();
    designs.removeWhere((d) => d.id == id);

    // Clean up files
    try {
      final dir = await _designsDirectory;
      if (await dir.exists()) {
        // Delete source image
        final sourceFile = File('${dir.path}/$id.jpg');
        if (await sourceFile.exists()) {
          await sourceFile.delete();
        }
        // Delete any baked bitmaps for this design
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.contains('${id}_')) {
            await entity.delete();
          }
        }
      }
    } catch (_) {
      // File cleanup is best-effort
    }

    return _saveAll(designs);
  }

  /// Rename a design.
  Future<bool> rename(String id, String newName) async {
    final design = loadById(id);
    if (design == null) return false;
    return save(design.copyWith(name: newName, updatedAt: DateTime.now()));
  }

  // ── Quota ──────────────────────────────────────────────

  /// Check if the user has reached the free design quota.
  bool isQuotaFull({bool isPremium = false}) {
    if (isPremium) return false;
    return loadAll().length >= freeQuota;
  }

  /// Get remaining design slots for free users.
  int remainingSlots({bool isPremium = false}) {
    if (isPremium) return 999;
    return (freeQuota - loadAll().length).clamp(0, freeQuota);
  }

  // ── Baked bitmap cache ─────────────────────────────────

  /// Check if a baked bitmap exists for a given design + widget instance.
  Future<bool> hasBakedBitmap(String designId, int widgetId) async {
    final path = await bakedBitmapPath(designId, widgetId);
    return File(path).exists();
  }

  /// Delete all baked bitmaps for a design (used when design is updated).
  Future<void> clearBakedBitmaps(String designId) async {
    try {
      final dir = await _designsDirectory;
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.contains('${designId}_')) {
            await entity.delete();
          }
        }
      }
    } catch (_) {
      // Best-effort cleanup
    }
  }

  /// Get the designs directory path (for native code to access).
  Future<String> getDesignsDirectoryPath() async {
    final dir = await _designsDirectory;
    return dir.path;
  }
}
