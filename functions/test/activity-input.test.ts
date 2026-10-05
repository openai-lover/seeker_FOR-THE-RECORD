import test from 'node:test';
import assert from 'node:assert/strict';
import bs58 from 'bs58';
import {ActivityService, SolanaActivityProvider} from '../src/activity.js';
import {Fault} from '../src/domain.js';

// Synthetic values only. No Firebase, live RPC, wallet, or personal records.
const wallet = '11111111111111111111111111111111';
const cursor = bs58.encode(new Uint8Array(64).fill(7));
const otherWallet = 'SysvarRent111111111111111111111111111111111';

function observedService() {
  const events: string[] = [];
  const calls: {wallet: string; before?: string}[] = [];
  const service = new ActivityService(async token => {
    events.push('authenticate');
    if (token !== 'synthetic-token') throw new Fault('sign-in-required', 401);
    return {uid: 'synthetic-user', wallet};
  }, async () => { events.push('rate-limit'); }, () => {
    events.push('create-provider');
    return {
      signatures: async (address: string, before?: string) => {
        events.push('signatures');
        calls.push({wallet: address, before});
        return [];
      },
      transaction: async () => { throw new Error('unexpected transaction lookup'); },
    };
  });
  return {service, events, calls};
}

const invalidBodies: [string, unknown][] = [
  ['SQL quote/comment', {before: "' OR 1=1 --"}],
  ['SQL union', {before: "x'; UNION SELECT wallet FROM users; --"}],
  ['encoded SQL', {before: '%27%20OR%201%3D1--'}],
  ['JSON-RPC escape text', {before: '\"],\"method\":\"sendTransaction\",\"params\":[\"x'}],
  ['path traversal', {before: '../../users/other'}],
  ['URL in cursor', {before: 'https://attacker.invalid/rpc'}],
  ['operator object', {before: {$ne: null}}],
  ['array cursor', {before: [cursor]}],
  ['numeric cursor', {before: 7}],
  ['null cursor', {before: null}],
  ['empty cursor', {before: ''}],
  ['invalid base58 alphabet', {before: '0OIl'.repeat(22)}],
  ['63-byte decoded cursor', {before: bs58.encode(new Uint8Array(63).fill(7))}],
  ['65-byte decoded cursor', {before: bs58.encode(new Uint8Array(65).fill(7))}],
  ['body wallet override', {before: cursor, wallet: otherWallet}],
  ['body RPC method override', {before: cursor, method: 'sendTransaction'}],
  ['body RPC endpoint override', {before: cursor, url: 'https://attacker.invalid/rpc'}],
  ['body signed transaction', {before: cursor, signedTransaction: 'synthetic'}],
  ['JSON prototype key', JSON.parse('{"__proto__":{"wallet":"other"}}')],
  ['array body', []],
  ['null body', null],
];

test('crafted activity input is rejected before rate-limit, cache access or RPC', async t => {
  for (const [name, body] of invalidBodies) {
    await t.test(name, async () => {
      const h = observedService();
      await assert.rejects(h.service.query('synthetic-token', body),
        (error: unknown) => error instanceof Fault && error.code === 'invalid-input' && error.status === 400);
      assert.deepEqual(h.events, ['authenticate']);
      assert.deepEqual(h.calls, []);
      // Rejection must not poison the cache or modify the next valid request.
      const page = await h.service.query('synthetic-token', {before: cursor});
      assert.equal(page.wallet, wallet);
      assert.deepEqual(h.calls, [{wallet, before: cursor}]);
      assert.deepEqual(h.events, ['authenticate', 'authenticate', 'rate-limit', 'create-provider', 'signatures']);
    });
  }
});

test('authentication failure precedes input validation and provider creation', async () => {
  const h = observedService();
  await assert.rejects(h.service.query('', {before: "' OR 1=1 --"}),
    (error: unknown) => error instanceof Fault && error.code === 'sign-in-required' && error.status === 401);
  assert.deepEqual(h.events, ['authenticate']);
  assert.deepEqual(h.calls, []);
});

test('valid 64-byte cursors retain exact value and authenticated wallet', async () => {
  for (const byte of [0, 1, 7, 127, 255]) {
    const exact = bs58.encode(new Uint8Array(64).fill(byte));
    const h = observedService();
    await h.service.query('synthetic-token', {before: exact});
    await h.service.query('synthetic-token', {before: exact});
    assert.deepEqual(h.calls, [{wallet, before: exact}]);
    assert.equal(h.events.filter(e => e === 'authenticate').length, 2);
    assert.equal(h.events.filter(e => e === 'rate-limit').length, 2);
  }
});

test('accepted input reaches only fixed read-only JSON-RPC methods and structured parameters', async t => {
  const url = 'https://rpc.example.invalid';
  const signature = bs58.encode(new Uint8Array(64).fill(9));
  const requests: {url: unknown; method: string; body: unknown}[] = [];
  t.mock.method(globalThis, 'fetch', async (input: unknown, init?: RequestInit) => {
    assert.equal(typeof init?.body, 'string');
    const body = JSON.parse(init!.body as string);
    requests.push({url: input, method: init?.method ?? '', body});
    let result: unknown;
    if (body.method === 'getGenesisHash') result = '5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp';
    else if (body.method === 'getSignaturesForAddress') result = [{signature, blockTime: 1700000000, err: null}];
    else if (body.method === 'getTransaction') result = null;
    else throw new Error(`Unexpected RPC method: ${body.method}`);
    return new Response(JSON.stringify({jsonrpc: '2.0', id: 1, result}), {status: 200});
  });
  const service = new ActivityService(async () => ({uid: 'synthetic-user', wallet}),
    async () => {}, () => new SolanaActivityProvider(url));
  const page = await service.query('synthetic-token', {before: cursor});
  assert.deepEqual(requests, [
    {url, method: 'POST', body: {jsonrpc: '2.0', id: 1, method: 'getGenesisHash', params: []}},
    {url, method: 'POST', body: {jsonrpc: '2.0', id: 1, method: 'getSignaturesForAddress',
      params: [wallet, {commitment: 'finalized', limit: 20, before: cursor}]}},
    {url, method: 'POST', body: {jsonrpc: '2.0', id: 1, method: 'getTransaction',
      params: [signature, {commitment: 'finalized', encoding: 'jsonParsed', maxSupportedTransactionVersion: 1}]}},
  ]);
  assert.equal(page.items[0]?.status, 'unavailable');
  assert.equal(page.items[0]?.type, 'other');
});
