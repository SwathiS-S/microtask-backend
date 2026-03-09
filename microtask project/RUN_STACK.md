# Running TaskNest (Frontend + Backend)

The **microtask-web** frontend is connected to the **microtask-backend** API.

## Prerequisites

- **Node.js** installed
- **MongoDB** running locally (e.g. `mongodb://127.0.0.1:27017`)

## 1. Start the backend

```bash
cd microtask-backend
npm install
node server.js
```

Backend runs at **https://localhost:5000**.

## 1.1 Expose to Public (for Razorpay Dashboard)
If you are configuring **Webhooks** or **Redirect URLs** in the Razorpay dashboard, you must use a public URL.

1.  **Download ngrok**: [ngrok.com](https://ngrok.com/)
2.  **Start tunnel**: Run `ngrok http 5000`
3.  **Copy public URL**: Use the provided `https://xxxx.ngrok-free.app` URL in the Razorpay Dashboard.
4.  **Update code**: Update `API_URL` in `microtask-web/index.html` and `lib/services/api_service.dart` with this URL.

## 2. Start the frontend

In a **second terminal**:

```bash
cd microtask-web
npm install
node server.js
```

Frontend runs at **https://localhost:3000**.

## 3. Use the app

1. Open **https://localhost:3000** in your browser.
2. **Register** (Worker or Business Owner), then **Login**.
3. **Tasks**: Create tasks (Business), accept and complete them (Worker). Wallet updates when a task is completed.

## API connection

- Frontend uses `API_URL = 'https://localhost:5000'` in `microtask-web/index.html`.
- Backend has CORS enabled so the browser can call it from port 3000.
- Endpoints used: `/users/register`, `/auth/login` (or `/users/login`), `/tasks/all`, `/tasks/create`, `/tasks/accept`, `/tasks/complete`, `/users/:id` (wallet refresh).
