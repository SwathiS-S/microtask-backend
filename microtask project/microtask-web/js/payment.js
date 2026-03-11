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
       alert('Error: ' + data.message); 
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

