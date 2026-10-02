// ============================================================
// SHILPA SENA LMS - Web App Script
// Mirrors Flutter app logic (GoRouter, Providers, Firestore)
// ============================================================

// --- Firebase Configuration (from firebase_options.dart) ---
const firebaseConfig = {
  apiKey: "AIzaSyAUWxwHs6Q3Ei_fNeOAV8ktqqVRgngOYVI",
  authDomain: "exim-graphics-lms.firebaseapp.com",
  projectId: "exim-graphics-lms",
  storageBucket: "exim-graphics-lms.firebasestorage.app",
  messagingSenderId: "54375527170",
  appId: "1:54375527170:web:80b8dff8c3a1e01c0c881b",
  measurementId: "G-9CD61L58XS"
};

// Initialize Firebase safely
let app, auth, db, storage;
try {
  if (typeof firebase !== 'undefined') {
    app = firebase.initializeApp(firebaseConfig);
    auth = typeof firebase.auth === 'function' ? firebase.auth() : null;
    db = typeof firebase.firestore === 'function' ? firebase.firestore() : null;
    storage = typeof firebase.storage === 'function' ? firebase.storage() : null;
  } else {
    console.warn("Firebase SDK not detected. App will run in offline mode.");
  }
} catch (e) {
  console.error("Firebase initialization failed:", e);
}

// --- Global State ---
let currentUser = null;
let currentRole = 'student';
let courses = [];
let myCourses = [];
let promos = [
  "assets/images/promo_banner_1.png",
  "assets/images/promo_banner_2.png"
];
let recordings = [];
let studyPacks = [];
let announcements = [];
let systemAlerts = [];
let enrollmentsMap = {}; // courseId -> status ("purchased", "pending")
let hasApprovedEnrollment = false;

// Admin Dashboard state
let enrollmentRequests = [];
let registeredUsers = [];
let activeAdminTab = 'banners'; // default tab
let activeNotificationsTab = 'alerts'; // default tab

// Firebase listener references
let coursesUnsubscribe = null;
let promosUnsubscribe = null;
let recordingsUnsubscribe = null;
let studyPacksUnsubscribe = null;
let announcementsUnsubscribe = null;
let enrollmentsUnsubscribe = null;
let adminEnrollmentsUnsubscribe = null;
let adminUsersUnsubscribe = null;

// --- DOM Elements ---
const topNav = document.getElementById('top-nav');
const appContent = document.getElementById('app-content');
const loginNavBtn = document.getElementById('login-nav-btn');
const userMenu = document.getElementById('user-menu');
const userAvatar = document.getElementById('user-avatar');
const adminNavItem = document.getElementById('admin-nav-item');
const authOverlay = document.getElementById('auth-overlay');
const loginForm = document.getElementById('login-form');
const signupForm = document.getElementById('signup-form');
const authSubtitle = document.getElementById('auth-subtitle');
const authError = document.getElementById('auth-error');
const authLoading = document.getElementById('auth-loading');
const toastEl = document.getElementById('toast');
const notifBadge = document.getElementById('notif-badge');
const hamburgerBtn = document.getElementById('hamburger-btn');
const navLinks = document.getElementById('nav-links');

// --- Initialization ---
document.addEventListener('DOMContentLoaded', () => {
  setupMobieMenu();
  loadSystemAlerts();
  initRouter();
  initFirebaseListeners();
  subscribeGlobalListeners(); // Fetch courses and promos immediately on startup
});

// --- System Alerts Storage & State ---
function loadSystemAlerts() {
  try {
    const data = localStorage.getItem('saved_notifications');
    systemAlerts = data ? JSON.parse(data) : [];
    // Ensure timestamps are date objects
    systemAlerts.forEach(alert => {
      alert.timestamp = new Date(alert.timestamp);
    });
  } catch (e) {
    console.error("Error loading system alerts:", e);
    systemAlerts = [];
  }
  updateNotifBadge();
}

function saveSystemAlerts() {
  try {
    localStorage.setItem('saved_notifications', JSON.stringify(systemAlerts));
  } catch (e) {
    console.error("Error saving system alerts:", e);
  }
  updateNotifBadge();
}

function updateNotifBadge() {
  const unreadCount = systemAlerts.filter(a => !a.isRead).length;
  const badge = document.getElementById('notif-badge');
  if (badge) {
    if (unreadCount > 0) {
      badge.innerText = unreadCount;
      badge.style.display = 'flex';
    } else {
      badge.style.display = 'none';
    }
  }
}

function addSystemAlert(title, body) {
  const alert = {
    id: Date.now().toString(),
    title: title,
    body: body,
    timestamp: new Date(),
    isRead: false
  };
  systemAlerts.unshift(alert);
  saveSystemAlerts();
  
  // Show toast notification
  showToast(`Notification: ${title}`);
  
  // If we are on the notifications screen, re-render it
  if (window.location.hash === '#notifications') {
    renderNotifications();
  }
}

// --- Mobile Navigation ---
function setupMobieMenu() {
  hamburgerBtn.addEventListener('click', () => {
    navLinks.classList.toggle('open');
  });
  
  // Close menu when a link is clicked
  navLinks.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
      navLinks.classList.remove('open');
    });
  });
}

// --- Firebase Listeners ---
function initFirebaseListeners() {
  if (!auth) {
    console.warn("Auth is unavailable.");
    const hash = window.location.hash || '#home';
    renderPage(hash);
    return;
  }
  // 1. Auth Listener
  auth.onAuthStateChanged(async (user) => {
    currentUser = user;
    if (user) {
      // User is signed in
      loginNavBtn.style.display = 'none';
      userMenu.style.display = 'flex';
      
      // Setup Avatar
      const photoURL = user.photoURL;
      if (photoURL) {
        userAvatar.innerHTML = `<img src="${photoURL}" alt="Profile">`;
      } else {
        userAvatar.innerHTML = `<span class="material-icons">person</span>`;
      }

      // Fetch user role
      try {
        const userDoc = await db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          currentRole = userDoc.data().role || 'student';
        }
      } catch(e) { console.error("Error fetching role:", e); }

      // Check admin
      if (user.email === 'admin@eximgraphics.com' || currentRole === 'admin') {
        adminNavItem.style.display = 'block';
        hasApprovedEnrollment = true; // Admins have access to everything
        subscribeAdminListeners(); // Listen to students list and requests
      } else {
        adminNavItem.style.display = 'none';
      }

      // Hide auth modal if open
      hideAuthModal();
      
      // Subscribe to user specific collections (global is subscribed once on startup)
      listenToMyEnrollments(user.uid);
      
    } else {
      // User is signed out
      loginNavBtn.style.display = 'block';
      userMenu.style.display = 'none';
      adminNavItem.style.display = 'none';
      currentRole = 'student';
      myCourses = [];
      enrollmentsMap = {};
      hasApprovedEnrollment = false;
      
      // Clean up user-specific enrollment listeners only
      if (enrollmentsUnsubscribe) {
        enrollmentsUnsubscribe();
        enrollmentsUnsubscribe = null;
      }
      
      // Re-render
      const hash = window.location.hash || '#home';
      renderPage(hash);
    }
  });

  document.getElementById('logout-btn').addEventListener('click', () => {
    auth.signOut().then(() => {
      showToast("Logged out successfully");
      window.location.hash = '#home';
    });
  });
}

function subscribeGlobalListeners() {
  if (!db) {
    console.warn("Firestore db is unavailable.");
    const hash = window.location.hash || '#home';
    renderPage(hash);
    return;
  }
  // Clean up any existing listeners before resubscribing
  unsubscribeGlobalListeners();

  // 1. Courses Listener
  coursesUnsubscribe = db.collection('courses').onSnapshot(snapshot => {
    courses = [];
    snapshot.forEach(doc => {
      courses.push({ id: doc.id, ...doc.data() });
    });
    updateMyCoursesList();
    if (['#courses', '#home', '#admin'].includes(window.location.hash)) {
      renderPage(window.location.hash);
    }
  }, error => {
    console.error("Error listening to courses:", error);
    courses = [];
    if (['#courses', '#home'].includes(window.location.hash)) {
      renderPage(window.location.hash);
    }
  });

  // 2. Promos Listener
  promosUnsubscribe = db.collection('promos').onSnapshot(snapshot => {
    let freshPromos = [];
    snapshot.forEach(doc => freshPromos.push(doc.data().url));
    if (freshPromos.length > 0) {
      promos = freshPromos;
    } else {
      promos = [
        "assets/images/promo_banner_1.png",
        "assets/images/promo_banner_2.png"
      ];
    }
    if (['#home', '#admin'].includes(window.location.hash)) {
      renderPage(window.location.hash);
    }
  }, error => {
    console.error("Error listening to promos:", error);
    promos = [
      "assets/images/promo_banner_1.png",
      "assets/images/promo_banner_2.png"
    ];
    if (window.location.hash === '#home') {
      renderPage('#home');
    }
  });

  // 3. Recordings Listener
  recordingsUnsubscribe = db.collection('recordings').orderBy('uploadedAt', 'desc').onSnapshot(snapshot => {
    recordings = [];
    snapshot.forEach(doc => {
      let data = doc.data();
      let dateStr = "Unknown date";
      if (data.uploadedAt && data.uploadedAt.toDate) {
        dateStr = data.uploadedAt.toDate().toISOString().split('T')[0];
      }
      recordings.push({ id: doc.id, dateStr: dateStr, ...data });
    });
    if (window.location.hash === '#recordings') renderPage('#recordings');
  }, error => {
    console.error("Error listening to recordings:", error);
  });

  // 4. Study Packs Listener
  studyPacksUnsubscribe = db.collection('studypacks').orderBy('createdAt', 'desc').onSnapshot(snapshot => {
    studyPacks = [];
    snapshot.forEach(doc => studyPacks.push({ id: doc.id, ...doc.data() }));
    if (window.location.hash === '#studypacks') renderPage('#studypacks');
  }, error => {
    console.error("Error listening to studypacks:", error);
  });

  // 5. Announcements Listener
  announcementsUnsubscribe = db.collection('announcements').orderBy('timestamp', 'desc').onSnapshot(snapshot => {
    announcements = [];
    snapshot.forEach(doc => {
      let data = doc.data();
      let date = data.timestamp ? (data.timestamp.toDate ? data.timestamp.toDate() : new Date(data.timestamp)) : new Date();
      announcements.push({ id: doc.id, timestamp: date, ...data });
    });
    if (window.location.hash === '#notifications') renderPage('#notifications');
    if (window.location.hash === '#admin') renderPage('#admin');
  }, error => {
    console.error("Error listening to announcements:", error);
  });
}

function unsubscribeGlobalListeners() {
  if (coursesUnsubscribe) { coursesUnsubscribe(); coursesUnsubscribe = null; }
  if (promosUnsubscribe) { promosUnsubscribe(); promosUnsubscribe = null; }
  if (recordingsUnsubscribe) { recordingsUnsubscribe(); recordingsUnsubscribe = null; }
  if (studyPacksUnsubscribe) { studyPacksUnsubscribe(); studyPacksUnsubscribe = null; }
  if (announcementsUnsubscribe) { announcementsUnsubscribe(); announcementsUnsubscribe = null; }
  if (adminEnrollmentsUnsubscribe) { adminEnrollmentsUnsubscribe(); adminEnrollmentsUnsubscribe = null; }
  if (adminUsersUnsubscribe) { adminUsersUnsubscribe(); adminUsersUnsubscribe = null; }
}

