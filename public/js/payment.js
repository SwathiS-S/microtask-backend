async function approveWork(taskId, btn) {
    if (!taskId || !currentUser || !currentUser.userId) {
        alert('Session expired. Please log in again.');
        return;
    }
    if (btn) {
        btn.disabled = true;
        btn.textContent = 'Approving...';
    }
    try {
        const response = await fetch(
            `${API_URL}/tasks/approve-work/${taskId}`,
            {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    approvedBy: currentUser.userId
                })
            }
        );
        const data = await response.json();
        if (data.success) {
            alert('Work approved! Admin will release payment shortly.');
            loadProviderTasks();
        } else {
            alert(data.message || 'Approval failed.');
        }
    } catch (error) {
        alert('Error: ' + error.message);
    } finally {
        if (btn) {
            btn.disabled = false;
            btn.textContent = 'Approve Work';
        }
    }
}
