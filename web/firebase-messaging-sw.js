importScripts('https://www.gstatic.com/firebasejs/9.x.x/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.x.x/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyB4yCbd-an0B88lhqNmSVpFcNA5WCYxzBs",
  authDomain: "my-cha-t-app-b2rdwj.firebaseapp.com",
  projectId: "my-cha-t-app-b2rdwj",
  storageBucket: "my-cha-t-app-b2rdwj.firebasestorage.app",
  messagingSenderId: "581576107912",
  appId: "1:581576107912:web:87a95f468ba0c364023c3d"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icon.png', // Add your app icon path
    data: {
      chatId: payload.data?.chatId // Store chatId to use when notification is clicked
    }
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click events
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const chatId = event.notification.data?.chatId;
  
  if (chatId) {
    // Focus on existing window or open new one
    event.waitUntil(
      clients.matchAll({ type: 'window', includeUncontrolled: true })
        .then((clientList) => {
          for (const client of clientList) {
            if ('focus' in client) {
              client.focus();
              // Navigate to specific chat
              client.navigate(`/chat/${chatId}`);
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