function subscribeAdminListeners() {
  // Clean up any existing admin listeners
  if (adminEnrollmentsUnsubscribe) adminEnrollmentsUnsubscribe();
  if (adminUsersUnsubscribe) adminUsersUnsubscribe();

  // 1. Listen to all enrollment requests (collectionGroup)
  adminEnrollmentsUnsubscribe = db.collectionGroup('enrollments').onSnapshot(snapshot => {
    enrollmentRequests = [];
    snapshot.forEach(doc => {
      enrollmentRequests.push({ id: doc.id, refPath: doc.ref.path, ...doc.data() });
    });
    // Sort by requestedAt desc
    enrollmentRequests.sort((a, b) => {
      const t1 = a.requestedAt ? (a.requestedAt.toDate ? a.requestedAt.toDate() : new Date(a.requestedAt)) : 0;
      const t2 = b.requestedAt ? (b.requestedAt.toDate ? b.requestedAt.toDate() : new Date(b.requestedAt)) : 0;
      return t2 - t1;
    });
    if (window.location.hash === '#admin') renderPage('#admin');
  }, error => {
    console.error("Error listening to admin enrollments:", error);
  });

  // 2. Listen to all registered users
  adminUsersUnsubscribe = db.collection('users').onSnapshot(snapshot => {
    registeredUsers = [];
    snapshot.forEach(doc => {
      registeredUsers.push({ id: doc.id, ...doc.data() });
    });
    if (window.location.hash === '#admin') renderPage('#admin');
  }, error => {
    console.error("Error listening to registered users:", error);
  });
}

function listenToMyEnrollments(uid) {
  if (enrollmentsUnsubscribe) {
    enrollmentsUnsubscribe();
    enrollmentsUnsubscribe = null;
  }
  enrollmentsUnsubscribe = db.collection('users').doc(uid).collection('enrollments').onSnapshot(snapshot => {
    const oldMap = { ...enrollmentsMap };
    enrollmentsMap = {};
    let foundApproved = false;
    
    snapshot.forEach(doc => {
      const data = doc.data();
      const courseId = doc.id;
      const status = data.status || 'pending';
      enrollmentsMap[courseId] = status;
      if (status === 'purchased') foundApproved = true;
      
      // Only trigger notification if we already had elements in oldMap (it's a real-time update, not initial load)
      if (Object.keys(oldMap).length > 0 && oldMap[courseId] && oldMap[courseId] !== status) {
        if (status === 'purchased') {
          addSystemAlert("Access Approved", `Your access request for "${data.courseTitle || 'Course'}" has been approved!`);
        } else if (status === 'rejected') {
          addSystemAlert("Access Rejected", `Your access request for "${data.courseTitle || 'Course'}" was rejected.`);
        }
      }
    });
    
    if (currentUser?.email === 'admin@eximgraphics.com' || currentRole === 'admin') {
      hasApprovedEnrollment = true;
    } else {
      hasApprovedEnrollment = foundApproved;
    }
    
    updateMyCoursesList();
    const hash = window.location.hash || '#home';
    renderPage(hash);
  }, error => {
    console.error("Error listening to enrollments:", error);
  });
}

function updateMyCoursesList() {
  myCourses = courses.filter(c => enrollmentsMap[c.id] === 'purchased');
}


// --- Auth Modal Logic ---
function showAuthModal(mode) {
  authOverlay.style.display = 'flex';
  switchAuthMode(mode);
}

function hideAuthModal() {
  authOverlay.style.display = 'none';
  loginForm.reset();
  signupForm.reset();
  authError.style.display = 'none';
}

function switchAuthMode(mode) {
  authError.style.display = 'none';
  if (mode === 'login') {
    loginForm.style.display = 'flex';
    signupForm.style.display = 'none';
    authSubtitle.innerText = 'Login to continue your learning journey';
  } else {
    loginForm.style.display = 'none';
    signupForm.style.display = 'flex';
    authSubtitle.innerText = 'Create an account to get started';
  }
}

async function handleLogin(e) {
  e.preventDefault();
  const email = document.getElementById('login-email').value;
  const pass = document.getElementById('login-password').value;
  
  if (!email || !pass) return;
  
  setAuthLoading(true);
  try {
    await auth.signInWithEmailAndPassword(email, pass);
    hideAuthModal();
    showToast("Login successful!");
  } catch (error) {
    showAuthError(mapAuthException(error));
  } finally {
    setAuthLoading(false);
  }
}

