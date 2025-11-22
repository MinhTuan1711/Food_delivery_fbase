/**
 * Firebase Cloud Functions - Notifications Module
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

// Initialize Admin only once per module
try {
  admin.app();
} catch (_) {
  admin.initializeApp();
}

/**
 * Cloud Function: Gửi FCM notification khi có notification mới trong Firestore
 *
 * Trigger: onCreate document trong collection 'notifications'
 */
exports.sendNotification = onDocumentCreated(
    {
      document: "notifications/{notificationId}",
      region: "us-central1",
    },
    async (event) => {
      const snap = event.data;
      const notificationId = event.params.notificationId;
      const notification = snap.data();

      console.log("New notification created:", notification);

      // Kiểm tra notification đã được gửi chưa
      if (notification.sent) {
        console.log("Notification already sent, skipping...");
        return null;
      }

      // Lấy FCM token của user từ Firestore
      let fcmToken = null;

      try {
        // Thử lấy từ collection fcm_tokens trước
        const tokenDoc = await admin.firestore()
            .collection("fcm_tokens")
            .doc(notification.userId)
            .get();

        if (tokenDoc.exists) {
          fcmToken = tokenDoc.data()?.token;
        }

        // Nếu không có, thử lấy từ user document
        if (!fcmToken) {
          const userDoc = await admin.firestore()
              .collection("users")
              .doc(notification.userId)
              .get();

          fcmToken = userDoc.data()?.fcmToken;
        }

        if (!fcmToken) {
          console.log("No FCM token found for user:", notification.userId);

          // Đánh dấu notification không thể gửi
          await snap.ref.update({
            sent: false,
            error: "No FCM token found",
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          return null;
        }

        console.log("Found FCM token for user:", notification.userId);
      } catch (error) {
        console.error("Error getting FCM token:", error);
        await snap.ref.update({
          sent: false,
          error: error.message,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return null;
      }

      // Tạo message payload cho FCM
      const message = {
        notification: {
          title: notification.title || "Thông báo đơn hàng",
          body: notification.body || "Đơn hàng của bạn đã được cập nhật",
        },
        data: {
          orderId: notification.data?.orderId || "",
          newStatus: notification.data?.newStatus || "",
          oldStatus: notification.data?.oldStatus || "",
          orderNumber: notification.data?.orderNumber || "",
          type: notification.type || "order_status_update",
          notificationId: notificationId,
        },
        token: fcmToken,
        android: {
          priority: "high",
          notification: {
            channelId: "order_updates",
            sound: "default",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      // Gửi notification
      try {
        const response = await admin.messaging().send(message);
        console.log("Successfully sent message:", response);

        // Đánh dấu notification đã được gửi thành công
        await snap.ref.update({
          sent: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          messageId: response,
        });

        return response;
      } catch (error) {
        console.error("Error sending message:", error);

        // Đánh dấu notification gửi thất bại
        await snap.ref.update({
          sent: false,
          error: error.message,
          errorCode: error.code,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return null;
      }
    });

/**
 * Cloud Function: Gửi notification trực tiếp (HTTP callable)
 */
exports.sendDirectNotification = onCall(
    async (request) => {
      const data = request.data;
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "User must be authenticated to send notifications",
        );
      }

      const {userId, title, body, data: notificationData} = data;

      if (!userId || !title || !body) {
        throw new HttpsError(
            "invalid-argument",
            "userId, title, and body are required",
        );
      }

      const userDoc = await admin.firestore()
          .collection("users")
          .doc(request.auth.uid)
          .get();

      const isAdmin = userDoc.data()?.isAdmin || false;
      if (!isAdmin) {
        throw new HttpsError(
            "permission-denied",
            "Only admins can send direct notifications",
        );
      }

      // Lấy FCM token của user nhận notification
      let fcmToken = null;
      try {
        const tokenDoc = await admin.firestore()
            .collection("fcm_tokens")
            .doc(userId)
            .get();

        if (tokenDoc.exists) {
          fcmToken = tokenDoc.data()?.token;
        }

        if (!fcmToken) {
          const targetUserDoc = await admin.firestore()
              .collection("users")
              .doc(userId)
              .get();

          fcmToken = targetUserDoc.data()?.fcmToken;
        }
      } catch (error) {
        throw new HttpsError(
            "internal",
            "Error getting FCM token",
            error,
        );
      }

      if (!fcmToken) {
        throw new HttpsError(
            "not-found",
            "FCM token not found for user",
        );
      }

      const message = {
        notification: {title, body},
        data: notificationData || {},
        token: fcmToken,
        android: {
          priority: "high",
          notification: {
            channelId: "order_updates",
            sound: "default",
          },
        },
      };

      try {
        const response = await admin.messaging().send(message);
        return {success: true, messageId: response};
      } catch (error) {
        throw new HttpsError(
            "internal",
            "Error sending notification",
            error,
        );
      }
    });

/**
 * Cloud Function: Gửi notification cho nhiều users (topic-based)
 */
exports.sendNotificationToTopic = onCall(
    async (request) => {
      const data = request.data;
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "User must be authenticated",
        );
      }

      const userDoc = await admin.firestore()
          .collection("users")
          .doc(request.auth.uid)
          .get();

      if (!userDoc.data()?.isAdmin) {
        throw new HttpsError(
            "permission-denied",
            "Only admins can send topic notifications",
        );
      }

      const {topic, title, body, data: notificationData} = data;

      if (!topic || !title || !body) {
        throw new HttpsError(
            "invalid-argument",
            "topic, title, and body are required",
        );
      }

      const message = {
        notification: {title, body},
        data: notificationData || {},
        topic: topic,
        android: {
          priority: "high",
        },
      };

      try {
        const response = await admin.messaging().send(message);
        return {success: true, messageId: response};
      } catch (error) {
        throw new HttpsError(
            "internal",
            "Error sending topic notification",
            error,
        );
      }
    });

/**
 * Scheduled Function: Gửi notification nhắc nhở (tùy chọn)
 */
exports.sendReminderNotifications = onSchedule(
    {schedule: "every 30 minutes", timeZone: "UTC"},
    async () => {
      const thirtyMinutesAgo = admin.firestore.Timestamp.fromDate(
          new Date(Date.now() - 30 * 60 * 1000),
      );

      // Tìm đơn hàng pending hơn 30 phút
      const pendingOrders = await admin.firestore()
          .collection("orders")
          .where("status", "==", "pending")
          .where("orderDate", "<=", thirtyMinutesAgo)
          .get();

      console.log(
          `Found ${pendingOrders.size} pending orders older than 30 minutes`,
      );

      // Gửi notification cho mỗi đơn hàng
      const promises = pendingOrders.docs.map(async (doc) => {
        const order = doc.data();

        await admin.firestore().collection("notifications").add({
          userId: order.userId,
          orderId: doc.id,
          type: "order_reminder",
          title: "Nhắc nhở đơn hàng",
          body: "Đơn hàng của bạn đang chờ xác nhận. " +
              "Vui lòng chờ trong giây lát.",
          data: {
            orderId: doc.id,
            type: "reminder",
          },
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await Promise.all(promises);
      console.log("Reminder notifications created");
      return null;
    });





















