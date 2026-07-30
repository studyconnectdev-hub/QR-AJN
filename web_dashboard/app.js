import {initializeApp} from 'https://www.gstatic.com/firebasejs/12.16.0/firebase-app.js';
import {getAuth, onAuthStateChanged, signInWithEmailAndPassword, createUserWithEmailAndPassword, signInWithPopup, GoogleAuthProvider, sendPasswordResetEmail, signOut} from 'https://www.gstatic.com/firebasejs/12.16.0/firebase-auth.js';
import {getFirestore, doc, getDoc, setDoc, serverTimestamp, collection, query, where, limit, getDocs} from 'https://www.gstatic.com/firebasejs/12.16.0/firebase-firestore.js';
import {firebaseConfig, publicDomain} from './firebase-config.js';

const root = document.getElementById('app');
const configured = firebaseConfig.apiKey && !firebaseConfig.apiKey.startsWith('REPLACE_');
let app, auth, db, currentUser = null, profile = null, entitlement = {active:false, plan:'free'};

if (configured) {
  app = initializeApp(firebaseConfig);
  auth = getAuth(app);
  db = getFirestore(app);
  onAuthStateChanged(auth, user => {
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

function shell(content, {plain=false}={}) {
  if (plain) return content;
  return `<div class="shell">
    <header class="topbar">
      <a class="brand" href="/" data-nav><img src="/app_icon_192.png" alt="QR AJN"><span><strong>QR AJN</strong><small>Digital Business Identity</small></span></a>
      <nav class="nav">
        <a class="btn secondary hide-mobile" href="#features">Features</a>
        <a class="btn secondary" href="/builder" data-nav>${currentUser ? 'Dashboard' : 'Create Profile'}</a>
        ${currentUser ? `<button class="btn primary" id="signOutBtn">Sign out</button>` : `<a class="btn primary" href="/login" data-nav>Sign in</a>`}
      </nav>
    </header>
    ${content}
    <footer class="footer">© 2026 QR AJN • <a href="/privacy.html">Privacy Policy</a> • <a href="/delete-account.html">Delete Account</a> • qrajn.online</footer>
  </div>`;
}

async function route() {
  const path = decodeURIComponent(location.pathname);
  try {
    if (path.startsWith('/@')) return renderPublicProfile(path.slice(2));
    if (path.startsWith('/card/')) return renderPublicProfile(path.slice(6));
    if (path.startsWith('/q/')) return resolveDynamicLink(path.slice(3));
    if (path === '/login') return renderLogin();
    if (path === '/builder' || path === '/dashboard') return renderBuilder();
    renderLanding();
  } catch (error) {
    renderError(error.message || String(error));
  }
  bindGlobal();
}

function bindGlobal() {
  document.querySelectorAll('[data-nav]').forEach(link => link.addEventListener('click', event => {
    const href = link.getAttribute('href');
    if (href?.startsWith('/')) { event.preventDefault(); navigate(href); }
  }));
  document.getElementById('signOutBtn')?.addEventListener('click', () => signOut(auth));
}

function renderLanding() {
  root.innerHTML = shell(`
    <section class="hero">
      <div><span class="status">QR AJN V4 • Firebase-ready</span><h1>One QR for your complete business identity.</h1><p>Create professional digital business cards, editable QR destinations and beautiful profile pages on <strong>qrajn.online</strong>. Your customers can call, message, save contacts, view services, pay by UPI and book appointments without installing an app.</p><div style="display:flex;gap:10px;flex-wrap:wrap;margin-top:20px"><a class="btn secondary" href="/builder" data-nav>Create Business Profile</a><a class="btn primary" href="#features">Explore Features</a></div></div>
      <div class="hero-card"><div class="qr-preview">▦</div><h3 style="text-align:center">qrajn.online/@yourname</h3><p style="font-size:14px;text-align:center">Editable profile • dynamic QR • no reprinting</p></div>
    </section>
    <section class="section" id="features"><div class="section-head"><div><h2>Built for real business workflows</h2><p>More than a digital visiting card.</p></div></div>
      <div class="grid">
        ${feature('⚡','Fast public profiles','Mobile-first pages with call, WhatsApp, email, maps, UPI and save-contact actions.')}
        ${feature('🎨','Professional templates','Individual, employee, shop, restaurant, doctor, portfolio and catalogue layouts.')}
        ${feature('🔁','Editable dynamic QR','Change the destination or profile content without printing a new QR code.')}
        ${feature('🛡️','Safe destination handling','QR AJN validates destinations and shows important actions before redirecting.')}
        ${feature('📈','Business analytics','Blaze-ready scan, click, lead and conversion analytics with privacy controls.')}
        ${feature('💎','Premium tools','Ad-free mobile app, advanced QR gradients, SVG/PDF exports and business features.')}
      </div>
    </section>
    <section class="section"><div class="panel"><div class="section-head"><div><h2>Free scanner. Optional business account.</h2><p>QR AJN mobile scanning and static QR creation stay usable without compulsory login. Sign in only to publish and manage cloud profiles.</p></div><a class="btn primary" href="/builder" data-nav>Start Building</a></div></div></section>
  `);
  bindGlobal();
}

function feature(icon,title,text){return `<article class="card"><div class="feature-icon">${icon}</div><h3>${escapeHtml(title)}</h3><p class="muted">${escapeHtml(text)}</p></article>`}

function renderLogin() {
  if (currentUser) return navigate('/builder');
  root.innerHTML = shell(`<div class="auth-layout">
    <div class="panel"><h1>Manage your QR AJN profile</h1><p class="muted">Create and update your public business identity on qrajn.online.</p><div class="notice">Firebase Email/Password and Google providers must be enabled in Firebase Authentication.</div></div>
    <form class="panel" id="authForm"><div class="tabs"><button type="button" class="tab active" data-mode="login">Sign in</button><button type="button" class="tab" data-mode="register">Create account</button></div>
      <div class="field"><label>Email</label><input id="authEmail" type="email" required autocomplete="email"></div>
      <div class="field"><label>Password</label><input id="authPassword" type="password" required minlength="6" autocomplete="current-password"></div>
      <button class="btn primary" style="width:100%" id="authSubmit">Sign in</button>
      <button class="btn secondary" type="button" style="width:100%;margin-top:10px" id="googleBtn">Continue with Google</button>
      <button class="btn secondary" type="button" style="width:100%;margin-top:10px" id="resetBtn">Send password reset</button>
      <p id="authMessage" class="muted"></p>
    </form></div>`);
  bindGlobal();
  let mode='login';
  document.querySelectorAll('[data-mode]').forEach(button=>button.onclick=()=>{
    mode=button.dataset.mode;
    document.querySelectorAll('[data-mode]').forEach(item=>item.classList.toggle('active',item===button));
    document.getElementById('authSubmit').textContent=mode==='login'?'Sign in':'Create account';
  });
  document.getElementById('authForm').onsubmit=async event=>{
    event.preventDefault();
    if(!configured) return message('Firebase is not configured. Run ONE_CLICK_FULL_SETUP.ps1.');
    const email=value('authEmail'), password=value('authPassword');
    try{
      if(mode==='login') await signInWithEmailAndPassword(auth,email,password); else await createUserWithEmailAndPassword(auth,email,password);
      navigate('/builder');
    }catch(error){message(error.message)}
  };
  document.getElementById('googleBtn').onclick=async()=>{try{await signInWithPopup(auth,new GoogleAuthProvider());navigate('/builder')}catch(error){message(error.message)}};
  document.getElementById('resetBtn').onclick=async()=>{try{await sendPasswordResetEmail(auth,value('authEmail'));message('Password reset email sent.')}catch(error){message(error.message)}};
  function message(text){document.getElementById('authMessage').textContent=text}
}

async function renderBuilder() {
  if (!configured) {
    root.innerHTML = shell(`<div class="error panel"><h1>Connect Firebase first</h1><p>The website source is complete, but Firebase web configuration has not been generated.</p><p>Run <code>ONE_CLICK_FULL_SETUP.ps1</code> with your Firebase project ID.</p></div>`);
    return bindGlobal();
  }
  if (!currentUser) return navigate('/login');
  root.innerHTML = shell(`<div class="boot"><div class="spinner"></div><strong>Loading your profile…</strong></div>`);
  [profile, entitlement] = await Promise.all([loadMyProfile(), loadEntitlement()]);
  const p = profile || defaultProfile();
  if (!entitlement.active && !profile) p.published = false;
  root.innerHTML = shell(`<div class="dashboard">
    <form class="panel" id="profileForm"><h2>Business profile builder</h2><p class="muted">Publish a mobile-first profile and QR destination.</p>
      <div class="notice">${entitlement.active ? `Premium active: ${escapeHtml(entitlement.plan || 'pro')}` : 'Free preview mode: save a private draft now. Activate QR AJN Pro or Business in the Android app before publishing publicly.'}</div>
      ${field('slug','Profile URL',p.slug,'text','qrajn.online/@your-name')}
      ${field('name','Name / business name',p.name)}
      ${field('title','Professional title',p.title)}
      ${field('company','Company',p.company)}
      ${field('photoUrl','Profile photo URL',p.photoUrl,'url')}
      ${field('logoUrl','Logo URL',p.logoUrl,'url')}
      ${field('phone','Phone',p.phone,'tel')}
      ${field('whatsapp','WhatsApp number',p.whatsapp,'tel')}
      ${field('email','Business email',p.email,'email')}
      ${field('website','Website',p.website,'url')}
      ${area('address','Address',p.address)}
      ${field('mapUrl','Map URL',p.mapUrl,'url')}
      ${area('services','Services • one per line',p.services)}
      ${area('products','Products • one per line',p.products)}
      ${field('brochureUrl','Brochure URL',p.brochureUrl,'url')}
      ${field('upiId','UPI ID',p.upiId)}
      ${field('appointmentUrl','Appointment URL',p.appointmentUrl,'url')}
      ${area('socialLinks','Social links • platform=url',socialToText(p.socialLinks))}
      <div class="field"><label>Template</label><select id="template"><option value="aurora">Aurora Professional</option><option value="minimal">Minimal Business</option><option value="restaurant">Restaurant & Menu</option><option value="portfolio">Portfolio & Creator</option><option value="store">Shop & Catalogue</option></select></div>
      <div class="field"><label>Primary colour</label><input id="primaryColor" type="color" value="${escapeAttr(p.primaryColor||'#2563EB')}"></div>
      <label style="display:flex;gap:8px;align-items:center;margin:12px 0"><input id="published" type="checkbox" ${p.published!==false?'checked':''}> Public profile ${entitlement.active ? '' : '• Premium required'}</label>
      <button class="btn primary" style="width:100%" type="submit">${entitlement.active ? 'Publish profile' : 'Save private draft'}</button><p id="saveMessage" class="muted"></p>
    </form>
    <div><div class="panel" style="margin-bottom:16px"><div class="section-head"><div><h2>Live preview</h2><p>Your public link: <strong id="publicUrl">${publicDomain}/@${escapeHtml(p.slug||'your-name')}</strong></p></div><button class="btn secondary" id="copyLink">Copy</button></div></div><div id="profilePreview"></div>
      <div class="panel" style="margin-top:16px"><h3>Editable dynamic QR</h3><p class="muted">Create a short qrajn.online/q/code link. Spark mode resolves it in the browser; the included Blaze backend adds secure redirect analytics and limits.</p>${field('dynamicCode','Short code','','text','example: summer-offer')}${field('dynamicDestination','Destination URL','','url')}<button class="btn secondary" id="createDynamic" type="button">Create dynamic link</button><p id="dynamicMessage" class="muted"></p></div>
    </div>
  </div>`);
  bindGlobal();
  document.getElementById('template').value=p.template||'aurora';
  const refresh=()=>renderProfileCard(readProfileForm(),document.getElementById('profilePreview'));
  document.querySelectorAll('#profileForm input,#profileForm textarea,#profileForm select').forEach(item=>item.addEventListener('input',refresh));
  refresh();
  document.getElementById('profileForm').onsubmit=saveProfile;
  document.getElementById('copyLink').onclick=()=>navigator.clipboard.writeText(document.getElementById('publicUrl').textContent);
  document.getElementById('createDynamic').onclick=createDynamic;
}


async function loadEntitlement(){
  try{
    const snapshot=await getDoc(doc(db,'entitlements',currentUser.uid));
    return snapshot.exists()?snapshot.data():{active:false,plan:'free'};
  }catch{
    return {active:false,plan:'free'};
  }
}

async function loadMyProfile(){
  const q=query(collection(db,'business_profiles'),where('ownerUid','==',currentUser.uid),limit(1));
  const snapshot=await getDocs(q);
  return snapshot.empty?null:snapshot.docs[0].data();
}

function readProfileForm(){
  return {slug:slugify(value('slug')),name:value('name'),title:value('title'),company:value('company'),photoUrl:value('photoUrl'),logoUrl:value('logoUrl'),phone:value('phone'),whatsapp:value('whatsapp'),email:value('email'),website:value('website'),address:value('address'),mapUrl:value('mapUrl'),services:value('services'),products:value('products'),brochureUrl:value('brochureUrl'),upiId:value('upiId'),appointmentUrl:value('appointmentUrl'),socialLinks:textToSocial(value('socialLinks')),template:value('template'),primaryColor:value('primaryColor'),published:document.getElementById('published').checked};
}

async function saveProfile(event){
  event.preventDefault();const p=readProfileForm();const message=document.getElementById('saveMessage');
  if(p.slug.length<3||!p.name){message.textContent='Enter a profile name and a URL with at least 3 characters.';return}
  if(p.published&&!entitlement.active){message.textContent='An active QR AJN Pro or Business entitlement is required to publish. Turn off Public profile to save a private draft.';return}
  const ref=doc(db,'business_profiles',p.slug);const existing=await getDoc(ref);
  if(existing.exists()&&existing.data().ownerUid!==currentUser.uid){message.textContent='That public URL is already taken.';return}
  await setDoc(ref,{...p,ownerUid:currentUser.uid,updatedAt:serverTimestamp()},{merge:true});
  await setDoc(doc(db,'users',currentUser.uid),{businessProfileSlug:p.slug,updatedAt:serverTimestamp()},{merge:true});
  document.getElementById('publicUrl').textContent=`${publicDomain}/@${p.slug}`;message.textContent=p.published?'Profile published successfully.':'Private draft saved successfully.';profile=p;
}

async function createDynamic(){
  const code=slugify(value('dynamicCode')), destination=normalizeUrl(value('dynamicDestination')), message=document.getElementById('dynamicMessage');
  if(code.length<3||!destination){message.textContent='Enter a short code and destination.';return}
  const ref=doc(db,'dynamic_links',code);const existing=await getDoc(ref);
  if(existing.exists()&&existing.data().ownerUid!==currentUser.uid){message.textContent='That code is already taken.';return}
  await setDoc(ref,{ownerUid:currentUser.uid,destination,active:true,label:code,updatedAt:serverTimestamp()},{merge:true});
  message.innerHTML=`Created: <a href="${publicDomain}/q/${code}" target="_blank">${publicDomain}/q/${code}</a>`;
}

async function renderPublicProfile(slug){
  root.innerHTML='<div class="boot"><div class="spinner"></div><strong>Opening profile…</strong></div>';
  if(!configured) return renderError('Firebase is not configured.');
  const snapshot=await getDoc(doc(db,'business_profiles',slugify(slug)));
  if(!snapshot.exists()||snapshot.data().published===false)return renderError('This QR AJN profile is unavailable.');
  const p=snapshot.data();
  root.innerHTML=shell(`<div class="public-wrap"><div id="publicProfile"></div><div class="footer"><a href="/" data-nav>Create your own QR AJN profile</a></div></div>`,{plain:true});
  renderProfileCard(p,document.getElementById('publicProfile'),true);bindGlobal();
}

async function resolveDynamicLink(code){
  root.innerHTML='<div class="boot"><div class="spinner"></div><strong>Checking destination…</strong></div>';
  if(!configured)return renderError('Firebase is not configured.');
  const snapshot=await getDoc(doc(db,'dynamic_links',slugify(code)));
  if(!snapshot.exists())return renderError('Dynamic QR link not found.');
  const data=snapshot.data();
  if(data.active!==true)return renderError('This dynamic QR link is paused.');
  if(data.expiresAt?.toDate&&data.expiresAt.toDate()<new Date())return renderError('This dynamic QR link has expired.');
  const destination=normalizeUrl(data.destination||'');
  if(!/^https?:\/\//i.test(destination))return renderError('The destination is invalid.');
  location.replace(destination);
}

function renderProfileCard(p,target,publicView=false){
  const services=lines(p.services),products=lines(p.products),social=p.socialLinks||{};
  const photo=p.photoUrl||p.logoUrl||'/app_icon_192.png';
  target.innerHTML=`<article class="profile-card" style="--profile:${escapeAttr(p.primaryColor||'#2563EB')}"><div class="cover"></div><div class="profile-content"><img class="avatar" src="${escapeAttr(photo)}" alt="Profile" onerror="this.src='/app_icon_192.png'"><h1>${escapeHtml(p.name||'Your business name')}</h1><p class="muted">${escapeHtml([p.title,p.company].filter(Boolean).join(' • '))}</p>
  <div class="profile-actions">${action(p.phone?`tel:${p.phone}`:'','#','☎','Call')}${action(p.whatsapp?`https://wa.me/${digits(p.whatsapp)}`:'','#','💬','WhatsApp')}${action(p.email?`mailto:${p.email}`:'','#','✉','Email')}${action(p.mapUrl||'','#','📍','Directions')}</div>
  ${p.website?`<p><a href="${escapeAttr(normalizeUrl(p.website))}" target="_blank">${escapeHtml(p.website)}</a></p>`:''}${p.address?`<p>${escapeHtml(p.address)}</p>`:''}
  ${services.length?`<h3>Services</h3><div class="chips">${services.map(x=>`<span class="chip">${escapeHtml(x)}</span>`).join('')}</div>`:''}
  ${products.length?`<h3>Products</h3><div class="list">${products.map(x=>`<div class="list-item">${escapeHtml(x)}</div>`).join('')}</div>`:''}
  <div class="profile-actions">${action(p.brochureUrl||'','#','📄','Brochure')}${action(p.upiId?`upi://pay?pa=${encodeURIComponent(p.upiId)}&pn=${encodeURIComponent(p.name||'QR AJN')}`:'','#','₹','Pay')}${action(p.appointmentUrl||'','#','📅','Book')}${action(p.website||'','#','🌐','Website')}</div>
  ${Object.keys(social).length?`<h3>Social links</h3><div class="chips">${Object.entries(social).map(([name,url])=>`<a class="chip" href="${escapeAttr(normalizeUrl(url))}" target="_blank">${escapeHtml(name)}</a>`).join('')}</div>`:''}
  ${publicView?`<button class="btn primary" id="saveContact" style="width:100%;margin-top:22px">Save Contact</button>`:''}</div></article>`;
  if(publicView)document.getElementById('saveContact')?.addEventListener('click',()=>downloadVcard(p));
}

function action(url,fallback,icon,label){const href=url||fallback;return `<a class="action" href="${escapeAttr(href)}" ${url.startsWith('http')?'target="_blank"':''}><span style="display:block;font-size:22px">${icon}</span>${label}</a>`}
function downloadVcard(p){const data=`BEGIN:VCARD\nVERSION:3.0\nFN:${p.name||''}\nORG:${p.company||''}\nTITLE:${p.title||''}\nTEL:${p.phone||''}\nEMAIL:${p.email||''}\nURL:${p.website||''}\nADR:${(p.address||'').replace(/\n/g,' ')}\nEND:VCARD`;const blob=new Blob([data],{type:'text/vcard'});const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download=`${slugify(p.name||'qrajn-contact')}.vcf`;a.click();URL.revokeObjectURL(a.href)}
function renderError(message){root.innerHTML=shell(`<div class="error panel"><img src="/app_icon_192.png" style="width:90px;border-radius:24px"><h1>QR AJN</h1><p>${escapeHtml(message)}</p><a class="btn primary" href="/" data-nav>Go Home</a></div>`);bindGlobal()}
function field(id,label,val='',type='text',placeholder=''){return `<div class="field"><label for="${id}">${label}</label><input id="${id}" type="${type}" value="${escapeAttr(val||'')}" placeholder="${escapeAttr(placeholder)}"></div>`}
function area(id,label,val=''){return `<div class="field"><label for="${id}">${label}</label><textarea id="${id}" rows="3">${escapeHtml(val||'')}</textarea></div>`}
function value(id){return document.getElementById(id)?.value?.trim()||''}
function lines(text){return String(text||'').split('\n').map(x=>x.trim()).filter(Boolean)}
function digits(text){return String(text||'').replace(/\D/g,'')}
function slugify(text){return String(text||'').toLowerCase().trim().replace(/[^a-z0-9_-]+/g,'-').replace(/-+/g,'-').replace(/^-|-$/g,'').slice(0,48)}
function normalizeUrl(text){const value=String(text||'').trim();if(!value)return'';return /^[a-z][a-z0-9+.-]*:\/\//i.test(value)?value:`https://${value}`}
function textToSocial(text){const output={};lines(text).forEach(line=>{const index=line.indexOf('=');if(index>0)output[line.slice(0,index).trim()]=line.slice(index+1).trim()});return output}
function socialToText(value){return Object.entries(value||{}).map(([key,url])=>`${key}=${url}`).join('\n')}
function defaultProfile(){return{slug:'',name:'',title:'',company:'',photoUrl:'',logoUrl:'',phone:'',whatsapp:'',email:currentUser?.email||'',website:'',address:'',mapUrl:'',services:'',products:'',brochureUrl:'',upiId:'',appointmentUrl:'',socialLinks:{},template:'aurora',primaryColor:'#2563EB',published:true}}
function escapeHtml(value){return String(value??'').replace(/[&<>'"]/g,char=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[char]))}
function escapeAttr(value){return escapeHtml(value)}
