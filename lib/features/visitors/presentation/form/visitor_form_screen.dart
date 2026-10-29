import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_messenger.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../data/visitor.dart';
import '../../domain/visitor_options.dart';
import '../../domain/visitor_status.dart';
import '../../domain/visitor_validators.dart';
import '../providers/visitor_providers.dart';
import '../visitor_messages.dart';
import '../widgets/status_chip.dart';

class VisitorFormScreen extends ConsumerWidget {
  const VisitorFormScreen({super.key, this.visitorId});

  final String? visitorId;

  bool get isEditing => visitorId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isEditing) {
      return const _VisitorForm(title: 'Register visitor');
    }

    final visitors = ref.watch(visitorsProvider);
    final visitor = ref.watch(visitorByIdProvider(visitorId!));

    if (visitor == null && visitors.isLoading && !visitors.hasValue) {
      return const Scaffold(
        appBar: _FormAppBar(title: 'Edit visitor'),
        body: LoadingView(),
      );
    }

    if (visitor == null) {
      return Scaffold(
        appBar: const _FormAppBar(title: 'Edit visitor'),
        body: ErrorStateWidget(
          message: visitors.hasError
              ? readableError(visitors.error!)
              : 'This visitor is no longer on the list.',
          onRetry: () => ref.read(visitorsProvider.notifier).refresh(),
        ),
      );
    }

    return _VisitorForm(
      key: ValueKey(visitor.id),
      title: 'Edit visitor',
      visitor: visitor,
    );
  }
}

class _FormAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FormAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}

class _VisitorForm extends ConsumerStatefulWidget {
  const _VisitorForm({super.key, required this.title, this.visitor});

  final String title;
  final Visitor? visitor;

  @override
  ConsumerState<_VisitorForm> createState() => _VisitorFormState();
}

class _VisitorFormState extends ConsumerState<_VisitorForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _purpose;
  late String? _visitorType;
  late String? _project;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final visitor = widget.visitor;
    _name = TextEditingController(text: visitor?.name ?? '');
    _mobile = TextEditingController(text: visitor?.mobile ?? '');
    _email = TextEditingController(text: visitor?.email ?? '');
    _purpose = TextEditingController(text: visitor?.purpose ?? '');
    _visitorType = visitor?.visitorType;
    _project = visitor?.project;
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _purpose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.visitor != null;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          children: [
            if (editing)
              Align(
                alignment: Alignment.centerLeft,
                child: StatusChip(status: widget.visitor!.status),
              )
            else
              const Align(
                alignment: Alignment.centerLeft,
                child: StatusChip(status: VisitorStatus.registered),
              ),
            const SizedBox(height: 8),
            Text(
              editing
                  ? 'Status changes only when the visitor checks in or out.'
                  : 'New visitors start as Registered.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _name,
              label: 'Visitor name',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: VisitorValidators.name,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _mobile,
              label: 'Mobile number',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: VisitorValidators.mobile,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _email,
              label: 'Email (optional)',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: VisitorValidators.email,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _optionOrNull(VisitorOptions.types, _visitorType),
              decoration: const InputDecoration(labelText: 'Visitor type'),
              items: [
                for (final type in VisitorOptions.types)
                  DropdownMenuItem(value: type, child: Text(type)),
              ],
              onChanged: (value) => _visitorType = value,
              validator: VisitorValidators.visitorType,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _optionOrNull(VisitorOptions.projects, _project),
              decoration: const InputDecoration(labelText: 'Project'),
              items: [
                for (final project in VisitorOptions.projects)
                  DropdownMenuItem(value: project, child: Text(project)),
              ],
              onChanged: (value) => _project = value,
              validator: VisitorValidators.project,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _purpose,
              label: 'Purpose of visit',
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              validator: VisitorValidators.purpose,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: editing ? 'Save' : 'Register',
              loading: _saving,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Cancel',
              outlined: true,
              onPressed: _saving ? null : () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  String? _optionOrNull(List<String> options, String? value) {
    if (value != null && options.contains(value)) return value;
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim();
    final draft = VisitorDraft(
      name: _name.text.trim(),
      mobile: _mobile.text.trim(),
      email: email.isEmpty ? null : email,
      visitorType: _visitorType!,
      project: _project!,
      purpose: _purpose.text.trim(),
    );

    setState(() => _saving = true);
    try {
      final notifier = ref.read(visitorsProvider.notifier);
      final existing = widget.visitor;
      if (existing == null) {
        final created = await notifier.register(draft);
        if (!mounted) return;
        showAppMessage(context, 'Visitor registered.');
        context.pushReplacement(AppRoutes.visitorDetails(created.id));
      } else {
        await notifier.updateVisitor(existing.copyWithDetails(draft));
        if (!mounted) return;
        showAppMessage(context, 'Visitor updated.');
        context.pop();
      }
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, readableError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
