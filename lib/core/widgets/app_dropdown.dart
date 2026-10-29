import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({required this.value, required this.label});

  final T value;
  final String label;
}

class AppDropdown<T> extends FormField<T> {
  AppDropdown({
    super.key,
    required String label,
    required T? value,
    required List<AppDropdownOption<T>> items,
    required ValueChanged<T?> onChanged,
    IconData? icon,
    super.validator,
  }) : super(
         initialValue: value,
         builder: (field) {
           return _DropdownAnchor<T>(
             label: label,
             icon: icon,
             value: value,
             items: items,
             errorText: field.errorText,
             onSelected: (selected) {
               field.didChange(selected);
               onChanged(selected);
             },
           );
         },
       );
}

class _DropdownAnchor<T> extends StatefulWidget {
  const _DropdownAnchor({
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
    required this.errorText,
    this.icon,
  });

  final String label;
  final T? value;
  final List<AppDropdownOption<T>> items;
  final ValueChanged<T?> onSelected;
  final String? errorText;
  final IconData? icon;

  @override
  State<_DropdownAnchor<T>> createState() => _DropdownAnchorState<T>();
}

class _DropdownAnchorState<T> extends State<_DropdownAnchor<T>> {
  final LayerLink _link = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _menu;
  var _open = false;

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  void _toggle() {
    if (_open) {
      _close();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final field = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (field == null || !field.hasSize) return;
    final width = field.size.width;
    final height = field.size.height;

    _menu = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: Offset(0, height + 6),
              child: SizedBox(
                width: width,
                child: _OptionMenu<T>(
                  items: widget.items,
                  value: widget.value,
                  onSelected: (selected) {
                    widget.onSelected(selected);
                    _close();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_menu!);
    setState(() => _open = true);
  }

  void _close() {
    _removeMenu();
    if (mounted) setState(() => _open = false);
  }

  void _removeMenu() {
    _menu?.remove();
    _menu = null;
  }

  String? _selectedLabel() {
    for (final option in widget.items) {
      if (option.value == widget.value) return option.label;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedLabel();
    return CompositedTransformTarget(
      link: _link,
      child: InkWell(
        key: _fieldKey,
        borderRadius: BorderRadius.circular(16),
        onTap: _toggle,
        child: InputDecorator(
          isFocused: _open,
          isEmpty: selected == null,
          decoration: InputDecoration(
            labelText: widget.label,
            errorText: widget.errorText,
            prefixIcon: widget.icon == null ? null : Icon(widget.icon),
            suffixIcon: Icon(
              _open
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppTheme.seed,
            ),
          ),
          child: Text(
            selected ?? '',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionMenu<T> extends StatelessWidget {
  const _OptionMenu({
    required this.items,
    required this.value,
    required this.onSelected,
  });

  final List<AppDropdownOption<T>> items;
  final T? value;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in items)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelected(option.value),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: option.value == value
                        ? const Color(0xFFD7EBE6)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _OptionRow(
                    label: option.label,
                    selected: option.value == value,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.ink,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        if (selected)
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(Icons.check_rounded, size: 18, color: AppTheme.seed),
          ),
      ],
    );
  }
}
