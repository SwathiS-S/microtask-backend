const express = require('express');
const path = require('path');
const http = require('http');
const fs = require('fs');
const app = express();

const PORT = 3000;

// Security headers (Removed HSTS for HTTP)
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  next();
});

app.use(express.static(path.join(__dirname)));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Web frontend running on http://localhost:${PORT}`);
});
