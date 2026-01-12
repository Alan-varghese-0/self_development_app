import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:self_develpoment_app/scheduler/scheduler_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProjectPage extends StatefulWidget {
  final ProjectHive? projectToEdit; // Null = create new, not null = edit

  const AddProjectPage({super.key, this.projectToEdit});

  @override
  State<AddProjectPage> createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _hoursCtrl;
  late DateTime _start;
  late DateTime _deadline;

  bool _saving = false;
  final SchedulerData data = SchedulerData();

  @override
  void initState() {
    super.initState();
    final p = widget.projectToEdit;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _hoursCtrl = TextEditingController(text: p?.dailyHours.toString() ?? '4');
    _start = p?.startDate ?? DateTime.now();
    _deadline = p?.deadline ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
          if (_deadline.isBefore(_start))
            _deadline = _start.add(const Duration(days: 1));
        } else {
          _deadline = picked;
        }
      });
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      if (widget.projectToEdit == null) {
        // CREATE NEW
        final color =
            (math.Random().nextInt(0xFFFFFF) + 0xFF000000) | 0xFF000000;
        await data.addLocal(
          userId: userId,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          dailyHours: int.parse(_hoursCtrl.text),
          startDate: _start,
          deadline: _deadline,
          colorValue: color,
        );
      } else {
        // UPDATE EXISTING
        final updatedProject = widget.projectToEdit!;
        updatedProject.title = _titleCtrl.text;
        updatedProject.description = _descCtrl.text;
        updatedProject.dailyHours = int.parse(_hoursCtrl.text);
        updatedProject.startDate = _start;
        updatedProject.deadline = _deadline;

        // Mark as pending to re-sync and re-generate AI plan
        updatedProject.pending = true;
        await data.updateLocal(updatedProject);

        // Optional: delete old AI days so new ones are generated
        if (Supabase.instance.client != null) {
          await Supabase.instance.client
              .from('ai_project_days')
              .delete()
              .eq('project_id', updatedProject.id);
        }
      }

      await data.syncBoth(userId: userId);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.projectToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Project' : 'New Project')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Project Title *'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (helps AI plan better)',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hoursCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Daily Hours *'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n < 1 || n > 12) ? 'Enter 1-12' : null;
                },
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text('${_start.year}-${_start.month}-${_start.day}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(true),
              ),
              ListTile(
                title: const Text('Deadline'),
                subtitle: Text(
                  '${_deadline.year}-${_deadline.month}-${_deadline.day}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(false),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _saveProject,
                child: _saving
                    ? const CircularProgressIndicator()
                    : Text(
                        isEditing
                            ? 'Save Changes & Regenerate AI Plan'
                            : 'Create & Generate AI Schedule',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
