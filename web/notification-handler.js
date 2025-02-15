import { getMessaging, onMessage, getToken } from 'firebase/messaging';
import { initializeApp } from 'firebase/app';
import { firebaseConfig } from './firebase-config';

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const messaging = getMessaging(app);

// Request permission and get FCM token
export const requestNotificationPermission = async () => {
  try {
    const permission = await Notification.requestPermission();
    if (permission === 'granted') {
      const token = await getToken(messaging, {
        vapidKey: 'YOUR_VAPID_KEY' // Replace with your VAPID key
      });
      return token;
    }
  } catch (error) {
    console.error('Error requesting notification permission:', error);
  }
};

// Handle foreground messages
export const onForegroundMessage = (callback) => {
  return onMessage(messaging, (payload) => {
    callback(payload);
  });
};

// Handle notification click
export const setupNotificationClickHandler = () => {
  // Handle notification click when app is in background
  self.addEventListener('notificationclick', (event) => {
    event.notification.close();
    const chatId = event.notification.data?.chatId;
    
    if (chatId) {
      // Focus on existing window or open new one
      event.waitUntil(
        clients.matchAll({ type: 'window', includeUncontrolled: true })
          .then((clientList) => {
            for (const client of clientList) {
              if (client.url.includes('/chat') && 'focus' in client) {
                client.focus();
                // Navigate to specific chat
                client.postMessage({ type: 'NAVIGATE_TO_CHAT', chatId });
                return;
              }
            }
            // If no existing window, open new one
            if (clients.openWindow) {
              clients.openWindow(`/chat/${chatId}`);
            }
          })
      );
    }
  });
};

// Register service worker for background notifications
export const registerServiceWorker = async () => {
  if ('serviceWorker' in navigator) {
    try {
      const registration = await navigator.serviceWorker.register('/firebase-messaging-sw.js');
      console.log('Service Worker registered successfully:', registration);
    } catch (error) {
      console.error('Service Worker registration failed:', error);
    }
  }
};
