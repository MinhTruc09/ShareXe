importScripts('https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDHPaITZkBNPmusF6Its8-kvSdxZM3fKFw",
  authDomain: "sharexe-c2071.firebaseapp.com",
  projectId: "sharexe-c2071",
  storageBucket: "sharexe-c2071.firebasestorage.app",
  messagingSenderId: "581146190372",
  appId: "1:581146190372:web:4237d01dcc5ed7f12d6eb1"
});

const messaging = firebase.messaging(); 