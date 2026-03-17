async function approveWork(taskId, btn) { 
   if (!confirm('Approve this work?')) return; 
 
   if (btn) { 
     btn.disabled = true; 
     btn.textContent = 'Approving...'; 
   } 
 
   try { 
     const response = await fetch( 
       `${API_URL}/tasks/approve`, 
       { 
         method: 'POST', 
         headers: { 
           'Content-Type': 'application/json' 
         }, 
         body: JSON.stringify({ 
           taskId: taskId, 
           approvedBy: currentUser.userId 
         }) 
       } 
     ); 
 
     const data = await response.json(); 
     console.log('Approve response:', data); 
 
     if (data.success) { 
       alert('✅ Work approved! Admin will release payment shortly.'); 
       loadProviderTasks(); 
     } else { 
       alert('❌ ' + data.message); 
       if (btn) { 
         btn.disabled = false; 
         btn.textContent = 'Approve Work'; 
       } 
     } 
   } catch (error) { 
     alert('Error: ' + error.message); 
     if (btn) { 
       btn.disabled = false; 
       btn.textContent = 'Approve Work'; 
     } 
   } 
 } 


async function payEscrow(taskId, totalAmount) {
    try {
        const orderRes = await fetch(`${API_URL}/payments/razorpay/create-order`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                amount: totalAmount, 
                userId: currentUser.userId,
                currency: 'INR'
            })
        });
        const orderData = await orderRes.json();

        if (!orderRes.ok || !orderData.success) {
            alert(orderData.message || 'Failed to create payment order');
            return;
        }

        const options = {
            "key": "rzp_live_SSMM7fQBlGlwlq", // LIVE KEY
            "amount": orderData.order.amount,
            "currency": "INR",
            "name": "Microtask Platform",
            "description": "Task Escrow Payment",
            "order_id": orderData.order.id,
            "handler": async function (response) {
                try {
                    const verifyRes = await fetch(`${API_URL}/payments/razorpay/verify-escrow-payment`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            razorpay_order_id: response.razorpay_order_id,
                            razorpay_payment_id: response.razorpay_payment_id,
                            razorpay_signature: response.razorpay_signature,
                            taskId: taskId,
                            providerId: currentUser.userId,
                            amount: totalAmount
                        })
                    });
                    const verifyData = await verifyRes.json();
                    if (verifyData.success) {
                        alert('Task funded and published successfully! ✅');
                        loadProviderTasks();
                    } else {
                        alert('Payment verification failed: ' + verifyData.message);
                    }
                } catch (err) {
                    alert('Verification error: ' + err.message);
                }
            },
            "prefill": {
                "name": currentUser.name || "",
                "email": currentUser.email || ""
            },
            "theme": { "color": "#3b82f6" }
        };
        const rzp = new Razorpay(options);
        rzp.open();
    } catch (error) {
        alert('Payment error: ' + error.message);
    }
}
