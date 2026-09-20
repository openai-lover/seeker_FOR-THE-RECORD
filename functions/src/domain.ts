import {createHash, randomBytes} from 'node:crypto';
import nacl from 'tweetnacl';
import bs58 from 'bs58';

export class Fault extends Error {
  constructor(public code: string, public status = 400) { super(code); }
}
export function requireThat(value: unknown, code: string, status = 400): asserts value {
  if (!value) throw new Fault(code, status);
}
export const uidFor = (wallet: string) => createHash('sha256').update(wallet).digest('hex');
export const randomId = () => randomBytes(18).toString('hex');
export const SGT_AUTHORITY = 'GT2zuHVaZQYZSyQMgJPLzvkmyztfyXg2NJunqFp4p3A4';
export const SGT_GROUP = 'GT22s89nU4iWFkNXj1Bw6uYhJJWDRPpShHt4Bk8f99Te';
export const SKR_MINT = 'SKRbvo6Gf7GondiT3BbTfuRDPqLWei4j2Qy2NPGZhW3';
export const SKU = 'shared-exhibition-v1';
export type Challenge = {
  wallet: string; domain: string; uri: string; nonce: string;
  issuedAt: number; expiresAt: number; consumed: boolean;
};
export function siwsMessage(c: Challenge): string {
  return `${c.domain} wants you to sign in with your Solana account:\n${c.wallet}\n\nSign in to FOR THE RECORD. This does not authorize any transfer.\n\nURI: ${c.uri}\nVersion: 1\nChain ID: mainnet\nNonce: ${c.nonce}\nIssued At: ${new Date(c.issuedAt).toISOString()}\nExpiration Time: ${new Date(c.expiresAt).toISOString()}`;
}
export function verifyChallenge(c: Challenge, input: {wallet: string; message: string; signature: string}, domain: string, uri: string, now: number) {
  requireThat(!c.consumed, 'nonce-used', 409);
  requireThat(now >= c.issuedAt && now < c.expiresAt, 'challenge-expired', 401);
  requireThat(c.domain === domain && c.uri === uri, 'domain-mismatch', 401);
  requireThat(c.wallet === input.wallet, 'account-changed', 401);
  requireThat(input.message === siwsMessage(c), 'message-mismatch', 401);
  let valid = false;
  try { valid = nacl.sign.detached.verify(Buffer.from(input.message), Buffer.from(input.signature, 'base64'), bs58.decode(c.wallet)); } catch { /* malformed keys are invalid */ }
  requireThat(valid, 'invalid-signature', 401);
}
export type SgtEvidence = {program: string; balance: bigint; authority?: string; metadataAuthority?: string; metadataAddress?: string; group?: string};
export function validSgt(e: SgtEvidence) {
  return e.program === 'TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb' && e.balance > 0n && e.authority === SGT_AUTHORITY && e.metadataAuthority === SGT_AUTHORITY && e.metadataAddress === SGT_GROUP && e.group === SGT_GROUP;
}
export type Seat = {uid: string; sgtMint: string; category: string; ready: boolean; finished: boolean; left: boolean};
export type Room = {host: string; seats: Seat[]; memberUids: string[]; status: 'waiting'|'ready'|'running'|'finished'|'expired'|'cancelled'; expiresAt: number; startAt: number|null; durationSec: number; pack: boolean};
export function joinRoom(room: Room, seat: Seat, now: number): Room {
  requireThat(now < room.expiresAt, 'room-expired', 410);
  requireThat(['waiting','ready'].includes(room.status), 'room-already-started', 409);
  if (room.memberUids.includes(seat.uid)) return room;
  requireThat(room.seats.length < 2, 'room-full', 409);
  requireThat(!room.seats.some(s => s.sgtMint === seat.sgtMint), 'same-sgt', 409);
  return {...room, seats: [...room.seats, seat], memberUids: [...room.memberUids, seat.uid]};
}
export function changeRoom(room: Room, uid: string, action: string, now: number): Room {
  const seats = room.seats.map(s => ({...s}));
  const seat = seats.find(s => s.uid === uid);
  requireThat(seat, 'not-a-member', 403);
  if (action === 'finish' && seat.finished) return room;
  requireThat(!['cancelled','expired','finished'].includes(room.status), 'room-closed', 409);
  if (room.startAt === null) requireThat(now < room.expiresAt, 'room-expired', 410);
  if (action === 'ready') {
    requireThat(['waiting','ready'].includes(room.status) && !seat.left, 'invalid-state', 409);
    seat.ready = !seat.ready;
    return {...room, seats, status: seats.length === 2 && seats.every(s => s.ready && !s.left) ? 'ready' : 'waiting'};
  }
  if (action === 'start') {
    requireThat(uid === room.host, 'host-only', 403);
    if (room.status === 'running') return room;
    requireThat(room.status === 'ready' && seats.length === 2 && seats.every(s => s.ready && !s.left), 'both-must-be-ready', 409);
    return {...room, status: 'running', startAt: now + 3000};
  }
  if (action === 'finish') {
    requireThat(room.status === 'running', 'invalid-state', 409);
    seat.finished = true;
    return {...room, seats, status: seats.every(s => s.finished || s.left) ? 'finished' : 'running'};
  }
  if (action === 'leave') {
    seat.left = true;
    return {...room, seats, status: room.startAt === null ? 'cancelled' : seats.every(s => s.left || s.finished) ? 'finished' : 'running'};
  }
  throw new Fault('unknown-action');
}

export type Order = {uid: string; wallet: string; sku: string; mint: string; amountAtomic: string; decimals: number; recipient: string; recipientAta: string; sourceAta: string; reference: string; expiresAt: number; createdAt: number; messageBase64: string; transactionBase64: string; blockhash: string; lastValidBlockHeight: number; status: 'pending'|'paid'|'expired'; signature?: string};
export type Receipt = {messageBase64: string; error: unknown; blockTime: number|null; signers: string[]; mint: string; amountAtomic: string; recipientAta: string; sourceAta: string; reference: string};
export function verifyReceipt(order: Order, receipt: Receipt) {
  requireThat(receipt.error === null, 'transaction-failed', 409);
  // Quote expiry prevents initial submission; it must not reject money already
  // transferred by the exact authorized message while its blockhash was valid.
  requireThat(receipt.blockTime !== null && receipt.blockTime * 1000 >= order.createdAt - 30000, 'transaction-outside-order', 409);
  requireThat(receipt.messageBase64 === order.messageBase64, 'transaction-mismatch', 409);
  requireThat(receipt.signers.length === 1 && receipt.signers[0] === order.wallet, 'wrong-signer', 403);
  requireThat(receipt.mint === order.mint && receipt.amountAtomic === order.amountAtomic && receipt.recipientAta === order.recipientAta && receipt.sourceAta === order.sourceAta && receipt.reference === order.reference, 'wrong-transfer', 409);
}
