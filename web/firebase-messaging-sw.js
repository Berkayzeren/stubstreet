// firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing in
// your app's Firebase config object.
firebase.initializeApp({
  apiKey: "AIzaSyD8M9YVyNKxQvhGZOLkV_6Rl0I4gGpbOHE",
  authDomain: "device-streaming-70d2d53c.firebaseapp.com",
  projectId: "device-streaming-70d2d53c",
  storageBucket: "device-streaming-70d2d53c.appspot.com",
  messagingSenderId: "340648294228",
  appId: "1:340648294228:web:bf5525886eb610979fbac1"
});

// Retrieve an instance of Firebase Messaging so that it can handle background
// messages.
const messaging = firebase.messaging();
