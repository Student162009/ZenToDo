import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(ZenToDo());
}

class ZenToDo extends StatefulWidget {
  @override
  _ZenToDoState createState() => _ZenToDoState();
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
      _tasks = (prefs.getStringList('tasks') ?? [])
          .map((taskJson) {
            final parts = taskJson.split('|');
            return {
              'id': parts[0],
              'text': parts[1],
              'done': parts[2] == 'true',
              'createdAt': DateTime.now().toIso8601String(),
            };
          }).toList();
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', _currentTheme);
    await prefs.setString('lang', _currentLang);
    await prefs.setStringList(
        'tasks', _tasks.map((task) => '${task['id']}|${task['text']}|${task['done']}').toList());
  }

  void _addTask() {
    if (_newTaskController.text.trim().isNotEmpty) {
      setState(() {
        _tasks.insert(0, {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'text': _newTaskController.text.trim(),
          'done': false,
          'createdAt': DateTime.now().toIso8601String(),
        });
      });
      _newTaskController.clear();
      _saveData();
    }
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['done'] = !_tasks[index]['done'];
    });
    _saveData();
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveData();
  }

  void _updateTask(int index, String newText) {
    if (newText.trim().isNotEmpty) {
      setState(() {
        _tasks[index]['text'] = newText.trim();
      });
      _saveData();
    }
  }

  String _toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZenToDo',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: _getThemeGradient(_currentTheme),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // 🖼️ HEADER С АВАТАРКОЙ
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // ТВОЯ JPG АВАТАРКА
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: AssetImage('assets/images/avatar.jpg'),
                            backgroundColor: Colors.pink.withOpacity(0.3),
                            child: Icon(Icons.person, size: 35, color: Colors.white54),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _toTitleCase(_currentLang == 'ru' ? 'ZenToDo 禅' : 'ZenToDo Zen'),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 2,
                                foreground: Paint()
                                  ..shader = LinearGradient(
                                    colors: _getThemeColors(_currentTheme),
                                  ).createShader(Rect.fromLTWH(0, 0, 200, 100)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newTaskController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: _currentLang == 'ru'
                                    ? 'Что в гармонии сегодня?'
                                    : 'What brings harmony today?',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.15),
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              style: TextStyle(color: Colors.white, fontSize: 18),
                              maxLength: 200,
                              onSubmitted: (_) => _addTask(),
                            ),
                          ),
                          SizedBox(width: 12),
                          FloatingActionButton(
                            onPressed: _addTask,
                            backgroundColor: Color(0xFFFF99CC),
                            elevation: 0,
                            child: Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 📋 СПИСОК ЗАДАЧ
                Expanded(
                  child: _tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.task_alt, size: 64, color: Colors.white54),
                              SizedBox(height: 16),
                              Text(
                                _currentLang == 'ru' ? 'Задачи пусты' : 'No tasks yet',
                                style: TextStyle(color: Colors.white70, fontSize: 18),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return Dismissible(
                              key: Key(task['id']),
                              onDismissed: (_) => _deleteTask(index),
                              background: Container(
                                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.only(right: 20),
                                child: Icon(Icons.delete, color: Colors.white, size: 28),
                              ),
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 8),
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _toggleTask(index),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: task['done']
                                              ? Color(0xFF10B981).withOpacity(0.3)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: task['done']
                                                ? Color(0xFF10B981)
                                                : Colors.white38,
                                            width: 2,
                                          ),
                                        ),
                                        child: task['done']
                                            ? Icon(Icons.check, color: Color(0xFF10B981), size: 20)
                                            : Icon(Icons.radio_button_unchecked,
                                                color: Colors.white54, size: 20),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: task['done']
                                          ? Text(
                                              task['text'],
                                              style: TextStyle(
                                                color: Colors.white70,
                                                decoration: TextDecoration.lineThrough,
                                                fontSize: 16,
                                              ),
                                            )
                                          : TextField(
                                              controller: TextEditingController(text: task['text']),
                                              onSubmitted: (newText) => _updateTask(index, newText),
                                              maxLines: null,
                                              style: TextStyle(color: Colors.white, fontSize: 16),
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                hintStyle: TextStyle(color: Colors.white54),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // 🎨 ПЕРЕКЛЮЧАТЕЛИ
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(children: [
                        _buildThemeButton('dark', '🌙'),
                        SizedBox(width: 8),
                        _buildThemeButton('light', '☀️'),
                        SizedBox(width: 8),
                        _buildThemeButton('japanese', '🌸'),
                      ]),
                      Row(children: [
                        _buildLangButton('ru'),
                        SizedBox(width: 8),
                        _buildLangButton('en'),
                      ]),
                    ],
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
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(colors: [Color(0xFFFF99CC), Color(0xFFE066B3)])
              : null,
          color: isActive ? null : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: isActive ? Colors.white : Colors.white24, width: 2),
          boxShadow: isActive
              ? [BoxShadow(color: Color(0xFFFF99CC).withOpacity(0.4), blurRadius: 16)]
              : null,
        ),
        child: Text(icon,
            style: TextStyle(
              fontSize: 20,
              color: isActive ? Colors.white : Colors.white54,
              fontWeight: FontWeight.w600,
            )),
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(colors: [Color(0xFFFF99CC), Color(0xFFE066B3)])
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.white : Colors.white24, width: 2),
        ),
        child: Text(lang.toUpperCase(),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            )),
      ),
    );
  }

  LinearGradient _getThemeGradient(String theme) {
    switch (theme) {
      case 'japanese':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1117), Color(0xFF1E3A8A), Color(0xFF000000)],
        );
      case 'dark':
        return LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F0F23)]);
      case 'light':
      default:
        return LinearGradient(colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFF1F5F9)]);
    }
  }

  List<Color> _getThemeColors(String theme) {
    switch (theme) {
      case 'japanese':
        return [Color(0xFFF4C7D6), Color(0xFFFF99CC), Color(0xFF1E3A8A)];
      case 'dark':
        return [Color(0xFFEC4899), Color(0xFF8B5CF6)];
      case 'light':
      default:
        return [Color(0xFF3B82F6), Color(0xFF8B5CF6)];
    }
  }
}
