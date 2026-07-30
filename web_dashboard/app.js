import {
  initializeApp,
} from 'https://www.gstatic.com/firebasejs/12.16.0/firebase-app.js';
import {
  GoogleAuthProvider,
  createUserWithEmailAndPassword,
  getAuth,
  onAuthStateChanged,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut,
} from 'https://www.gstatic.com/firebasejs/12.16.0/firebase-auth.js';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  getFirestore,
  limit,
  query,
  serverTimestamp,
  setDoc,
  where,
} from 'https://www.gstatic.com/firebasejs/12.16.0/firebase-firestore.js';
import {
  getDownloadURL,
  getStorage,
  ref,
  uploadBytes,
} from 'https://www.gstatic.com/firebasejs/12.16.0/firebase-storage.js';
import {firebaseConfig, publicDomain} from './firebase-config.js';

const root = document.getElementById('app');
const configured = Boolean(
  firebaseConfig.apiKey &&
  !firebaseConfig.apiKey.startsWith('REPLACE_'),
);

let app;
let auth;
let db;
let storage;
let currentUser = null;
let entitlement = {active: false, plan: 'free'};

if (configured) {
  app = initializeApp(firebaseConfig);
  auth = getAuth(app);
  db = getFirestore(app);
  storage = getStorage(app);
  onAuthStateChanged(auth, (user) => {
    currentUser = user;
    route();
  });
} else {
  route();
}

window.addEventListener('popstate', route);

function navigate(path) {
  history.pushState({}, '', path);
  route();
}

function bindNavigation() {
  document.querySelectorAll('[data-nav]').forEach((link) => {
    link.addEventListener('click', (event) => {
      const href = link.getAttribute('href');
      if (href?.startsWith('/')) {
        event.preventDefault();
        navigate(href);
      }
    });
  });
  document.getElementById('signOutBtn')?.addEventListener(
    'click',
    () => signOut(auth),
  );
}

function shell(content, {plain = false} = {}) {
  if (plain) return content;
  return `<div class="shell">
    <header class="topbar">
      <a class="brand" href="/" data-nav>
        <img src="/app_icon_192.png" alt="QR AJN">
        <span><strong>QR AJN</strong><small>Digital Business Identity</small></span>
      </a>
      <nav class="nav">
        <a class="btn secondary hide-mobile" href="/#features">Features</a>
        <a class="btn secondary" href="/builder" data-nav>${currentUser ? 'Builder' : 'Create Profile'}</a>
        ${currentUser ? '<a class="btn secondary" href="/dynamic" data-nav>Dynamic QR</a><a class="btn secondary" href="/analytics" data-nav>Analytics</a><button class="btn primary" id="signOutBtn">Sign out</button>' : '<a class="btn primary" href="/login" data-nav>Sign in</a>'}
      </nav>
    </header>
    ${content}
    <footer class="footer">© 2026 QR AJN • <a href="/privacy.html">Privacy</a> • <a href="/delete-account.html">Delete account</a> • qrajn.online</footer>
  </div>`;
}

async function route() {
  const path = decodeURIComponent(location.pathname);
  try {
    if (path.startsWith('/@')) return renderPublicProfile(path.slice(2));
    if (path.startsWith('/business/')) return renderPublicProfile(path.slice(10));
    if (path.startsWith('/card/')) return renderPublicProfile(path.slice(6));
    if (path.startsWith('/q/')) return resolveDynamicLink(path.slice(3));
    if (path === '/login') return renderLogin();
    if (path === '/builder' || path === '/dashboard') return renderBuilder();
    if (path === '/dynamic') return renderDynamicManager();
    if (path === '/analytics') return renderAnalytics();
    renderLanding();
  } catch (error) {
    renderError(error.message || String(error));
  }
}

function renderLanding() {
  root.innerHTML = shell(`
    <section class="hero">
      <div>
        <span class="status">QR AJN V5 • Firebase production kit</span>
        <h1>One QR for your complete business identity.</h1>
        <p>Create professional public profiles, editable QR destinations and branded digital business cards on <strong>qrajn.online</strong>. Customers can call, WhatsApp, save contact details, browse products, download brochures, pay by UPI and book appointments without installing an app.</p>
        <div class="hero-actions">
          <a class="btn secondary" href="/builder" data-nav>Create Business Profile</a>
          <a class="btn primary" href="#features">Explore Features</a>
        </div>
      </div>
      <div class="hero-card">
        <div class="qr-preview">▦</div>
        <h3>qrajn.online/@yourname</h3>
        <p>Editable profile • dynamic QR • no reprinting</p>
      </div>
    </section>
    <section class="section" id="features">
      <div class="section-head"><div><h2>Built for real business workflows</h2><p>More than a digital visiting card.</p></div></div>
      <div class="grid">
        ${feature('⚡', 'Fast public profiles', 'Mobile-first pages with call, WhatsApp, email, directions, UPI and save-contact actions.')}
        ${feature('🎨', 'Professional templates', 'Profiles for professionals, employees, shops, restaurants, doctors, schools and portfolios.')}
        ${feature('🔁', 'Editable dynamic QR', 'Keep the printed QR while changing the destination, campaign or fallback URL.')}
        ${feature('🛡️', 'Safe destination handling', 'QR AJN validates destinations and presents payment details before redirecting.')}
        ${feature('📈', 'Business analytics', 'Track privacy-safe views, clicks, leads, downloads and dynamic QR scans.')}
        ${feature('💎', 'Premium tools', 'Ad-free mobile use, advanced design, high-resolution exports and business publishing.')}
      </div>
    </section>
    <section class="section">
      <div class="panel callout">
        <div><h2>Free scanner. Optional business account.</h2><p>Scanning and static QR creation remain usable without compulsory login. Sign in only when you choose cloud profiles, dynamic links, leads or analytics.</p></div>
        <a class="btn primary" href="/builder" data-nav>Start Building</a>
      </div>
    </section>
  `);
  bindNavigation();
}

