importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBAV-JjIMXSTSQWHZKDXnWgaVznV6107I4',
  authDomain: 'desperdicio-zero-f55d6.firebaseapp.com',
  projectId: 'desperdicio-zero-f55d6',
  storageBucket: 'desperdicio-zero-f55d6.firebasestorage.app',
  messagingSenderId: '620910670834',
  appId: '1:620910670834:web:8072682ffdbc8ae30ff16b',
  measurementId: 'G-670GB4X0BV'
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  const notificationTitle = payload.notification?.title || 'Nova notificação';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    data: payload.data || {}
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
