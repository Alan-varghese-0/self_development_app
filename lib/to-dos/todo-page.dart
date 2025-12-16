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
      // newest first
      _items = todoData.todos.reversed.toList();
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${removed.title}"'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            final restored = await todoData.addTodo(
              title: removed.title,
              startTime: removed.startTime,
              endTime: removed.endTime,
              description: removed.description,
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
    final h = int.tryParse(parts[0]) ?? 9;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: h, minute: m);
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

    final due = _todayAt(_parseTime(t.endTime));

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

  Widget _todoTile(TodoHive t, int index) {
    final missed = _isMissed(t);
    final start = _parseTime(t.startTime).format(context);
    final end = _parseTime(t.endTime).format(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => _editItem(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (missed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Can't complete a missed task."),
                      ),
                    );
                    return;
                  }
                  _toggleDone(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: t.isDone ? Colors.green : Colors.transparent,
                    border: Border.all(
                      color: missed
                          ? Colors.grey.shade500
                          : (t.isDone ? Colors.green : Colors.grey.shade400),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: missed
                      ? Icon(Icons.block, size: 18, color: Colors.grey.shade500)
                      : (t.isDone
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              )
                            : null),
                ),
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        decoration: t.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: t.isDone ? Colors.grey : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),

                    if (t.description != null && t.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          t.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "$start — $end  •  ${_repeatSummary(t)}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (missed) const SizedBox(width: 8),
                        if (missed)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'MISSED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deleteItem(index),
              ),
            ],
          ),
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
        padding: const EdgeInsets.only(bottom: 100),
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

/* ---------------------------
   BOTTOM SHEET (Add / Edit)
   - ensures TodoData is initialized before saving
   - computes defaults asynchronously
---------------------------- */
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
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  bool _saving = false;
  bool _preparedDefaults = false;

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      final t = widget.editing!;
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description ?? "";
      _repeatType = t.repeatType;
      _weekdays.addAll(t.weekdays);
      _startTime = _parseTime(t.startTime);
      _endTime = _parseTime(t.endTime);
      _preparedDefaults = true;
    } else {
      // prepare defaults async (ensures TodoData.init is awaited)
      _prepareDefaults();
    }
  }

  Future<void> _prepareDefaults() async {
    final td = TodoData();
    await td.init(); // make sure hive is open
    // use helper to find next available start for 60 mins
    final next = td.getNextAvailableStart(60);
    final parsed = _parseTime(next);
    final dt = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      parsed.hour,
      parsed.minute,
    ).add(const Duration(minutes: 60));
    setState(() {
      _startTime = parsed;
      _endTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      _preparedDefaults = true;
    });
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 9;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, "0");
    final m = t.minute.toString().padLeft(2, "0");
    return "$h:$m";
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        final s = DateTime(0, 0, 0, _startTime.hour, _startTime.minute);
        final e = DateTime(0, 0, 0, _endTime.hour, _endTime.minute);
        if (!e.isAfter(s)) {
          final nd = s.add(const Duration(hours: 1));
          _endTime = TimeOfDay(hour: nd.hour, minute: nd.minute);
        }
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  DateTime _todayAt(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  bool _isPastForNone() {
    final now = DateTime.now();
    final chosenEnd = _todayAt(_endTime);
    return chosenEnd.isBefore(now);
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

    final startDt = _todayAt(_startTime);
    final endDt = _todayAt(_endTime);
    if (!startDt.isBefore(endDt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time")),
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
    await td
        .init(); // <--- ensure hive is ready before add/update/overlap check

    final startStr = _formatTime(_startTime);
    final endStr = _formatTime(_endTime);

    // overlap check only for one-time tasks
    if (_repeatType == "none") {
      final exceptId = widget.editing?.id;
      final overlapping = td.isOverlapping(
        startStr,
        endStr,
        exceptId: exceptId,
      );
      if (overlapping) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("This time slot overlaps another task."),
          ),
        );
        setState(() => _saving = false);
        return;
      }
    }

    try {
      if (widget.editing == null) {
        final created = await td.addTodo(
          title: _titleCtrl.text.trim(),
          startTime: startStr,
          endTime: endStr,
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
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
        e.startTime = startStr;
        e.endTime = endStr;
        e.repeatType = _repeatType;
        e.weekdays = _weekdays.toList();
        await td.updateTodo(e);
        Navigator.pop(context, e);
      }
    } catch (ex) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save: $ex")));
    } finally {
      setState(() => _saving = false);
    }
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

    // if defaults haven't been prepared yet, show a small loader to avoid weird defaults
    if (!_preparedDefaults) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text("Preparing..."),
            ],
          ),
        ),
      );
    }

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

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Start",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickStart,
                  child: Text("Start: ${_startTime.format(context)}"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickEnd,
                  child: Text("End: ${_endTime.format(context)}"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

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
              FocusScope.of(context).unfocus();
              setState(() => _repeatType = v!);
            },
          ),

          RadioListTile<String>(
            title: const Text("Daily"),
            value: "daily",
            groupValue: _repeatType,
            onChanged: (v) {
              FocusScope.of(context).unfocus();
              setState(() => _repeatType = v!);
            },
          ),

          RadioListTile<String>(
            title: const Text("Weekly (Select days)"),
            value: "weekly",
            groupValue: _repeatType,
            onChanged: (v) {
              FocusScope.of(context).unfocus();
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