function feature(icon, title, text) {
  return `<article class="card"><div class="feature-icon">${icon}</div><h3>${escapeHtml(title)}</h3><p class="muted">${escapeHtml(text)}</p></article>`;
}

function renderLogin() {
  if (currentUser) return navigate('/builder');
  root.innerHTML = shell(`
    <div class="auth-layout">
      <div class="panel auth-intro">
        <img class="auth-logo" src="/app_icon_192.png" alt="QR AJN">
        <h1>Manage your QR AJN identity</h1>
        <p class="muted">Create and update public business profiles, dynamic QR routes, leads and analytics.</p>
        <div class="notice">Enable Email/Password and Google providers in Firebase Authentication after running the setup kit.</div>
      </div>
      <form class="panel" id="authForm">
        <div class="tabs">
          <button type="button" class="tab active" data-mode="login">Sign in</button>
          <button type="button" class="tab" data-mode="register">Create account</button>
        </div>
        <div class="field"><label>Email</label><input id="authEmail" type="email" required autocomplete="email"></div>
        <div class="field"><label>Password</label><input id="authPassword" type="password" required minlength="6" autocomplete="current-password"></div>
        <button class="btn primary full" id="authSubmit">Sign in</button>
        <button class="btn secondary full" type="button" id="googleBtn">Continue with Google</button>
        <button class="btn secondary full" type="button" id="resetBtn">Send password reset</button>
        <p id="authMessage" class="muted"></p>
      </form>
    </div>
  `);
  bindNavigation();

  let mode = 'login';
  document.querySelectorAll('[data-mode]').forEach((button) => {
    button.onclick = () => {
      mode = button.dataset.mode;
      document.querySelectorAll('[data-mode]').forEach(
        (item) => item.classList.toggle('active', item === button),
      );
      document.getElementById('authSubmit').textContent =
        mode === 'login' ? 'Sign in' : 'Create account';
    };
  });

  document.getElementById('authForm').onsubmit = async (event) => {
    event.preventDefault();
    if (!configured) return authMessage('Connect Firebase first.');
    try {
      const email = value('authEmail');
      const password = value('authPassword');
      if (mode === 'login') {
        await signInWithEmailAndPassword(auth, email, password);
      } else {
        await createUserWithEmailAndPassword(auth, email, password);
      }
      navigate('/builder');
    } catch (error) {
      authMessage(error.message);
    }
  };
  document.getElementById('googleBtn').onclick = async () => {
    try {
      await signInWithPopup(auth, new GoogleAuthProvider());
      navigate('/builder');
    } catch (error) {
      authMessage(error.message);
    }
  };
  document.getElementById('resetBtn').onclick = async () => {
    try {
      await sendPasswordResetEmail(auth, value('authEmail'));
      authMessage('Password reset email sent.');
    } catch (error) {
      authMessage(error.message);
    }
  };
}

function authMessage(text) {
  document.getElementById('authMessage').textContent = text;
}

async function requireAccount() {
  if (!configured) {
    root.innerHTML = shell(`<div class="error panel"><h1>Connect Firebase first</h1><p>Run <code>START_QR_AJN_V5_FULL_SETUP.ps1</code> with your new Firebase project ID.</p></div>`);
    bindNavigation();
    return false;
  }
  if (!currentUser) {
    navigate('/login');
    return false;
  }
  return true;
}

