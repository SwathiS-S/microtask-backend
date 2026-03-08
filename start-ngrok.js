const ngrok = require('@ngrok/ngrok');
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

// Load environment variables from .env
dotenv.config();

async function setup() {
  try {
    const port = 5000;
    const authtoken = process.env.NGROK_AUTHTOKEN;

    if (!authtoken) {
      console.error('NGROK_AUTHTOKEN is missing in .env');
      process.exit(1);
    }

    console.log(`Starting ngrok on port ${port}...`);

    // Using the official @ngrok/ngrok library
    const listener = await ngrok.forward({
      addr: port,
      authtoken: authtoken,
    });

    const url = listener.url();
    console.log(`Ngrok tunnel established: ${url}`);

    // Update backend .env
    const envPath = path.join(__dirname, '.env');
    let envContent = '';
    if (fs.existsSync(envPath)) {
      envContent = fs.readFileSync(envPath, 'utf8');
    }
    const envConfig = dotenv.parse(envContent);
    envConfig.BASE_URL = url;
    
    const newEnvContent = Object.entries(envConfig)
      .map(([key, value]) => `${key}=${value}`)
      .join('\n');
    
    fs.writeFileSync(envPath, newEnvContent);
    console.log('Updated backend .env with BASE_URL');

    // Update Flutter config.dart
    const flutterConfigPath = path.join(__dirname, '..', 'microtask-frontend', 'lib', 'config.dart');
    if (fs.existsSync(flutterConfigPath)) {
      const configContent = `class Config {\n  static const String baseUrl = "${url}";\n}\n`;
      fs.writeFileSync(flutterConfigPath, configContent);
      console.log('Updated Flutter config.dart with baseUrl');
    } else {
      console.warn('Flutter config.dart not found at', flutterConfigPath);
    }

    console.log('\n--- SETUP COMPLETE ---');
    console.log(`Backend Base URL: ${url}`);
    console.log('You can now start your backend and Flutter app.');
    console.log('--- KEEP THIS TERMINAL OPEN ---');
    console.log('The ngrok tunnel will stay active as long as this process is running.');

    // Keep the process alive
    process.stdin.resume();

    // Handle termination signals to close the tunnel gracefully
    process.on('SIGINT', async () => {
      console.log('\nClosing ngrok tunnel...');
      process.exit(0);
    });

  } catch (err) {
    console.error('Error starting ngrok:', err);
    process.exit(1);
  }
}

setup();
