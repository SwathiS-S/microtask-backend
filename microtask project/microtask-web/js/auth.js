function chooseRole(role) {
    selectedRole = role === 'taskProvider' ? 'taskProvider' : 'taskUser';
    const landing = document.getElementById('landingSection');
    const auth = document.getElementById('authSection');
    if (landing) landing.classList.add('hidden');
    if (auth) auth.classList.remove('hidden');
    
    // Update labels based on role if elements exist
    const loginTitle = document.querySelector('#loginForm h1');
    if (loginTitle) {
        loginTitle.innerHTML = `Task <span style="color: #3b82f6;">Nest</span>`;
    }
    const regTitle = document.querySelector('#registerForm h1');
    if (regTitle) {
        regTitle.innerHTML = `Task <span style="color: #3b82f6;">Nest</span>`;
    }
}

function toggleForms() {
    document.getElementById('loginForm').classList.toggle('hidden');
    document.getElementById('registerForm').classList.toggle('hidden');
    document.getElementById('loginMessage').innerHTML = '';
    document.getElementById('registerMessage').innerHTML = '';
}

async function handleLogin() {
    const email = document.getElementById('loginEmail').value;
    const password = document.getElementById('loginPassword').value;
    const messageDiv = document.getElementById('loginMessage');
    
    if (!email || !password) {
        messageDiv.innerHTML = '<p style="color: red;">Please enter email and password</p>';
        return;
    }

    try {
        const response = await fetch(`${API_URL}/users/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });

        const data = await response.json();

        if (response.ok && data.success) {
            localStorage.setItem('currentUser', JSON.stringify({
                userId: data.userId,
                email: data.email,
                name: data.name,
                role: data.role,
                wallet: data.wallet != null ? data.wallet : 0
            }));
            window.location.reload(); // Reload to trigger window.onload logic
        } else {
            messageDiv.innerHTML = `<p style="color: red;">${data.message || 'Login failed'}</p>`;
        }
    } catch (error) {
        console.error('Login error:', error);
        messageDiv.innerHTML = '<p style="color: red;">Network error. Please try again.</p>';
    }
}

async function handleRegister() {
    const name = document.getElementById('regName').value;
    const email = document.getElementById('regEmail').value;
    const password = document.getElementById('regPassword').value;
    const messageDiv = document.getElementById('registerMessage');

    if (!name || !email || !password) {
        messageDiv.innerHTML = '<p style="color: red;">Please fill all fields</p>';
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
            messageDiv.innerHTML = '<p style="color: green;">Registration successful! Redirecting to login...</p>';
            setTimeout(() => {
                toggleForms();
            }, 2000);
        } else {
            messageDiv.innerHTML = `<p style="color: red;">${data.message || 'Registration failed'}</p>`;
        }
    } catch (error) {
        console.error('Registration error:', error);
        messageDiv.innerHTML = '<p style="color: red;">Network error. Please try again.</p>';
    }
}
