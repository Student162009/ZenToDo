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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentTheme = prefs.getString('theme') ?? 'japanese';
      _currentLang = prefs.getString('lang') ?? 'ru';
      final taskList = prefs.getStringList('tasks') ?? [];
      _tasks = taskList.map((taskJson) {
        final parts = taskJson.split('|');
        return {
          'id': parts[0],
          'text': parts.length > 1 ? parts[1] : '',
          'done': parts.length > 2 ? parts[2] == 'true' : false,
        };
      }).toList();
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', _currentTheme);
    await prefs.setString('lang', _currentLang);
    await prefs.setStringList(
      'tasks',
      _tasks.map((task) => '${task['id']}|${task['text']}|${task['done']}').toList(),
    );
  }

  void _addTask() {
    final text = _newTaskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _tasks.insert(0, {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'text': text,
          'done': false,
        });
      });
      _newTaskController.clear();
      _saveData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Задача добавлена! ✅')),
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

  void _deleteTask(int index) {
    if (index >= 0 && index < _tasks.length) {
      setState(() {
        _tasks.removeAt(index);
      });
      _saveData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Задача удалена! 🗑️')),
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
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Редактировать',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Новый текст',
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white38),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена', style: TextStyle(color: Colors.grey)),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF99CC)),
              child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZenToDo',
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: _getThemeGradient(_currentTheme),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // АВАТАРКА
                          Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFF99CC), Color(0xFFE066B3)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 35,
                              color: Colors.white,
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
                      // INPUT + КНОПКА
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newTaskController,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                              decoration: InputDecoration(
                                hintText: _currentLang == 'ru'
                                    ? 'Что в гармонии сегодня?'
                                    : 'What brings harmony today?',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(color: Colors.white),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.15),
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
                          // КНОПКА +
                          FloatingActionButton(
                            onPressed: _addTask,
                            backgroundColor: const Color(0xFFFF99CC),
                            elevation: 8,
                            highlightElevation: 12,
                            child: const Icon(Icons.add, color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // СПИСОК ЗАДАЧ
                Expanded(
                  child: _tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.task_alt, size: 80, color: Colors.white54),
                              const SizedBox(height: 24),
                              Text(
                                _currentLang == 'ru' ? 'Задачи пусты' : 'No tasks yet',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _currentLang == 'ru'
                                    ? 'Нажми + чтобы добавить'
                                    : 'Press + to add tasks',
                                style: TextStyle(
                                  color: Colors.white54,
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
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Row(
                                    children: [
                                      // ЧЕКБОКС
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
                                                  : Colors.white38,
                                              width: 2,
                                            ),
                                          ),
                                          child: (task['done'] as bool)
                                              ? const Icon(
                                                  Icons.check,
                                                  color: Color(0xFF10B981),
                                                  size: 20,
                                                )
                                              : const Icon(
                                                  Icons.radio_button_unchecked,
                                                  color: Colors.white54,
                                                  size: 20,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // ТЕКСТ
                                      Expanded(
                                        child: Text(
                                          task['text'] as String,
                                          style: TextStyle(
                                            color: (task['done'] as bool)
                                                ? Colors.white70
                                                : Colors.white,
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
                // КОНТРОЛЛЕРЫ
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // ТЕМЫ
                        Row(
                          children: [
                            _buildThemeButton('japanese', '🌸'),
                            const SizedBox(width: 8),
                            _buildThemeButton('dark', '🌙'),
                            const SizedBox(width: 8),
                            _buildThemeButton('light', '☀️'),
                          ],
                        ),
                        // ЯЗЫКИ
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
              ? const LinearGradient(colors: [Color(0xFFFF99CC), Color(0xFFE066B3)])
              : null,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.white : Colors.white24,
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF99CC).withOpacity(0.4),
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
            color: isActive ? Colors.white : Colors.white60,
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
              ? const LinearGradient(colors: [Color(0xFFFF99CC), Color(0xFFE066B3)])
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white24,
            width: 2,
          ),
        ),
        child: Text(
          lang.toUpperCase(),
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
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
        return const [Color(0xFFF4C7D6), Color(0xFFFF99CC), Color(0xFF1E3A8A)];
      case 'dark':
        return const [Color(0xFFEC4899), Color(0xFF8B5CF6)];
      case 'light':
      default:
        return const [Color(0xFF3B82F6), Color(0xFF8B5CF6)];
    }
  }
}
