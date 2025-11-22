## Firebase Functions Deployment Guide (Notifications + Stripe)

### 1) Prerequisites
- Install Firebase CLI:

```bash
npm i -g firebase-tools
```

- Login:

```bash
firebase login
```

- Select project (or set default):

```bash
firebase use --add
```

- Upgrade Firebase Billing to Blaze (required for outbound HTTP calls to Stripe).

### 2) Project Structure (Functions)
- `functions/index.js`: Entrypoint, re-exports modules
- `functions/notifications.js`: FCM handlers
  - `sendNotification` (Firestore onCreate `notifications/{notificationId}`)
  - `sendDirectNotification` (HTTPS Callable)
  - `sendNotificationToTopic` (HTTPS Callable)
  - `sendReminderNotifications` (Scheduled, every 30 minutes)
- `functions/payments.js`: Stripe
  - `createPaymentIntent` (HTTPS onRequest, CORS enabled)

### 3) Install Dependencies (if needed)
Run inside `functions`:

```bash
cd functions
npm install
# Ensure stripe is present
npm install stripe --save
```

### 4) Configure Stripe Secret (Secure)
Run inside the project (root or `functions` is fine):

```bash
firebase functions:secrets:set STRIPE_SECRET_KEY
```

Paste your `sk_test_...` (or `sk_live_...`) when prompted.

Notes:
- Using Firebase Secrets with `defineSecret('STRIPE_SECRET_KEY')`.
- Do NOT commit any secret keys into source control.

### 5) Node Runtime
`functions/package.json` contains:

```json
{
  "engines": { "node": "22" }
}
```

If deployment warns about runtime, change to `"20"` and redeploy.

### 6) Deploy
From project root:

```bash
firebase deploy --only functions
```

The first deploy can take longer (enabling APIs, building gen2 functions).

### 7) Endpoints and Triggers
- Stripe HTTP endpoint (replace `<project-id>`):
  - `https://us-central1-<project-id>.cloudfunctions.net/createPaymentIntent`

- Callable functions (invoke via Firebase SDK):
  - `sendDirectNotification`
  - `sendNotificationToTopic`

- Firestore trigger:
  - `sendNotification`: fires when a document is created in `notifications/{notificationId}`

- Scheduler:
  - `sendReminderNotifications`: runs every 30 minutes (UTC)

### 8) Test Payment Intent (Local quick test)
PowerShell:

```powershell
$body = @{ amount = 100000; currency = "vnd" } | ConvertTo-Json
Invoke-RestMethod -Method Post `
  -Uri "https://us-central1-<project-id>.cloudfunctions.net/createPaymentIntent" `
  -ContentType "application/json" -Body $body
```

curl (CMD):

```bash
curl -X POST "https://us-central1-<project-id>.cloudfunctions.net/createPaymentIntent" ^
  -H "Content-Type: application/json" ^
  -d "{\"amount\":100000,\"currency\":\"vnd\"}"
```

Expected response:

```json
{ "clientSecret": "...", "paymentIntentId": "pi_..." }
```

Amount and currency:
- `vnd`: send integer VND (e.g., 100000 for 100k VND)
- `usd`/`eur`/`gbp`: send decimal (e.g., 10.5), backend converts to cents (`*100`)

### 9) Using from Flutter
- If previously calling your own backend/Cloud Run, change to Functions URL:
  - Update `_backendUrl` in your payment service (e.g., `lib/services/stripe_service.dart`) to the Functions URL above.
- POST JSON:

```json
{ "amount": 100000, "currency": "vnd" }
```

- Use the returned `clientSecret` with Stripe SDK to confirm payment.

### 10) Notifications (Flutter)
- Direct (admin only) via callable:
  - `sendDirectNotification` (checks `users/{uid}.isAdmin == true`)
- Topic via callable:
  - `sendNotificationToTopic` (admin only)
- Firestore-triggered:
  - Insert doc into `notifications`; `sendNotification` sends to the user’s FCM token.

### 11) Emulator (optional)
Run locally:

```bash
cd functions
npm run serve
```

Note:
- Stripe live calls from emulator require Blaze and Internet egress (still uses real Stripe with test key).

### 12) Troubleshooting
- 403 on callables: ensure user is authenticated and has `isAdmin` when required.
- 500 from Stripe: check Billing (Blaze), secret keyed, view Logs in Firebase Console.
- Amount mismatch:
  - `vnd` stays integer
  - `usd/eur/gbp` multiply by 100 in backend

---

This repo already includes:
- `functions/index.js` re-export modules (`notifications`, `payments`)
- Proper Stripe secret handling with `defineSecret`
- CORS enabled for `createPaymentIntent`

You’re ready to deploy with `firebase deploy --only functions`.




















