import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ZenToDo());
}

class ZenToDo extends StatefulWidget {
  const ZenToDo({super.key});

  @override
  State<ZenToDo> createState() => _ZenToDoState();
}

class _ZenToDoState extends State<ZenToDo> {
  String _currentTheme = 'japanese';
  String _currentLang = 'ru';
  List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _newTaskController = TextEditingController();

  static const Color _accentColor = Color(0xFFFF99CC);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentTheme = prefs.getString('theme') ?? 'japanese';
        _currentLang = prefs.getString('lang') ?? 'ru';

        final taskList = prefs.getStringList('tasks') ?? [];
        _tasks = taskList.map((taskJson) {
          try {
            return Map<String, dynamic>.from(jsonDecode(taskJson) as Map);
          } catch (e) {
            // Попытка прочитать старый формат (с разделителем |) для совместимости
            final parts = taskJson.split('|');
            if (parts.length >= 2) {
              return {
                'id': parts[0],
                'text': parts[1],
                'done': parts.length > 2 ? parts[2] == 'true' : false,
              };
            }
            return {'id': '', 'text': '', 'done': false};
          }
        }).where((task) => task['id'].isNotEmpty).toList();
      });
      debugPrint('Data loaded: ${_tasks.length} tasks');
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme', _currentTheme);
      await prefs.setString('lang', _currentLang);
      await prefs.setStringList(
        'tasks',
        _tasks.map((task) => jsonEncode(task)).toList(),
      );
      debugPrint('Data saved successfully');
    } catch (e) {
      debugPrint('Error saving data: $e');
      // Показываем ошибку пользователю (опционально)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addTask() async {
    final text = _newTaskController.text.trim();
    debugPrint('Add task pressed. Text: "$text"');

    if (text.isEmpty) {
      debugPrint('Text is empty – not adding');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Введите текст задачи'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      setState(() {
        _tasks.insert(0, {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'text': text,
          'done': false,
        });
      });
      debugPrint('Task added to list. New length: ${_tasks.length}');

      _newTaskController.clear();

      await _saveData(); // ждём сохранения

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_currentLang == 'ru' ? 'Задача добавлена! ✅' : 'Task added! ✅'),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('Exception in _addTask: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleTask(int index) {
    if (index >= 0 && index < _tasks.length) {
      setState(() {
        _tasks[index]['done'] = !_tasks[index]['done'];
      });
      _saveData();
    }
  }

  void _deleteTask(int index) async {
    if (index >= 0 && index < _tasks.length) {
      setState(() {
        _tasks.removeAt(index);
      });
      await _saveData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_currentLang == 'ru' ? 'Задача удалена! 🗑️' : 'Task deleted! 🗑️'),
          ),
        );
      }
    }
  }

  void _editTask(int index) {
    if (index >= 0 && index < _tasks.length) {
      final controller = TextEditingController(text: _tasks[index]['text'] as String);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _getBackgroundColor(),
          title: Text(
            _currentLang == 'ru' ? 'Редактировать' : 'Edit',
            style: TextStyle(color: _getTextColor()),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(color: _getTextColor()),
            decoration: InputDecoration(
              hintText: _currentLang == 'ru' ? 'Новый текст' : 'New text',
              hintStyle: TextStyle(color: _getTextColor().withOpacity(0.5)),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: _getTextColor().withOpacity(0.3)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                _currentLang == 'ru' ? 'Отмена' : 'Cancel',
                style: TextStyle(color: _getTextColor().withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newText = controller.text.trim();
                if (newText.isNotEmpty) {
                  setState(() {
                    _tasks[index]['text'] = newText;
                  });
                  _saveData();
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
              child: Text(
                _currentLang == 'ru' ? 'Сохранить' : 'Save',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ).then((_) => controller.dispose());
    }
  }

  @override
  void dispose() {
    _newTaskController.dispose();
    super.dispose();
  }

  Color _getTextColor() => _currentTheme == 'light' ? Colors.black87 : Colors.white;
  Color _getSecondaryTextColor() => _currentTheme == 'light' ? Colors.black54 : Colors.white70;
  Color _getBackgroundColor() => _currentTheme == 'light' ? Colors.white : Colors.grey[900]!;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZenToDo',
      theme: ThemeData(
        useMaterial3: true,
        brightness: _currentTheme == 'light' ? Brightness.light : Brightness.dark,
      ),
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: _getThemeGradient(_currentTheme),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_accentColor, Color(0xFFE066B3)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 35,
                              color: _getTextColor(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _currentLang == 'ru' ? 'ZenToDo 禅' : 'ZenToDo Zen',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1.5,
                                foreground: Paint()
                                  ..shader = LinearGradient(
                                    colors: _getThemeColors(_currentTheme),
                                  ).createShader(const Rect.fromLTWH(0, 0, 200, 80)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newTaskController,
                              style: TextStyle(color: _getTextColor(), fontSize: 18),
                              decoration: InputDecoration(
                                hintText: _currentLang == 'ru'
                                    ? 'Что в гармонии сегодня?'
                                    : 'What brings harmony today?',
                                hintStyle: TextStyle(color: _getSecondaryTextColor()),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: _getTextColor().withOpacity(0.2)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: _getTextColor().withOpacity(0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: _getTextColor()),
                                ),
                                filled: true,
                                fillColor: _getTextColor().withOpacity(0.1),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              onSubmitted: (_) => _addTask(),
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                          const SizedBox(width: 12),
                          FloatingActionButton(
                            onPressed: _addTask,
                            backgroundColor: _accentColor,
                            elevation: 8,
                            highlightElevation: 12,
                            child: const Icon(Icons.add, color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.task_alt, size: 80, color: _getSecondaryTextColor()),
                              const SizedBox(height: 24),
                              Text(
                                _currentLang == 'ru' ? 'Задачи пусты' : 'No tasks yet',
                                style: TextStyle(
                                  color: _getSecondaryTextColor(),
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _currentLang == 'ru'
                                    ? 'Нажми + чтобы добавить'
                                    : 'Press + to add tasks',
                                style: TextStyle(
                                  color: _getSecondaryTextColor().withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return Dismissible(
                              key: Key(task['id'] as String),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _deleteTask(index),
                              background: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              child: GestureDetector(
                                onTap: () => _editTask(index),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: _getTextColor().withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _getTextColor().withOpacity(0.15)),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _toggleTask(index),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: (task['done'] as bool)
                                                ? const Color(0xFF10B981).withOpacity(0.4)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(
                                              color: (task['done'] as bool)
                                                  ? const Color(0xFF10B981)
                                                  : _getTextColor().withOpacity(0.3),
                                              width: 2,
                                            ),
                                          ),
                                          child: (task['done'] as bool)
                                              ? const Icon(
                                                  Icons.check,
                                                  color: Color(0xFF10B981),
                                                  size: 20,
                                                )
                                              : Icon(
                                                  Icons.radio_button_unchecked,
                                                  color: _getTextColor().withOpacity(0.5),
                                                  size: 20,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          task['text'] as String,
                                          style: TextStyle(
                                            color: (task['done'] as bool)
                                                ? _getSecondaryTextColor()
                                                : _getTextColor(),
                                            decoration: (task['done'] as bool)
                                                ? TextDecoration.lineThrough
                                                : null,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getTextColor().withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          children: [
                            _buildThemeButton('japanese', '🌸'),
                            const SizedBox(width: 8),
                            _buildThemeButton('dark', '🌙'),
                            const SizedBox(width: 8),
                            _buildThemeButton('light', '☀️'),
                          ],
                        ),
                        Row(
                          children: [
                            _buildLangButton('ru'),
                            const SizedBox(width: 8),
                            _buildLangButton('en'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeButton(String theme, String icon) {
    final isActive = _currentTheme == theme;
    return GestureDetector(
      onTap: () {
        setState(() => _currentTheme = theme);
        _saveData();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: [_accentColor, Color(0xFFE066B3)])
              : null,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? _getTextColor() : _getTextColor().withOpacity(0.3),
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Text(
          icon,
          style: TextStyle(
            fontSize: 20,
            color: isActive ? _getTextColor() : _getTextColor().withOpacity(0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLangButton(String lang) {
    final isActive = _currentLang == lang;
    return GestureDetector(
      onTap: () {
        setState(() => _currentLang = lang);
        _saveData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: [_accentColor, Color(0xFFE066B3)])
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _getTextColor() : _getTextColor().withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Text(
          lang.toUpperCase(),
          style: TextStyle(
            color: isActive ? _getTextColor() : _getTextColor().withOpacity(0.6),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  LinearGradient _getThemeGradient(String theme) {
    switch (theme) {
      case 'japanese':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1117), Color(0xFF1E3A8A), Color(0xFF000000)],
        );
      case 'dark':
        return const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F0F23)],
        );
      case 'light':
      default:
        return const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFF1F5F9)],
        );
    }
  }

  List<Color> _getThemeColors(String theme) {
    switch (theme) {
      case 'japanese':
        return const [Color(0xFFF4C7D6), _accentColor, Color(0xFF1E3A8A)];
      case 'dark':
        return const [Color(0xFFEC4899), Color(0xFF8B5CF6)];
      case 'light':
      default:
        return const [Color(0xFF3B82F6), Color(0xFF8B5CF6)];
    }
  }
}