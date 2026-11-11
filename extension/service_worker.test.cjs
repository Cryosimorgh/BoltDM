const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

const script = fs.readFileSync(path.join(__dirname, 'service_worker.js'), 'utf8');

function makeBrowser({ enabled = false, accepted = 1, offline = false } = {}) {
  const activity = { requests: [], cancelled: [], erased: [] };
  let created;
  const chrome = {
    runtime: { id: 'boltdm-test', onMessage: { addListener() {} } },
    storage: { local: { async get() { return { autoCapture: enabled }; } } },
    cookies: { async getAll() { return []; } },
    downloads: {
      onCreated: { addListener(fn) { created = fn; } },
      async search({ id }) { return [{ id, state: 'in_progress' }]; },
      async cancel(id) { activity.cancelled.push(id); },
      async erase({ id }) { activity.erased.push(id); }
    }
  };
  const fetch = async (_url, options) => {
    activity.requests.push(JSON.parse(options.body));
    if (offline) throw new Error('offline');
    return { ok: true, async json() { return { accepted }; } };
  };
  vm.runInNewContext(script, { chrome, fetch, URL, console, navigator: { userAgent: 'Test' } });
  return {
    activity,
    async created(item) {
      created(item);
      await new Promise(resolve => setImmediate(resolve));
    }
  };
}

const file = { id: 42, state: 'in_progress', url: 'https://example.org/file.zip', referrer: 'https://example.org' };

test('auto capture is disabled by default', async () => {
  const app = makeBrowser();
  await app.created(file);
  assert.equal(app.activity.requests.length, 0);
  assert.deepEqual(app.activity.cancelled, []);
});

test('accepted download is sent before browser cancellation', async () => {
  const app = makeBrowser({ enabled: true, accepted: 1 });
  await app.created(file);
  assert.equal(app.activity.requests[0].downloads[0].url, file.url);
  assert.deepEqual(app.activity.cancelled, [42]);
  assert.deepEqual(app.activity.erased, [42]);
});

test('rejected and unreachable handoffs leave browser download intact', async () => {
  for (const config of [{ enabled: true, accepted: 0 }, { enabled: true, offline: true }]) {
    const app = makeBrowser(config);
    await app.created(file);
    assert.deepEqual(app.activity.cancelled, []);
    assert.deepEqual(app.activity.erased, []);
  }
});

test('unsupported schemes and completed browser items are not intercepted', async () => {
  const app = makeBrowser({ enabled: true });
  await app.created({ ...file, url: 'blob:https://example.org/x' });
  await app.created({ ...file, state: 'complete' });
  assert.equal(app.activity.requests.length, 0);
});
