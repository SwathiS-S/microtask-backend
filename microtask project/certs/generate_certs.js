const selfsigned = require('selfsigned');
const fs = require('fs');
const path = require('path');

const attrs = [{ name: 'commonName', value: 'localhost' }];
async function generate() {
    const pems = await selfsigned.generate(attrs, { days: 365 });
    const certDir = __dirname;
    fs.writeFileSync(path.join(certDir, 'key.pem'), pems.private);
    fs.writeFileSync(path.join(certDir, 'cert.pem'), pems.cert);
    console.log('Certificates generated successfully in certs/ folder');
}

generate();
