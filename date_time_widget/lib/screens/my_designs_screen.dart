import 'package:flutter/material.dart';

import '../models/clock_config.dart';
import '../models/widget_design.dart';
import '../services/design_storage_service.dart';
import '../services/share_service.dart';
import '../widgets/clock_preview.dart';
import 'editor_screen.dart' show EditorScreen, EditorScreenResult;

/// Screen showing user-created designs (My Designs).
///
/// Displays a grid of design cards with mini live previews.
/// User can create, rename, delete, and apply designs.
///
/// Returns a [WidgetDesign] to the caller via [Navigator.pop]
/// when the user taps "Apply" on a design.
class MyDesignsScreen extends StatefulWidget {
  final DesignStorageService designStorage;
  final bool isPremium;

  const MyDesignsScreen({
    super.key,
    required this.designStorage,
    this.isPremium = false,
  });

  @override
  State<MyDesignsScreen> createState() => _MyDesignsScreenState();
}

class _MyDesignsScreenState extends State<MyDesignsScreen> {
  List<WidgetDesign> _designs = [];

  @override
  void initState() {
    super.initState();
    _loadDesigns();
  }

  void _loadDesigns() {
    setState(() => _designs = widget.designStorage.loadAll());
  }

  bool get _canCreate => !widget.designStorage.isQuotaFull(isPremium: widget.isPremium);
  int get _remaining => widget.designStorage.remainingSlots(isPremium: widget.isPremium);

  void _applyDesign(WidgetDesign design) {
    Navigator.of(context).pop(design);
  }

  Future<void> _createDesign() async {
    if (!_canCreate) {
      _showQuotaFullDialog();
      return;
    }

    // Navigate to editor with empty config to create new design
    if (!mounted) return;
    final result = await Navigator.of(context).push<EditorScreenResult>(
      MaterialPageRoute(
        builder: (_) => EditorScreen(
          config: const ClockConfig(),
          storage: null, // Not saving to global config yet
        ),
      ),
    );

    if (result == null || !mounted) return;

    // Show name dialog
    final name = await _showNameDialog();
    if (name == null || name.isEmpty) return;

    final design = WidgetDesign(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      clock: result.config,
      background: result.background,
      updatedAt: DateTime.now(),
    );

    await widget.designStorage.save(design);
    _loadDesigns();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Design "$name" created')),
      );
    }
  }

  Future<void> _renameDesign(WidgetDesign design) async {
    final name = await _showNameDialog(initial: design.name);
    if (name == null || name.isEmpty || name == design.name) return;

    await widget.designStorage.rename(design.id, name);
    _loadDesigns();
  }

  Future<void> _deleteDesign(WidgetDesign design) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete design?'),
        content: Text('"${design.name}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.designStorage.delete(design.id);
      _loadDesigns();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Design "${design.name}" deleted')),
        );
      }
    }
  }

  void _showQuotaFullDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.folder_off, size: 48),
        title: const Text('Design limit reached'),
        content: Text(
          widget.isPremium
              ? 'You have reached the maximum number of designs.'
              : 'Free accounts can store up to 3 designs.\n\n'
                  'Delete an existing design to create a new one, '
                  'or upgrade to Premium for unlimited designs.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showNameDialog({String? initial}) {
    final controller = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(initial != null ? 'Rename design' : 'Name your design'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(
            hintText: 'e.g. Home, Night, Travel',
            counterText: '',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDesignOptions(WidgetDesign design) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Apply'),
              onTap: () {
                Navigator.of(ctx).pop();
                _applyDesign(design);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () {
                Navigator.of(ctx).pop();
                ShareService.shareDesign(context, design);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.of(ctx).pop();
                _renameDesign(design);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(ctx).pop();
                _deleteDesign(design);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Designs'),
        actions: [
          // Quota indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _remaining > 0
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.isPremium
                      ? '∞'
                      : '${_designs.length}/3',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _remaining > 0 ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _designs.isEmpty
          ? _buildEmptyState()
          : _buildDesignGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: _canCreate ? _createDesign : _showQuotaFullDialog,
        tooltip: _canCreate ? 'Create design' : 'Limit reached',
        child: Icon(_canCreate ? Icons.add : Icons.folder_off),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.palette_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No designs yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first design with a custom background',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _createDesign,
            icon: const Icon(Icons.add),
            label: const Text('Create Design'),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignGrid() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _designs.length,
        itemBuilder: (context, index) {
          final design = _designs[index];
          return _DesignCard(
            design: design,
            onTap: () => _applyDesign(design),
            onLongPress: () => _showDesignOptions(design),
          );
        },
      ),
    );
  }
}



/// A card displaying a user design with mini live preview.
class _DesignCard extends StatelessWidget {
  final WidgetDesign design;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _DesignCard({
    required this.design,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mini preview with background
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: ClockPreview(
                  config: design.clock,
                  background: design.background,
                ),
              ),
            ),

            // Label bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      design.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.more_vert, size: 14, color: Colors.grey[500]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
