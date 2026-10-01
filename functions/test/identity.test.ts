import {test} from 'node:test';
import assert from 'node:assert/strict';
import {Keypair} from '@solana/web3.js';
import {uidFor} from '../src/domain.js';
import {verifiedTokenUid, verifiedWalletIdentity} from '../src/identity.js';

const wallet = Keypair.generate().publicKey.toBase58();
const uid = uidFor(wallet);

test('accepts the canonical wallet bound to its SHA-256 UID', () => {
  assert.deepEqual(verifiedWalletIdentity(uid, wallet), {uid, wallet});
});

test('rejects token UIDs that could create a nested or non-user document path', () => {
  for (const candidate of ['users/other', '../other', uid.toUpperCase(), 'a'.repeat(63), `${uid}/rooms/private`]) {
    assert.throws(() => verifiedTokenUid(candidate));
  }
});

test('rejects a valid wallet stored under another UID', () => {
  const otherUid = uidFor(Keypair.generate().publicKey.toBase58());
  assert.throws(() => verifiedWalletIdentity(otherUid, wallet));
});

test('rejects malformed and non-canonical stored wallets', () => {
  assert.throws(() => verifiedWalletIdentity(uid, 'not-a-solana-wallet'));
  assert.throws(() => verifiedWalletIdentity(uid, `1${wallet}`));
});