async function renderBuilder() {
  if (!await requireAccount()) return;
  root.innerHTML = shell(loading('Loading your business builder…'));
  bindNavigation();

  const [profile, access] = await Promise.all([
    loadMyProfile(),
    loadEntitlement(),
  ]);
  entitlement = access;
  const p = profile || defaultProfile();
  if (!entitlement.active && !profile) p.published = false;

  root.innerHTML = shell(`
    <div class="builder-shell">
      <aside class="panel builder-sidebar">
        <h2>Profile builder</h2>
        <p class="muted">Complete the four steps, preview the mobile page, then publish.</p>
        <div class="builder-steps">
          <button class="builder-step active" data-step="0"><strong>1</strong><span>Identity</span></button>
          <button class="builder-step" data-step="1"><strong>2</strong><span>Actions</span></button>
          <button class="builder-step" data-step="2"><strong>3</strong><span>Content</span></button>
          <button class="builder-step" data-step="3"><strong>4</strong><span>Design & publish</span></button>
        </div>
        <div class="notice">${entitlement.active ? `Premium active: ${escapeHtml(entitlement.plan || 'pro')}` : 'Free draft mode. Activate Pro or Business in the Android app before publishing publicly.'}</div>
      </aside>

      <form class="panel builder-form" id="profileForm">
        <section class="builder-page active" data-page="0">
          <h2>Identity and public URL</h2>
          ${selectField('template', 'Profile template', p.template, templates())}
          ${field('slug', 'Profile URL', p.slug, 'text', 'qrajn.online/@your-name')}
          ${field('name', 'Name / business name', p.name)}
          ${field('title', 'Professional title', p.title)}
          ${field('company', 'Company', p.company)}
          ${uploadField('coverUrl', 'Cover image URL', p.coverUrl, 'image/*')}
          ${uploadField('photoUrl', 'Profile photo URL', p.photoUrl, 'image/*')}
          ${uploadField('logoUrl', 'Logo URL', p.logoUrl, 'image/*')}
        </section>

        <section class="builder-page" data-page="1">
          <h2>Contact and action buttons</h2>
          ${field('phone', 'Phone', p.phone, 'tel')}
          ${field('whatsapp', 'WhatsApp number', p.whatsapp, 'tel')}
          ${field('email', 'Email', p.email, 'email')}
          ${field('website', 'Website', p.website, 'url')}
          ${textarea('address', 'Address', p.address)}
          ${field('mapUrl', 'Map / directions URL', p.mapUrl, 'url')}
          ${field('upiId', 'UPI ID', p.upiId)}
          ${field('reviewUrl', 'Google Review URL', p.reviewUrl, 'url')}
          ${field('appointmentUrl', 'Appointment URL', p.appointmentUrl, 'url')}
          ${field('leadFormUrl', 'Lead form URL', p.leadFormUrl, 'url')}
        </section>

        <section class="builder-page" data-page="2">
          <h2>Business content</h2>
          ${textarea('services', 'Services — one per line', lines(p.services), 5)}
          ${textarea('products', 'Products — one per line', lines(p.products), 5)}
          ${textarea('priceList', 'Price list — one per line', lines(p.priceList), 5)}
          ${textarea('galleryUrls', 'Gallery image URLs', lines(p.galleryUrls), 4)}
          ${textarea('videoUrls', 'Video URLs', lines(p.videoUrls), 4)}
          ${uploadField('brochureUrl', 'Brochure PDF URL', p.brochureUrl, 'application/pdf')}
          ${textarea('openingHours', 'Opening hours', p.openingHours, 4)}
          ${textarea('branchLocations', 'Branch locations', lines(p.branchLocations), 4)}
          ${textarea('languages', 'Languages', lines(p.languages), 3)}
          ${textarea('testimonials', 'Testimonials', lines(p.testimonials), 5)}
          ${textarea('certifications', 'Certifications', lines(p.certifications), 4)}
          ${textarea('offers', 'Offers', lines(p.offers), 4)}
          ${textarea('socialLinks', 'Social links: platform=url', mapLines(p.socialLinks), 6)}
        </section>

        <section class="builder-page" data-page="3">
          <h2>Design, preview and publish</h2>
          ${selectField('primaryColor', 'Primary colour', p.primaryColor, [
            ['#2563EB', 'Ocean Blue'], ['#7C3AED', 'Royal Violet'],
            ['#059669', 'Emerald'], ['#E11D48', 'Rose'],
            ['#EA580C', 'Sunset'], ['#111827', 'Midnight'],
          ])}
          <label class="switch-row"><input id="published" type="checkbox" ${p.published ? 'checked' : ''}><span><strong>Publish publicly</strong><small>When disabled, the profile remains an owner-only draft.</small></span></label>
          <div id="profilePreview"></div>
        </section>

        <div class="builder-actions">
          <button type="button" class="btn secondary" id="builderBack">Back</button>
          <button type="button" class="btn secondary" id="builderNext">Continue</button>
          <button type="submit" class="btn primary hidden" id="builderSave">Save & publish</button>
        </div>
        <p id="builderMessage" class="muted"></p>
      </form>
    </div>
  `);
  bindNavigation();
  bindBuilder(p);
}

