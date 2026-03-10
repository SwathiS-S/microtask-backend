async function showWallet() {
    if (!currentUser) return;
    const walletView = document.getElementById('wallet-view');
    if (walletView) {
        walletView.classList.remove('hidden');
        await refreshUserWallet();
    }
}

async function refreshUserWallet() {
    if (!currentUser) return;
    try {
        const response = await fetch(`${API_URL}/wallet/balance/${currentUser.userId}`);
        const data = await response.json();
        if (data.success) {
            const balanceEl = document.getElementById('wallet-balance');
            if (balanceEl) {
                balanceEl.textContent = `₹${data.balance}`;
            }
        }
    } catch (error) {
        console.error('Error refreshing wallet balance:', error);
    }
}
