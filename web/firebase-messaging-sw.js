console.log("[firebase-messaging-sw.js] Service Worker script loading...");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAH8jdpuyZ7cs5LqvRAnbznPv9KDxWlYps",
  appId: "1:576075181196:web:9f43885806cdbe326fdfa9",
  messagingSenderId: "576075181196",
  projectId: "eventease-5def8",
  authDomain: "eventease-5def8.firebaseapp.com",
  storageBucket: "eventease-5def8.firebasestorage.app",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png",
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
