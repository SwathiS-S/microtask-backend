async function loadTasks() {
    if (!currentUser) return;
    const isProvider = currentUser.role === 'taskProvider';
    const userId = currentUser.userId;

    try {
        const response = await fetch(`${API_URL}/tasks`);
        const tasks = await response.json();

        const taskGrid = document.getElementById('task-grid');
        if (!taskGrid) return;
        taskGrid.innerHTML = '';

        tasks.forEach(task => {
            const isMyTask = String(task.acceptedBy && (task.acceptedBy._id || task.acceptedBy)) === String(userId);
            const canApply = !isProvider && !isMyTask && isVisibleTask(task);

            let statusHTML = '';
            if (isMyTask) {
                if (task.status === 'submitted') {
                    statusHTML = `<div class="task-status status-under-review">Work submitted ✅</div>`;
                } else if (task.status === 'reviewed') {
                    statusHTML = `<div class="task-status status-under-review">Under review ⏳</div>`;
                } else if (task.status === 'pending_release') {
                    statusHTML = `<div class="task-status status-under-review">Payment being processed ⏳</div>`;
                } else if (task.status === 'completed') {
                    statusHTML = `<div class="task-status status-completed">₹${task.amount} received! <button class="btn-small" onclick="showWallet()">Withdraw</button></div>`;
                } else {
                    statusHTML = `<div class="task-status status-inprogress">In Progress</div>`;
                }
            } else {
                statusHTML = `<div class="task-status status-open">Open</div>`;
            }

            const taskCard = `
                <div class="task-card-new">
                    <div class="task-card-header">
                        <h3>${task.title}</h3>
                        <div class="task-card-price">₹${task.amount}</div>
                    </div>
                    <p class="task-card-description">${task.description}</p>
                    <div class="task-card-tags">
                        ${task.tags.map(tag => `<span class="tag-item">${tag}</span>`).join('')}
                    </div>
                    <div class="task-card-footer">
                        ${statusHTML}
                        ${canApply ? `<button class="btn-small" onclick="applyForTask('${task._id}')">Apply Now</button>` : ''}
                    </div>
                </div>
            `;
            taskGrid.innerHTML += taskCard;
        });
    } catch (error) {
        console.error('Error loading tasks:', error);
    }
}

async function loadProviderTasks() {
    if (!currentUser || currentUser.role !== 'taskProvider') return;

    try {
        const response = await fetch(`${API_URL}/tasks/provider/${currentUser.userId}`);
        const tasks = await response.json();

        const providerTasksGrid = document.getElementById('provider-tasks-grid');
        if (!providerTasksGrid) return;
        providerTasksGrid.innerHTML = '';

        tasks.forEach(task => {
            const tid = task._id;
            let actionButtons = '';
            if (task.status === 'submitted') {
                actionButtons = `<a class="btn-small btn-secondary" href="${API_URL}${task.finalFile.path}" target="_blank">View Final Work</a>`;
            } else if (task.status === 'reviewed') {
                actionButtons = `<button class="btn-small" data-action="approve-work" data-id="${tid}">Approve Work</button>
                               <button class="btn-small btn-danger" data-action="dispute" data-id="${tid}">Dispute</button>`;
            } else if (task.status === 'pending_release') {
                actionButtons = `<span>Waiting for admin release ⏳</span>`;
            } else if (task.status === 'completed') {
                actionButtons = `<span>Completed ✅</span>`;
            }

            const taskCard = `
                <div class="task-card-new">
                    <div class="task-card-header">
                        <h3>${task.title}</h3>
                        <div class="task-card-price">₹${task.amount}</div>
                    </div>
                    <p class="task-card-description">${task.description}</p>
                    <div class="task-card-footer">
                        ${actionButtons}
                    </div>
                </div>
            `;
            providerTasksGrid.innerHTML += taskCard;
        });
    } catch (error) {
        console.error('Error loading provider tasks:', error);
    }
}
