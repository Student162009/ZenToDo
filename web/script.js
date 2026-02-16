document.addEventListener('DOMContentLoaded', () => {
    
    // 🔘 КНОПКИ ТЕМ И ЯЗЫКА
    const themeBtns = document.querySelectorAll('.theme-btn');
    const langBtns = document.querySelectorAll('.lang-btn');
    
    // Инициализация темы
    let currentTheme = localStorage.getItem('theme') || 'japanese';
    document.body.className = `theme-${currentTheme}`;
    themeBtns.forEach(btn => {
        if (btn.dataset.theme === currentTheme) btn.classList.add('active');
    });
    
    // Инициализация языка
    let currentLang = localStorage.getItem('lang') || 'ru';
    langBtns.forEach(btn => {
        if (btn.dataset.lang === currentLang) btn.classList.add('active');
    });
    
    // Переключение тем
    themeBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const newTheme = btn.dataset.theme;
            document.body.className = `theme-${newTheme}`;
            themeBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            localStorage.setItem('theme', newTheme);
        });
    });
    
    // Переключение языка
    langBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            currentLang = btn.dataset.lang;
            langBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            setLanguage(currentLang);
            localStorage.setItem('lang', currentLang);
        });
    });
    
    // 📝 ЭЛЕМЕНТЫ TODO
    const form = document.getElementById('new-task-form');
    const input = document.getElementById('new-task-input');
    const tasksContainer = document.getElementById('tasks');
    const appTitle = document.getElementById('app-title');
    const tasksTitle = document.getElementById('tasks-title');
    
    // ДАННЫЕ ЗАДАЧ
    let tasks = JSON.parse(localStorage.getItem('tasks') || '[]');
    let sortMode = localStorage.getItem('sortMode') || 'none';
    
    // ЛОКАЛИЗАЦИЯ
    const texts = {
        ru: {
            title: 'ZenTodo 禅',
            tasksTitle: 'Задачи Дзен',
            placeholder: 'Что в гармонии сегодня?',
            submit: 'Добавить',
            sort: 'Сортировка:',
            sortNone: 'Без сортировки',
            sortAlpha: 'A→Я',
            sortAlphaRev: 'Я→A',
            sortLength: 'По длине',
            sortLengthRev: 'По длине (обр.)',
            sortDateNew: 'Сначала новые',
            sortDateOld: 'Сначала старые',
            sortStatus: 'По статусу',
            edit: 'Ред.',
            delete: '✕',
            togglePending: '⏳ Ожидание',
            toggleDone: '✅ Выполнено',
            statusPending: '⏳ Ожидание',
            statusDone: '✅ Выполнено'
        },
        en: {
            title: 'ZenTodo 禅',
            tasksTitle: 'Zen Tasks',
            placeholder: 'What brings harmony today?',
            submit: 'Add',
            sort: 'Sort:',
            sortNone: 'None',
            sortAlpha: 'A→Z',
            sortAlphaRev: 'Z→A',
            sortLength: 'Length',
            sortLengthRev: 'Length (rev)',
            sortDateNew: 'Newest first',
            sortDateOld: 'Oldest first',
            sortStatus: 'By status',
            edit: 'Edit',
            delete: '✕',
            togglePending: '⏳ Pending',
            toggleDone: '✅ Done',
            statusPending: '⏳ Pending',
            statusDone: '✅ Done'
        }
    };
    
    // УСТАНОВКА ЯЗЫКА
    function setLanguage(lang) {
        const t = texts[lang];
        appTitle.textContent = t.title;
        tasksTitle.textContent = t.tasksTitle;
        input.placeholder = t.placeholder;
        document.getElementById('new-task-submit').textContent = t.submit;
        updateSortButtons(t);
        renderTasks();
    }
    
    // 🔄 СОЗДАНИЕ КНОПОК СОРТИРОВКИ
    const sortContainer = document.createElement('div');
    sortContainer.className = 'sort-controls';
    sortContainer.innerHTML = `
        <label>${texts.ru.sort}</label>
        <button class="sort-btn" data-sort="none">${texts.ru.sortNone}</button>
        <button class="sort-btn" data-sort="alpha">${texts.ru.sortAlpha}</button>
        <button class="sort-btn" data-sort="alpha-rev">${texts.ru.sortAlphaRev}</button>
        <button class="sort-btn" data-sort="length">${texts.ru.sortLength}</button>
        <button class="sort-btn" data-sort="length-rev">${texts.ru.sortLengthRev}</button>
        <button class="sort-btn" data-sort="date-new">${texts.ru.sortDateNew}</button>
        <button class="sort-btn" data-sort="date-old">${texts.ru.sortDateOld}</button>
        <button class="sort-btn" data-sort="status">${texts.ru.sortStatus}</button>
    `;
    document.querySelector('.task-list').insertBefore(sortContainer, tasksContainer);
    
    function updateSortButtons(t) {
        const buttons = sortContainer.querySelectorAll('.sort-btn');
        buttons[0].textContent = t.sortNone;
        buttons[1].textContent = t.sortAlpha;
        buttons[2].textContent = t.sortAlphaRev;
        buttons[3].textContent = t.sortLength;
        buttons[4].textContent = t.sortLengthRev;
        buttons[5].textContent = t.sortDateNew;
        buttons[6].textContent = t.sortDateOld;
        buttons[7].textContent = t.sortStatus;
        sortContainer.querySelector('label').textContent = t.sort;
    }
    
    // 🔄 ОБРАБОТКА КНОПОК СОРТИРОВКИ
    sortContainer.querySelectorAll('.sort-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            sortMode = btn.dataset.sort;
            sortContainer.querySelectorAll('.sort-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            renderTasks();
            localStorage.setItem('sortMode', sortMode);
        });
    });
    
    // 🎯 РЕНДЕР ЗАДАЧ С СОРТИРОВКОЙ
    function renderTasks() {
        tasksContainer.innerHTML = '';
        let sortedTasks = [...tasks];
        
        // 🔄 ВСЕ ВИДЫ СОРТИРОВКИ
        switch(sortMode) {
            case 'alpha':
                sortedTasks.sort((a, b) => a.text.localeCompare(b.text));
                break;
            case 'alpha-rev':
                sortedTasks.sort((a, b) => b.text.localeCompare(a.text));
                break;
            case 'length':
                sortedTasks.sort((a, b) => a.text.length - b.text.length);
                break;
            case 'length-rev':
                sortedTasks.sort((a, b) => b.text.length - a.text.length);
                break;
            case 'date-new':
                sortedTasks.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
                break;
            case 'date-old':
                sortedTasks.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
                break;
            case 'status':
                sortedTasks.sort((a, b) => a.status.localeCompare(b.status));
                break;
        }
        
        sortedTasks.forEach(taskData => addTask(taskData, false));
    }
    
    // ➕ ДОБАВЛЕНИЕ НОВОЙ ЗАДАЧИ
    form.addEventListener('submit', (e) => {
        e.preventDefault();
        const text = input.value.trim();
        if (!text) return;
        
        const taskData = {
            id: Date.now(),
            text: text,
            createdAt: new Date().toISOString(),
            status: 'pending'
        };
        
        tasks.unshift(taskData);
        input.value = '';
        renderTasks();
        saveTasks();
    });
    
    // 🖌️ СОЗДАНИЕ ЭЛЕМЕНТА ЗАДАЧИ
    function addTask(taskData, save = true) {
        const task = document.createElement('div');
        task.className = `task ${taskData.status}`;
        task.dataset.id = taskData.id;
        
        const t = texts[currentLang];
        const statusText = taskData.status === 'pending' ? t.statusPending : t.statusDone;
        const toggleText = taskData.status === 'pending' ? t.toggleDone : t.togglePending;
        
        task.innerHTML = `
            <div class="task-header">
                <div class="content">
                    <div class="text" contenteditable="false">${taskData.text}</div>
                </div>
                <div class="task-meta">
                    <span class="status">${statusText}</span>
                    <span class="date">${formatDate(taskData.createdAt)}</span>
                </div>
            </div>
            <div class="actions">
                <button class="toggle-status">${toggleText}</button>
                <button class="edit">${t.edit}</button>
                <button class="delete">${t.delete}</button>
            </div>
        `;
        
        tasksContainer.appendChild(task);
        
        // 📝 РЕДАКТИРОВАНИЕ
        const textEl = task.querySelector('.text');
        const editBtn = task.querySelector('.edit');
        
        editBtn.addEventListener('click', () => {
            textEl.contentEditable = true;
            textEl.focus();
            textEl.classList.add('editing');
        });
        
        textEl.addEventListener('blur', () => {
            textEl.contentEditable = false;
            textEl.classList.remove('editing');
            const newText = textEl.textContent.trim();
            if (newText && newText !== taskData.text) {
                const taskIndex = tasks.findIndex(t => t.id === taskData.id);
                if (taskIndex > -1) {
                    tasks[taskIndex].text = newText;
                    renderTasks();
                    saveTasks();
                }
            }
        });
        
        textEl.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                textEl.blur();
            }
        });
        
        // ✅ ПЕРЕКЛЮЧЕНИЕ СТАТУСА
        const toggleBtn = task.querySelector('.toggle-status');
        toggleBtn.addEventListener('click', () => {
            const taskIndex = tasks.findIndex(t => t.id === taskData.id);
            if (taskIndex > -1) {
                tasks[taskIndex].status = tasks[taskIndex].status === 'pending' ? 'done' : 'pending';
                renderTasks();
                saveTasks();
            }
        });
        
        // 🗑️ УДАЛЕНИЕ
        task.querySelector('.delete').addEventListener('click', () => {
            tasks = tasks.filter(t => t.id !== taskData.id);
            renderTasks();
            saveTasks();
        });
    }
    
    // 📅 ФОРМАТ ДАТЫ
    function formatDate(isoString) {
        const date = new Date(isoString);
        return date.toLocaleDateString(currentLang === 'ru' ? 'ru-RU' : 'en-US', {
            day: 'numeric',
            month: 'short',
            hour: '2-digit',
            minute: '2-digit'
        });
    }
    
    // 💾 СОХРАНЕНИЕ
    function saveTasks() {
        localStorage.setItem('tasks', JSON.stringify(tasks));
    }
    
    // 🚀 ИНИЦИАЛИЗАЦИЯ
    setLanguage(currentLang);
    const activeSortBtn = sortContainer.querySelector(`[data-sort="${sortMode}"]`);
    if (activeSortBtn) activeSortBtn.classList.add('active');
    renderTasks();
});

