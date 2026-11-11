const API = 'http://127.0.0.1:17654';
const KEY = 'b7a9f4e6b8634a9bbf95c7a84c2d3e71';

function supported(value) {
  try { const u = new URL(value); return u.protocol === 'http:' || u.protocol === 'https:'; }
  catch { return false; }
}

async function cookieHeader(url) {
  try {
    const cookies = await chrome.cookies.getAll({ url });
    return cookies.map(c => `${c.name}=${c.value}`).join('; ');
  } catch { return ''; }
}

async function sendBatch(message) {
  const urls = [...new Set(Array.isArray(message.urls) ? message.urls : [])].filter(supported);
  const downloads = [];
  for (const url of urls) {
    const headers = {};
    const cookie = await cookieHeader(url);
    if (cookie) headers.Cookie = cookie;
    if (message.pageUrl) headers.Referer = message.pageUrl;
    if (message.userAgent) headers['User-Agent'] = message.userAgent;
    const request = { url, headers };
    if (message.engine) request.engine = message.engine;
    downloads.push(request);
  }
  const response = await fetch(`${API}/api/v1/downloads`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-BoltDM-Key': KEY },
    body: JSON.stringify({ downloads })
  });
  if (!response.ok) throw new Error(`BoltDM returned HTTP ${response.status}: ${await response.text()}`);
  return response.json();
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message?.type === 'BOLTDM_DOWNLOAD_BATCH') {
    sendBatch(message).then(r => sendResponse({ ok: true, requested: message.urls?.length || 0, started: r.accepted, failed: r.errors || [] }))
      .catch(e => sendResponse({ ok: false, requested: message.urls?.length || 0, started: 0, failed: [{ error: e.message }] }));
    return true;
  }
  if (message?.type === 'BOLTDM_HEALTH') {
    fetch(`${API}/api/v1/health`).then(r => r.json()).then(r => sendResponse({ ok: !!r.ok })).catch(() => sendResponse({ ok: false }));
    return true;
  }
});


// Opt-in automatic download interception. Never cancel the browser's download
// unless BoltDM has explicitly accepted it.
async function captureDownload(item) {
  if (!item || item.state !== 'in_progress' || item.byExtensionId === chrome.runtime.id) return;
  const { autoCapture = false } = await chrome.storage.local.get({ autoCapture: false });
  if (!autoCapture) return;
  const url = item.finalUrl || item.url;
  if (!supported(url)) return;
  try {
    const result = await sendBatch({ urls: [url], pageUrl: item.referrer || '' });
    if (result.accepted !== 1) return;
    const current = await chrome.downloads.search({ id: item.id });
    if (current.length !== 1 || current[0].state !== 'in_progress') return;
    await chrome.downloads.cancel(item.id);
    await chrome.downloads.erase({ id: item.id });
  } catch (error) {
    console.warn('BoltDM capture failed; keeping browser download:', error);
  }
}

chrome.downloads.onCreated.addListener((item) => { void captureDownload(item); });
