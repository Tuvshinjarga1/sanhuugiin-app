import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../models/task_model.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskService _taskService = TaskService();
  bool _isLoading = true;
  List<TaskModel> _tasks = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();

    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Хэрэглэгч нэвтрээгүй байна';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final tasks = await _taskService.getUserTasks(user.uid);
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ажлуудыг ачаалахад алдаа гарлаа: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _addTask() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();

    if (user == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TaskDialog(
        isEdit: false,
      ),
    );

    if (result != null) {
      try {
        final newTask = TaskModel(
          id: '',
          userId: user.uid,
          title: result['title'],
          description: result['description'],
          dueDate: result['dueDate'],
          priority: result['priority'],
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        await _taskService.addTask(newTask);
        _loadTasks();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ажил нэмэхэд алдаа гарлаа: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _editTask(TaskModel task) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TaskDialog(
        isEdit: true,
        task: task,
      ),
    );

    if (result != null) {
      try {
        final updatedTask = TaskModel(
          id: task.id,
          userId: task.userId,
          title: result['title'],
          description: result['description'],
          dueDate: result['dueDate'],
          priority: result['priority'],
          isCompleted: task.isCompleted,
          createdAt: task.createdAt,
        );

        await _taskService.updateTask(updatedTask);
        _loadTasks();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ажил засварлахад алдаа гарлаа: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleTaskCompletion(TaskModel task) async {
    try {
      final updatedTask = TaskModel(
        id: task.id,
        userId: task.userId,
        title: task.title,
        description: task.description,
        dueDate: task.dueDate,
        priority: task.priority,
        isCompleted: !task.isCompleted,
        createdAt: task.createdAt,
      );

      await _taskService.updateTask(updatedTask);
      _loadTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Ажлын төлөв өөрчлөхөд алдаа гарлаа: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _taskService.deleteTask(taskId);
      _loadTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ажил устгахад алдаа гарлаа: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ажлын удирдлага'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTasks,
                        child: const Text('Дахин оролдох'),
                      ),
                    ],
                  ),
                )
              : _tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Одоогоор ажил байхгүй байна',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _addTask,
                            child: const Text('Ажил нэмэх'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTasks,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          return _buildTaskCard(task);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final bool isOverdue =
        task.dueDate.isBefore(DateTime.now()) && !task.isCompleted;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue
              ? Colors.red
              : task.isCompleted
                  ? Colors.green
                  : Colors.transparent,
          width: isOverdue || task.isCompleted ? 1 : 0,
        ),
      ),
      child: InkWell(
        onTap: () => _editTask(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getPriorityIcon(task.priority),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? Colors.grey
                            : isOverdue
                                ? Colors.red
                                : null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      task.isCompleted
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: task.isCompleted ? Colors.green : Colors.grey,
                    ),
                    onPressed: () => _toggleTaskCompletion(task),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editTask(task);
                      } else if (value == 'delete') {
                        _deleteTask(task.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Засах'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Устгах', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: TextStyle(
                    color: task.isCompleted ? Colors.grey : null,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Хугацаа: ${_formatDate(task.dueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue
                          ? Colors.red
                          : task.isCompleted
                              ? Colors.grey
                              : Colors.blue,
                    ),
                  ),
                  Text(
                    'Үүсгэсэн: ${_formatDate(task.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getPriorityIcon(String priority) {
    IconData iconData;
    Color iconColor;

    switch (priority.toLowerCase()) {
      case 'өндөр':
        iconData = Icons.flag;
        iconColor = Colors.red;
        break;
      case 'дунд':
        iconData = Icons.flag;
        iconColor = Colors.orange;
        break;
      case 'бага':
        iconData = Icons.flag;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.flag_outlined;
        iconColor = Colors.grey;
    }

    return Icon(iconData, color: iconColor, size: 20);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class TaskDialog extends StatefulWidget {
  final bool isEdit;
  final TaskModel? task;

  const TaskDialog({
    super.key,
    required this.isEdit,
    this.task,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _dueDate;
  String _priority = 'Дунд';
  final List<String> _priorities = ['Өндөр', 'Дунд', 'Бага'];

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _dueDate = widget.task!.dueDate;
      _priority = widget.task!.priority;
    } else {
      _dueDate = DateTime.now().add(const Duration(days: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Ажил засах' : 'Шинэ ажил'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Гарчиг',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Гарчиг оруулна уу';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Тайлбар',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _dueDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Хугацаа',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_formatDate(_dueDate)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Чухалчлал',
                  border: OutlineInputBorder(),
                ),
                value: _priority,
                items: _priorities.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _priority = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Цуцлах'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'title': _titleController.text,
                'description': _descriptionController.text,
                'dueDate': _dueDate,
                'priority': _priority,
              });
            }
          },
          child: Text(widget.isEdit ? 'Хадгалах' : 'Нэмэх'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
