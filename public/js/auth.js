async function login() {
    const email = document.getElementById('loginEmail').value;
    const password = document.getElementById('loginPassword').value;
    const msg = document.getElementById('loginMessage');
    
    if (!email || !password) {
        showMessage(msg, 'Please fill all fields', 'error');
        return;
    }

    try {
        const response = await fetch(`${API_URL}/users/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password, role: selectedRole })
        });
        const data = await response.json();

        if (response.ok && data.success) {
            currentUser = {
                userId: data.userId,
                email: data.email,
                name: data.name,
                role: data.role,
                wallet: data.wallet
            };
            localStorage.setItem('microtaskUser', JSON.stringify(currentUser));
            showDashboard();
        } else {
            showMessage(msg, data.message || 'Login failed', 'error');
        }
    } catch (error) {
        showMessage(msg, 'Connection error', 'error');
    }
}

async function register() {
    const name = document.getElementById('regName').value;
    const email = document.getElementById('regEmail').value;
    const password = document.getElementById('regPassword').value;
    const msg = document.getElementById('registerMessage');

    if (!name || !email || !password) {
        showMessage(msg, 'Please fill all fields', 'error');
        return;
    }

    try {
        const response = await fetch(`${API_URL}/users/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, email, password, role: selectedRole })
        });
        const data = await response.json();

        if (response.ok && data.success) {
            showMessage(msg, 'Registration successful! Please login.', 'success');
            setTimeout(toggleForms, 2000);
        } else {
            showMessage(msg, data.message || 'Registration failed', 'error');
        }
    } catch (error) {
        showMessage(msg, 'Connection error', 'error');
    }
}

function chooseRole(role) {
    selectedRole = role;
    document.getElementById('landingSection').classList.add('hidden');
    document.getElementById('authSection').classList.remove('hidden');
}

function toggleForms() {
    document.getElementById('loginForm').classList.toggle('hidden');
    document.getElementById('registerForm').classList.toggle('hidden');
}

function logout() {
    localStorage.removeItem('microtaskUser');
    location.reload();
}

function showDashboard() {
    document.getElementById('authSection').classList.add('hidden');
    document.getElementById('dashboardContainer').classList.remove('hidden');
    
    // UI adjustments based on role
    const isProvider = currentUser.role === 'taskProvider';
    document.getElementById('providerActionBtn').classList.toggle('hidden', !isProvider);
    document.getElementById('browse-section').classList.toggle('hidden', isProvider);
    document.getElementById('provider-section').classList.toggle('hidden', !isProvider);
    
    if (isProvider) {
        loadProviderTasks();
    } else {
        loadTasks();
    }
    refreshUserWallet();
}

function showMessage(el, text, type) {
    el.innerHTML = `<div class="message ${type}">${text}</div>`;
}

// Check for existing session
window.onload = () => {
    const savedUser = localStorage.getItem('microtaskUser');
    if (savedUser) {
        currentUser = JSON.parse(savedUser);
        showDashboard();
    }
};
