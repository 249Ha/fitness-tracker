// --- Data Store (localStorage) ---

function loadData(key) {
    const raw = localStorage.getItem(key);
    return raw ? JSON.parse(raw) : [];
}

function saveData(key, data) {
    localStorage.setItem(key, JSON.stringify(data));
}

function getWorkouts() { return loadData('workouts'); }
function getBodyRecords() { return loadData('bodyRecords'); }
function getMealRecords() { return loadData('mealRecords'); }

function setWorkouts(data) { saveData('workouts', data); }
function setBodyRecords(data) { saveData('bodyRecords', data); }
function setMealRecords(data) { saveData('mealRecords', data); }

// --- State ---

let currentTab = 'home';
let selectedCategory = 'workout';
let selectedExercise = '';
let selectedBodyMetric = 'bodyWeight';
let selectedMealMetric = 'calories';
let exerciseInputs = [];
let chartInstance = null;

// --- Utility ---

function uuid() {
    return crypto.randomUUID ? crypto.randomUUID() : Math.random().toString(36).slice(2);
}

function formatDate(dateStr) {
    const d = new Date(dateStr);
    const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日(${weekdays[d.getDay()]})`;
}

function formatTime(dateStr) {
    const d = new Date(dateStr);
    return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
}

function formatMonthDay(dateStr) {
    const d = new Date(dateStr);
    return `${d.getMonth() + 1}/${d.getDate()}`;
}

function formatDateTimeFull(dateStr) {
    const d = new Date(dateStr);
    const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日(${weekdays[d.getDay()]}) ${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
}

function startOfDay(date) {
    const d = new Date(date);
    d.setHours(0, 0, 0, 0);
    return d;
}

function isToday(dateStr) {
    const d = startOfDay(dateStr);
    const today = startOfDay(new Date());
    return d.getTime() === today.getTime();
}

function startOfWeek(date) {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day;
    const start = new Date(d);
    start.setDate(diff);
    start.setHours(0, 0, 0, 0);
    return start;
}

function isSameDay(d1, d2) {
    return startOfDay(d1).getTime() === startOfDay(d2).getTime();
}

// --- Tab Switching ---

function switchTab(tab) {
    currentTab = tab;
    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.getElementById('tab-' + tab).classList.add('active');
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.tab === tab);
    });

    const titles = { home: 'フィットトラッカー', progress: '進捗', history: '履歴' };
    document.getElementById('page-title').textContent = titles[tab];
    document.getElementById('add-btn').style.display = tab === 'home' ? '' : 'none';

    if (tab === 'home') renderHome();
    else if (tab === 'progress') renderProgress();
    else if (tab === 'history') renderHistory();
}

// --- Home Tab ---

function renderHome() {
    renderStatsRow();
    renderBodyMetricsOverview();
    renderMealOverview();
    renderTodaySection();
    renderRecentSection();
}

function renderStatsRow() {
    const workouts = getWorkouts();
    const weekStart = startOfWeek(new Date());
    const thisWeekCount = workouts.filter(w => new Date(w.date) >= weekStart).length;
    const streak = calcStreak(workouts);

    document.getElementById('stats-row').innerHTML = `
        <div class="stat-card">
            <div class="stat-icon">📅</div>
            <div class="stat-value">${thisWeekCount}<span class="stat-unit">回</span></div>
            <div class="stat-title">今週</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon">⚡</div>
            <div class="stat-value">${streak}<span class="stat-unit">日</span></div>
            <div class="stat-title">連続</div>
        </div>
    `;
}

function calcStreak(workouts) {
    if (workouts.length === 0) return 0;
    let streak = 0;
    let checkDate = startOfDay(new Date());

    if (!workouts.some(w => isSameDay(w.date, checkDate))) {
        checkDate.setDate(checkDate.getDate() - 1);
    }

    while (workouts.some(w => isSameDay(w.date, checkDate))) {
        streak++;
        checkDate.setDate(checkDate.getDate() - 1);
    }
    return streak;
}

function renderBodyMetricsOverview() {
    const records = getBodyRecords().sort((a, b) => new Date(b.date) - new Date(a.date));
    const container = document.getElementById('body-metrics-overview');

    if (records.length === 0) {
        container.innerHTML = `
            <div class="section">
                <div class="section-title-text">体組成</div>
                <div class="empty-state">
                    <div class="empty-icon">💓</div>
                    <div class="empty-text">体重と体脂肪率の記録はまだありません</div>
                </div>
            </div>`;
        return;
    }

    const latest = records[0];
    const fatDisplay = latest.bodyFatPercentage != null
        ? `${latest.bodyFatPercentage.toFixed(1)}`
        : '-';
    const fatUnit = latest.bodyFatPercentage != null ? '%' : '';
    const dateStr = formatDateTimeFull(latest.date).replace(/^\d{4}年/, '');

    container.innerHTML = `
        <div class="section">
            <div class="section-title-text">体組成</div>
            <div class="metrics-row">
                <div class="metric-card">
                    <div class="metric-icon">⚖️</div>
                    <div class="metric-value-row">
                        <span class="metric-value">${latest.bodyWeight.toFixed(1)}</span>
                        <span class="metric-unit">kg</span>
                    </div>
                    <div class="metric-title">体重</div>
                </div>
                <div class="metric-card">
                    <div class="metric-icon">🏋️</div>
                    <div class="metric-value-row">
                        <span class="metric-value">${fatDisplay}</span>
                        <span class="metric-unit">${fatUnit}</span>
                    </div>
                    <div class="metric-title">体脂肪率</div>
                </div>
            </div>
            <div class="section-caption">最終記録: ${dateStr}</div>
        </div>`;
}

function renderMealOverview() {
    const records = getMealRecords().sort((a, b) => new Date(b.date) - new Date(a.date));
    const container = document.getElementById('meal-overview');

    const todayRecords = records.filter(r => isToday(r.date));
    let summary = null;
    let caption = '';

    if (todayRecords.length > 0) {
        summary = {
            calories: todayRecords.reduce((s, r) => s + r.calories, 0),
            protein: todayRecords.reduce((s, r) => s + r.protein, 0),
        };
        caption = '今日の合計';
    } else if (records.length > 0) {
        const grouped = groupMealsByDay(records);
        if (grouped.length > 0) {
            summary = grouped[0];
            caption = `直近の合計: ${formatMonthDay(grouped[0].date)}`;
        }
    }

    if (!summary) {
        container.innerHTML = `
            <div class="section">
                <div class="section-title-text">食事</div>
                <div class="empty-state">
                    <div class="empty-icon">🍽️</div>
                    <div class="empty-text">食事の記録はまだありません</div>
                </div>
            </div>`;
        return;
    }

    container.innerHTML = `
        <div class="section">
            <div class="section-title-text">食事</div>
            <div class="metrics-row">
                <div class="metric-card">
                    <div class="metric-icon">🔥</div>
                    <div class="metric-value-row">
                        <span class="metric-value">${Math.round(summary.calories)}</span>
                        <span class="metric-unit">kcal</span>
                    </div>
                    <div class="metric-title">カロリー</div>
                </div>
                <div class="metric-card">
                    <div class="metric-icon">💪</div>
                    <div class="metric-value-row">
                        <span class="metric-value">${summary.protein.toFixed(1)}</span>
                        <span class="metric-unit">g</span>
                    </div>
                    <div class="metric-title">タンパク質</div>
                </div>
            </div>
            <div class="section-caption">${caption}</div>
        </div>`;
}

function groupMealsByDay(records) {
    const groups = {};
    for (const r of records) {
        const key = startOfDay(r.date).toISOString();
        if (!groups[key]) groups[key] = { date: startOfDay(r.date).toISOString(), calories: 0, protein: 0 };
        groups[key].calories += r.calories;
        groups[key].protein += r.protein;
    }
    return Object.values(groups).sort((a, b) => new Date(b.date) - new Date(a.date));
}

function renderTodaySection() {
    const workouts = getWorkouts();
    const todayWorkout = workouts.find(w => isToday(w.date));
    const container = document.getElementById('today-section');

    let html = '<div class="section"><div class="section-title-text">本日のワークアウト</div>';

    if (todayWorkout && todayWorkout.exercises.length > 0) {
        const sorted = [...todayWorkout.exercises].sort((a, b) => a.name.localeCompare(b.name));
        html += '<div class="workout-card-list">';
        sorted.forEach((ex, i) => {
            html += `
                <div class="workout-item">
                    <div>
                        <div class="workout-item-name">${esc(ex.name)}</div>
                        <div class="workout-item-detail">${ex.sets}セット × ${ex.reps}回</div>
                    </div>
                    <div class="workout-item-weight">${ex.weight.toFixed(1)} kg</div>
                </div>`;
            if (i < sorted.length - 1) html += '<div class="workout-divider"></div>';
        });
        html += '</div>';
    } else {
        html += `
            <div class="empty-state">
                <div class="empty-icon">🏋️</div>
                <div class="empty-text">まだ記録がありません</div>
                <button class="empty-btn" onclick="showAddModal()">＋ ワークアウトを記録</button>
            </div>`;
    }

    html += '</div>';
    container.innerHTML = html;
}

function renderRecentSection() {
    const workouts = getWorkouts().sort((a, b) => new Date(b.date) - new Date(a.date));
    const container = document.getElementById('recent-section');

    if (workouts.length === 0) {
        container.innerHTML = '';
        return;
    }

    let html = '<div class="section"><div class="section-title-text">最近の記録</div>';

    workouts.slice(0, 5).forEach(w => {
        const sorted = [...w.exercises].sort((a, b) => a.name.localeCompare(b.name));
        html += `<div class="recent-card">
            <div class="recent-header">
                <span class="recent-date">${formatDate(w.date)}</span>
                <span class="recent-badge">${w.exercises.length}種目</span>
            </div>`;
        sorted.forEach(ex => {
            html += `<div class="recent-exercise">
                <span>${esc(ex.name)}</span>
                <span class="recent-exercise-detail">${ex.weight.toFixed(1)}kg × ${ex.sets}s × ${ex.reps}r</span>
            </div>`;
        });
        html += '</div>';
    });

    html += '</div>';
    container.innerHTML = html;
}

// --- Progress Tab ---

function renderProgress() {
    renderCategoryPicker();
    renderSubPicker();
    renderChart();
    renderProgressStats();
    renderRecordList();
}

function renderCategoryPicker() {
    const categories = [
        { key: 'workout', label: '筋トレ' },
        { key: 'body', label: '体組成' },
        { key: 'meal', label: '食事' },
    ];
    document.getElementById('category-picker').innerHTML = categories.map(c =>
        `<button class="category-btn ${selectedCategory === c.key ? 'active' : ''}" onclick="selectCategory('${c.key}')">${c.label}</button>`
    ).join('');
}

function selectCategory(cat) {
    selectedCategory = cat;
    renderProgress();
}

function renderSubPicker() {
    const container = document.getElementById('sub-picker');

    if (selectedCategory === 'workout') {
        const names = getUsedExerciseNames();
        if (names.length > 0 && !names.includes(selectedExercise)) {
            selectedExercise = names[0];
        }
        container.innerHTML = `<div class="sub-picker">${names.map(n =>
            `<button class="sub-picker-btn ${selectedExercise === n ? 'active blue' : ''}" onclick="selectExercise('${esc(n)}')">${esc(n)}</button>`
        ).join('')}</div>`;
    } else if (selectedCategory === 'body') {
        const metrics = [
            { key: 'bodyWeight', label: '体重', color: 'green' },
            { key: 'bodyFatPercentage', label: '体脂肪率', color: 'pink' },
        ];
        container.innerHTML = `<div class="sub-picker">${metrics.map(m =>
            `<button class="sub-picker-btn ${selectedBodyMetric === m.key ? 'active ' + m.color : ''}" onclick="selectBodyMetric('${m.key}')">${m.label}</button>`
        ).join('')}</div>`;
    } else {
        const metrics = [
            { key: 'calories', label: 'カロリー', color: 'orange' },
            { key: 'protein', label: 'タンパク質', color: 'mint' },
        ];
        container.innerHTML = `<div class="sub-picker">${metrics.map(m =>
            `<button class="sub-picker-btn ${selectedMealMetric === m.key ? 'active ' + m.color : ''}" onclick="selectMealMetric('${m.key}')">${m.label}</button>`
        ).join('')}</div>`;
    }
}

function selectExercise(name) { selectedExercise = name; renderProgress(); }
function selectBodyMetric(m) { selectedBodyMetric = m; renderProgress(); }
function selectMealMetric(m) { selectedMealMetric = m; renderProgress(); }

function getUsedExerciseNames() {
    const workouts = getWorkouts();
    const seen = new Set();
    const names = [];
    for (const w of workouts) {
        for (const ex of w.exercises) {
            if (!seen.has(ex.name)) {
                seen.add(ex.name);
                names.push(ex.name);
            }
        }
    }
    return names;
}

function getActiveProgressData() {
    if (selectedCategory === 'workout') {
        const workouts = getWorkouts();
        const points = [];
        for (const w of workouts) {
            for (const ex of w.exercises) {
                if (ex.name === selectedExercise) {
                    points.push({ date: ex.date || w.date, value: ex.weight });
                }
            }
        }
        return points.sort((a, b) => new Date(a.date) - new Date(b.date));
    } else if (selectedCategory === 'body') {
        const records = getBodyRecords();
        return records
            .filter(r => selectedBodyMetric === 'bodyWeight' || r.bodyFatPercentage != null)
            .map(r => ({
                date: r.date,
                value: selectedBodyMetric === 'bodyWeight' ? r.bodyWeight : r.bodyFatPercentage,
            }))
            .sort((a, b) => new Date(a.date) - new Date(b.date));
    } else {
        const records = getMealRecords();
        const daily = groupMealsByDay(records).reverse();
        return daily.map(d => ({
            date: d.date,
            value: selectedMealMetric === 'calories' ? d.calories : d.protein,
        }));
    }
}

function getChartTitle() {
    if (selectedCategory === 'workout') return '重量推移';
    if (selectedCategory === 'body') return selectedBodyMetric === 'bodyWeight' ? '体重推移' : '体脂肪率推移';
    return selectedMealMetric === 'calories' ? 'カロリー推移' : 'タンパク質推移';
}

function getChartUnit() {
    if (selectedCategory === 'workout') return 'kg';
    if (selectedCategory === 'body') return selectedBodyMetric === 'bodyWeight' ? 'kg' : '%';
    return selectedMealMetric === 'calories' ? 'kcal' : 'g';
}

function getChartColor() {
    if (selectedCategory === 'workout') return '#007AFF';
    if (selectedCategory === 'body') return selectedBodyMetric === 'bodyWeight' ? '#34C759' : '#FF2D55';
    return selectedMealMetric === 'calories' ? '#FF9500' : '#00C7BE';
}

function getEmptyMessage() {
    if (selectedCategory === 'workout') return 'この種目のデータはまだありません';
    if (selectedCategory === 'body') {
        return selectedBodyMetric === 'bodyWeight' ? '体重の記録はまだありません' : '体脂肪率の記録はまだありません';
    }
    return selectedMealMetric === 'calories' ? 'カロリーの記録はまだありません' : 'タンパク質の記録はまだありません';
}

function renderChart() {
    const data = getActiveProgressData();
    const container = document.getElementById('chart-container');
    const title = getChartTitle();
    const unit = getChartUnit();
    const color = getChartColor();

    if (data.length === 0) {
        container.innerHTML = `
            <div class="chart-card">
                <h3>${title}</h3>
                <div class="chart-empty">
                    <div class="chart-empty-icon">📈</div>
                    <div class="chart-empty-text">${getEmptyMessage()}</div>
                </div>
            </div>`;
        if (chartInstance) { chartInstance.destroy(); chartInstance = null; }
        return;
    }

    if (data.length === 1) {
        container.innerHTML = `
            <div class="chart-card">
                <h3>${title}</h3>
                <div class="chart-single-value">
                    <div class="big-number" style="color:${color}">${data[0].value.toFixed(1)} ${unit}</div>
                    <div class="date-label">${formatMonthDay(data[0].date)}</div>
                    <div class="hint">データが2つ以上でグラフを表示します</div>
                </div>
            </div>`;
        if (chartInstance) { chartInstance.destroy(); chartInstance = null; }
        return;
    }

    container.innerHTML = `
        <div class="chart-card">
            <h3>${title}</h3>
            <div class="chart-wrapper"><canvas id="progress-chart"></canvas></div>
        </div>`;

    if (chartInstance) { chartInstance.destroy(); chartInstance = null; }

    const ctx = document.getElementById('progress-chart').getContext('2d');
    const gradient = ctx.createLinearGradient(0, 0, 0, 220);
    gradient.addColorStop(0, color + '33');
    gradient.addColorStop(1, color + '05');

    chartInstance = new Chart(ctx, {
        type: 'line',
        data: {
            labels: data.map(p => new Date(p.date)),
            datasets: [{
                data: data.map(p => p.value),
                borderColor: color,
                backgroundColor: gradient,
                fill: true,
                tension: 0.4,
                borderWidth: 2.5,
                pointBackgroundColor: color,
                pointRadius: 4,
                pointHoverRadius: 6,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    callbacks: {
                        title: (items) => formatMonthDay(data[items[0].dataIndex].date),
                        label: (item) => `${item.parsed.y.toFixed(1)} ${unit}`,
                    }
                }
            },
            scales: {
                x: {
                    type: 'time',
                    time: {
                        unit: 'day',
                        displayFormats: { day: 'M/d' }
                    },
                    grid: { display: false },
                    ticks: { font: { size: 10 } }
                },
                y: {
                    title: { display: true, text: unit, font: { size: 11 } },
                    grid: { color: 'rgba(0,0,0,0.05)' },
                    ticks: { font: { size: 10 } }
                }
            }
        }
    });
}

function renderProgressStats() {
    const data = getActiveProgressData();
    const unit = getChartUnit();
    const color = getChartColor();
    const container = document.getElementById('progress-stats');

    const maxVal = data.length > 0 ? Math.max(...data.map(d => d.value)) : 0;
    const latest = data.length > 0 ? data[data.length - 1].value : 0;
    const prev = data.length > 1 ? data[data.length - 2].value : null;
    const change = prev != null ? latest - prev : null;
    const changeStr = change != null ? (change >= 0 ? '+' : '') + change.toFixed(1) : '-';
    const changeIcon = change == null ? '↗️' : (change >= 0 ? '↗️' : '↘️');
    const countLabel = selectedCategory === 'meal' ? '日数' : '記録回数';

    container.innerHTML = `
        <div class="progress-stats-row">
            <div class="progress-stat-card">
                <div class="stat-icon">🏆</div>
                <div class="stat-value">${maxVal.toFixed(1)}</div>
                <div class="stat-label">最高値 (${unit})</div>
            </div>
            <div class="progress-stat-card">
                <div class="stat-icon" style="color:${color}">#</div>
                <div class="stat-value">${data.length}</div>
                <div class="stat-label">${countLabel}</div>
            </div>
            <div class="progress-stat-card">
                <div class="stat-icon">${changeIcon}</div>
                <div class="stat-value">${changeStr}</div>
                <div class="stat-label">前回比 (${unit})</div>
            </div>
        </div>`;
}

function renderRecordList() {
    const data = getActiveProgressData();
    const unit = getChartUnit();
    const container = document.getElementById('record-list');

    if (data.length === 0) {
        container.innerHTML = '';
        return;
    }

    const maxVal = Math.max(...data.map(d => d.value));
    const listLabel = selectedCategory === 'meal' ? '日別一覧' : '記録一覧';

    let html = `<div class="section-title-text">${listLabel}</div>`;
    [...data].reverse().forEach(p => {
        const trophy = p.value === maxVal ? '<span class="record-trophy">🏆</span>' : '';
        html += `<div class="record-item">
            <span class="record-date">${formatMonthDay(p.date)}</span>
            <span class="record-value">${p.value.toFixed(1)} ${unit}${trophy}</span>
        </div>`;
    });

    container.innerHTML = html;
}

// --- History Tab ---

function renderHistory() {
    const workouts = getWorkouts().sort((a, b) => new Date(b.date) - new Date(a.date));
    const container = document.getElementById('history-list');

    if (workouts.length === 0) {
        container.innerHTML = `
            <div class="empty-state" style="margin-top:40px;">
                <div class="empty-icon">📅</div>
                <div class="empty-text">ワークアウト履歴がまだありません</div>
                <div style="font-size:12px;color:var(--text-tertiary);margin-top:8px;">
                    ワークアウトを記録すると<br>ここに表示されます
                </div>
            </div>`;
        return;
    }

    let html = '';
    workouts.forEach(w => {
        const sorted = [...w.exercises].sort((a, b) => a.name.localeCompare(b.name));
        const totalVolume = w.exercises.reduce((s, e) => s + e.weight * e.sets * e.reps, 0);

        html += `<div class="history-card">
            <button class="history-delete-btn" onclick="confirmDelete('${w.id}')">🗑️</button>
            <div class="history-header">
                <div>
                    <div class="history-date-main">${formatDate(w.date)}</div>
                    <div class="history-date-sub">${formatTime(w.date)}</div>
                </div>
                <div class="history-stats">
                    <div class="history-stat">
                        <div class="history-stat-value blue">${w.exercises.length}</div>
                        <div class="history-stat-label">種目</div>
                    </div>
                    <div class="history-stat">
                        <div class="history-stat-value orange">${Math.round(totalVolume)}</div>
                        <div class="history-stat-label">kg</div>
                    </div>
                </div>
            </div>
            <div class="history-divider"></div>`;

        sorted.forEach(ex => {
            html += `<div class="history-exercise">
                <span class="history-exercise-name">${esc(ex.name)}</span>
                <div class="history-exercise-detail">
                    <span class="history-exercise-weight">${ex.weight.toFixed(1)}kg</span>
                    <span style="color:var(--text-tertiary)">×</span>
                    <span class="history-exercise-sets">${ex.sets}s × ${ex.reps}r</span>
                </div>
            </div>`;
        });

        html += '</div>';
    });

    container.innerHTML = html;
}

let deleteTargetId = null;

function confirmDelete(id) {
    deleteTargetId = id;
    document.getElementById('delete-modal').style.display = '';
    document.getElementById('confirm-delete-btn').onclick = () => {
        deleteWorkout(deleteTargetId);
        hideDeleteModal();
    };
}

function hideDeleteModal() {
    document.getElementById('delete-modal').style.display = 'none';
    deleteTargetId = null;
}

function deleteWorkout(id) {
    let workouts = getWorkouts().filter(w => w.id !== id);
    setWorkouts(workouts);
    renderHistory();
    if (currentTab === 'home') renderHome();
}

// --- Add Workout Modal ---

function showAddModal() {
    exerciseInputs = [{ id: uuid(), name: '', weight: 60, sets: 3, reps: 10 }];
    document.getElementById('input-body-weight').value = '';
    document.getElementById('input-body-fat').value = '';
    document.getElementById('input-calories').value = '';
    document.getElementById('input-protein').value = '';
    document.getElementById('modal-date').textContent = formatDateTimeFull(new Date());
    document.getElementById('add-modal').style.display = '';
    renderExerciseInputs();
    updateSaveSummary();
}

function hideAddModal() {
    document.getElementById('add-modal').style.display = 'none';
}

function addExerciseInput() {
    exerciseInputs.push({ id: uuid(), name: '', weight: 60, sets: 3, reps: 10 });
    renderExerciseInputs();
    updateSaveSummary();
}

function removeExerciseInput(id) {
    exerciseInputs = exerciseInputs.filter(e => e.id !== id);
    renderExerciseInputs();
    updateSaveSummary();
}

function renderExerciseInputs() {
    const container = document.getElementById('exercise-inputs');
    let html = '';

    exerciseInputs.forEach((ex, i) => {
        const volume = ex.weight * ex.sets * ex.reps;
        const canDelete = exerciseInputs.length > 1;

        html += `
        <div class="exercise-card" data-id="${ex.id}">
            <div class="exercise-card-header">
                <span class="exercise-number">種目 ${i + 1}</span>
                ${canDelete ? `<button class="delete-exercise-btn" onclick="removeExerciseInput('${ex.id}')">🗑️</button>` : ''}
            </div>
            <div class="input-group-full">
                <label>種目名</label>
                <input type="text" placeholder="例: ベンチプレス" value="${esc(ex.name)}"
                    oninput="updateExInput('${ex.id}','name',this.value)">
            </div>
            <div class="stepper-row">
                <div class="stepper-group">
                    <label>重量 (kg)</label>
                    <div class="stepper">
                        <button onclick="stepExInput('${ex.id}','weight',-2.5)">−</button>
                        <span class="stepper-value">${ex.weight.toFixed(1)}</span>
                        <button onclick="stepExInput('${ex.id}','weight',2.5)">＋</button>
                    </div>
                </div>
                <div class="stepper-group">
                    <label>セット</label>
                    <div class="stepper">
                        <button onclick="stepExInput('${ex.id}','sets',-1)">−</button>
                        <span class="stepper-value">${ex.sets}</span>
                        <button onclick="stepExInput('${ex.id}','sets',1)">＋</button>
                    </div>
                </div>
                <div class="stepper-group">
                    <label>回数</label>
                    <div class="stepper">
                        <button onclick="stepExInput('${ex.id}','reps',-1)">−</button>
                        <span class="stepper-value">${ex.reps}</span>
                        <button onclick="stepExInput('${ex.id}','reps',1)">＋</button>
                    </div>
                </div>
            </div>
            ${ex.name ? `<div class="volume-display">ボリューム: <span>${Math.round(volume)} kg</span></div>` : ''}
        </div>`;
    });

    container.innerHTML = html;
}

function updateExInput(id, field, value) {
    const ex = exerciseInputs.find(e => e.id === id);
    if (ex) {
        ex[field] = value;
        updateSaveSummary();
        if (field === 'name') {
            const volumeEl = document.querySelector(`.exercise-card[data-id="${id}"] .volume-display`);
            if (value && !volumeEl) renderExerciseInputs();
            else if (!value && volumeEl) renderExerciseInputs();
        }
    }
}

function stepExInput(id, field, delta) {
    const ex = exerciseInputs.find(e => e.id === id);
    if (!ex) return;
    if (field === 'weight') ex.weight = Math.max(0, ex.weight + delta);
    else if (field === 'sets') ex.sets = Math.max(1, Math.min(20, ex.sets + delta));
    else if (field === 'reps') ex.reps = Math.max(1, Math.min(50, ex.reps + delta));
    renderExerciseInputs();
    updateSaveSummary();
}

function updateSaveSummary() {
    const validCount = exerciseInputs.filter(e => e.name.trim() !== '').length;
    const hasBody = parseFloat(document.getElementById('input-body-weight').value) > 0;
    const hasMeal = parseFloat(document.getElementById('input-calories').value) > 0;
    const canSave = validCount > 0 || hasBody || hasMeal;

    const parts = [];
    if (validCount > 0) parts.push(`${validCount}種目`);
    if (hasBody) parts.push('体組成');
    if (hasMeal) parts.push('食事');

    document.getElementById('save-summary').textContent = parts.length > 0 ? parts.join(' + ') : '未入力';
    document.getElementById('save-btn').disabled = !canSave;
}

function saveWorkout() {
    const validExercises = exerciseInputs.filter(e => e.name.trim() !== '');
    const bodyWeight = parseFloat(document.getElementById('input-body-weight').value);
    const bodyFat = parseFloat(document.getElementById('input-body-fat').value);
    const calories = parseFloat(document.getElementById('input-calories').value);
    const protein = parseFloat(document.getElementById('input-protein').value);
    const now = new Date().toISOString();

    if (validExercises.length === 0 && isNaN(bodyWeight) && isNaN(calories)) return;

    if (validExercises.length > 0) {
        const workouts = getWorkouts();
        workouts.push({
            id: uuid(),
            date: now,
            exercises: validExercises.map(e => ({
                id: uuid(),
                name: e.name.trim(),
                weight: e.weight,
                sets: e.sets,
                reps: e.reps,
                date: now,
            }))
        });
        setWorkouts(workouts);
    }

    if (!isNaN(bodyWeight)) {
        const records = getBodyRecords();
        records.push({
            id: uuid(),
            date: now,
            bodyWeight: bodyWeight,
            bodyFatPercentage: isNaN(bodyFat) ? null : bodyFat,
        });
        setBodyRecords(records);
    }

    if (!isNaN(calories)) {
        const records = getMealRecords();
        records.push({
            id: uuid(),
            date: now,
            calories: calories,
            protein: isNaN(protein) ? 0 : protein,
        });
        setMealRecords(records);
    }

    hideAddModal();
    switchTab(currentTab);
}

// --- Helpers ---

function esc(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

// Listen for input changes in modal
document.addEventListener('input', (e) => {
    if (['input-body-weight', 'input-body-fat', 'input-calories', 'input-protein'].includes(e.target.id)) {
        updateSaveSummary();
    }
});

// --- Init ---
renderHome();
