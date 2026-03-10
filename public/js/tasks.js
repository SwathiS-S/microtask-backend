async function loadTasks() {
    const grid = document.getElementById('task-grid');
    if (!grid) return;
    grid.innerHTML = '<div class="loading">Loading tasks...</div>';

    try {
        const response = await fetch(`${API_URL}/tasks`);
        const tasks = await response.json();

        if (!tasks || tasks.length === 0) {
            grid.innerHTML = '<div class="no-tasks">No tasks available at the moment.</div>';
            return;
        }

        grid.innerHTML = tasks.map(task => {
            const isMyTask = task.acceptedBy === currentUser.userId;
            let statusHTML = '';
            
            if (task.status === 'pending_release') {
                statusHTML = '<span class="status-pill pending">⏳ Payment being processed by admin</span>';
            } else if (task.status === 'completed') {
                statusHTML = `<span class="status-pill completed">✅ ₹${task.amount} received!</span>`;
            } else {
                statusHTML = `<span class="status-pill ${task.status}">${task.status}</span>`;
            }

            return `
                <div class="task-card-new">
                    <div class="task-card-header">
                        <h3>${task.title}</h3>
                        <span class="price-tag">₹${task.amount}</span>
                    </div>
                    <p>${task.description}</p>
                    <div class="task-card-footer">
                        ${statusHTML}
                        ${!isMyTask && task.status === 'open' ? `<button onclick="applyForTask('${task._id}')" class="btn-primary">Apply Now</button>` : ''}
                    </div>
                </div>
            `;
        }).join('');
    } catch (error) {
        grid.innerHTML = '<div class="error">Failed to load tasks.</div>';
    }
}

async function loadProviderTasks() {
    const grid = document.getElementById('provider-tasks-grid');
    if (!grid) return;
    grid.innerHTML = '<div class="loading">Loading your tasks...</div>';

    try {
        const response = await fetch(`${API_URL}/tasks/provider/${currentUser.userId}`);
        const tasks = await response.json();

        if (!tasks || tasks.length === 0) {
            grid.innerHTML = '<div class="no-tasks">You haven\'t posted any tasks yet.</div>';
            return;
        }

        grid.innerHTML = tasks.map(task => {
            let statusHTML = '';
            let actionButtons = '';

            if (task.status === 'pending_release') {
                statusHTML = '<span class="status-pill pending">⏳ Waiting for admin to release payment</span>';
            } else if (task.status === 'completed') {
                statusHTML = '<span class="status-pill completed">✅ Task Completed</span>';
            } else {
                statusHTML = `<span class="status-pill ${task.status}">${task.status}</span>`;
            }

            if (task.status === 'reviewed') {
                actionButtons = `<button onclick="approveWork('${task._id}', this)" class="btn-primary">Approve Work</button>`;
            }

            return `
                <div class="task-card-new">
                    <div class="task-card-header">
                        <h3>${task.title}</h3>
                        <span class="price-tag">₹${task.amount}</span>
                    </div>
                    <p>${task.description}</p>
                    <div class="task-card-footer">
                        ${statusHTML}
                        ${actionButtons}
                    </div>
                </div>
            `;
        }).join('');
    } catch (error) {
        grid.innerHTML = '<div class="error">Failed to load provider tasks.</div>';
    }
}

function showSection(sectionId) {
    // Hide all sections
    document.getElementById('browse-section').classList.add('hidden');
    document.getElementById('provider-section').classList.add('hidden');
    document.getElementById('wallet-view').classList.add('hidden');
    
    // Show requested section
    if (sectionId === 'browse') {
        document.getElementById('browse-section').classList.remove('hidden');
        loadTasks();
    } else if (sectionId === 'my-tasks') {
        // For workers, this might show their accepted tasks
        // For now, let's just reuse provider section if they are provider
        if (currentUser.role === 'taskProvider') {
            document.getElementById('provider-section').classList.remove('hidden');
            loadProviderTasks();
        } else {
            // Show worker's tasks
            document.getElementById('browse-section').classList.remove('hidden');
        }
    } else if (sectionId === 'wallet') {
        showWallet();
    }
    
    // Update sidebar active state
    document.querySelectorAll('.nav-item').forEach(item => item.classList.remove('active'));
    // This part would need more specific logic to match sectionId to nav items
}

async function applyForTask(taskId) {
    try {
        const response = await fetch(`${API_URL}/tasks/apply`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ taskId, userId: currentUser.userId })
        });
        const data = await response.json();
        if (data.success) {
            alert('Application submitted!');
            loadTasks();
        } else {
            alert(data.message || 'Application failed');
        }
    } catch (error) {
        alert('Error applying for task');
    }
}
