import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const ZenTodoApp());
}

class ZenTodoApp extends StatefulWidget {
  const ZenTodoApp({super.key});

  @override
  State<ZenTodoApp> createState() => _ZenTodoAppState();
}

class _ZenTodoAppState extends State<ZenTodoApp> with TickerProviderStateMixin {
  String _currentTheme = 'japanese';
  String _currentLang = 'ru';
  List<Map<String, dynamic>> _tasks = [];
  String _sortMode = 'none';

  final TextEditingController _newTaskController = TextEditingController();

  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMusicPlaying = false;

  late Map<String, String> _texts;
  final Map<String, Map<String, String>> _allTexts = {
    'ru': {
      'title': 'ZenTodo 禅',
      'tasksTitle': 'Задачи Дзен',
      'placeholder': 'Что в гармонии сегодня?',
      'submit': 'Добавить',
      'sort': 'Сортировка:',
      'sortNone': 'Без сортировки',
      'sortAlpha': 'A→Я',
      'sortAlphaRev': 'Я→A',
      'sortLength': 'По длине',
      'sortLengthRev': 'По длине (обр.)',
      'sortDateNew': 'Сначала новые',
      'sortDateOld': 'Сначала старые',
      'sortStatus': 'По статусу',
      'edit': 'Ред.',
      'delete': '✕',
      'togglePending': '⏳ Ожидание',
      'toggleDone': '✅ Выполнено',
      'statusPending': '⏳ Ожидание',
      'statusDone': '✅ Выполнено',
      'taskAdded': 'Задача добавлена! ✅',
      'taskDeleted': 'Задача удалена! 🗑️',
      'enterTask': 'Введите текст задачи',
      'cancel': 'Отмена',
      'save': 'Сохранить',
    },
    'en': {
      'title': 'ZenTodo 禅',
      'tasksTitle': 'Zen Tasks',
      'placeholder': 'What brings harmony today?',
      'submit': 'Add',
      'sort': 'Sort:',
      'sortNone': 'None',
      'sortAlpha': 'A→Z',
      'sortAlphaRev': 'Z→A',
      'sortLength': 'Length',
      'sortLengthRev': 'Length (rev)',
      'sortDateNew': 'Newest first',
      'sortDateOld': 'Oldest first',
      'sortStatus': 'By status',
      'edit': 'Edit',
      'delete': '✕',
      'togglePending': '⏳ Pending',
      'toggleDone': '✅ Done',
      'statusPending': '⏳ Pending',
      'statusDone': '✅ Done',
      'taskAdded': 'Task added! ✅',
      'taskDeleted': 'Task deleted! 🗑️',
      'enterTask': 'Enter task text',
      'cancel': 'Cancel',
      'save': 'Save',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _updateTexts();
    _loadMusicState();
    _initAudioPlayer();

    _gradientController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);
    _gradientAnimation = Tween<double>(begin: 0.0, end: 0.2).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );
  }

  void _updateTexts() {
    _texts = _allTexts[_currentLang]!;
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentTheme = prefs.getString('theme') ?? 'japanese';
        _currentLang = prefs.getString('lang') ?? 'ru';
        _sortMode = prefs.getString('sortMode') ?? 'none';
        _updateTexts();

        final taskList = prefs.getStringList('tasks') ?? [];
        _tasks = taskList.map((taskJson) {
          try {
            return Map<String, dynamic>.from(jsonDecode(taskJson) as Map);
          } catch (e) {
            final parts = taskJson.split('|');
            if (parts.length >= 2) {
              return {
                'id': parts[0],
                'text': parts[1],
                'done': parts.length > 2 ? parts[2] == 'true' : false,
                'createdAt': DateTime.now().toIso8601String(),
                'status': parts.length > 2 && parts[2] == 'true' ? 'done' : 'pending',
              };
            }
            return {'id': '', 'text': '', 'done': false, 'status': 'pending'};
          }
        }).where((task) => task['id'].isNotEmpty).toList();

        for (var task in _tasks) {
          task['createdAt'] ??= DateTime.now().toIso8601String();
          task['status'] ??= (task['done'] == true ? 'done' : 'pending');
          task.remove('done');
        }
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme', _currentTheme);
      await prefs.setString('lang', _currentLang);
      await prefs.setString('sortMode', _sortMode);
      await prefs.setStringList(
        'tasks',
        _tasks.map((task) => jsonEncode(task)).toList(),
      );
    } catch (e) {
      debugPrint('Error saving data: $e');
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

  // --- Музыка ---
  Future<void> _loadMusicState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMusicPlaying = prefs.getBool('music') ?? false; // по умолчанию выключена
    });
    if (_isMusicPlaying) {
      _playMusic();
    }
  }

  void _initAudioPlayer() {
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.setVolume(0.3);
  }

  Future<void> _playMusic() async {
    try {
      await _audioPlayer.play(AssetSource('audio/lofi.mp3'));
    } catch (e) {
      debugPrint('Error playing music: $e');
    }
  }

  void _toggleMusic() async {
    if (_isMusicPlaying) {
      await _audioPlayer.stop();
    } else {
      await _playMusic();
    }
    setState(() {
      _isMusicPlaying = !_isMusicPlaying;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music', _isMusicPlaying);
  }
  // -----------------

  void _addTask() async {
    final text = _newTaskController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_texts['enterTask']!),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _tasks.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': text,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
    });
    _newTaskController.clear();
    await _saveData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_texts['taskAdded']!)),
      );
    }
  }

  void _toggleTask(int index) {
    if (index >= 0 && index < _tasks.length) {
      setState(() {
        _tasks[index]['status'] =
            _tasks[index]['status'] == 'pending' ? 'done' : 'pending';
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
          SnackBar(content: Text(_texts['taskDeleted']!)),
        );
      }
    }
  }

  void _editTask(int index, String newText) {
    if (index >= 0 && index < _tasks.length && newText.isNotEmpty) {
      setState(() {
        _tasks[index]['text'] = newText;
      });
      _saveData();
    }
  }

  List<Map<String, dynamic>> _getSortedTasks() {
    List<Map<String, dynamic>> sorted = List.from(_tasks);
    switch (_sortMode) {
      case 'alpha':
        sorted.sort((a, b) => a['text'].compareTo(b['text']));
        break;
      case 'alpha-rev':
        sorted.sort((a, b) => b['text'].compareTo(a['text']));
        break;
      case 'length':
        sorted.sort((a, b) => a['text'].length.compareTo(b['text'].length));
        break;
      case 'length-rev':
        sorted.sort((a, b) => b['text'].length.compareTo(a['text'].length));
        break;
      case 'date-new':
        sorted.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
        break;
      case 'date-old':
        sorted.sort((a, b) => a['createdAt'].compareTo(b['createdAt']));
        break;
      case 'status':
        sorted.sort((a, b) => a['status'].compareTo(b['status']));
        break;
      default:
        break;
    }
    return sorted;
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString).toLocal();
    String dayMonth;
    if (_currentLang == 'ru') {
      const months = [
        'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
        'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
      ];
      dayMonth = '${date.day} ${months[date.month - 1]}';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      dayMonth = '${months[date.month - 1]} ${date.day}';
    }
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$dayMonth, $hour:$minute';
  }

  Color get textColor =>
      _currentTheme == 'light' ? Colors.black87 : Colors.white;
  Color get secondaryTextColor =>
      _currentTheme == 'light' ? Colors.black54 : Colors.white70;
  Color get surfaceColor => textColor.withOpacity(0.08);

  LinearGradient getThemeGradient() {
    final animValue = _gradientAnimation.value;
    switch (_currentTheme) {
      case 'japanese':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment(0.8 + animValue, 0.8 + animValue),
          colors: const [Color(0xFF0D1117), Color(0xFF1E3A8A), Color(0xFF000000)],
        );
      case 'dark':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment(0.8 + animValue, 0.8 + animValue),
          colors: const [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F0F23)],
        );
      case 'light':
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment(0.8 + animValue, 0.8 + animValue),
          colors: const [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFF1F5F9)],
        );
    }
  }

  static const Color accentColor = Color(0xFFFF99CC);

  @override
  void dispose() {
    _gradientController.dispose();
    _newTaskController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZenTodo 禅',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        brightness: _currentTheme == 'light' ? Brightness.light : Brightness.dark,
      ),
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: getThemeGradient()),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Определяем, широкий ли экран (планшет или большой телефон в landscape)
                final bool isWide = constraints.maxWidth > 600;
                final double horizontalPadding = isWide ? 40 : 24;
                final double titleFontSize = isWide ? 32 : 40;
                final double inputFontSize = isWide ? 14 : 18;
                final double buttonFontSize = isWide ? 14 : 18;
                final double tasksTitleFontSize = isWide ? 24 : 28;
                final double verticalSpacing = isWide ? 16 : 24;

                return Column(
                  children: [
                    // Адаптивный хедер
                    Padding(
                      padding: EdgeInsets.all(horizontalPadding),
                      child: Column(
                        children: [
                          Text(
                            _texts['title']!,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w300,
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: _getTitleGradientColors(),
                                ).createShader(const Rect.fromLTWH(0, 0, 200, 80)),
                            ),
                          ),
                          SizedBox(height: verticalSpacing),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newTaskController,
                                  style: TextStyle(color: textColor, fontSize: inputFontSize),
                                  decoration: InputDecoration(
                                    hintText: _texts['placeholder'],
                                    hintStyle: TextStyle(color: secondaryTextColor, fontSize: inputFontSize),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(color: textColor.withOpacity(0.2)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(color: textColor.withOpacity(0.2)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(color: textColor),
                                    ),
                                    filled: true,
                                    fillColor: surfaceColor,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: isWide ? 12 : 16,
                                    ),
                                  ),
                                  onSubmitted: (_) => _addTask(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _addTask,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isWide ? 16 : 24,
                                    vertical: isWide ? 12 : 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 8,
                                ),
                                child: Text(
                                  _texts['submit']!,
                                  style: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Заголовок "Задачи Дзен" (тоже адаптивный)
                    Text(
                      _texts['tasksTitle']!,
                      style: TextStyle(
                        fontSize: tasksTitleFontSize,
                        fontWeight: FontWeight.w300,
                        color: textColor,
                      ),
                    ),

                    // Кнопки сортировки (можно тоже сделать адаптивными, но пока оставим)
                    _buildSortButtons(),

                    // Список задач
                    Expanded(
                      child: _tasks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.task_alt,
                                    size: 80,
                                    color: secondaryTextColor,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _currentLang == 'ru'
                                        ? 'Задачи пусты'
                                        : 'No tasks yet',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _currentLang == 'ru'
                                        ? 'Напиши что‑нибудь и нажми Добавить'
                                        : 'Write something and press Add',
                                    style: TextStyle(
                                      color: secondaryTextColor.withOpacity(0.7),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              itemCount: _getSortedTasks().length,
                              itemBuilder: (context, index) {
                                final task = _getSortedTasks()[index];
                                final originalIndex = _tasks.indexWhere((t) => t['id'] == task['id']);
                                return AnimatedTaskCard(
                                  task: task,
                                  index: originalIndex,
                                  onToggle: _toggleTask,
                                  onDelete: _deleteTask,
                                  onEdit: _editTask,
                                  textColor: textColor,
                                  secondaryTextColor: secondaryTextColor,
                                  surfaceColor: surfaceColor,
                                  accentColor: accentColor,
                                  currentLang: _currentLang,
                                  texts: _texts,
                                  formatDate: _formatDate,
                                );
                              },
                            ),
                    ),

                    // Адаптивный футер
                    _buildFooter(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortButtons() {
    final sortModes = [
      'none',
      'alpha',
      'alpha-rev',
      'length',
      'length-rev',
      'date-new',
      'date-old',
      'status',
    ];
    final sortLabels = [
      _texts['sortNone']!,
      _texts['sortAlpha']!,
      _texts['sortAlphaRev']!,
      _texts['sortLength']!,
      _texts['sortLengthRev']!,
      _texts['sortDateNew']!,
      _texts['sortDateOld']!,
      _texts['sortStatus']!,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _texts['sort']!,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(sortModes.length, (i) {
              final isActive = _sortMode == sortModes[i];
              return GestureDetector(
                onTap: () {
                  setState(() => _sortMode = sortModes[i]);
                  _saveData();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(colors: _getButtonGradientColors())
                        : null,
                    color: isActive ? null : surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? Colors.transparent : textColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    sortLabels[i],
                    style: TextStyle(
                      color: isActive ? Colors.white : textColor,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final verticalPadding = isWide ? 8.0 : 20.0;
        final buttonSize = isWide ? 36.0 : 48.0;
        final iconSize = isWide ? 16.0 : 20.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    _buildThemeButton('japanese', '🌸', buttonSize, iconSize),
                    const SizedBox(width: 8),
                    _buildThemeButton('dark', '🌙', buttonSize, iconSize),
                    const SizedBox(width: 8),
                    _buildThemeButton('light', '☀️', buttonSize, iconSize),
                  ],
                ),
                Row(
                  children: [
                    _buildLangButton('ru', buttonSize, iconSize),
                    const SizedBox(width: 8),
                    _buildLangButton('en', buttonSize, iconSize),
                  ],
                ),
                _buildMusicButton(buttonSize, iconSize),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeButton(String theme, String icon, double buttonSize, double iconSize) {
    final isActive = _currentTheme == theme;
    return GestureDetector(
      onTap: () {
        setState(() => _currentTheme = theme);
        _saveData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: buttonSize,
        height: buttonSize,
        padding: EdgeInsets.all(buttonSize * 0.2),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(colors: _getButtonGradientColors())
              : null,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.transparent : textColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            icon,
            style: TextStyle(fontSize: iconSize, color: isActive ? Colors.white : textColor.withOpacity(0.6)),
          ),
        ),
      ),
    );
  }

  Widget _buildLangButton(String lang, double buttonSize, double iconSize) {
    final isActive = _currentLang == lang;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentLang = lang;
          _updateTexts();
        });
        _saveData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: buttonSize * 0.8,
        padding: EdgeInsets.symmetric(horizontal: buttonSize * 0.4, vertical: buttonSize * 0.2),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(colors: _getButtonGradientColors())
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : textColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            lang.toUpperCase(),
            style: TextStyle(
              color: isActive ? Colors.white : textColor.withOpacity(0.6),
              fontWeight: FontWeight.w700,
              fontSize: iconSize * 0.8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMusicButton(double buttonSize, double iconSize) {
    return GestureDetector(
      onTap: _toggleMusic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: buttonSize,
        height: buttonSize,
        padding: EdgeInsets.all(buttonSize * 0.2),
        decoration: BoxDecoration(
          color: _isMusicPlaying ? accentColor : surfaceColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: _isMusicPlaying ? Colors.transparent : textColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(
          _isMusicPlaying ? Icons.music_note : Icons.music_off,
          color: _isMusicPlaying ? Colors.white : textColor.withOpacity(0.6),
          size: iconSize,
        ),
      ),
    );
  }

  List<Color> _getTitleGradientColors() {
    switch (_currentTheme) {
      case 'japanese':
        return const [Color(0xFFFFF0F5), Color(0xFFFFB6C1), Colors.white];
      case 'dark':
        return const [Color(0xFFEC4899), Color(0xFF8B5CF6)];
      case 'light':
      default:
        return const [Color(0xFF3B82F6), Color(0xFF8B5CF6)];
    }
  }

  List<Color> _getButtonGradientColors() {
    switch (_currentTheme) {
      case 'japanese':
        return const [Color(0xFFFF99CC), Color(0xFFE066B3)];
      case 'dark':
        return const [Color(0xFFEC4899), Color(0xFF8B5CF6)];
      case 'light':
      default:
        return const [Color(0xFF3B82F6), Color(0xFF8B5CF6)];
    }
  }
}

class AnimatedTaskCard extends StatefulWidget {
  final Map<String, dynamic> task;
  final int index;
  final Function(int) onToggle;
  final Function(int) onDelete;
  final Function(int, String) onEdit;
  final Color textColor;
  final Color secondaryTextColor;
  final Color surfaceColor;
  final Color accentColor;
  final String currentLang;
  final Map<String, String> texts;
  final String Function(String) formatDate;

  const AnimatedTaskCard({
    Key? key,
    required this.task,
    required this.index,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.textColor,
    required this.secondaryTextColor,
    required this.surfaceColor,
    required this.accentColor,
    required this.currentLang,
    required this.texts,
    required this.formatDate,
  }) : super(key: key);

  @override
  State<AnimatedTaskCard> createState() => _AnimatedTaskCardState();
}

class _AnimatedTaskCardState extends State<AnimatedTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    final task = widget.task;
    final isDone = task['status'] == 'done';
    final statusText = isDone ? widget.texts['statusDone']! : widget.texts['statusPending']!;
    final toggleText = isDone ? widget.texts['togglePending']! : widget.texts['toggleDone']!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.textColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildEditableText()),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      color: isDone ? Colors.green : widget.accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.formatDate(task['createdAt']),
                    style: TextStyle(
                      color: widget.secondaryTextColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                onPressed: () => widget.onToggle(widget.index),
                label: toggleText,
                color: isDone ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                onPressed: _showEditDialog,
                label: widget.texts['edit']!,
                color: Colors.purple,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                onPressed: () => widget.onDelete(widget.index),
                label: widget.texts['delete']!,
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableText() {
    final TextEditingController controller = TextEditingController(text: widget.task['text']);
    final FocusNode focusNode = FocusNode();
    bool isEditing = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onDoubleTap: () {
            setState(() => isEditing = true);
            focusNode.requestFocus();
          },
          child: isEditing
              ? TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(color: widget.textColor, fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: widget.texts['edit'],
                  ),
                  onSubmitted: (newText) {
                    widget.onEdit(widget.index, newText.trim());
                    setState(() => isEditing = false);
                  },
                  onEditingComplete: () {
                    widget.onEdit(widget.index, controller.text.trim());
                    setState(() => isEditing = false);
                  },
                )
              : Text(
                  widget.task['text'],
                  style: TextStyle(
                    color: widget.task['status'] == 'done'
                        ? widget.secondaryTextColor
                        : widget.textColor,
                    decoration: widget.task['status'] == 'done'
                        ? TextDecoration.lineThrough
                        : null,
                    fontSize: 16,
                  ),
                ),
        );
      },
    );
  }

  void _showEditDialog() {
    final controller = TextEditingController(text: widget.task['text']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(widget.texts['edit']!, style: TextStyle(color: widget.textColor)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: widget.textColor),
          decoration: InputDecoration(
            hintText: widget.texts['edit'],
            hintStyle: TextStyle(color: widget.secondaryTextColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.texts['cancel']!, style: TextStyle(color: widget.secondaryTextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onEdit(widget.index, controller.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor),
            child: Text(widget.texts['save']!, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        minimumSize: const Size(0, 36),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}