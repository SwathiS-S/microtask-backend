const API_URL = 'https://microtask-backend-bc7z.onrender.com';
let adminUser = null;
function setAdmin(u) {
  adminUser = u;
  const s = document.getElementById('adminStatus');
  if (u && u.userId && u.role === 'admin') {
    s.textContent = u.email + ' (admin)';
    refreshMetrics();
    loadUsers(); loadTasks(); loadTransactions(); loadRevenue(); loadWithdrawals();
  } else {
    s.textContent = 'Not signed in';
    location.href = 'admin-login.html';
  }
}
function getAdminIdHeader() {
  return adminUser && adminUser.userId ? { 'x-admin-user-id': String(adminUser.userId) } : {};
}
function logoutAdmin() {
  localStorage.removeItem('adminUser');
  location.href = 'admin-login.html';
}
function loadPersisted() {
  const raw = localStorage.getItem('adminUser');
  if (raw) {
    try { setAdmin(JSON.parse(raw)); } catch (_) { location.href = 'admin-login.html'; }
  } else {
    location.href = 'admin-login.html';
  }
}
function switchSection(name) {
  const ids = ['overview','users','tasks','transactions','revenue','withdrawals'];
  ids.forEach(id => {
    document.getElementById('section-' + id).classList.toggle('active', id === name);
    document.getElementById('nav-' + id).classList.toggle('active', id === name);
  });
}
async function refreshMetrics() {
  try {
    const [users, tasks, wd] = await Promise.all([
      fetch(`${API_URL}/admin/users`, { headers: getAdminIdHeader() }).then(r => r.json()),
      fetch(`${API_URL}/admin/tasks`, { headers: getAdminIdHeader() }).then(r => r.json()),
      fetch(`${API_URL}/admin/withdrawals?status=PENDING`, { headers: getAdminIdHeader() }).then(r => r.json())
    ]);
    document.getElementById('metricUsers').textContent = (users.count ?? (users.users?.length ?? '–'));
    document.getElementById('metricTasks').textContent = (tasks.count ?? (tasks.tasks?.length ?? '–'));
    document.getElementById('metricWithdrawals').textContent = (wd.count ?? 0);
  } catch (_) {}
}
async function loadUsers() {
  const tbody = document.getElementById('usersTable');
  tbody.innerHTML = '<tr><td colspan="6">Loading...</td></tr>';
  try {
    const data = await fetch(`${API_URL}/admin/users`, { headers: getAdminIdHeader() }).then(r => r.json());
    const items = data.users || [];
    tbody.innerHTML = items.map(u => `
      <tr>
        <td>${u.name || '-'}</td>
        <td>${u.email || '-'}</td>
        <td>${u.role || '-'}</td>
        <td><span class="status ${u.status}">${u.status}</span></td>
        <td>₹ ${Number(u.wallet || 0).toFixed(2)}</td>
        <td>
          ${u.status === 'ACTIVE' ? `<button class="btn small danger" onclick="blockUser('${u._id}')">Block</button>` : `<button class="btn small success" onclick="activateUser('${u._id}')">Activate</button>`}
        </td>
      </tr>
    `).join('');
  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="6">${e.message}</td></tr>`;
  }
}
async function blockUser(id) {
  if (!confirm('Block this user?')) return;
  try {
    const r = await fetch(`${API_URL}/admin/users/${id}/block`, { method: 'POST', headers: { 'Content-Type': 'application/json', ...getAdminIdHeader() } });
    const d = await r.json();
    alert(d.message || (r.ok ? 'User blocked' : 'Failed'));
    loadUsers();
  } catch (e) { alert(e.message); }
}
async function activateUser(id) {
  if (!confirm('Activate this user?')) return;
  try {
    const r = await fetch(`${API_URL}/admin/users/${id}/activate`, { method: 'POST', headers: { 'Content-Type': 'application/json', ...getAdminIdHeader() } });
    const d = await r.json();
    alert(d.message || (r.ok ? 'User activated' : 'Failed'));
    loadUsers();
  } catch (e) { alert(e.message); }
}
async function loadTasks() {
  const tbody = document.getElementById('tasksTable');
  tbody.innerHTML = '<tr><td colspan="6">Loading...</td></tr>';
  try {
    const data = await fetch(`${API_URL}/admin/tasks`, { headers: getAdminIdHeader() }).then(r => r.json());
    const items = data.tasks || [];
    tbody.innerHTML = items.map(t => `
      <tr>
        <td>${t.title || '-'}</td>
        <td>₹ ${Number(t.amount || 0).toFixed(2)}</td>
        <td><span class="badge">${t.status}</span></td>
        <td>${t.postedBy ? (t.postedBy.email || t.postedBy.name || t.postedBy._id) : '-'}</td>
        <td>${t.acceptedBy ? (t.acceptedBy.email || t.acceptedBy.name || t.acceptedBy._id) : '-'}</td>
        <td><button class="btn small danger" onclick="removeTask('${t._id}')">Remove</button></td>
      </tr>
    `).join('');
  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="6">${e.message}</td></tr>`;
  }
}
async function removeTask(id) {
  if (!confirm('Remove this task?')) return;
  try {
    const r = await fetch(`${API_URL}/admin/tasks/${id}`, { method: 'DELETE', headers: getAdminIdHeader() });
    const d = await r.json();
    alert(d.message || (r.ok ? 'Task removed' : 'Failed'));
    loadTasks();
  } catch (e) { alert(e.message); }
}
async function loadTransactions() {
  const tbody = document.getElementById('txTable');
  tbody.innerHTML = '<tr><td colspan="5">Loading...</td></tr>';
  try {
    const data = await fetch(`${API_URL}/admin/transactions`, { headers: getAdminIdHeader() }).then(r => r.json());
    const items = data.transactions || [];
    tbody.innerHTML = items.map(x => `
      <tr>
        <td>${x.user_id ? (x.user_id.name || x.user_id.email || x.user_id) : '-'}</td>
        <td><span class="badge" style="background:${x.type==='COMMISSION'?'#fef3c7':x.type==='CREDIT'?'#dcfce7':'#fee2e2'};color:${x.type==='COMMISSION'?'#92400e':x.type==='CREDIT'?'#166534':'#991b1b'}">${x.type}</span></td>
        <td>₹ ${Number(x.amount || 0).toFixed(2)}</td>
        <td>${x.status}</td>
        <td>${new Date(x.created_at).toLocaleString()}</td>
      </tr>
    `).join('');
  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="5">${e.message}</td></tr>`;
  }
}
async function loadRevenue() {
  try {
    const data = await fetch(`${API_URL}/admin/analytics/revenue`, { headers: getAdminIdHeader() }).then(r => r.json());
    const inflow = data.revenue?.inflow?.total ?? 0;
    const outflow = data.revenue?.outflow?.total ?? 0;
    const commission = data.revenue?.commission?.total ?? 0;
    document.getElementById('inflowTotal').textContent = `₹ ${Number(inflow).toFixed(2)}`;
    document.getElementById('outflowTotal').textContent = `₹ ${Number(outflow).toFixed(2)}`;
    document.getElementById('commissionTotal').textContent = `₹ ${Number(commission).toFixed(2)}`;
  } catch (_) {}
}
async function loadWithdrawals() {
  const tbody = document.getElementById('wdTable');
  tbody.innerHTML = '<tr><td colspan="5">Loading...</td></tr>';
  try {
    const data = await fetch(`${API_URL}/admin/withdrawals?status=PENDING`, { headers: getAdminIdHeader() }).then(r => r.json());
    const items = data.withdrawals || [];
    tbody.innerHTML = items.map(w => `
      <tr>
        <td>${w.user_id ? (w.user_id.email || w.user_id.name || w.user_id._id) : '-'}</td>
        <td>₹ ${Number(w.amount || 0).toFixed(2)}</td>
        <td><span class="badge">${w.status}</span></td>
        <td>${new Date(w.created_at).toLocaleString()}</td>
        <td>
          <button class="btn small success" onclick="approveWithdrawal('${w._id}')">Approve</button>
          <button class="btn small danger" onclick="rejectWithdrawal('${w._id}')">Reject</button>
        </td>
      </tr>
    `).join('');
  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="5">${e.message}</td></tr>`;
  }
}
async function approveWithdrawal(id) {
  try {
    const r = await fetch(`${API_URL}/admin/withdrawals/${id}/approve`, { method: 'POST', headers: getAdminIdHeader() });
    const d = await r.json();
    alert(d.message || (r.ok ? 'Withdrawal approved' : 'Failed'));
    loadWithdrawals(); refreshMetrics();
  } catch (e) { alert(e.message); }
}
async function rejectWithdrawal(id) {
  try {
    const r = await fetch(`${API_URL}/admin/withdrawals/${id}/reject`, { method: 'POST', headers: getAdminIdHeader() });
    const d = await r.json();
    alert(d.message || (r.ok ? 'Withdrawal rejected' : 'Failed'));
    loadWithdrawals();
  } catch (e) { alert(e.message); }
}
loadPersisted();
