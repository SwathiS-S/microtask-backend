function chooseRole(role) {
    selectedRole = role === 'taskProvider' ? 'taskProvider' : 'taskUser';
    const landing = document.getElementById('landingSection');
    const auth = document.getElementById('authSection');
    if (landing) landing.classList.add('hidden');
    if (auth) auth.classList.remove('hidden');
    const logoText = document.querySelector('#loginForm .logo p');
    if (logoText) {
        logoText.textContent = selectedRole === 'taskProvider'
            ? 'Post tasks and review submissions'
            : 'Find tasks and earn rewards';
    }
    const regLogoText = document.querySelector('#registerForm .logo p');
    if (regLogoText) {
        regLogoText.textContent = selectedRole === 'taskProvider'
            ? 'Create an account to post tasks'
            : 'Create an account to find tasks';
    }
}

function toggleForms() {
    document.getElementById('loginForm').classList.toggle('hidden');
    document.getElementById('registerForm').classList.toggle('hidden');
    document.getElementById('loginMessage').innerHTML = '';
    document.getElementById('registerMessage').innerHTML = '';
}
