// lib/todo/todo_page.dart
import 'package:flutter/material.dart';
import 'todo_data.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TodoData todoData = TodoData();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  List<TodoHive> _items = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await todoData.init();
    setState(() {
      _items = todoData.todos.reversed.toList(); // newest first
      _loading = false;
    });
  }

  Future<void> _addFromSheet() async {
    final result = await showModalBottomSheet<TodoHive?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: const _AddEditSheet(),
        );
      },
    );

    if (result != null) {
      setState(() {
        _items.insert(0, result);
        _listKey.currentState?.insertItem(0);
      });
    }
  }

  Future<void> _editItem(int index) async {
    final current = _items[index];

    final updated = await showModalBottomSheet<TodoHive?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AddEditSheet(editing: current),
      ),
    );

    if (updated != null) {
      setState(() => _items[index] = updated);
    }
  }

  Future<void> _toggleDone(int index) async {
    final t = _items[index];
    await todoData.toggleDone(t);
    setState(() {});
  }

  Future<void> _deleteItem(int index) async {
    final removed = _items.removeAt(index);
    await todoData.delete(removed.id);

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(removed.title),
            subtitle: removed.description != null
                ? Text(removed.description!)
                : null,
          ),
        ),
      ),
    );

    // undo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${removed.title}"'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            final restored = await todoData.addTodo(
              title: removed.title,
              description: removed.description,
              time: removed.time,
              repeatType: removed.repeatType,
              weekdays: removed.weekdays,
            );
            setState(() {
              _items.insert(index, restored);
              _listKey.currentState?.insertItem(index);
            });
          },
        ),
      ),
    );
  }

  String _repeatSummary(TodoHive t) {
    if (t.repeatType == 'none') return 'No repeat';
    if (t.repeatType == 'daily') return 'Daily';
    if (t.repeatType == 'weekly') {
      if (t.weekdays.isEmpty) return 'Weekly';
      return "Weekly: ${t.weekdays.map(_weekdayName).join(', ')}";
    }
    return '';
  }

  String _weekdayName(int d) {
    const map = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return map[d] ?? "";
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  DateTime _todayAt(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  bool _isMissed(TodoHive t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final created = DateTime(
      t.createdAt.year,
      t.createdAt.month,
      t.createdAt.day,
    );

    final due = _todayAt(_parseTime(t.time));

    if (t.repeatType == 'none') {
      if (created.isBefore(today) && !t.isDone) return true;
      if (created.isAtSameMomentAs(today) && due.isBefore(now) && !t.isDone)
        return true;
      return false;
    }

    if (t.repeatType == 'daily') {
      return due.isBefore(now) && !t.isDone;
    }

    if (t.repeatType == 'weekly') {
      if (t.weekdays.contains(now.weekday)) {
        return due.isBefore(now) && !t.isDone;
      }
    }

    return false;
  }

  // tile UI
  Widget _todoTile(TodoHive t, int index) {
    final missed = _isMissed(t);
    final tod = _parseTime(t.time).format(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: () => _editItem(index),
        leading: GestureDetector(
          onTap: () {
            if (missed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Can't complete a missed task.")),
              );
              return;
            }
            _toggleDone(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.isDone ? Colors.green : Colors.transparent,
              border: Border.all(
                color: missed
                    ? Colors.grey.shade500
                    : (t.isDone ? Colors.green : Colors.grey),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: missed
                ? Icon(Icons.block, size: 18, color: Colors.grey.shade500)
                : (t.isDone
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null),
          ),
        ),
        title: Text(
          t.title,
          style: TextStyle(
            decoration: t.isDone ? TextDecoration.lineThrough : null,
            color: t.isDone ? Colors.grey : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (t.description != null && t.description!.isNotEmpty)
              Text(t.description!),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  "$tod  •  ${_repeatSummary(t)}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (missed)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'MISSED',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => _deleteItem(index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("To-Do")),
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _items.length,
        padding: const EdgeInsets.only(bottom: 80),
        itemBuilder: (context, index, animation) {
          final item = _items[index];
          return SizeTransition(
            sizeFactor: animation,
            child: _todoTile(item, index),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFromSheet,
        label: const Text("New Task"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

//
// BOTTOM SHEET (Add/Edit)
//
class _AddEditSheet extends StatefulWidget {
  final TodoHive? editing;
  const _AddEditSheet({this.editing});

  @override
  State<_AddEditSheet> createState() => _AddEditSheetState();
}

class _AddEditSheetState extends State<_AddEditSheet> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  String _repeatType = "none";
  final Set<int> _weekdays = {};
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    if (widget.editing != null) {
      final t = widget.editing!;
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description ?? "";
      _repeatType = t.repeatType;
      _weekdays.addAll(t.weekdays);
      _selectedTime = _parseTime(t.time);
    }
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(":");
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, "0");
    final m = t.minute.toString().padLeft(2, "0");
    return "$h:$m";
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  DateTime _todayAt(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  bool _isPastForNone() {
    final now = DateTime.now();
    final chosen = _todayAt(_selectedTime);
    return chosen.isBefore(now);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Title required")));
      return;
    }

    if (_repeatType == "weekly" && _weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select weekdays for weekly repeat")),
      );
      return;
    }

    if (_repeatType == "none" && _isPastForNone()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot schedule past time")),
      );
      return;
    }

    setState(() => _saving = true);

    final td = TodoData();
    final tStr = _formatTime(_selectedTime);

    if (widget.editing == null) {
      final created = await td.addTodo(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        time: tStr,
        repeatType: _repeatType,
        weekdays: _weekdays.toList(),
      );
      Navigator.pop(context, created);
    } else {
      final e = widget.editing!;
      e.title = _titleCtrl.text.trim();
      e.description = _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim();
      e.time = tStr;
      e.repeatType = _repeatType;
      e.weekdays = _weekdays.toList();
      await td.updateTodo(e);
      Navigator.pop(context, e);
    }

    setState(() => _saving = false);
  }

  Widget _weekdayChip(int dow, String label) {
    final selected = _weekdays.contains(dow);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        setState(() {
          if (v) {
            _weekdays.add(dow);
          } else {
            _weekdays.remove(dow);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          Text(
            widget.editing == null ? "New Task" : "Edit Task",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: "Title",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _descCtrl,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "Description (optional)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          //
          // TIME
          //
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Time",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _pickTime,
            child: Text("Select Time: ${_selectedTime.format(context)}"),
          ),

          const SizedBox(height: 20),

          //
          // REPEAT
          //
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Repeat",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),

          RadioListTile<String>(
            title: const Text("None"),
            value: "none",
            groupValue: _repeatType,
            onChanged: (v) {
              FocusScope.of(context).unfocus(); // FIX
              setState(() => _repeatType = v!);
            },
          ),

          RadioListTile<String>(
            title: const Text("Daily"),
            value: "daily",
            groupValue: _repeatType,
            onChanged: (v) {
              FocusScope.of(context).unfocus(); // FIX
              setState(() => _repeatType = v!);
            },
          ),

          RadioListTile<String>(
            title: const Text("Weekly (Select days)"),
            value: "weekly",
            groupValue: _repeatType,
            onChanged: (v) {
              FocusScope.of(context).unfocus(); // FIX
              setState(() => _repeatType = v!);
            },
          ),

          if (_repeatType == "weekly")
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _weekdayChip(1, "Mon"),
                  _weekdayChip(2, "Tue"),
                  _weekdayChip(3, "Wed"),
                  _weekdayChip(4, "Thu"),
                  _weekdayChip(5, "Fri"),
                  _weekdayChip(6, "Sat"),
                  _weekdayChip(7, "Sun"),
                ],
              ),
            ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(widget.editing == null ? "Add" : "Save"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
