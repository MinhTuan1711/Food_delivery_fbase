## Hướng Dẫn Triển Khai Firebase Functions (Thông báo + Stripe)

### 1) Điều kiện tiên quyết
- Cài đặt Firebase CLI:

```bash
npm i -g firebase-tools
```

- Đăng nhập:

```bash
firebase login
```

- Chọn project (hoặc đặt mặc định):

```bash
firebase use --add
```

- Nâng cấp gói thanh toán Firebase lên Blaze (bắt buộc để gọi HTTP ra ngoài tới Stripe).

### 2) Cấu trúc dự án (Functions)
- `functions/index.js`: Điểm vào, re-export các module
- `functions/notifications.js`: Xử lý FCM
  - `sendNotification` (Firestore onCreate `notifications/{notificationId}`)
  - `sendDirectNotification` (HTTPS Callable)
  - `sendNotificationToTopic` (HTTPS Callable)
  - `sendReminderNotifications` (Lịch, mỗi 30 phút)
- `functions/payments.js`: Stripe
  - `createPaymentIntent` (HTTPS onRequest, bật CORS)

### 3) Cài đặt phụ thuộc (nếu cần)
Chạy bên trong thư mục `functions`:

```bash
cd functions
npm install
# Ensure stripe is present
npm install stripe --save
```

### 4) Cấu hình Secret Stripe (Bảo mật)
Chạy trong dự án (thư mục gốc hoặc `functions` đều được):

```bash
firebase functions:secrets:set STRIPE_SECRET_KEY
```

Khi được hỏi, dán khóa bí mật `sk_test_...` (hoặc `sk_live_...`).

Ghi chú:
- Sử dụng Firebase Secrets với `defineSecret('STRIPE_SECRET_KEY')`.
- Không commit bất kỳ khóa bí mật nào vào source control.

### 5) Phiên bản Node Runtime
Trong `functions/package.json` có:

```json
{
  "engines": { "node": "22" }
}
```

Nếu khi deploy có cảnh báo runtime, đổi về `"20"` rồi deploy lại.

### 6) Triển khai (Deploy)
Từ thư mục gốc dự án:

```bash
firebase deploy --only functions
```

Lần deploy đầu có thể lâu hơn (bật API, dựng functions gen2).

### 7) Endpoint và Trigger
- Endpoint HTTP Stripe (thay `<project-id>`):
  - `https://us-central1-<project-id>.cloudfunctions.net/createPaymentIntent`

- Các hàm Callable (gọi qua Firebase SDK):
  - `sendDirectNotification`
  - `sendNotificationToTopic`

- Trigger Firestore:
  - `sendNotification`: kích hoạt khi tạo document trong `notifications/{notificationId}`

- Lịch (Scheduler):
  - `sendReminderNotifications`: chạy mỗi 30 phút (UTC)

### 8) Test Payment Intent (test nhanh cục bộ)
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

Kết quả mong đợi:

```json
{ "clientSecret": "...", "paymentIntentId": "pi_..." }
```

Số tiền và đơn vị tiền tệ:
- `vnd`: gửi số nguyên theo VND (ví dụ 100000 cho 100k VND)
- `usd`/`eur`/`gbp`: có thể gửi số thập phân (vd 10.5), backend sẽ nhân 100 thành cent (`*100`)

### 9) Sử dụng từ Flutter
- Nếu trước đây gọi backend riêng/Cloud Run, chuyển sang URL của Functions:
  - Cập nhật `_backendUrl` trong service thanh toán (vd `lib/services/stripe_service.dart`) thành URL Functions phía trên.
- Gửi POST JSON:

```json
{ "amount": 100000, "currency": "vnd" }
```

- Dùng `clientSecret` trả về với Stripe SDK để xác nhận thanh toán.

### 10) Thông báo (Flutter)
- Trực tiếp (chỉ admin) qua callable:
  - `sendDirectNotification` (kiểm tra `users/{uid}.isAdmin == true`)
- Theo chủ đề (topic) qua callable:
  - `sendNotificationToTopic` (chỉ admin)
- Kích hoạt qua Firestore:
  - Thêm document vào `notifications`; `sendNotification` sẽ gửi tới FCM token của người dùng.

### 11) Emulator (tùy chọn)
Chạy cục bộ:

```bash
cd functions
npm run serve
```

Lưu ý:
- Gọi Stripe thật từ emulator vẫn cần gói Blaze và Internet egress (dùng Stripe với test key).

### 12) Khắc phục sự cố
- 403 khi gọi callable: đảm bảo người dùng đã đăng nhập và có `isAdmin` khi cần.
- 500 từ Stripe: kiểm tra Billing (Blaze), khóa bí mật, xem Logs trong Firebase Console.
- Sai lệch số tiền:
  - `vnd` luôn là số nguyên
  - `usd/eur/gbp` được backend nhân 100

---

Repo này đã bao gồm:
- `functions/index.js` re-export module (`notifications`, `payments`)
- Xử lý Stripe secret đúng chuẩn với `defineSecret`
- Đã bật CORS cho `createPaymentIntent`

Bạn đã sẵn sàng deploy với `firebase deploy --only functions`.




