function bindBuilder(initial) {
  let step = 0;
  const form = document.getElementById('profileForm');
  const updateStep = (next) => {
    step = Math.max(0, Math.min(3, next));
    document.querySelectorAll('.builder-page').forEach(
      (page) => page.classList.toggle('active', Number(page.dataset.page) === step),
    );
    document.querySelectorAll('.builder-step').forEach(
      (button) => button.classList.toggle('active', Number(button.dataset.step) <= step),
    );
    document.getElementById('builderBack').disabled = step === 0;
    document.getElementById('builderNext').classList.toggle('hidden', step === 3);
    document.getElementById('builderSave').classList.toggle('hidden', step !== 3);
    if (step === 3) updateProfilePreview(readProfile(initial));
  };
  document.querySelectorAll('.builder-step').forEach(
    (button) => button.onclick = () => updateStep(Number(button.dataset.step)),
  );
  document.getElementById('builderBack').onclick = () => updateStep(step - 1);
  document.getElementById('builderNext').onclick = () => updateStep(step + 1);

  document.querySelectorAll('[data-upload]').forEach((button) => {
    button.onclick = () => uploadBusinessMedia(button.dataset.upload);
  });
  form.addEventListener('input', () => {
    if (step === 3) updateProfilePreview(readProfile(initial));
  });
  form.onsubmit = async (event) => {
    event.preventDefault();
    const p = readProfile(initial);
    const message = document.getElementById('builderMessage');
    try {
      if (!p.name.trim()) throw new Error('Enter the profile name.');
      p.slug = normalizeSlug(p.slug);
      if (p.slug.length < 3) throw new Error('Profile URL must contain at least 3 characters.');
      if (p.published && !entitlement.active) {
        throw new Error('Activate QR AJN Pro or Business in the Android app before publishing publicly.');
      }
      const existing = await getDoc(doc(db, 'business_profiles', p.slug));
      if (existing.exists() && existing.data().ownerUid !== currentUser.uid) {
        throw new Error('That public profile URL is already taken.');
      }
      await setDoc(doc(db, 'business_profiles', p.slug), {
        ...p,
        ownerUid: currentUser.uid,
        updatedAt: serverTimestamp(),
      }, {merge: true});
      await setDoc(doc(db, 'users', currentUser.uid), {
        businessProfileSlug: p.slug,
        updatedAt: serverTimestamp(),
      }, {merge: true});
      message.innerHTML = `Saved. <a href="/@${encodeURIComponent(p.slug)}" data-nav>Open public profile</a>`;
      bindNavigation();
    } catch (error) {
      message.textContent = error.message;
    }
  };
  updateStep(0);
}

async function uploadBusinessMedia(fieldId) {
  const input = document.getElementById(`${fieldId}File`);
  if (!input?.files?.length) return;
  const file = input.files[0];
  const max = file.type === 'application/pdf' ? 10 * 1024 * 1024 : 5 * 1024 * 1024;
  if (file.size > max) {
    alert(`File is too large. Maximum ${file.type === 'application/pdf' ? '10 MB' : '5 MB'}.`);
    return;
  }
  const safeName = `${Date.now()}_${file.name.replace(/[^A-Za-z0-9._-]/g, '_')}`;
  const objectRef = ref(storage, `business_media/${currentUser.uid}/${fieldId}/${safeName}`);
  await uploadBytes(objectRef, file, {contentType: file.type});
  document.getElementById(fieldId).value = await getDownloadURL(objectRef);
  input.value = '';
  document.getElementById(fieldId).dispatchEvent(new Event('input', {bubbles: true}));
}

function readProfile(initial = {}) {
  const map = parseMap(value('socialLinks'));
  return {
    slug: normalizeSlug(value('slug')),
    name: value('name'),
    title: value('title'),
    company: value('company'),
    coverUrl: value('coverUrl'),
    photoUrl: value('photoUrl'),
    logoUrl: value('logoUrl'),
    phone: value('phone'),
    whatsapp: value('whatsapp'),
    email: value('email'),
    website: value('website'),
    address: value('address'),
    mapUrl: value('mapUrl'),
    services: parseLines(value('services')),
    products: parseLines(value('products')),
    priceList: parseLines(value('priceList')),
    galleryUrls: parseLines(value('galleryUrls')),
    videoUrls: parseLines(value('videoUrls')),
    brochureUrl: value('brochureUrl'),
    upiId: value('upiId'),
    reviewUrl: value('reviewUrl'),
    leadFormUrl: value('leadFormUrl'),
    appointmentUrl: value('appointmentUrl'),
    openingHours: value('openingHours'),
    branchLocations: parseLines(value('branchLocations')),
    languages: parseLines(value('languages')),
    testimonials: parseLines(value('testimonials')),
    certifications: parseLines(value('certifications')),
    offers: parseLines(value('offers')),
    socialLinks: map,
    template: value('template') || initial.template || 'professional',
    primaryColor: value('primaryColor') || '#2563EB',
    published: document.getElementById('published')?.checked ?? false,
  };
}

function updateProfilePreview(p) {
  document.getElementById('profilePreview').innerHTML = profileCard(p, {preview: true});
}

async function renderPublicProfile(slug) {
  if (!configured) return renderError('Firebase is not configured.');
  const snapshot = await getDoc(doc(db, 'business_profiles', normalizeSlug(slug)));
  if (!snapshot.exists()) return renderError('This QR AJN profile was not found.');
  const p = snapshot.data();
  if (p.published !== true && p.ownerUid !== currentUser?.uid) {
    return renderError('This profile is private.');
  }
  root.innerHTML = shell(`<main class="public-wrap">${profileCard(p)}</main>`);
  bindNavigation();
  bindProfileActions(p);
}

