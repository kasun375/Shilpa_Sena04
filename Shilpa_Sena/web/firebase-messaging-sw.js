importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAUWxwHs6Q3Ei_fNeOAV8ktqqVRgngOYVI",
  authDomain: "exim-graphics-lms.firebaseapp.com",
  projectId: "exim-graphics-lms",
  storageBucket: "exim-graphics-lms.firebasestorage.app",
  messagingSenderId: "54375527170",
  appId: "1:54375527170:web:80b8dff8c3a1e01c0c881b",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("Received background message ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/favicon.png",
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
