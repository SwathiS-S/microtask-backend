const express = require('express');
const path = require('path');
const app = express();

const PORT = 3000;

// Serve static files from build/web directory
app.use(express.static(path.join(__dirname, 'build/web')));

// Handle all other routes by serving index.html (for SPA)
app.use((req, res) => {
  res.sendFile(path.join(__dirname, 'build/web/index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n╔════════════════════════════════════════╗`);
  console.log(`║   TaskNest Flutter Web App Running     ║`);
  console.log(`╠════════════════════════════════════════╣`);
  console.log(`║  Local:    http://localhost:${PORT}         ║`);
  console.log(`║  Network:  http://<YOUR-PC-IP>:${PORT}      ║`);
  console.log(`╚════════════════════════════════════════╝\n`);
});