function profileCard(p, {preview = false} = {}) {
  const colour = safeColour(p.primaryColor);
  const actions = [
    p.phone && actionLink('☎', 'Call', `tel:${encodeURIComponent(p.phone)}`, 'phone'),
    p.whatsapp && actionLink('💬', 'WhatsApp', `https://wa.me/${digits(p.whatsapp)}`, 'whatsapp'),
    p.email && actionLink('✉', 'Email', `mailto:${encodeURIComponent(p.email)}`, 'email'),
    p.mapUrl && actionLink('📍', 'Directions', p.mapUrl, 'map'),
    p.website && actionLink('🌐', 'Website', p.website, 'website'),
    p.upiId && actionLink('₹', 'UPI Pay', `upi://pay?pa=${encodeURIComponent(p.upiId)}&pn=${encodeURIComponent(p.name || 'QR AJN Business')}`, 'upi'),
    p.reviewUrl && actionLink('★', 'Review', p.reviewUrl, 'review'),
    p.appointmentUrl && actionLink('📅', 'Book', p.appointmentUrl, 'appointment'),
  ].filter(Boolean).join('');

  const coverUrl = safeHttpUrl(p.coverUrl);
  const photoUrl = safeHttpUrl(p.photoUrl);
  const logoUrl = safeHttpUrl(p.logoUrl);
  const brochureUrl = safeHttpUrl(p.brochureUrl);
  const leadFormUrl = safeHttpUrl(p.leadFormUrl);
  return `<article class="profile-card" style="--profile:${colour}">
    <div class="cover" ${coverUrl ? `style="background-image:url('${escapeAttribute(coverUrl)}')"` : ''}></div>
    <div class="profile-content">
      ${photoUrl ? `<img class="avatar" src="${escapeAttribute(photoUrl)}" alt="" loading="lazy">` : '<div class="avatar avatar-placeholder">AJN</div>'}
      ${logoUrl ? `<img class="business-logo" src="${escapeAttribute(logoUrl)}" alt="" loading="lazy">` : ''}
      <h1>${escapeHtml(p.name || 'QR AJN Business')}</h1>
      <p class="muted">${escapeHtml([p.title, p.company].filter(Boolean).join(' • '))}</p>
      <div class="profile-actions">${actions}</div>
      ${p.address ? section('Address', `<p>${escapeHtml(p.address)}</p>`) : ''}
      ${p.openingHours ? section('Opening hours', `<p class="preline">${escapeHtml(p.openingHours)}</p>`) : ''}
      ${listSection('Services', p.services)}
      ${listSection('Products', p.products)}
      ${listSection('Price list', p.priceList)}
      ${listSection('Current offers', p.offers)}
      ${gallerySection(p.galleryUrls)}
      ${brochureUrl ? section('Brochure', `<a class="btn primary" href="${escapeAttribute(brochureUrl)}" target="_blank" rel="noopener" data-action="brochure">Download brochure</a>`) : ''}
      ${leadFormUrl ? section('Contact / lead form', `<a class="btn secondary" href="${escapeAttribute(leadFormUrl)}" target="_blank" rel="noopener" data-action="lead">Send enquiry</a>`) : ''}
      ${listSection('Branches', p.branchLocations)}
      ${listSection('Languages', p.languages)}
      ${listSection('Testimonials', p.testimonials)}
      ${listSection('Certifications', p.certifications)}
      ${socialSection(p.socialLinks)}
      ${preview ? '' : `<button class="btn secondary full" id="saveContactBtn">Save contact</button>`}
    </div>
  </article>`;
}

function bindProfileActions(p) {
  document.querySelectorAll('[data-action]').forEach((link) => {
    link.addEventListener('click', () => {
      // Production Blaze backend can aggregate this privacy-safe action.
    });
  });
  document.getElementById('saveContactBtn')?.addEventListener('click', () => {
    const vcard = [
      'BEGIN:VCARD', 'VERSION:3.0',
      `FN:${escapeVcard(p.name || '')}`,
      `ORG:${escapeVcard(p.company || '')}`,
      `TITLE:${escapeVcard(p.title || '')}`,
      p.phone ? `TEL:${escapeVcard(p.phone)}` : '',
      p.email ? `EMAIL:${escapeVcard(p.email)}` : '',
      p.website ? `URL:${escapeVcard(p.website)}` : '',
      p.address ? `ADR:;;${escapeVcard(p.address)};;;;` : '',
      'END:VCARD',
    ].filter(Boolean).join('\r\n');
    const blob = new Blob([vcard], {type: 'text/vcard'});
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = `${normalizeSlug(p.name || 'qr-ajn-contact')}.vcf`;
    anchor.click();
    URL.revokeObjectURL(url);
  });
}

async function renderDynamicManager() {
  if (!await requireAccount()) return;
  entitlement = await loadEntitlement();
  root.innerHTML = shell(loading('Loading dynamic QR links…'));
  bindNavigation();

  const snapshot = await getDocs(
    query(collection(db, 'dynamic_links'), where('ownerUid', '==', currentUser.uid), limit(100)),
  );
  const links = snapshot.docs.map((document) => ({code: document.id, ...document.data()}));

  root.innerHTML = shell(`
    <div class="dashboard">
      <aside class="panel">
        <h1>Dynamic QR</h1>
        <p class="muted">Keep one printed qrajn.online QR while editing the destination.</p>
        <div class="notice">${entitlement.active ? 'Premium is active.' : 'An active Pro or Business entitlement is required by Firestore rules.'}</div>
        <button class="btn primary full" id="newDynamicBtn">Create dynamic QR</button>
      </aside>
      <main class="panel">
        <h2>Your links</h2>
        <div class="list">${links.length ? links.map(dynamicLinkCard).join('') : '<div class="empty">No dynamic QR links yet.</div>'}</div>
      </main>
    </div>
    <dialog id="dynamicDialog">${dynamicForm()}</dialog>
  `);
  bindNavigation();
  bindDynamicManager(links);
}