async function handleSignup(e) {
  e.preventDefault();
  const name = document.getElementById('signup-name').value;
  const email = document.getElementById('signup-email').value;
  const pass = document.getElementById('signup-password').value;
  
  if (!email || !pass || !name) return;
  
  setAuthLoading(true);
  try {
    const userCredential = await auth.createUserWithEmailAndPassword(email, pass);
    
    await userCredential.user.updateProfile({ displayName: name });
    
    const role = (email.toLowerCase() === 'admin@eximgraphics.com') ? 'admin' : 'student';
    
    await db.collection('users').doc(userCredential.user.uid).set({
      name: name,
      email: email,
      role: role,
      photoUrl: null,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    
    hideAuthModal();
    showToast("Account created successfully!");
  } catch (error) {
    showAuthError(mapAuthException(error));
  } finally {
    setAuthLoading(false);
  }
}

async function handleGoogleSignIn() {
  setAuthLoading(true);
  const provider = new firebase.auth.GoogleAuthProvider();
  try {
    const result = await auth.signInWithPopup(provider);
    const user = result.user;
    
    // Check if new user
    const userDoc = await db.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      await db.collection('users').doc(user.uid).set({
        name: user.displayName || 'User',
        email: user.email || '',
        role: 'student',
        photoUrl: user.photoURL || '',
        createdAt: firebase.firestore.FieldValue.serverTimestamp()
      });
    }
    
    hideAuthModal();
    showToast("Signed in with Google!");
  } catch (error) {
    showAuthError("Google Sign-In failed: " + error.message);
  } finally {
    setAuthLoading(false);
  }
}

function setAuthLoading(isLoading) {
  loginForm.style.display = isLoading ? 'none' : (loginForm.style.display === 'none' ? 'none' : 'flex');
  signupForm.style.display = isLoading ? 'none' : (signupForm.style.display === 'none' ? 'none' : 'flex');
  authLoading.style.display = isLoading ? 'flex' : 'none';
  authError.style.display = 'none';
}

function showAuthError(msg) {
  authError.innerText = msg;
  authError.style.display = 'block';
}

function mapAuthException(e) {
  switch (e.code) {
    case 'auth/user-not-found': return 'No user found with this email.';
    case 'auth/wrong-password': return 'Incorrect password. Please try again.';
    case 'auth/invalid-email': return 'The email address is not valid.';
    case 'auth/user-disabled': return 'This user account has been disabled.';
    case 'auth/too-many-requests': return 'Too many attempts. Please try again later.';
    case 'auth/email-already-in-use': return 'This email is already registered.';
    case 'auth/weak-password': return 'The password is too weak.';
    default: return e.message || 'An unknown authentication error occurred.';
  }
}

function showToast(msg) {
  toastEl.innerText = msg;
  toastEl.style.display = 'block';
  // Small delay for CSS transition if needed, simple approach:
  setTimeout(() => toastEl.classList.add('show'), 10);
  setTimeout(() => {
    toastEl.classList.remove('show');
    setTimeout(() => toastEl.style.display = 'none', 300);
  }, 3000);
}

// --- SPA Router ---
function initRouter() {
  window.addEventListener('hashchange', handleRoute);
  
  // Initial route
  let hash = window.location.hash;
  if (!hash) {
    window.location.hash = '#home';
  } else {
    handleRoute();
  }
}

function handleRoute() {
  const hash = window.location.hash || '#home';
  const page = hash.substring(1); // remove '#'
  
  // Update nav links styling
  document.querySelectorAll('.nav-link').forEach(link => {
    link.classList.remove('active');
    if (link.getAttribute('data-page') === page) {
      link.classList.add('active');
    }
  });

  renderPage(hash);
  window.scrollTo(0,0);
}

function renderPage(hash) {
  appContent.innerHTML = ''; // clear current
  appContent.className = 'page-enter'; // trigger animation
  
  // Small trick to re-trigger animation
  void appContent.offsetWidth;

  switch(hash) {
    case '#home': renderHome(); break;
    case '#courses': renderCourses(); break;
    case '#my-courses': renderMyCourses(); break;
    case '#recordings': renderRecordings(); break;
    case '#studypacks': renderStudyPacks(); break;
    case '#privacy': renderPrivacy(); break;
    case '#terms': renderTerms(); break;
    case '#refund': renderRefund(); break;
    case '#contact': renderContact(); break;
    case '#admin': renderAdmin(); break;
    case '#notifications': renderNotifications(); break;
    default: renderHome();
  }
}

// --- Page Renderers ---

function renderHome() {
  const userName = currentUser ? (currentUser.displayName || 'Student') : 'Student';
  
  let html = `
    <div class="welcome-banner">
      <h2>Hello, ${userName}!</h2>
      <p>Ready to learn something new?</p>
    </div>

    <div class="search-container">
      <div class="search-bar-wrapper">
        <span class="material-icons-outlined search-icon">search</span>
        <input type="text" id="class-search-input" placeholder="Search classes/courses..." autocomplete="off">
        <span class="material-icons-outlined clear-icon" id="class-search-clear" style="display:none;">close</span>
      </div>
      <div class="search-dropdown-overlay" id="class-search-dropdown" style="display:none;"></div>
    </div>
  `;

  // Carousel + QR Code Container
  if (promos.length > 0) {
    html += `
      <div class="hero-section">
        <div class="carousel-container">
          <div class="carousel-track" id="home-carousel-track">
            ${promos.map(url => `<div class="carousel-slide" style="background-image: url('${url}')"></div>`).join('')}
          </div>
          <div class="carousel-dots">
            ${promos.map((_, i) => `<div class="carousel-dot ${i===0?'active':''}" onclick="goToSlide(${i})"></div>`).join('')}
          </div>
        </div>
        <div class="qr-container">
          <img src="assets/images/qr-code.png" alt="App Download QR Code" class="qr-image">
          <div class="qr-details">
            <h4>Scan to Download</h4>
            <p>Get the Shilpa Sena Mobile App for a premium on-the-go experience</p>
          </div>
        </div>
      </div>
    `;
  }

  if (courses.length > 0) {
    html += `
      <div class="section-header">
        <h3>Available Courses</h3>
        <a href="#courses">See All</a>
      </div>
      <div>
        ${courses.map(c => `
          <div class="card card-row" onclick="window.location.hash='#courses'">
            <div class="card-icon"><span class="material-icons-outlined">school</span></div>
            <div class="card-info">
              <h4>${c.title}</h4>
              <p>${c.date}, ${c.time} &bull; Rs. ${parseFloat(c.price || 10.0).toFixed(2)}</p>
            </div>
          </div>
        `).join('')}
      </div>
    `;
  } else {
    html += `<div class="empty-state">
      <span class="material-icons-outlined">school</span>
      <p>No courses available</p>
    </div>`;
  }

  appContent.innerHTML = html;
  
  // Simple carousel auto-slide logic (if in DOM)
  initCarousel();
  initHomeSearchListeners();
}

function initHomeSearchListeners() {
  const searchInput = document.getElementById('class-search-input');
  const clearIcon = document.getElementById('class-search-clear');
  const dropdown = document.getElementById('class-search-dropdown');

  if (!searchInput || !dropdown) return;

  // Handle input changes
  searchInput.addEventListener('input', () => {
    const query = searchInput.value.trim().toLowerCase();
    
    if (query.length === 0) {
      if (clearIcon) clearIcon.style.display = 'none';
      dropdown.style.display = 'none';
      dropdown.innerHTML = '';
      return;
    }

    if (clearIcon) clearIcon.style.display = 'block';

    const filtered = courses.filter(c => c.title && c.title.toLowerCase().includes(query));

    if (filtered.length === 0) {
      dropdown.innerHTML = `
        <div class="dropdown-empty-state">
          No matching classes found
        </div>
      `;
    } else {
      dropdown.innerHTML = filtered.map(c => `
        <div class="dropdown-item" onclick="handleSearchItemClick('${c.id}')">
          <span class="material-icons-outlined">school</span>
          <div class="item-details">
            <span class="item-title">${c.title}</span>
            <span class="item-meta">${c.date || ''}, ${c.time || ''}</span>
          </div>
        </div>
      `).join('');
    }

    dropdown.style.display = 'block';
  });

  // Handle focus showing dropdown if not empty
  searchInput.addEventListener('focus', () => {
    if (searchInput.value.trim().length > 0) {
      dropdown.style.display = 'block';
    }
  });

  // Handle clear action
  if (clearIcon) {
    clearIcon.addEventListener('click', () => {
      searchInput.value = '';
      clearIcon.style.display = 'none';
      dropdown.style.display = 'none';
      dropdown.innerHTML = '';
      searchInput.focus();
    });
  }

  // Handle clicking outside to dismiss dropdown
  const handleOutsideClick = (e) => {
    if (!searchInput.contains(e.target) && !dropdown.contains(e.target)) {
      dropdown.style.display = 'none';
      document.removeEventListener('click', handleOutsideClick);
    }
  };

  document.addEventListener('click', handleOutsideClick);
}

window.handleSearchItemClick = function(courseId) {
  window.pendingScrollCourseId = courseId;
  window.location.hash = '#courses';
};


let carouselInterval;
let currentSlideIndex = 0;

function initCarousel() {
  clearInterval(carouselInterval);
  if (promos.length <= 1) return;
  
  currentSlideIndex = 0;
  startCarouselTimer();
}

function startCarouselTimer() {
  clearInterval(carouselInterval);
  carouselInterval = setInterval(() => {
    currentSlideIndex = (currentSlideIndex + 1) % promos.length;
    goToSlide(currentSlideIndex, false);
  }, 4000);
}

window.goToSlide = function(index, resetTimer = true) {
  const track = document.getElementById('home-carousel-track');
  const dots = document.querySelectorAll('.carousel-dot');
  if (!track) return;
  
  currentSlideIndex = index;
  track.style.transform = `translateX(-${index * 100}%)`;
  dots.forEach(d => d.classList.remove('active'));
  if (dots[index]) dots[index].classList.add('active');
  
  if (resetTimer) {
    startCarouselTimer();
  }
}

function renderCourses() {
  if (courses.length === 0) {
    appContent.innerHTML = `<div class="empty-state">
      <span class="material-icons-outlined">school</span>
      <p>No courses available yet.</p>
    </div>`;
    return;
  }

  let html = `<h2 style="margin-bottom: 24px;">All Courses</h2>`;
  
  courses.forEach(course => {
    const status = currentUser ? (enrollmentsMap[course.id] || 'available') : 'available';
    let statusClass = status;
    let statusIcon = 'shopping_cart';
    let statusText = 'Available';
    
    if (status === 'purchased') { statusIcon = 'check_circle'; statusText = 'Purchased'; }
    if (status === 'pending') { statusIcon = 'hourglass_top'; statusText = 'Pending'; }

    let actionsHtml = '';
    
    if (status === 'purchased') {
      actionsHtml = `
        <div class="course-actions">
          <button class="btn-primary btn-flex" onclick="window.open('${course.zoomLink}', '_blank')">
            <span class="material-icons-outlined" style="font-size:18px;">videocam</span> Join Zoom
          </button>
          <button class="btn-outline btn-flex" onclick="window.location.hash='#studypacks'">
            <span class="material-icons-outlined" style="font-size:18px;">library_books</span> Materials
          </button>
        </div>
      `;
    } else if (status === 'pending') {
      actionsHtml = `
        <div class="pending-notice">Your payment is being verified by admin. Please check back later.</div>
      `;
    } else {
      actionsHtml = `
        <button class="btn-primary btn-full" onclick="showPaymentModal('${course.id}')">
          <span class="material-icons">payment</span> Purchase (Rs. ${parseFloat(course.price || 10.0).toFixed(2)})
        </button>
      `;
    }

    html += `
      <div class="course-card-full" id="course-card-${course.id}">
        <div class="course-card-header">
          <h3>${course.title}</h3>
          <div class="status-badge ${statusClass}">
            <span class="material-icons" style="font-size:12px;">${statusIcon}</span> ${statusText}
          </div>
        </div>
        <div class="course-schedule">
          <span class="material-icons-outlined">schedule</span>
          Next Class: ${course.date} at ${course.time}
        </div>
        <div class="course-schedule" style="margin-top:-10px;">
          <span class="material-icons-outlined">sell</span>
          Price: Rs. ${parseFloat(course.price || 10.0).toFixed(2)}
        </div>
        <hr class="course-divider">
        ${actionsHtml}
      </div>
    `;
  });
  
  appContent.innerHTML = html;

  if (window.pendingScrollCourseId) {
    const courseId = window.pendingScrollCourseId;
    window.pendingScrollCourseId = null;
    
    setTimeout(() => {
      const cardElement = document.getElementById(`course-card-${courseId}`);
      if (cardElement) {
        cardElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
        cardElement.classList.add('active-pulse');
        setTimeout(() => {
          cardElement.classList.remove('active-pulse');
        }, 3000);
      }
    }, 150);
  }
}

window.launchWhatsApp = async function(courseId, courseTitle, isPending) {
  if (!currentUser) {
    showAuthModal('login');
    return;
  }

  const phoneNumber = '+94766341872';
  const text = isPending
    ? `Hello Shilpa Sena, I am following up on my payment for the ${courseTitle} course.`
    : `Hello Shilpa Sena, I would like to purchase the ${courseTitle} course. Here is my payment receipt for this course.`;
  
  const url = `https://wa.me/${phoneNumber}?text=${encodeURIComponent(text)}`;
  window.open(url, '_blank');
  
  if (!isPending) {
    try {
      await db.collection('users').doc(currentUser.uid).collection('enrollments').doc(courseId).set({
        courseId: courseId,
        courseTitle: courseTitle,
        studentName: currentUser.displayName || 'Anonymous student',
        studentEmail: currentUser.email || 'No email',
        status: 'pending',
        requestedAt: firebase.firestore.FieldValue.serverTimestamp()
      });
      showToast("Enrollment request sent!");
      addSystemAlert("Enrollment Requested", `Your enrollment request for "${courseTitle}" has been sent.`);
    } catch(e) {
      console.error(e);
      showToast("Error sending request.");
    }
  }
}

function renderMyCourses() {
  if (!currentUser) {
    renderWelcomePage('#my-courses');
    return;
  }

  if (myCourses.length === 0) {
    appContent.innerHTML = `<div class="empty-state">
      <span class="material-icons-outlined" style="font-size:80px; color:rgba(255,255,255,0.1)">school</span>
      <p>No courses enrolled yet</p>
    </div>`;
    return;
  }

  let html = `<h2 style="margin-bottom: 24px;">Current Enrollments</h2>`;
  
  html += `<div>`;
  myCourses.forEach(c => {
    html += `
      <div class="card card-row" onclick="window.location.hash='#courses'">
        <div class="card-icon"><span class="material-icons-outlined">play_circle_outline</span></div>
        <div class="card-info">
          <h4>${c.title}</h4>
          <p>Last Class: ${c.date}</p>
        </div>
        <span class="material-icons-outlined card-arrow">arrow_forward_ios</span>
      </div>
    `;
  });
  html += `</div>`;
  
  appContent.innerHTML = html;
}

function renderRecordings() {
  if (!currentUser || (!hasApprovedEnrollment)) {
    renderLockedState("Access Restricted", "Please enroll in a course to access our exclusive recordings library.");
    return;
  }

  if (recordings.length === 0) {
    appContent.innerHTML = `<div class="empty-state">
      <span class="material-icons-outlined">video_library</span>
      <p>No recordings available</p>
    </div>`;
    return;
  }

  let html = `<h2 style="margin-bottom: 24px;">Course Recordings</h2><div class="cards-grid">`;
  
  recordings.forEach(r => {
    html += `
      <a class="resource-card" href="${r.videoUrl}" target="_blank" rel="noopener">
        <div class="resource-icon">
          <span class="material-icons-outlined">play_circle_outline</span>
        </div>
        <h4>${r.title}</h4>
        <div class="resource-meta">
          <span class="material-icons-outlined" style="font-size:14px;">calendar_today</span>
          ${r.dateStr}
        </div>
      </a>
    `;
  });
  html += `</div>`;
  appContent.innerHTML = html;
}

function renderStudyPacks() {
  if (!currentUser || (!hasApprovedEnrollment)) {
    renderLockedState("Enrollment Required", "Comprehensive study packs and materials are available exclusively for enrolled students.");
    return;
  }

  if (studyPacks.length === 0) {
    appContent.innerHTML = `<div class="empty-state">
      <span class="material-icons-outlined">library_books</span>
      <p>No study materials currently uploaded</p>
    </div>`;
    return;
  }

  let html = `<h2 style="margin-bottom: 24px;">Learning Resources</h2><div class="cards-grid">`;
  
  studyPacks.forEach(sp => {
    // Determine link URL (assume structure similar to recording for demo, or field might be URL/fileUrl)
    let url = sp.driveLink || sp.url || sp.fileUrl || sp.zoomLink || '#';
    html += `
      <a class="resource-card" href="${url}" target="_blank" rel="noopener">
        <div class="resource-icon">
          <span class="material-icons-outlined">picture_as_pdf</span>
        </div>
        <h4>${sp.title}</h4>
        <div class="resource-meta">
          PDF Document
        </div>
      </a>
    `;
  });
  html += `</div>`;
  appContent.innerHTML = html;
}

function renderPrivacy() {
  appContent.innerHTML = `
    <div class="info-page" style="margin: 0 auto;">
      <h1>Privacy Policy</h1>
      <p class="subtitle">Last Updated: September 23, 2026</p>
      
      <p class="body-text">
        At <strong>Shilpa Sena LMS</strong>, we are committed to protecting the privacy and security of our customers' personal information. This Privacy Policy outlines how we collect, use, and safeguard your information when you visit or make a purchase on our website. By using our website, you consent to the practices described in this policy.
      </p>

      <h2>Information We Collect</h2>
      <p class="body-text">When you visit our website, we may collect certain information about you, including:</p>
      <ul>
        <li><strong>Personal identification information:</strong> (such as your name, email address, and phone number) provided voluntarily by you during the registration or checkout process.</li>
        <li><strong>Payment and billing information:</strong> necessary to process your orders, including credit card details, which are securely handled by trusted third-party payment processors.</li>
        <li><strong>Browsing information:</strong> such as your IP address, browser type, and device information, collected automatically using cookies and similar technologies.</li>
      </ul>

      <h2>Use of Information</h2>
      <p class="body-text">We may use the collected information for the following purposes:</p>
      <ul>
        <li>To process and fulfill your orders, including shipping and delivery.</li>
        <li>To communicate with you regarding your purchases, provide customer support, and respond to inquiries or requests.</li>
        <li>To personalize your shopping experience and present relevant product recommendations and promotions.</li>
        <li>To improve our website, products, and services based on your feedback and browsing patterns.</li>
        <li>To detect and prevent fraud, unauthorized activities, and abuse of our website.</li>
      </ul>

      <h2>Information Sharing</h2>
      <p class="body-text">We respect your privacy and do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except in the following circumstances:</p>
      <ul>
        <li><strong>Trusted service providers:</strong> We may share your information with third-party service providers who assist us in operating our website, processing payments, and delivering products. These providers are contractually obligated to handle your data securely and confidentially.</li>
        <li><strong>Legal requirements:</strong> We may disclose your information if required to do so by law or in response to valid legal requests or orders.</li>
      </ul>

      <h2>Data Security</h2>
      <p class="body-text">
        We implement industry-standard security measures to protect your personal information from unauthorized access, alteration, disclosure, or destruction. However, please be aware that no method of transmission over the internet or electronic storage is 100% secure, and we cannot guarantee absolute security.
      </p>

      <h2>Cookies and Tracking Technologies</h2>
      <p class="body-text">
        We use cookies and similar technologies to enhance your browsing experience, analyze website traffic, and gather information about your preferences and interactions with our website. You have the option to disable cookies through your browser settings, but this may limit certain features and functionality of our website.
      </p>

      <h2>Changes to the Privacy Policy</h2>
      <p class="body-text">
        We reserve the right to update or modify this Privacy Policy at any time. Any changes will be posted on this page with a revised "last updated" date. We encourage you to review this Privacy Policy periodically to stay informed about how we collect, use, and protect your information.
      </p>

      <h2>Contact Us</h2>
      <p class="body-text">
        If you have any questions, concerns, or requests regarding our Privacy Policy or the handling of your personal information, please contact us using the information provided on our website.
      </p>

      <h2 style="margin-top:40px;">Social Support</h2>
      <div class="social-row">
        <a href="https://www.facebook.com/eximgraphics" target="_blank" class="social-icon facebook" aria-label="Facebook"><i class="material-icons">facebook</i></a>
        <a href="https://www.instagram.com/eximgraphics" target="_blank" class="social-icon instagram" aria-label="Instagram"><i class="material-icons">camera_alt</i></a>
        <a href="https://www.youtube.com/channel/@eximgraphics" target="_blank" class="social-icon youtube" aria-label="YouTube"><i class="material-icons">play_circle_filled</i></a>
      </div>
    </div>
  `;
}

function renderTerms() {
  appContent.innerHTML = `
    <div class="info-page" style="margin: 0 auto;">
      <h1>Terms and Conditions</h1>
      <p class="subtitle">Last Updated: September 23, 2026</p>
      
      <p class="body-text">
        Welcome to <strong>Shilpa Sena LMS</strong>. These Terms and Conditions govern your use of our website and the purchase and sale of products from our platform. By accessing and using our website, you agree to comply with these terms. Please read them carefully before proceeding with any transactions.
      </p>

      <h2>1. Use of the Website</h2>
      <ul>
        <li>You must be at least 18 years old to use our website or make purchases.</li>
        <li>You are responsible for maintaining the confidentiality of your account information, including your username and password.</li>
        <li>You agree to provide accurate and current information during the registration and checkout process.</li>
        <li>You may not use our website for any unlawful or unauthorized purposes.</li>
      </ul>

      <h2>2. Product Information and Pricing</h2>
      <ul>
        <li>We strive to provide accurate product descriptions, images, and pricing information. However, we do not guarantee the accuracy or completeness of such information.</li>
        <li>Prices are subject to change without notice. Any promotions or discounts are valid for a limited time and may be subject to additional terms and conditions.</li>
      </ul>

      <h2>3. Orders and Payments</h2>
      <ul>
        <li>By placing an order on our website, you are making an offer to purchase the selected products.</li>
        <li>We reserve the right to refuse or cancel any order for any reason, including but not limited to product availability, errors in pricing or product information, or suspected fraudulent activity.</li>
        <li>You agree to provide valid and up-to-date payment information and authorize us to charge the total order amount, including applicable taxes and shipping fees, to your chosen payment method.</li>
        <li>We use trusted third-party payment processors to handle your payment information securely. We do not store or have access to your full payment details.</li>
      </ul>

      <h2>4. Shipping and Delivery</h2>
      <ul>
        <li>We will make reasonable efforts to ensure timely shipping and delivery of your orders.</li>
        <li>Shipping and delivery times provided are estimates and may vary based on your location and other factors.</li>
      </ul>

      <h2>5. Returns and Refunds</h2>
      <p class="body-text">
        Our Returns and Refund Policy governs the process and conditions for returning products and seeking refunds. Please refer to our <a href="#refund" style="color: var(--primary-cyan); font-weight: 600;">Refund Policy</a> for detailed information.
      </p>

      <h2>6. Intellectual Property</h2>
      <ul>
        <li>All content and materials on our website, including but not limited to text, images, logos, and graphics, are protected by intellectual property rights and are the property of Shilpa Sena LMS or its licensors.</li>
        <li>You may not use, reproduce, distribute, or modify any content from our website without our prior written consent.</li>
      </ul>

      <h2>7. Limitation of Liability</h2>
      <ul>
        <li>In no event shall Shilpa Sena LMS, its directors, employees, or affiliates be liable for any direct, indirect, incidental, special, or consequential damages arising out of or in connection with your use of our website or the purchase and use of our products.</li>
        <li>We make no warranties or representations, express or implied, regarding the quality, accuracy, or suitability of the products offered on our website.</li>
      </ul>

      <h2>8. Amendments and Termination</h2>
      <p class="body-text">
        We reserve the right to modify, update, or terminate these Terms and Conditions at any time without prior notice. It is your responsibility to review these terms periodically for any changes.
      </p>

      <h2 style="margin-top:40px;">Social Support</h2>
      <div class="social-row">
        <a href="https://www.facebook.com/eximgraphics" target="_blank" class="social-icon facebook" aria-label="Facebook"><i class="material-icons">facebook</i></a>
        <a href="https://www.instagram.com/eximgraphics" target="_blank" class="social-icon instagram" aria-label="Instagram"><i class="material-icons">camera_alt</i></a>
        <a href="https://www.youtube.com/channel/@eximgraphics" target="_blank" class="social-icon youtube" aria-label="YouTube"><i class="material-icons">play_circle_filled</i></a>
      </div>
    </div>
  `;
}

function renderRefund() {
  appContent.innerHTML = `
    <div class="info-page" style="margin: 0 auto;">
      <h1>Refund Policy</h1>
      <p class="subtitle">Last Updated: September 23, 2026</p>
      
      <p class="body-text">
        Thank you for shopping at <strong>Shilpa Sena LMS</strong>. We value your satisfaction and strive to provide you with the best online shopping experience possible. If, for any reason, you are not completely satisfied with your purchase, we are here to help.
      </p>

      <h2>Returns</h2>
      <p class="body-text">
        We accept returns within 30 days from the date of purchase. To be eligible for a return, your item must be unused and in the same condition that you received it. It must also be in the original packaging.
      </p>

      <h2>Refunds</h2>
      <p class="body-text">
        Once we receive your return and inspect the item, we will notify you of the status of your refund. If your return is approved, we will initiate a refund to your original method of payment. Please note that the refund amount will exclude any shipping charges incurred during the initial purchase.
      </p>

      <h2>Exchanges</h2>
      <p class="body-text">
        If you would like to exchange your item for a different size, color, or style, please contact our customer support team within 30 days of receiving your order. We will provide you with further instructions on how to proceed with the exchange.
      </p>

      <h2>Non-Returnable Items</h2>
      <p class="body-text">Certain items are non-returnable and non-refundable. These include:</p>
      <ul>
        <li>Gift cards</li>
        <li>Downloadable software products</li>
        <li>Personalized or custom-made items</li>
        <li>Perishable goods</li>
      </ul>

      <h2>Damaged or Defective Items</h2>
      <p class="body-text">
        In the unfortunate event that your item arrives damaged or defective, please contact us immediately. We will arrange for a replacement or issue a refund, depending on your preference and product availability.
      </p>

      <h2>Return Shipping</h2>
      <p class="body-text">
        You will be responsible for paying the shipping costs for returning your item unless the return is due to our error (e.g., wrong item shipped, defective product). In such cases, we will provide you with a prepaid shipping label.
      </p>

      <h2>Processing Time</h2>
      <p class="body-text">
        Refunds and exchanges will be processed within 5 business days after we receive your returned item. Please note that it may take additional time for the refund to appear in your account, depending on your payment provider.
      </p>

      <h2>Contact Us</h2>
      <p class="body-text">
        If you have any questions or concerns regarding our refund policy, please contact our customer support team. We are here to assist you and ensure your shopping experience with us is enjoyable and hassle-free.
      </p>

      <h2 style="margin-top:40px;">Social Support</h2>
      <div class="social-row">
        <a href="https://www.facebook.com/eximgraphics" target="_blank" class="social-icon facebook" aria-label="Facebook"><i class="material-icons">facebook</i></a>
        <a href="https://www.instagram.com/eximgraphics" target="_blank" class="social-icon instagram" aria-label="Instagram"><i class="material-icons">camera_alt</i></a>
        <a href="https://www.youtube.com/channel/@eximgraphics" target="_blank" class="social-icon youtube" aria-label="YouTube"><i class="material-icons">play_circle_filled</i></a>
      </div>
    </div>
  `;
}

function renderContact() {
  
  let profileSection = '';
  if (currentUser) {
    const avatar = currentUser.photoURL 
      ? `<img id="contact-avatar-img" src="${currentUser.photoURL}" alt="User">` 
      : `<span id="contact-avatar-placeholder" class="material-icons">person</span>`;
      
    profileSection = `
      <div class="profile-card">
        <h3>My Profile Identity</h3>
        <div class="avatar-container-outer">
          <div class="profile-avatar-lg" id="profile-avatar-clickable">
            ${avatar}
            <div class="profile-avatar-loader" id="profile-avatar-loader" style="display:none;">
              <div class="spinner-sm"></div>
            </div>
          </div>
          <button class="profile-camera-btn" onclick="triggerProfilePictureUpload()" title="Change Profile Picture">
            <span class="material-icons">camera_alt</span>
          </button>
        </div>
        <input type="file" id="profile-picture-input" accept="image/*" style="display:none;" onchange="handleProfilePictureUpload(event)">
        <div class="user-name">${currentUser.displayName || 'Student'}</div>
        <p class="user-desc">Your profile picture helps instructors and peers recognize you in the LMS community.</p>
      </div>
    `;
  }
  
  appContent.innerHTML = `
    <div class="info-page" style="margin: 0 auto;">
      <h1 style="text-align:center; font-size: 32px; margin-bottom: 10px;">Contact Us</h1>
      <p class="body-text" style="text-align:center; margin-bottom: 40px; color:rgba(255,255,255,0.7);">
        Our team is here to support your learning journey.<br>Feel free to reach out to us anytime.
      </p>
      
      ${profileSection}
      
      <div class="contact-item" onclick="window.open('tel:0760891262')">
        <label>Phone Number</label>
        <span>076 089 12 62</span>
      </div>
       <div class="contact-item" onclick="window.open('https://wa.me/94766341872', '_blank')">
        <label>Whatsapp</label>
        <span>076 634 18 72</span>
      </div>
       <div class="contact-item" onclick="window.location.href='mailto:kasunjayaweera80@gmail.com'">
        <label>Email Us</label>
        <span>kasunjayaweera80@gmail.com</span>
      </div>
      
      <h2 style="margin-top:60px;">Social Support</h2>
      <div class="social-row">
        <a href="https://www.facebook.com/eximgraphics" target="_blank" class="social-icon facebook"><i class="material-icons">facebook</i></a>
        <a href="https://www.instagram.com/eximgraphics" target="_blank" class="social-icon instagram"><i class="material-icons">camera_alt</i></a>
        <a href="https://www.youtube.com/channel/@eximgraphics" target="_blank" class="social-icon youtube"><i class="material-icons">play_circle_filled</i></a>
      </div>
    </div>
  `;
}

window.triggerProfilePictureUpload = function() {
  const input = document.getElementById('profile-picture-input');
  if (input) input.click();
};

window.handleProfilePictureUpload = async function(e) {
  const file = e.target.files[0];
  if (!file || !currentUser) return;
  
  const loader = document.getElementById('profile-avatar-loader');
  if (loader) loader.style.display = 'flex';
  
  showToast("Uploading profile picture...");
  try {
    const storageRef = storage.ref(`user_profiles/${currentUser.uid}.jpg`);
    const uploadTask = await storageRef.put(file);
    const downloadUrl = await uploadTask.ref.getDownloadURL();
    
    // Update Auth Profile
    await currentUser.updateProfile({ photoURL: downloadUrl });
    
    // Update Database User Document
    await db.collection('users').doc(currentUser.uid).update({
      photoUrl: downloadUrl
    });
    
    // Update navbar avatar if in DOM
    const navAvatar = document.getElementById('user-avatar');
    if (navAvatar) {
      navAvatar.innerHTML = `<img src="${downloadUrl}" alt="Profile">`;
    }
    
    // Update contact page avatar image
    const clickableContainer = document.getElementById('profile-avatar-clickable');
    if (clickableContainer) {
      clickableContainer.innerHTML = `
        <img id="contact-avatar-img" src="${downloadUrl}" alt="User">
        <div class="profile-avatar-loader" id="profile-avatar-loader" style="display:none;">
          <div class="spinner-sm"></div>
        </div>
      `;
    }
    
    showToast("Profile picture updated successfully!");
  } catch (error) {
    console.error("Error updating profile picture:", error);
    showToast("Failed to upload: " + error.message);
  } finally {
    if (loader) loader.style.display = 'none';
  }
};

// Helper to format timestamps matching Flutter app's _formatDate
function formatDate(date) {
  if (!(date instanceof Date)) {
    // Handle Firestore Timestamp
    if (date && date.toDate) {
      date = date.toDate();
    } else {
      date = new Date(date);
    }
  }
  
  if (isNaN(date.getTime())) return 'Unknown date';

  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  
  // Calculate day boundary difference
  const dateStart = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const nowStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const diffDays = Math.floor((nowStart - dateStart) / 86400000);

  if (diffMins < 60) {
    if (diffMins <= 1) return 'Just now';
    return `${diffMins} minutes ago`;
  } else if (diffHours < 24 && diffDays === 0) {
    return `${diffHours} hours ago`;
  } else if (diffDays === 0) {
    return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  } else if (diffDays < 7) {
    return `${diffDays} days ago`;
  } else {
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
  }
}

function renderNotifications() {
  // Mark all local system alerts as read on open
  let updatedAny = false;
  systemAlerts.forEach(a => {
    if (!a.isRead) {
      a.isRead = true;
      updatedAny = true;
    }
  });
  if (updatedAny) {
    saveSystemAlerts();
  }

  let html = `
    <div class="notifications-container">
      <div class="notifications-header">
        <div>
          <h2>Notification Center</h2>
          <p class="subtitle">Stay updated with system alerts and official announcements</p>
        </div>
        ${activeNotificationsTab === 'alerts' && systemAlerts.length > 0 ? `
          <button class="btn-outline btn-clear-alerts" onclick="clearAllSystemAlerts()" title="Clear Alerts">
            <span class="material-icons-outlined" style="font-size:18px;">clear_all</span> Clear Alerts
          </button>
        ` : ''}
      </div>

      <!-- Tab Navigator -->
      <div class="notifications-tabs-nav">
        <button class="tab-btn ${activeNotificationsTab === 'alerts' ? 'active' : ''}" onclick="switchNotificationsTab('alerts')">
          <span class="material-icons-outlined">notifications_none</span> System Alerts
        </button>
        <button class="tab-btn ${activeNotificationsTab === 'announcements' ? 'active' : ''}" onclick="switchNotificationsTab('announcements')">
          <span class="material-icons-outlined">campaign</span> Announcements
        </button>
      </div>

      <div class="notifications-tab-content">
  `;

  if (activeNotificationsTab === 'alerts') {
    if (systemAlerts.length === 0) {
      html += `
        <div class="empty-state">
          <span class="material-icons-outlined">notifications_off</span>
          <p>No system alerts yet.</p>
        </div>
      `;
    } else {
      html += `
        <div class="alerts-list">
          ${systemAlerts.map(alert => `
            <div class="notification-card system-alert-card">
              <div class="notification-card-header">
                <div class="notification-avatar circle-cyan">
                  <span class="material-icons">notifications_active</span>
                </div>
                <div class="notification-meta">
                  <h4>${escapeHtml(alert.title)}</h4>
                  <p class="timestamp">${formatDate(alert.timestamp)}</p>
                </div>
              </div>
              <div class="notification-body">
                <p>${escapeHtml(alert.body)}</p>
              </div>
            </div>
          `).join('')}
        </div>
      `;
    }
  } else {
    // Announcements Tab
    if (announcements.length === 0) {
      html += `
        <div class="empty-state">
          <span class="material-icons-outlined">campaign</span>
          <p>No announcements broadcasted yet.</p>
        </div>
      `;
    } else {
      html += `
        <div class="announcements-list">
          ${announcements.map(item => {
            let badgeColor = '#00d2ff'; // primary cyan
            let iconData = 'info_outline';
            switch (item.type) {
              case 'alert':
                badgeColor = '#ff3b30'; // notification red
                iconData = 'warning_amber';
                break;
              case 'promo':
                badgeColor = '#ffb800'; // accent yellow
                iconData = 'campaign';
                break;
            }

            const hasAction = item.actionUrl && item.actionUrl.trim().length > 0;
            const cardClickAction = hasAction ? `onclick="window.open('${escapeHtml(item.actionUrl.trim())}', '_blank')"` : '';
            const cardClass = `notification-card announcement-card ${item.type}-announcement-card ${hasAction ? 'clickable-card' : ''}`;

            return `
              <div class="${cardClass}" ${cardClickAction}>
                <div class="notification-card-header">
                  <div class="notification-avatar" style="background: ${badgeColor}15; color: ${badgeColor};">
                    <span class="material-icons">${iconData}</span>
                  </div>
                  <div class="notification-meta">
                    <div class="title-row">
                      <h4>${escapeHtml(item.title)}</h4>
                      <span class="type-badge" style="background: ${badgeColor}15; color: ${badgeColor};">${escapeHtml(item.type.toUpperCase())}</span>
                    </div>
                    <p class="timestamp">${formatDate(item.timestamp)}</p>
                  </div>
                </div>
                <div class="notification-body">
                  <p>${escapeHtml(item.body)}</p>
                  ${item.imageUrl && item.imageUrl.trim().length > 0 ? `
                    <div class="announcement-image-container">
                      <img src="${escapeHtml(item.imageUrl.trim())}" alt="Announcement Image" class="announcement-image">
                    </div>
                  ` : ''}
                </div>
                ${hasAction ? `
                  <div class="announcement-action-footer" style="color: ${badgeColor}">
                    <span>Learn More</span>
                    <span class="material-icons-outlined">arrow_forward</span>
                  </div>
                ` : ''}
              </div>
            `;
          }).join('')}
        </div>
      `;
    }
  }

  html += `
      </div>
    </div>
  `;

  appContent.innerHTML = html;
}

window.switchNotificationsTab = function(tabName) {
  activeNotificationsTab = tabName;
  renderNotifications();
};

window.clearAllSystemAlerts = function() {
  if (confirm("Are you sure you want to clear all system alerts?")) {
    systemAlerts = [];
    saveSystemAlerts();
    renderNotifications();
  }
};

function renderAdmin() {
  if (currentRole !== 'admin' && currentUser?.email !== 'admin@eximgraphics.com') {
    window.location.hash = '#home';
    return;
  }
  
  let html = `
    <div class="admin-dashboard-container">
      <div class="admin-header">
        <div>
          <h2>Admin Control Center</h2>
          <p class="subtitle">Platform configuration, students directory and database streams</p>
        </div>
        <div class="admin-header-actions">
          <button class="btn-outline btn-seed" onclick="seedDefaultData()">
            <span class="material-icons-outlined" style="font-size:18px;">storage</span> Seed Default Data
          </button>
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="admin-stats-grid">
        <div class="stat-card" onclick="switchAdminTab('courses')">
          <span class="material-icons-outlined stat-icon">school</span>
          <div class="stat-info">
            <span class="stat-value">${courses.length}</span>
            <span class="stat-label">Active Courses</span>
          </div>
        </div>
        <div class="stat-card" onclick="switchAdminTab('banners')">
          <span class="material-icons-outlined stat-icon">photo_library</span>
          <div class="stat-info">
            <span class="stat-value">${promos.length}</span>
            <span class="stat-label">Promo Banners</span>
          </div>
        </div>
        <div class="stat-card" onclick="switchAdminTab('requests')">
          <span class="material-icons-outlined stat-icon" style="color:var(--accent-yellow); background:rgba(255,184,0,0.1)">how_to_reg</span>
          <div class="stat-info">
            <span class="stat-value">${enrollmentRequests.filter(r => r.status === 'pending').length}</span>
            <span class="stat-label">Pending Requests</span>
          </div>
        </div>
        <div class="stat-card" onclick="switchAdminTab('students')">
          <span class="material-icons-outlined stat-icon" style="color:#a855f7; background:rgba(168,85,247,0.1)">group</span>
          <div class="stat-info">
            <span class="stat-value">${registeredUsers.length}</span>
            <span class="stat-label">Registered Students</span>
          </div>
        </div>
      </div>

      <!-- Tab Navigator -->
      <div class="admin-tabs-nav">
        <button class="tab-btn ${activeAdminTab === 'banners' ? 'active' : ''}" onclick="switchAdminTab('banners')">
          <span class="material-icons-outlined">photo_library</span> Banners
        </button>
        <button class="tab-btn ${activeAdminTab === 'courses' ? 'active' : ''}" onclick="switchAdminTab('courses')">
          <span class="material-icons-outlined">school</span> Courses
        </button>
        <button class="tab-btn ${activeAdminTab === 'requests' ? 'active' : ''}" onclick="switchAdminTab('requests')">
          <span class="material-icons-outlined">how_to_reg</span> Requests
        </button>
        <button class="tab-btn ${activeAdminTab === 'students' ? 'active' : ''}" onclick="switchAdminTab('students')">
          <span class="material-icons-outlined">group</span> Students
        </button>
        <button class="tab-btn ${activeAdminTab === 'messages' ? 'active' : ''}" onclick="switchAdminTab('messages')">
          <span class="material-icons-outlined">campaign</span> Announcements
        </button>
        <button class="tab-btn ${activeAdminTab === 'resources' ? 'active' : ''}" onclick="switchAdminTab('resources')">
          <span class="material-icons-outlined">folder</span> Resources
        </button>
      </div>

      <div class="admin-tab-content">
  `;

  if (activeAdminTab === 'banners') {
    html += `
        <div class="admin-card">
          <div class="admin-card-header">
            <h3>Manage Carousel Banners</h3>
            <p class="card-subtitle">Upload custom banner images directly to Firebase Storage or paste image URLs</p>
          </div>
          
          <div class="upload-section">
            <label for="admin-banner-file" class="upload-dropzone">
              <span class="material-icons-outlined dropzone-icon">cloud_upload</span>
              <span class="dropzone-text">Click to choose image file</span>
              <span class="dropzone-subtext">PNG, JPG or GIF up to 5MB</span>
            </label>
            <input type="file" id="admin-banner-file" accept="image/*" style="display:none;" onchange="handleBannerUpload(event)">
            
            <div class="divider-text"><span>OR</span></div>
            
            <form id="admin-banner-url-form" onsubmit="handleBannerUrlSubmit(event)" class="admin-url-form">
              <div class="input-group">
                <span class="material-icons-outlined input-icon">link</span>
                <input type="url" id="admin-banner-url" placeholder="Paste Image URL" required>
              </div>
              <button type="submit" class="btn-primary" style="margin-top: 10px; width: 100%; justify-content: center;">Add Banner URL</button>
            </form>
          </div>

          <div class="banner-list-container">
            <h4>Current Banners (${promos.length})</h4>
            ${promos.length === 0 ? `
              <div class="admin-empty-state">No banners active. Default banners will be shown.</div>
            ` : `
              <div class="banner-grid">
                ${promos.map(url => {
                  const isUploaded = url.includes('firebasestorage.googleapis.com');
                  const displayName = isUploaded ? 'Uploaded Image' : url.substring(url.lastIndexOf('/') + 1);
                  return `
                    <div class="admin-banner-item">
                      <img src="${url}" alt="Promo Banner" class="admin-banner-img">
                      <div class="banner-item-details">
                        <span class="banner-item-name" title="${url}">${displayName}</span>
                        <button class="btn-delete-icon" onclick="deleteAdminPromo('${url}')" title="Delete Banner">
                          <span class="material-icons-outlined">delete</span>
                        </button>
                      </div>
                    </div>
                  `;
                }).join('')}
              </div>
            `}
          </div>
        </div>
    `;
  }
  else if (activeAdminTab === 'courses') {
    html += `
      <div class="admin-main-grid">
        <div class="admin-column">
          <div class="admin-card">
            <div class="admin-card-header">
              <h3>Create New Course</h3>
              <p class="card-subtitle">Fill in the fields to publish a course</p>
            </div>
            
            <form id="admin-course-form" onsubmit="handleCourseSubmit(event)" class="admin-form">
              <div class="input-group">
                <span class="material-icons-outlined input-icon">title</span>
                <input type="text" id="admin-course-title" placeholder="Course Title" required>
              </div>
              <div class="input-group">
                <span class="material-icons-outlined input-icon">calendar_today</span>
                <input type="text" id="admin-course-date" placeholder="Class Date (e.g. Monday & Thursday)" required>
              </div>
              <div class="input-group">
                <span class="material-icons-outlined input-icon">schedule</span>
                <input type="text" id="admin-course-time" placeholder="Class Time (e.g. 7:00 PM - 9:00 PM)" required>
              </div>
              <div class="input-group">
                <span class="material-icons-outlined input-icon">videocam</span>
                <input type="url" id="admin-course-zoom" placeholder="Zoom Link" required>
              </div>
              <div class="input-group">
                <span class="material-icons-outlined input-icon">sell</span>
                <input type="number" step="0.01" id="admin-course-price" placeholder="Price (USD)" required min="0">
              </div>
              <button type="submit" class="btn-primary btn-full">
                <span class="material-icons-outlined">add</span> Publish Course
              </button>
            </form>
          </div>
        </div>

        <div class="admin-column">
          <div class="admin-card">
            <div class="admin-card-header">
              <h3>Existing Courses (${courses.length})</h3>
            </div>
            <div class="admin-course-list">
              ${courses.length === 0 ? `
                <div class="admin-empty-state">No courses added. Use the form or click Seed Default Data.</div>
              ` : courses.map(c => `
                <div class="admin-course-row">
                  <div class="admin-course-info">
                    <h4>${c.title}</h4>
                    <p>${c.date} at ${c.time}</p>
                  </div>
                  <button class="btn-delete-icon" onclick="deleteAdminCourse('${c.id}')" title="Delete Course">
                    <span class="material-icons-outlined">delete</span>
                  </button>
                </div>
              `).join('')}
            </div>
          </div>
        </div>
      </div>
    `;
  }
  else if (activeAdminTab === 'requests') {
    const pendings = enrollmentRequests.filter(r => r.status === 'pending');
    const histories = enrollmentRequests.filter(r => r.status !== 'pending');
    
    html += `
      <div class="admin-card">
        <div class="admin-card-header">
          <h3>Enrollment Access Requests</h3>
          <p class="card-subtitle">Approve student payments and verify access keys</p>
        </div>
        
        <div class="requests-tabs">
          <div class="tab-header">Pending Requests (${pendings.length})</div>
          <div class="requests-list">
            ${pendings.length === 0 ? `
              <div class="admin-empty-state">No pending enrollment requests. All students are approved!</div>
            ` : pendings.map(r => {
              const reqDate = r.requestedAt ? (r.requestedAt.toDate ? r.requestedAt.toDate().toLocaleDateString() : new Date(r.requestedAt).toLocaleDateString()) : 'Recently';
              return `
                <div class="request-card">
                  <div class="request-card-info">
                    <div class="student-avatar-circle">
                      <span class="material-icons-outlined">person</span>
                    </div>
                    <div>
                      <h4>${r.studentName}</h4>
                      <p class="email">${r.studentEmail}</p>
                      <p class="course-req"><span class="material-icons-outlined">school</span> ${r.courseTitle}</p>
                      <p class="date">Requested: ${reqDate}</p>
                    </div>
                  </div>
                  <div class="request-card-actions">
                    <button class="action-btn btn-reject" onclick="updateEnrollmentStatus('${r.refPath}', 'rejected')" title="Reject Access">
                      <span class="material-icons-outlined">close</span>
                    </button>
                    <button class="action-btn btn-approve" onclick="updateEnrollmentStatus('${r.refPath}', 'purchased')" title="Approve Access">
                      <span class="material-icons-outlined">check</span>
                    </button>
                  </div>
                </div>
              `;
            }).join('')}
          </div>
          
          <div class="tab-header" style="margin-top: 40px;">Activity History (${histories.length})</div>
          <div class="requests-list">
            ${histories.length === 0 ? `
              <div class="admin-empty-state">No history recorded yet.</div>
            ` : histories.map(r => {
              const statusClass = r.status === 'purchased' ? 'approved' : 'rejected';
              const reqDate = r.requestedAt ? (r.requestedAt.toDate ? r.requestedAt.toDate().toLocaleDateString() : new Date(r.requestedAt).toLocaleDateString()) : 'Recently';
              return `
                <div class="request-card history">
                  <div class="request-card-info">
                    <div class="student-avatar-circle">
                      <span class="material-icons-outlined">person</span>
                    </div>
                    <div>
                      <h4>${r.studentName}</h4>
                      <p class="email">${r.studentEmail}</p>
                      <p class="course-req"><span class="material-icons-outlined">school</span> ${r.courseTitle}</p>
                      <p class="date">Date: ${reqDate}</p>
                    </div>
                  </div>
                  <div class="status-badge ${statusClass}">
                    ${r.status === 'purchased' ? 'APPROVED' : 'REJECTED'}
                  </div>
                </div>
              `;
            }).join('')}
          </div>
        </div>
      </div>
    `;
  }
  else if (activeAdminTab === 'students') {
    html += `
      <div class="admin-card">
        <div class="admin-card-header">
          <h3>LMS Student Directory</h3>
          <p class="card-subtitle">Complete registry of all users registered on the Shilpa Sena system</p>
        </div>
        
        <div class="students-table-container">
          <table class="students-table">
            <thead>
              <tr>
                <th>Student Details</th>
                <th>Role Identity</th>
              </tr>
            </thead>
            <tbody>
              ${registeredUsers.length === 0 ? `
                <tr>
                  <td colspan="2" class="empty-cell">No registered students found.</td>
                </tr>
              ` : registeredUsers.map(u => {
                const isAdminBadge = u.role === 'admin' || u.email === 'admin@eximgraphics.com';
                return `
                  <tr>
                    <td>
                      <div class="table-student-info">
                        <span class="material-icons-outlined info-avatar">account_circle</span>
                        <div>
                          <div class="name">${u.name || 'Anonymous student'}</div>
                          <div class="email">${u.email}</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <span class="badge ${isAdminBadge ? 'admin' : 'student'}">
                        ${isAdminBadge ? 'ADMIN' : 'STUDENT'}
                      </span>
                    </td>
                  </tr>
                `;
              }).join('')}
            </tbody>
          </table>
        </div>
      </div>
    `;
  }
  else if (activeAdminTab === 'resources') {
    html += `
      <div class="admin-main-grid">
        <!-- Recordings Column -->
        <div class="admin-column">
          <div class="admin-card">
            <div class="admin-card-header">
              <h3>Publish Class Recording</h3>
              <p class="card-subtitle">Publish zoom recordings to the student library</p>
            </div>
            
            <form id="admin-recording-form" onsubmit="handleRecordingSubmit(event)" class="admin-form">
              <div class="input-group">
                <span class="material-icons-outlined input-icon">title</span>
                <input type="text" id="admin-recording-title" placeholder="Recording Title (e.g. Photoshop Lesson 1)" required>
              </div>
              <div class="input-group">
                <span class="material-icons-outlined input-icon">description</span>
                <input type="text" id="admin-recording-desc" placeholder="Brief Description" required>
              </div>
              <div class="input-group">
                <span class="material-icons-outlined input-icon">link</span>
                <input type="url" id="admin-recording-link" placeholder="Video Link (YouTube/Drive URL)" required>
              </div>
              <button type="submit" class="btn-primary btn-full">
                <span class="material-icons-outlined">add</span> Add Video Recording
              </button>
            </form>
          </div>

          <div class="admin-card" style="margin-top:20px;">
            <div class="admin-card-header">
              <h3>Uploaded Videos (${recordings.length})</h3>
            </div>
            <div class="admin-course-list">
              ${recordings.length === 0 ? `
                <div class="admin-empty-state">No class video recordings published yet.</div>
              ` : recordings.map(r => `
                <div class="admin-course-row">
                  <div class="admin-course-info">
                    <h4>${r.title}</h4>
                    <p>${r.description || 'No description'}</p>
                  </div>
                  <button class="btn-delete-icon" onclick="deleteAdminRecording('${r.id}')" title="Delete Recording">
                    <span class="material-icons-outlined">delete</span>
                  </button>
                </div>
              `).join('')}
            </div>
          </div>
        </div>

        <!-- Study Packs Column -->
        <div class="admin-column">
          <div class="admin-card">
            <div class="admin-card-header">
              <h3>Publish Study Pack / PDF</h3>
              <p class="card-subtitle">Publish google drive resources for students to read</p>
            </div>
            
            <form id="admin-pack-form" onsubmit="handleStudyPackSubmit(event)" class="admin-form">
              <div class="input-group">
                <span class="material-icons-outlined input-icon">title</span>
                <input type="text" id="admin-pack-title" placeholder="Resource Title (e.g. UI/UX Workbook)" required>
              </div>
              <div class="input-group">
                <span class="material-icons-outlined input-icon">link</span>
                <input type="url" id="admin-pack-link" placeholder="Google Drive Link (URL)" required>
              </div>
              <button type="submit" class="btn-primary btn-full">
                <span class="material-icons-outlined">add</span> Publish Study Material
              </button>
            </form>
          </div>

          <div class="admin-card" style="margin-top:20px;">
            <div class="admin-card-header">
              <h3>Uploaded Study Materials (${studyPacks.length})</h3>
            </div>
            <div class="admin-course-list">
              ${studyPacks.length === 0 ? `
                <div class="admin-empty-state">No study material PDF files published yet.</div>
              ` : studyPacks.map(sp => `
                <div class="admin-course-row">
                  <div class="admin-course-info">
                    <h4>${sp.title}</h4>
                    <p style="text-overflow: ellipsis; white-space: nowrap; overflow: hidden;" title="${sp.driveLink || sp.url || ''}">${sp.driveLink || sp.url || 'No link'}</p>
                  </div>
                  <button class="btn-delete-icon" onclick="deleteAdminStudyPack('${sp.id}')" title="Delete Study Pack">
                    <span class="material-icons-outlined">delete</span>
                  </button>
                </div>
              `).join('')}
            </div>
          </div>
        </div>
      </div>
    `;
  }
  else if (activeAdminTab === 'messages') {
    html += `
      <div class="admin-main-grid">
        <!-- Broadcast Form Column -->
        <div class="admin-column">
          <div class="admin-card">
            <div class="admin-card-header">
              <h3>Broadcast New Message</h3>
              <p class="card-subtitle">Fill in the fields to broadcast an in-app message/announcement</p>
            </div>
            
            <form id="admin-announcement-form" onsubmit="handleAnnouncementSubmit(event)" class="admin-form">
              <div class="input-group">
                <span class="material-icons-outlined input-icon">title</span>
                <input type="text" id="admin-announcement-title" placeholder="Message Title" required>
              </div>
              <div class="input-group">
                <span class="material-icons-outlined input-icon" style="top: 14px;">description</span>
                <textarea id="admin-announcement-body" placeholder="Message Body Content" rows="4" required style="width:100%; padding: 14px 16px 14px 46px; background: rgba(255,255,255,0.1); border: 1px solid transparent; border-radius: var(--radius-sm); color: #fff; font-family: var(--font-body); font-size: 15px; outline: none; transition: all 0.25s var(--ease); resize: vertical;"></textarea>
              </div>
              <div class="input-group">
                <span class="material-icons-outlined input-icon" style="z-index: 5;">label</span>
                <select id="admin-announcement-type" required style="width:100%; padding: 14px 16px 14px 46px; background: #041c2b; border: 1px solid rgba(255,255,255,0.1); border-radius: var(--radius-sm); color: #fff; font-family: var(--font-body); font-size: 15px; outline: none; transition: all 0.25s var(--ease); cursor: pointer; -webkit-appearance: none; -moz-appearance: none; appearance: none;">
                  <option value="info">Information (Cyan)</option>
                  <option value="alert">System Alert (Red)</option>
                  <option value="promo">Promotion/Offer (Yellow)</option>
                </select>
                <span class="material-icons-outlined" style="position: absolute; right: 14px; color: rgba(255,255,255,0.4); pointer-events: none;">arrow_drop_down</span>
              </div>
              <div class="input-group">
                <span class="material-icons-outlined input-icon">image</span>
                <input type="url" id="admin-announcement-image" placeholder="Optional Image URL">
              </div>
              <div class="input-group">
                <span class="material-icons-outlined input-icon">link</span>
                <input type="url" id="admin-announcement-action" placeholder="Optional Action/Launch URL">
              </div>
              <button type="submit" class="btn-primary btn-full">
                <span class="material-icons-outlined">campaign</span> Broadcast Message
              </button>
            </form>
          </div>
        </div>

        <!-- History Column -->
        <div class="admin-column">
          <div class="admin-card">
            <div class="admin-card-header">
              <h3>Broadcast History (${announcements.length})</h3>
            </div>
            <div class="admin-course-list">
              ${announcements.length === 0 ? `
                <div class="admin-empty-state">No broadcast history recorded yet.</div>
              ` : announcements.map(item => {
                let badgeColor = '#00d2ff';
                switch (item.type) {
                  case 'alert': badgeColor = '#ff3b30'; break;
                  case 'promo': badgeColor = '#ffb800'; break;
                }
                return `
                  <div class="admin-course-row">
                    <div class="admin-course-info" style="flex: 1; min-width: 0; padding-right: 12px;">
                      <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
                        <h4 style="margin:0; font-size:14px; font-weight:700; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">${escapeHtml(item.title)}</h4>
                        <span class="type-badge" style="background: ${badgeColor}20; color: ${badgeColor}; font-size: 8px; padding: 2px 6px; border-radius: 6px; font-weight: 700; flex-shrink: 0;">${escapeHtml(item.type.toUpperCase())}</span>
                      </div>
                      <p style="font-size:12px; color:rgba(255,255,255,0.7); display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; margin: 0 0 4px 0;">${escapeHtml(item.body)}</p>
                      <p style="font-size:10px; color:rgba(255,255,255,0.3); margin:0;">${formatDate(item.timestamp)}</p>
                    </div>
                    <button class="btn-delete-icon" onclick="deleteAdminAnnouncement('${item.id}')" title="Delete Announcement" style="flex-shrink: 0;">
                      <span class="material-icons-outlined">delete</span>
                    </button>
                  </div>
                `;
              }).join('')}
            </div>
          </div>
        </div>
      </div>
    `;
  }

  html += `
      </div>
    </div>
  `;
  appContent.innerHTML = html;
}

// --- Admin Global Action Handlers ---

window.switchAdminTab = function(tabName) {
  activeAdminTab = tabName;
  renderAdmin();
};

window.uploadAdminPromoBanner = async function(file) {
  if (!file) return;
  showToast("Uploading banner image...");
  try {
    const fileName = `promo_${Date.now()}_${file.name}`;
    const storageRef = storage.ref(`promos/${fileName}`);
    const uploadTask = await storageRef.put(file);
    const downloadUrl = await uploadTask.ref.getDownloadURL();
    
    await db.collection('promos').add({
      url: downloadUrl,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    showToast("Banner uploaded successfully!");
  } catch (error) {
    console.error("Error uploading banner:", error);
    showToast("Failed to upload: " + error.message);
  }
};

window.handleBannerUpload = async function(e) {
  const file = e.target.files[0];
  if (file) {
    await window.uploadAdminPromoBanner(file);
  }
};

window.handleBannerUrlSubmit = async function(e) {
  e.preventDefault();
  const urlInput = document.getElementById('admin-banner-url');
  const url = urlInput.value.trim();
  if (!url) return;
  
  showToast("Adding banner URL...");
  try {
    await db.collection('promos').add({
      url: url,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    urlInput.value = '';
    showToast("Banner URL added successfully!");
  } catch (error) {
    console.error("Error adding banner URL:", error);
    showToast("Failed to add URL: " + error.message);
  }
};

window.deleteAdminPromo = async function(promoUrl) {
  if (!confirm("Are you sure you want to delete this banner?")) return;
  showToast("Deleting banner...");
  try {
    const snapshot = await db.collection('promos').where('url', '==', promoUrl).get();
    if (snapshot.empty) {
      showToast("Banner not found in database.");
      return;
    }
    for (const doc of snapshot.docs) {
      await doc.ref.delete();
    }
    
    // Delete from storage if appropriate
    if (promoUrl.includes('firebasestorage.googleapis.com')) {
      try {
        const fileRef = storage.refFromURL(promoUrl);
        await fileRef.delete();
      } catch (err) {
        console.warn("Storage deletion skipped/failed:", err);
      }
    }
    showToast("Banner deleted successfully!");
  } catch (error) {
    console.error("Error deleting banner:", error);
    showToast("Failed to delete: " + error.message);
  }
};

window.handleCourseSubmit = async function(e) {
  e.preventDefault();
  const title = document.getElementById('admin-course-title').value.trim();
  const date = document.getElementById('admin-course-date').value.trim();
  const time = document.getElementById('admin-course-time').value.trim();
  const zoomLink = document.getElementById('admin-course-zoom').value.trim();
  const priceVal = parseFloat(document.getElementById('admin-course-price').value.trim()) || 10.0;
  
  if (!title || !date || !time || !zoomLink || isNaN(priceVal)) {
    showToast("Please fill all fields!");
    return;
  }
  
  showToast("Adding course...");
  try {
    await db.collection('courses').add({
      title: title,
      date: date,
      time: time,
      zoomLink: zoomLink,
      price: priceVal,
      isAvailable: true,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    document.getElementById('admin-course-form').reset();
    showToast("Course added successfully!");
  } catch (error) {
    console.error("Error adding course:", error);
    showToast("Failed to add course: " + error.message);
  }
};

window.deleteAdminCourse = async function(courseId) {
  if (!confirm("Are you sure you want to delete this course?")) return;
  showToast("Deleting course...");
  try {
    await db.collection('courses').doc(courseId).delete();
    showToast("Course deleted successfully!");
  } catch (error) {
    console.error("Error deleting course:", error);
    showToast("Failed to delete course: " + error.message);
  }
};

window.updateEnrollmentStatus = async function(refPath, status) {
  showToast("Updating request status...");
  try {
    await db.doc(refPath).update({ status: status });
    showToast(`Request ${status === 'purchased' ? 'approved' : 'rejected'} successfully!`);
  } catch (error) {
    console.error("Error updating enrollment status:", error);
    showToast("Error updating status: " + error.message);
  }
};

window.handleRecordingSubmit = async function(e) {
  e.preventDefault();
  const title = document.getElementById('admin-recording-title').value.trim();
  const desc = document.getElementById('admin-recording-desc').value.trim();
  const link = document.getElementById('admin-recording-link').value.trim();
  
  if (!title || !desc || !link) return;
  
  showToast("Adding recording...");
  try {
    await db.collection('recordings').add({
      title: title,
      description: desc,
      videoUrl: link,
      uploadedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    document.getElementById('admin-recording-form').reset();
    showToast("Recording added successfully!");
  } catch (error) {
    console.error("Error adding recording:", error);
    showToast("Error: " + error.message);
  }
};

window.deleteAdminRecording = async function(id) {
  if (!confirm("Are you sure you want to delete this recording?")) return;
  showToast("Deleting recording...");
  try {
    await db.collection('recordings').doc(id).delete();
    showToast("Recording deleted successfully!");
  } catch (error) {
    console.error("Error deleting recording:", error);
    showToast("Error: " + error.message);
  }
};

window.handleStudyPackSubmit = async function(e) {
  e.preventDefault();
  const title = document.getElementById('admin-pack-title').value.trim();
  const link = document.getElementById('admin-pack-link').value.trim();
  
  if (!title || !link) return;
  
  showToast("Adding study pack...");
  try {
    await db.collection('studypacks').add({
      title: title,
      driveLink: link,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    document.getElementById('admin-pack-form').reset();
    showToast("Study pack added successfully!");
  } catch (error) {
    console.error("Error adding study pack:", error);
    showToast("Error: " + error.message);
  }
};

window.deleteAdminStudyPack = async function(id) {
  if (!confirm("Are you sure you want to delete this study pack?")) return;
  showToast("Deleting study pack...");
  try {
    await db.collection('studypacks').doc(id).delete();
    showToast("Study pack deleted successfully!");
  } catch (error) {
    console.error("Error deleting study pack:", error);
    showToast("Error: " + error.message);
  }
};

window.handleAnnouncementSubmit = async function(e) {
  e.preventDefault();
  const title = document.getElementById('admin-announcement-title').value.trim();
  const body = document.getElementById('admin-announcement-body').value.trim();
  const type = document.getElementById('admin-announcement-type').value;
  const imageUrl = document.getElementById('admin-announcement-image').value.trim();
  const actionUrl = document.getElementById('admin-announcement-action').value.trim();

  if (!title || !body) {
    showToast("Title and Body are required!");
    return;
  }

  showToast("Broadcasting announcement...");
  try {
    await db.collection('announcements').add({
      title: title,
      body: body,
      type: type,
      imageUrl: imageUrl || null,
      actionUrl: actionUrl || null,
      timestamp: firebase.firestore.FieldValue.serverTimestamp()
    });
    document.getElementById('admin-announcement-form').reset();
    showToast("Announcement broadcasted successfully!");
  } catch (error) {
    console.error("Error broadcasting announcement:", error);
    showToast("Error: " + error.message);
  }
};

window.deleteAdminAnnouncement = async function(id) {
  if (!confirm("Are you sure you want to delete this announcement?")) return;
  showToast("Deleting announcement...");
  try {
    await db.collection('announcements').doc(id).delete();
    showToast("Announcement deleted successfully!");
  } catch (error) {
    console.error("Error deleting announcement:", error);
    showToast("Error: " + error.message);
  }
};

window.seedDefaultData = async function() {
  if (!confirm("This will seed standard default courses and banners if they don't exist. Proceed?")) return;
  
  showToast("Seeding database...");
  try {
    // 1. Seed Promos
    const promosSnap = await db.collection('promos').get();
    if (promosSnap.empty) {
      const defaultBanners = [
        "assets/images/promo_banner_1.png",
        "assets/images/promo_banner_2.png"
      ];
      for (const url of defaultBanners) {
        await db.collection('promos').add({
          url: url,
          createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
      }
    }
    
    // 2. Seed Courses
    const coursesSnap = await db.collection('courses').get();
    if (coursesSnap.empty) {
      const defaultCourses = [
        {
          title: "Graphic Design Masterclass",
          date: "Monday & Thursday",
          time: "7:00 PM - 9:00 PM",
          zoomLink: "https://zoom.us/j/94766341872",
          price: 49.99,
          isAvailable: true,
          createdAt: firebase.firestore.FieldValue.serverTimestamp()
        },
        {
          title: "UI/UX Design Professional Course",
          date: "Tuesday & Friday",
          time: "6:30 PM - 8:30 PM",
          zoomLink: "https://zoom.us/j/94766341872",
          price: 59.99,
          isAvailable: true,
          createdAt: firebase.firestore.FieldValue.serverTimestamp()
        },
        {
          title: "Video Editing & Motion Graphics",
          date: "Wednesday",
          time: "7:00 PM - 9:30 PM",
          zoomLink: "https://zoom.us/j/94766341872",
          price: 39.99,
          isAvailable: true,
          createdAt: firebase.firestore.FieldValue.serverTimestamp()
        },
        {
          title: "3D Animation & Architecture Modeling",
          date: "Saturday",
          time: "4:00 PM - 6:30 PM",
          zoomLink: "https://zoom.us/j/94766341872",
          price: 69.99,
          isAvailable: true,
          createdAt: firebase.firestore.FieldValue.serverTimestamp()
        }
      ];
      for (const course of defaultCourses) {
        await db.collection('courses').add(course);
      }
    }
    showToast("Database seeded successfully!");
  } catch (error) {
    console.error("Seeding error:", error);
    showToast("Error seeding database: " + error.message);
  }
};

// --- Helper Screens ---
function renderLockedState(title, subtitle) {
  appContent.innerHTML = `
    <div class="locked-state">
      <span class="material-icons-outlined">lock</span>
      <h2>${title}</h2>
      <p>${subtitle}</p>
      <button class="btn-cyan" onclick="window.location.hash='#courses'">Browse Courses</button>
    </div>
  `;
}

function renderWelcomePage(targetRoute) {
  appContent.innerHTML = `
    <div class="welcome-page">
      <div class="brand-logo">Shilpa Sena</div>
      <h1>Welcome to Shilpa Sena</h1>
      <p>Unlock your creative potential with our premium courses and study materials.</p>
      <div class="welcome-actions">
        <button class="btn-primary" onclick="showAuthModal('signup')">Get Started</button>
        <button class="btn-outline" onclick="showAuthModal('login')">I already have an account</button>
      </div>
    </div>
  `;
}

// --- Stripe configuration mirroring stripe_config.dart ---
const stripeConfig = {
  useLiveMode: true, // MIRRORS MOBILE APP'S ACTIVE CONFIG
  testPublishableKey: 'pk_test_51TepX9PiY8ODIKHWGRvzRAbZaXdjdhq1IHHEgXQeUH9xujMbNSX1vunQJ0L3yQP1fh8iRixeQ0ogliT1N2Se3Mdj00qeXx4Fyo',
  testSecretKey: 'YOUR_STRIPE_TEST_SECRET_KEY',
  livePublishableKey: 'pk_live_51Ted5APDNJFdc8fiVuKPhOpSNZblzFGXW9FSUEUiOdC5YWgplyJ23EHagAyJqN2GOn3HXl4uMeYXsGhDLOWYFizC00hUBu6tBU',
  liveSecretKey: 'YOUR_STRIPE_LIVE_SECRET_KEY',
  defaultCurrency: 'usd',
  get publishableKey() { return this.useLiveMode ? this.livePublishableKey : this.testPublishableKey; },
  get secretKey() { return this.useLiveMode ? this.liveSecretKey : this.testSecretKey; }
};

// Payment modal state
let selectedPaymentCourseId = null;
let selectedPaymentCourseTitle = null;
let selectedPaymentCoursePrice = 0.0;
let paymentMethod = 'card';

// Escape HTML helper
function escapeHtml(str) {
  if (!str) return '';
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

// Show Payment Sheet Modal
window.showPaymentModal = function(courseId) {
  if (!currentUser) {
    showAuthModal('login');
    return;
  }
  
  const course = courses.find(c => c.id === courseId);
  if (!course) {
    showToast("Course details not found.");
    return;
  }
  
  selectedPaymentCourseId = courseId;
  selectedPaymentCourseTitle = course.title;
  selectedPaymentCoursePrice = parseFloat(course.price) || 10.0;
  
  // Set details in modal
  document.getElementById('payment-course-title').innerText = selectedPaymentCourseTitle;
  document.getElementById('payment-course-price').innerText = `Rs. ${selectedPaymentCoursePrice.toFixed(2)}`;
  document.getElementById('btn-pay-now').innerText = `Pay Rs. ${selectedPaymentCoursePrice.toFixed(2)} Now`;
  
  // Reset states
  document.getElementById('payment-error').style.display = 'none';
  document.getElementById('payment-main-content').style.display = 'block';
  document.getElementById('payment-processing').style.display = 'none';
  document.getElementById('payment-success').style.display = 'none';
  
  // Clear inputs
  document.getElementById('card-holder').value = '';
  document.getElementById('card-number').value = '';
  document.getElementById('card-expiry').value = '';
  document.getElementById('card-cvc').value = '';
  
  paymentMethod = 'card';
  
  // Open overlay
  document.getElementById('payment-overlay').style.display = 'flex';
  
  // Bind formatters once
  setupPaymentInputFormatters();
};

window.hidePaymentModal = function() {
  document.getElementById('payment-overlay').style.display = 'none';
};

// Format credit card inputs
let inputFormattersBound = false;
function setupPaymentInputFormatters() {
  if (inputFormattersBound) return;
  
  const cardNumberInput = document.getElementById('card-number');
  const cardExpiryInput = document.getElementById('card-expiry');
  const cardCvcInput = document.getElementById('card-cvc');
  
  // Format Card Number: xxxx xxxx xxxx xxxx
  cardNumberInput.addEventListener('input', (e) => {
    let value = e.target.value.replace(/\D/g, '');
    let formattedValue = '';
    for (let i = 0; i < value.length && i < 16; i++) {
      if (i > 0 && i % 4 === 0) {
        formattedValue += ' ';
      }
      formattedValue += value[i];
    }
    e.target.value = formattedValue;
  });
  
  // Format Expiry: MM/YY
  cardExpiryInput.addEventListener('input', (e) => {
    let value = e.target.value.replace(/\D/g, '');
    let formattedValue = '';
    for (let i = 0; i < value.length && i < 4; i++) {
      if (i === 2) {
        formattedValue += '/';
      }
      formattedValue += value[i];
    }
    e.target.value = formattedValue;
  });
  
  // Format CVC: max 3 digits
  cardCvcInput.addEventListener('input', (e) => {
    e.target.value = e.target.value.replace(/\D/g, '').substring(0, 3);
  });
  
  inputFormattersBound = true;
}

// REST Stripe Payment logic mirroring StripeService.processPayment
async function processStripePayment({ cardNumber, expMonth, expYear, cvc, amount }) {
  try {
    const cleanCardNumber = cardNumber.replace(/\s+/g, '');
    const cleanExpMonth = expMonth.trim();
    let cleanExpYear = expYear.trim();
    if (cleanExpYear.length === 2) {
      cleanExpYear = '20' + cleanExpYear;
    }
    const cleanCvc = cvc.trim();
    const amountInCents = Math.round(amount * 100);
    
    let token;
    
    if (!stripeConfig.useLiveMode) {
      // In test mode, map card prefix to standard test tokens
      if (cleanCardNumber.startsWith('4')) {
        token = 'tok_visa';
      } else if (cleanCardNumber.startsWith('5')) {
        token = 'tok_mastercard';
      } else if (cleanCardNumber.startsWith('37') || cleanCardNumber.startsWith('34')) {
        token = 'tok_amex';
      } else if (cleanCardNumber.startsWith('6')) {
        token = 'tok_discover';
      } else {
        token = 'tok_visa';
      }
      console.log('Stripe (Test Mode): Mapping card to test token ' + token);
    } else {
      // In live mode, tokenize card details
      console.log('Stripe (Live Mode): Tokenizing card details...');
      
      const formData = new URLSearchParams();
      formData.append('card[number]', cleanCardNumber);
      formData.append('card[exp_month]', cleanExpMonth);
      formData.append('card[exp_year]', cleanExpYear);
      formData.append('card[cvc]', cleanCvc);
      
      const tokenResponse = await fetch('https://api.stripe.com/v1/tokens', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${stripeConfig.publishableKey}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: formData
      });
      
      const tokenData = await tokenResponse.json();
      if (!tokenResponse.ok) {
        const errorMsg = tokenData.error?.message || 'Failed to tokenize card.';
        return { success: false, errorMessage: errorMsg };
      }
      token = tokenData.id;
    }
    
    // Create Payment Method
    console.log('Stripe: Creating Payment Method from token...');
    const pmFormData = new URLSearchParams();
    pmFormData.append('type', 'card');
    pmFormData.append('card[token]', token);
    
    const pmResponse = await fetch('https://api.stripe.com/v1/payment_methods', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${stripeConfig.secretKey}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: pmFormData
    });
    
    const pmData = await pmResponse.json();
    if (!pmResponse.ok) {
      const errorMsg = pmData.error?.message || 'Failed to create payment method.';
      return { success: false, errorMessage: errorMsg };
    }
    
    const paymentMethodId = pmData.id;
    console.log('Stripe: Payment Method created: ' + paymentMethodId);
    
    // Create and Confirm Payment Intent
    console.log('Stripe: Creating and Confirming Payment Intent...');
    const piFormData = new URLSearchParams();
    piFormData.append('amount', amountInCents.toString());
    piFormData.append('currency', stripeConfig.defaultCurrency.toLowerCase());
    piFormData.append('payment_method', paymentMethodId);
    piFormData.append('confirm', 'true');
    piFormData.append('automatic_payment_methods[enabled]', 'true');
    piFormData.append('automatic_payment_methods[allow_redirects]', 'never');
    
    const piResponse = await fetch('https://api.stripe.com/v1/payment_intents', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${stripeConfig.secretKey}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: piFormData
    });
    
    const piData = await piResponse.json();
    if (!piResponse.ok) {
      const errorMsg = piData.error?.message || 'Payment authorization failed.';
      return { success: false, errorMessage: errorMsg };
    }
    
    const status = piData.status;
    const intentId = piData.id;
    
    if (status === 'succeeded') {
      console.log('Stripe: Payment Succeeded! Intent: ' + intentId);
      return { success: true, paymentIntentId: intentId };
    } else {
      console.log('Stripe: Payment Status was ' + status + ', expected succeeded.');
      return { success: false, errorMessage: 'Payment status is: ' + status + '. Complete authentication if required.' };
    }
  } catch (e) {
    console.error('Stripe Service Exception:', e);
    // Graceful fallback in test mode for browser local CORS limits
    if (!stripeConfig.useLiveMode) {
      console.warn('Stripe API fetch failed (likely CORS on secret key request). Falling back to simulated success in test mode.');
      await new Promise(resolve => setTimeout(resolve, 1500));
      return { success: true, paymentIntentId: 'test_cors_bypass_' + Date.now() };
    }
    return { success: false, errorMessage: 'An unexpected error occurred while communicating with Stripe: ' + e.message };
  }
}

// Enroll user immediately on success
async function enrollUserImmediately(courseId, courseTitle, paymentIntentId, paymentMethod = 'stripe') {
  if (!currentUser) return;
  
  try {
    await db.collection('users').doc(currentUser.uid).collection('enrollments').doc(courseId).set({
      courseId: courseId,
      courseTitle: courseTitle,
      studentName: currentUser.displayName || 'Anonymous student',
      studentEmail: currentUser.email || 'No email',
      status: 'purchased',
      purchasedAt: firebase.firestore.FieldValue.serverTimestamp(),
      paymentIntentId: paymentIntentId,
      paymentMethod: paymentMethod
    });
    
    // Update local state map
    enrollmentsMap[courseId] = 'purchased';
    updateMyCoursesList();
    showToast("Enrollment successful!");
    addSystemAlert("Course Purchased", `You have successfully purchased and enrolled in "${courseTitle}".`);
  } catch (error) {
    console.error("Error enrolling immediately:", error);
    throw error;
  }
}

// Submit Credit Card checkout
window.handlePaymentSubmit = async function(e) {
  e.preventDefault();
  
  const cardHolder = document.getElementById('card-holder').value.trim();
  const cardNumber = document.getElementById('card-number').value.replace(/\s+/g, '');
  const cardExpiry = document.getElementById('card-expiry').value.trim();
  const cardCvc = document.getElementById('card-cvc').value.trim();
  const errorEl = document.getElementById('payment-error');
  
  errorEl.style.display = 'none';
  
  // Front-end validations
  if (!cardHolder) {
    showPaymentError('Cardholder name is required.');
    return;
  }
  if (cardNumber.length < 16) {
    showPaymentError('Please enter a valid 16-digit card number.');
    return;
  }
  
  const expiryParts = cardExpiry.split('/');
  if (expiryParts.length !== 2) {
    showPaymentError('Invalid expiration date format (MM/YY).');
    return;
  }
  
  const month = parseInt(expiryParts[0], 10);
  if (isNaN(month) || month < 1 || month > 12) {
    showPaymentError('Invalid expiration month.');
    return;
  }
  
  if (cardCvc.length < 3) {
    showPaymentError('Invalid CVC/CVV.');
    return;
  }
  
  // Show processing loader state
  document.getElementById('payment-main-content').style.display = 'none';
  document.getElementById('payment-processing').style.display = 'flex';
  
  const result = await processStripePayment({
    cardNumber,
    expMonth: expiryParts[0],
    expYear: expiryParts[1],
    cvc: cardCvc,
    amount: selectedPaymentCoursePrice
  });
  
  if (result.success) {
    try {
      await enrollUserImmediately(selectedPaymentCourseId, selectedPaymentCourseTitle, result.paymentIntentId, 'stripe');
      showPaymentSuccessView();
    } catch (err) {
      document.getElementById('payment-processing').style.display = 'none';
      document.getElementById('payment-main-content').style.display = 'block';
      showPaymentError('Payment succeeded but enrollment failed: ' + err.message + '. Please contact admin.');
    }
  } else {
    document.getElementById('payment-processing').style.display = 'none';
    document.getElementById('payment-main-content').style.display = 'block';
    showPaymentError(result.errorMessage);
  }
};



function showPaymentError(msg) {
  const errorEl = document.getElementById('payment-error');
  errorEl.innerText = msg;
  errorEl.style.display = 'block';
}

function showPaymentSuccessView() {
  document.getElementById('payment-processing').style.display = 'none';
  document.getElementById('payment-success').style.display = 'block';
  
  // Re-render hash to show purchased state (Materials buttons, etc.)
  const hash = window.location.hash || '#home';
  renderPage(hash);
  
  // Close modal after 2 seconds
  setTimeout(() => {
    hidePaymentModal();
  }, 2000);
}