function dynamicLinkCard(link) {
  return `<article class="list-item dynamic-card">
    <div><strong>${escapeHtml(link.title || 'Dynamic QR')}</strong><small>${escapeHtml(`${publicDomain}/q/${link.code}`)}</small><p>${escapeHtml(link.destination || '')}</p><span class="status">${link.active === false ? 'PAUSED' : 'ACTIVE'} • ${Number(link.scanCount || 0)} scans</span></div>
    <div class="row-actions"><button class="btn secondary" data-edit="${escapeAttribute(link.code)}">Edit</button><button class="btn danger" data-delete="${escapeAttribute(link.code)}">Delete</button></div>
  </article>`;
}

function dynamicForm(link = {}) {
  return `<form method="dialog" id="dynamicForm" class="dialog-form">
    <h2>${link.code ? 'Edit' : 'Create'} dynamic QR</h2>
    <input type="hidden" id="dynamicCode" value="${escapeAttribute(link.code || '')}">
    ${field('dynamicTitle', 'Title', link.title || '')}
    ${field('destination', 'Default HTTPS destination', link.destination || '', 'url')}
    ${field('androidDestination', 'Android destination', link.androidDestination || '', 'url')}
    ${field('iosDestination', 'iPhone destination', link.iosDestination || '', 'url')}
    ${field('desktopDestination', 'Desktop destination', link.desktopDestination || '', 'url')}
    ${field('fallbackDestination', 'Fallback destination', link.fallbackDestination || '', 'url')}
    ${field('maximumScans', 'Maximum scans (optional)', link.maximumScans || '', 'number')}
    <label class="switch-row"><input id="dynamicActive" type="checkbox" ${link.active === false ? '' : 'checked'}><span><strong>Active</strong><small>Pause redirects without deleting the QR.</small></span></label>
    <div class="row-actions"><button type="button" class="btn secondary" id="dynamicCancel">Cancel</button><button type="submit" class="btn primary">Save</button></div>
  </form>`;
}

function bindDynamicManager(links) {
  const dialog = document.getElementById('dynamicDialog');
  const open = (link = {}) => {
    dialog.innerHTML = dynamicForm(link);
    dialog.showModal();
    document.getElementById('dynamicCancel').onclick = () => dialog.close();
    document.getElementById('dynamicForm').onsubmit = async (event) => {
      event.preventDefault();
      try {
        const existingCode = value('dynamicCode');
        const code = existingCode || randomCode();
        const destination = safeHttpUrl(value('destination'));
        if (!destination) throw new Error('Enter a valid HTTP or HTTPS destination.');
        const androidDestination = optionalHttpUrl(value('androidDestination'));
        const iosDestination = optionalHttpUrl(value('iosDestination'));
        const desktopDestination = optionalHttpUrl(value('desktopDestination'));
        const fallbackDestination = optionalHttpUrl(value('fallbackDestination'));
        await setDoc(doc(db, 'dynamic_links', code), {
          ownerUid: currentUser.uid,
          title: value('dynamicTitle') || 'Dynamic QR',
          destination,
          androidDestination,
          iosDestination,
          desktopDestination,
          fallbackDestination,
          maximumScans: Number(value('maximumScans')) || null,
          scanCount: Number(link.scanCount || 0),
          active: document.getElementById('dynamicActive').checked,
          updatedAt: serverTimestamp(),
        }, {merge: true});
        dialog.close();
        renderDynamicManager();
      } catch (error) {
        alert(error.message);
      }
    };
  };
  document.getElementById('newDynamicBtn').onclick = () => open();
  document.querySelectorAll('[data-edit]').forEach((button) => {
    button.onclick = () => open(links.find((link) => link.code === button.dataset.edit));
  });
  document.querySelectorAll('[data-delete]').forEach((button) => {
    button.onclick = async () => {
      if (!confirm('Delete this dynamic QR? Printed copies will stop working.')) return;
      await deleteDoc(doc(db, 'dynamic_links', button.dataset.delete));
      renderDynamicManager();
    };
  });
}

async function resolveDynamicLink(code) {
  if (!configured) return renderError('Firebase is not configured.');
  const snapshot = await getDoc(doc(db, 'dynamic_links', code.toUpperCase()));
  if (!snapshot.exists()) return renderError('This dynamic QR was not found.');
  const link = snapshot.data();
  if (link.active !== true) return renderError('This dynamic QR is paused.');
  if (link.maximumScans && Number(link.scanCount || 0) >= Number(link.maximumScans)) {
    return renderError('This dynamic QR reached its scan limit.');
  }
  if (link.expiresAt?.toDate && link.expiresAt.toDate() < new Date()) {
    return renderError('This dynamic QR has expired.');
  }

  const ua = navigator.userAgent.toLowerCase();
  let destination = link.destination;
  if (/android/.test(ua) && link.androidDestination) destination = link.androidDestination;
  else if (/iphone|ipad|ipod/.test(ua) && link.iosDestination) destination = link.iosDestination;
  else if (!/mobile/.test(ua) && link.desktopDestination) destination = link.desktopDestination;
  destination ||= link.fallbackDestination;

  if (!safeHttpUrl(destination)) return renderError('The configured destination is invalid.');
  root.innerHTML = shell(`<div class="error panel"><div class="spinner"></div><h2>Opening secure QR destination…</h2><p>${escapeHtml(destination)}</p></div>`);
  setTimeout(() => location.replace(destination), 350);
}

async function renderAnalytics() {
  if (!await requireAccount()) return;
  root.innerHTML = shell(loading('Loading analytics…'));
  bindNavigation();
  const snapshot = await getDoc(doc(db, 'business_analytics', currentUser.uid));
  const data = snapshot.data() || {};
  const metrics = [
    ['Profile views', data.profileViews], ['Unique visitors', data.uniqueVisitors],
    ['Contact saves', data.contactSaves], ['Phone clicks', data.phoneClicks],
    ['WhatsApp clicks', data.whatsappClicks], ['Email clicks', data.emailClicks],
    ['Map clicks', data.mapClicks], ['Product views', data.productViews],
    ['Brochure downloads', data.brochureDownloads], ['UPI clicks', data.upiClicks],
    ['Lead submissions', data.leads], ['Dynamic QR scans', data.dynamicScans],
  ];
  root.innerHTML = shell(`
    <section class="section">
      <div class="section-head"><div><h1>Business analytics</h1><p>Privacy-safe engagement totals generated by the optional production backend.</p></div></div>
      <div class="metrics">${metrics.map(([label, count]) => `<article class="card metric"><strong>${Number(count || 0)}</strong><span>${escapeHtml(label)}</span></article>`).join('')}</div>
      <div class="panel section"><h2>Production analytics</h2><p class="muted">Deploy the included Blaze backend after enabling billing to collect redirect scans, profile actions, leads, expiry and platform routing. The Spark implementation intentionally does not write public counters directly from untrusted clients.</p></div>
    </section>
  `);
  bindNavigation();
}

async function loadMyProfile() {
  const userSnapshot = await getDoc(doc(db, 'users', currentUser.uid));
  const knownSlug = userSnapshot.data()?.businessProfileSlug;
  if (knownSlug) {
    const profileSnapshot = await getDoc(doc(db, 'business_profiles', knownSlug));
    if (profileSnapshot.exists()) return profileSnapshot.data();
  }
  const result = await getDocs(
    query(collection(db, 'business_profiles'), where('ownerUid', '==', currentUser.uid), limit(1)),
  );
  return result.empty ? null : result.docs[0].data();
}

async function loadEntitlement() {
  const snapshot = await getDoc(doc(db, 'entitlements', currentUser.uid));
  return snapshot.exists() ? snapshot.data() : {active: false, plan: 'free'};
}

function defaultProfile() {
  return {
    slug: '', name: '', title: '', company: '',
    coverUrl: '', photoUrl: '', logoUrl: '',
    phone: '', whatsapp: '', email: currentUser?.email || '',
    website: '', address: '', mapUrl: '',
    services: [], products: [], priceList: [], galleryUrls: [], videoUrls: [],
    brochureUrl: '', upiId: '', reviewUrl: '', leadFormUrl: '',
    appointmentUrl: '', openingHours: '', branchLocations: [],
    languages: [], testimonials: [], certifications: [], offers: [],
    socialLinks: {}, template: 'professional', primaryColor: '#2563EB',
    published: false,
  };
}

function templates() {
  return [
    ['professional', 'Individual professional'], ['employee', 'Company employee'],
    ['freelancer', 'Freelancer'], ['shop', 'Shop & catalogue'],
    ['restaurant', 'Restaurant & menu'], ['doctor', 'Doctor / clinic'],
    ['lawyer', 'Lawyer'], ['realestate', 'Real-estate agent'],
    ['teacher', 'Teacher'], ['student', 'Student portfolio'],
    ['event', 'Event organizer'], ['photographer', 'Photographer'],
    ['influencer', 'Influencer'], ['hotel', 'Hotel'],
    ['school', 'School'], ['emergency', 'Emergency profile'],
  ];
}

function field(id, label, current = '', type = 'text', helper = '') {
  return `<div class="field"><label for="${id}">${escapeHtml(label)}</label><input id="${id}" type="${type}" value="${escapeAttribute(current)}" ${helper ? `placeholder="${escapeAttribute(helper)}"` : ''}></div>`;
}

function uploadField(id, label, current, accept) {
  return `<div class="field"><label for="${id}">${escapeHtml(label)}</label><div class="upload-row"><input id="${id}" type="url" value="${escapeAttribute(current)}"><input class="hidden" id="${id}File" type="file" accept="${escapeAttribute(accept)}"><button type="button" class="btn secondary" onclick="document.getElementById('${id}File').click()">Choose</button><button type="button" class="btn secondary" data-upload="${id}">Upload</button></div></div>`;
}

function textarea(id, label, current = '', rows = 3) {
  return `<div class="field"><label for="${id}">${escapeHtml(label)}</label><textarea id="${id}" rows="${rows}">${escapeHtml(current || '')}</textarea></div>`;
}

function selectField(id, label, current, options) {
  return `<div class="field"><label for="${id}">${escapeHtml(label)}</label><select id="${id}">${options.map(([option, text]) => `<option value="${escapeAttribute(option)}" ${option === current ? 'selected' : ''}>${escapeHtml(text)}</option>`).join('')}</select></div>`;
}

function actionLink(icon, label, href, action) {
  const safe = safeActionUrl(href);
  if (!safe) return '';
  return `<a class="action" href="${escapeAttribute(safe)}" target="_blank" rel="noopener" data-action="${escapeAttribute(action)}"><span>${icon}</span>${escapeHtml(label)}</a>`;
}

function section(title, content) {
  return `<section class="profile-section"><h3>${escapeHtml(title)}</h3>${content}</section>`;
}

function listSection(title, items) {
  const list = Array.isArray(items) ? items : parseLines(items || '');
  if (!list.length) return '';
  return section(title, `<div class="list">${list.map((item) => `<div class="list-item">${escapeHtml(item)}</div>`).join('')}</div>`);
}

function gallerySection(items) {
  const list = (Array.isArray(items) ? items : [])
    .map((url) => safeHttpUrl(url))
    .filter(Boolean);
  if (!list.length) return '';
  return section('Gallery', `<div class="gallery">${list.map((url) => `<img src="${escapeAttribute(url)}" alt="" loading="lazy">`).join('')}</div>`);
}

function socialSection(map) {
  if (!map || typeof map !== 'object' || !Object.keys(map).length) return '';
  const links = Object.entries(map)
    .map(([name, url]) => [name, safeHttpUrl(url)])
    .filter(([, url]) => Boolean(url));
  if (!links.length) return '';
  return section('Social links', `<div class="chips">${links.map(([name, url]) => `<a class="chip" href="${escapeAttribute(url)}" target="_blank" rel="noopener">${escapeHtml(name)}</a>`).join('')}</div>`);
}

function loading(text) {
  return `<div class="boot"><div class="spinner"></div><strong>${escapeHtml(text)}</strong></div>`;
}

function renderError(message) {
  root.innerHTML = shell(`<div class="error panel"><h1>QR AJN</h1><p>${escapeHtml(message)}</p><a class="btn primary" href="/" data-nav>Go home</a></div>`);
  bindNavigation();
}

function value(id) {
  return document.getElementById(id)?.value?.trim() || '';
}

function parseLines(text) {
  return String(text || '').split(/\r?\n/).map((item) => item.trim()).filter(Boolean);
}

function parseMap(text) {
  const result = {};
  parseLines(text).forEach((line) => {
    const separator = line.indexOf('=');
    if (separator <= 0) return;
    const key = line.slice(0, separator).trim();
    const val = line.slice(separator + 1).trim();
    if (key && val) result[key] = val;
  });
  return result;
}

function lines(value) {
  return Array.isArray(value) ? value.join('\n') : value || '';
}

function mapLines(value) {
  return value && typeof value === 'object'
    ? Object.entries(value).map(([key, val]) => `${key}=${val}`).join('\n')
    : '';
}

function normalizeSlug(value) {
  return String(value || '').trim().toLowerCase()
    .replace(/[^a-z0-9_-]+/g, '-').replace(/-+/g, '-').replace(/^-|-$/g, '');
}

function randomCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return Array.from({length: 8}, () => alphabet[Math.floor(Math.random() * alphabet.length)]).join('');
}

function safeHttpUrl(value) {
  try {
    const url = new URL(String(value || '').trim());
    return ['https:', 'http:'].includes(url.protocol) ? url.href : '';
  } catch {
    return '';
  }
}

function optionalHttpUrl(value) {
  const text = String(value || '').trim();
  if (!text) return '';
  const safe = safeHttpUrl(text);
  if (!safe) throw new Error(`Invalid HTTP or HTTPS URL: ${text}`);
  return safe;
}

function safeActionUrl(value) {
  try {
    const url = new URL(String(value || '').trim());
    return ['https:', 'http:', 'tel:', 'mailto:', 'upi:'].includes(url.protocol)
      ? url.href
      : '';
  } catch {
    return '';
  }
}

function safeColour(value) {
  return /^#[0-9A-Fa-f]{6}$/.test(value || '') ? value : '#2563EB';
}

function digits(value) {
  return String(value || '').replace(/\D/g, '');
}

function escapeVcard(value) {
  return String(value || '').replace(/([,;\\])/g, '\\$1').replace(/\r?\n/g, '\\n');
}

function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>"']/g, (character) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;',
  })[character]);
}

function escapeAttribute(value) {
  return escapeHtml(value).replace(/`/g, '&#096;');
}
