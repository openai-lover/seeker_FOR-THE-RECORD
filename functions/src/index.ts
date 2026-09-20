import {initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore, Timestamp} from 'firebase-admin/firestore';
import {onRequest} from 'firebase-functions/v2/https';
import {defineSecret, defineString, defineBoolean} from 'firebase-functions/params';
import {createHash, randomBytes} from 'node:crypto';
import {PublicKey} from '@solana/web3.js';
import bs58 from 'bs58';
import {z} from 'zod';
import {Fault, requireThat, randomId, uidFor, siwsMessage, verifyChallenge, joinRoom, changeRoom, SKU, SKR_MINT, type Challenge, type Room, type Order, type Seat} from './domain.js';
import {connection, findSgt, buildOrder, validateSignedOrder, checkReceipt} from './chain.js';

import {ActivityService, SolanaActivityProvider} from './activity.js';

initializeApp();
const db = getFirestore();
const rpcSecret = defineSecret('SOLANA_RPC_URL');
const appDomain = defineString('APP_DOMAIN');
const appUri = defineString('APP_URI');
const payments = defineBoolean('PAYMENTS_ENABLED', {default:false});
const merchant = defineString('MERCHANT_WALLET', {default:''});
const amount = defineString('SKR_AMOUNT_ATOMIC', {default:''});
const key = z.string().min(32).max(44).refine(v => {try {return new PublicKey(v).toBytes().length === 32;} catch {return false;}});
const id = z.string().regex(/^[a-f0-9]{36}$/);
const category = z.enum(['build','design','write','learn','other']);
const parse = <T>(schema: z.ZodType<T>, input: unknown) => {const result = schema.safeParse(input); if (!result.success) throw new Fault('invalid-input'); return result.data;};
const rpc = () => connection(rpcSecret.value());

async function limit(label: string, cap = 30) {
  const window = Math.floor(Date.now()/600000);
  const ref = db.doc(`rateLimits/${createHash('sha256').update(`${label}:${window}`).digest('hex')}`);
  await db.runTransaction(async t => {
    const count = (await t.get(ref)).data()?.count ?? 0;
    requireThat(count < cap, 'too-many-requests', 429);
    t.set(ref, {count: count+1, ttl:Timestamp.fromMillis(Date.now()+1200000)});
  });
}
async function userFor(token: string) {
  requireThat(token.startsWith('Bearer '), 'sign-in-required', 401);
  let decoded;
  try { decoded = await getAuth().verifyIdToken(token.slice(7), true); } catch { throw new Fault('sign-in-expired', 401); }
  const user = (await db.doc(`users/${decoded.uid}`).get()).data();
  requireThat(user?.wallet, 'sign-in-required', 401);
  return {uid:decoded.uid, wallet:user.wallet as string};
}
async function currentSgt(wallet: string) {
  const mint = await findSgt(rpc(), wallet);
  requireThat(mint, 'sgt-not-owned', 403);
  return mint;
}
function seat(uid: string, sgtMint: string, value: string): Seat {return {uid, sgtMint, category:value, ready:false, finished:false, left:false};}
function publicOrder(order: Order, orderId: string) {return {...order, orderId, feeNote:'SOL network fee is separate. No account creation is included.'};}

const activityService = new ActivityService(userFor, limit, () => new SolanaActivityProvider(rpcSecret.value()));

export const api = onRequest({region:'asia-northeast3', secrets:[rpcSecret], cors:false, timeoutSeconds:60, maxInstances:5}, async (req, res) => {
  res.set('Cache-Control', 'no-store');
  try {
    requireThat(req.method === 'POST', 'post-required', 405);
    requireThat(Number(req.headers['content-length'] ?? 0) < 20000, 'request-too-large', 413);
    const action = req.path.replace(/^\//,'');
    if (action === 'challenge') {
      const input = parse(z.object({wallet:key}).strict(), req.body);
      await limit(`ip:${req.ip}`, 15); await limit(`challenge:${input.wallet}`, 10);
      requireThat(new URL(appUri.value()).hostname === appDomain.value() && appUri.value().startsWith('https://') && !appDomain.value().endsWith('.example.com'), 'identity-not-configured', 503);
      const now = Date.now(), challengeId = randomId();
      const challenge: Challenge = {wallet:input.wallet, domain:appDomain.value(), uri:appUri.value(), nonce:randomBytes(16).toString('hex'), issuedAt:now, expiresAt:now+600000, consumed:false};
      await db.doc(`challenges/${challengeId}`).create({...challenge, ttl:Timestamp.fromMillis(now+86400000)});
      res.json({challengeId, message:siwsMessage(challenge), expiresAt:challenge.expiresAt}); return;
    }
    if (action === 'authenticate') {
      const input = parse(z.object({challengeId:id, wallet:key, message:z.string().max(2048), signature:z.string().max(128)}).strict(), req.body);
      await limit(`auth:${input.wallet}`, 20);
      const ref = db.doc(`challenges/${input.challengeId}`), uid = uidFor(input.wallet);
      const snap = await ref.get(); requireThat(snap.exists, 'challenge-missing', 401);
      verifyChallenge(snap.data() as Challenge, input, appDomain.value(), appUri.value(), Date.now());
      // Authentication does not require SGT. Room admission performs fresh chain checks.
      await db.runTransaction(async t => {
        const latest = await t.get(ref); requireThat(latest.exists, 'challenge-missing', 401);
        verifyChallenge(latest.data() as Challenge, input, appDomain.value(), appUri.value(), Date.now());
        t.update(ref, {consumed:true});
        t.set(db.doc(`users/${uid}`), {wallet:input.wallet, signedInAt:Date.now()}, {merge:true});
      });
      res.json({token:await getAuth().createCustomToken(uid), uid, wallet:input.wallet}); return;
    }
    if (action === 'wallet-activity') {
      res.json(await activityService.query(req.headers.authorization ?? '', req.body)); return;
    }
    const user = await userFor(req.headers.authorization ?? '');
    await limit(`user:${user.uid}`, 120);
    const userRef = db.doc(`users/${user.uid}`);
    if (action === 'profile') {
      const data = (await userRef.get()).data()!;
      res.json({wallet:user.wallet, entitlement:data.entitlement === SKU, sgtMint:data.sgtMint ?? null, sgtCheckedAt:data.sgtCheckedAt ?? null, paymentsEnabled:payments.value(), mint:SKR_MINT}); return;
    }
    if (action === 'verify-seeker') {
      const mint = await findSgt(rpc(), user.wallet);
      await userRef.set({sgtMint:mint, sgtCheckedAt:Date.now()}, {merge:true});
      res.json({sgtMint:mint, checkedAt:Date.now()}); return;
    }
    if (action === 'room-create') {
      const input = parse(z.object({category}).strict(), req.body);
      const mint = await currentSgt(user.wallet);
      const roomId = randomId(), code = randomBytes(5).toString('hex').toUpperCase();
      const data = (await userRef.get()).data()!;
      const room:Room = {host:user.uid, seats:[seat(user.uid,mint,input.category)], memberUids:[user.uid], status:'waiting', expiresAt:Date.now()+900000, startAt:null, durationSec:1500, pack:data.entitlement === SKU};
      await db.runTransaction(async t => {
        const u = (await t.get(userRef)).data()!;
        if (u.activeRoomId) {
          const old = (await t.get(db.doc(`rooms/${u.activeRoomId}`))).data() as Room|undefined;
          requireThat(!old || ['finished','cancelled','expired'].includes(old.status) || (old.startAt ? Date.now()>old.startAt+1500000 : Date.now()>old.expiresAt), 'active-room-exists', 409);
        }
        t.create(db.doc(`rooms/${roomId}`),room);
        t.create(db.doc(`invites/${code}`),{roomId, expiresAt:room.expiresAt});
        t.update(userRef,{activeRoomId:roomId, activeRoomCode:code,sgtMint:mint,sgtCheckedAt:Date.now()});
      });
      res.json({roomId,code,...room,serverNow:Date.now()}); return;
    }
    if (action === 'room-join') {
      const input = parse(z.object({code:z.string().regex(/^[A-F0-9]{10}$/),category}).strict(),req.body);
      await limit(`join:${user.uid}`,15);
      const mint = await currentSgt(user.wallet);
      const invite = (await db.doc(`invites/${input.code}`).get()).data();
      requireThat(invite && invite.expiresAt > Date.now(),'invite-invalid-or-expired',410);
      const roomRef = db.doc(`rooms/${invite.roomId}`);
      const room = await db.runTransaction(async t => {
        const snapshot = await t.get(roomRef); requireThat(snapshot.exists,'room-missing',404);
        const u = (await t.get(userRef)).data()!;
        if (u.activeRoomId && u.activeRoomId !== invite.roomId) {
          const old = (await t.get(db.doc(`rooms/${u.activeRoomId}`))).data() as Room|undefined;
          requireThat(!old || ['finished','cancelled','expired'].includes(old.status) || (old.startAt ? Date.now()>old.startAt+1500000 : Date.now()>old.expiresAt),'active-room-exists',409);
        }
        const updated = joinRoom(snapshot.data() as Room,seat(user.uid,mint,input.category),Date.now());
        t.set(roomRef,updated); t.update(userRef,{activeRoomId:invite.roomId, activeRoomCode:input.code,sgtMint:mint,sgtCheckedAt:Date.now()}); return updated;
      });
      res.json({roomId:invite.roomId,code:input.code,...room,serverNow:Date.now()}); return;
    }
    if (action === 'room-current') {
      const u = (await userRef.get()).data()!;
      if (!u.activeRoomId) {res.json({room:null,serverNow:Date.now()});return;}
      const roomRef=db.doc(`rooms/${u.activeRoomId}`);
      const room=await db.runTransaction(async t=>{const data=(await t.get(roomRef)).data();if(data && data.startAt===null && Date.now()>=data.expiresAt && ['waiting','ready'].includes(data.status)){data.status='expired';t.update(roomRef,{status:'expired'});}return data;});
      res.json({room:room ? {...room, roomId:u.activeRoomId,code:u.activeRoomCode} : null,serverNow:Date.now()});return;
    }
    if (action === 'room-action') {
      const input = parse(z.object({roomId:id,action:z.enum(['ready','start','finish','leave'])}).strict(),req.body);
      const roomRef = db.doc(`rooms/${input.roomId}`);
      const updated = await db.runTransaction(async t => {
        const snapshot = await t.get(roomRef); requireThat(snapshot.exists,'room-missing',404);
        const room = changeRoom(snapshot.data() as Room,user.uid,input.action,Date.now());
        t.set(roomRef,room);return room;
      });
      res.json({...updated,roomId:input.roomId,serverNow:Date.now()});return;
    }
    if (action === 'order-create') {
      parse(z.object({}).strict(),req.body);
      requireThat(payments.value(),'payments-not-configured',503);
      await limit(`order:${user.uid}`,10);
      const prior = (await userRef.get()).data()!;
      requireThat(prior.entitlement !== SKU,'already-owned',409);
      if (prior.pendingOrderId) {
        const existing = (await db.doc(`orders/${prior.pendingOrderId}`).get()).data() as Order|undefined;
        if (existing?.status === 'pending') {res.json(publicOrder(existing,prior.pendingOrderId));return;}
      }
      const order = await buildOrder(rpc(),user.uid,user.wallet,merchant.value(),amount.value(),Date.now());
      const orderId = randomId();
      await db.runTransaction(async t => {
        const latest = (await t.get(userRef)).data()!;
        requireThat(latest.pendingOrderId === prior.pendingOrderId && latest.entitlement !== SKU,'order-race-retry',409);
        t.create(db.doc(`orders/${orderId}`),order);t.update(userRef,{pendingOrderId:orderId});
      });
      res.json(publicOrder(order,orderId));return;
    }
    if (action === 'order-submit' || action === 'order-check') {
      const input = parse(z.object({orderId:id,signedTransaction:z.string().max(4096).optional()}).strict(),req.body);
      const ref = db.doc(`orders/${input.orderId}`);
      let order = (await ref.get()).data() as Order|undefined;
      requireThat(order && order.uid === user.uid,'order-not-found',404);
      if (order.status === 'paid') {res.json({status:'paid',signature:order.signature});return;}
      if (action === 'order-submit') {
        requireThat(input.signedTransaction,'signed-transaction-required');
        const tx = validateSignedOrder(order,input.signedTransaction);
        const signature = bs58.encode(tx.signature!);
        await db.runTransaction(async t => {
          const latest = (await t.get(ref)).data() as Order;
          requireThat(latest.status === 'pending','order-closed',409);
          requireThat(!latest.signature || latest.signature === signature,'signature-already-attached',409);
          requireThat(latest.signature || Date.now() < latest.expiresAt,'order-expired',410);
          t.update(ref,{signature});
        });
        order = {...order,signature};
        // Store signature before network I/O. A lost response can always be checked.
        try {await rpc().sendRawTransaction(tx.serialize(),{skipPreflight:false,maxRetries:3});}
        catch {res.json({status:'pending',signature,reason:'submission-uncertain'});return;}
      }
      if (order.signature && await checkReceipt(rpc(),order,order.signature)) {
        await db.runTransaction(async t => {
          const latest = (await t.get(ref)).data() as Order;
          const useRef = db.doc(`receipts/${order.signature}`), use = await t.get(useRef);
          const u = (await t.get(userRef)).data()!;
          let roomRef, room;
          if (u.activeRoomId) {roomRef=db.doc(`rooms/${u.activeRoomId}`);room=(await t.get(roomRef)).data();}
          requireThat(!use.exists || use.data()?.orderId === input.orderId,'signature-reused',409);
          if (latest.status !== 'paid') {
            t.set(useRef,{orderId:input.orderId,uid:user.uid});
            t.update(ref,{status:'paid'});t.update(userRef,{entitlement:SKU,...(u.pendingOrderId===input.orderId?{pendingOrderId:null}:{})});
            if (room && room.host === user.uid && roomRef) t.update(roomRef,{pack:true});
          }
        });
        res.json({status:'paid',signature:order.signature});return;
      }
      if (Date.now() > order.expiresAt && await rpc().getBlockHeight('finalized') > order.lastValidBlockHeight) {
        // A submitted failed or unknown signature must still be resolved at finalized.
        const status = order.signature ? (await rpc().getSignatureStatuses([order.signature],{searchTransactionHistory:true})).value[0] : null;
        if (!status || (status.confirmationStatus === 'finalized' && status.err)) {
          await db.runTransaction(async t => {const latest=(await t.get(ref)).data() as Order;const u=(await t.get(userRef)).data()!;if(latest.status==='pending'){t.update(ref,{status:'expired'});if(u.pendingOrderId===input.orderId)t.update(userRef,{pendingOrderId:null});}});
          res.json({status:'expired',reason:status?.err ? 'transaction-failed':'blockhash-expired'});return;
        }
      }
      res.json({status:'pending',signature:order.signature ?? null});return;
    }
    if (action === 'order-current') {
      const u = (await userRef.get()).data()!;
      const order = u.pendingOrderId ? (await db.doc(`orders/${u.pendingOrderId}`).get()).data() as Order|undefined : undefined;
      res.json({order:order ? publicOrder(order,u.pendingOrderId) : null,owned:u.entitlement === SKU});return;
    }
    if (action === 'account-delete') {
      // Purchase receipts are retained for replay prevention; account/room membership is removed.
      // Page through all memberships; never silently leave older private rooms behind.
      for(;;){const rooms=await db.collection('rooms').where('memberUids','array-contains',user.uid).limit(400).get();if(rooms.empty)break;const batch=db.batch();for(const doc of rooms.docs)batch.delete(doc.ref);await batch.commit();}
      await userRef.delete();
      await getAuth().deleteUser(user.uid);
      res.json({deleted:true,retained:'Public-chain payment receipts and replay-prevention order records; local notes are unchanged.'});return;
    }
    throw new Fault('not-found',404);
  } catch(e) {
    // No request bodies, wallet signatures, personal notes, or RPC URLs in logs.
    if(e instanceof Fault){res.status(e.status).json({error:e.code});return;}
    res.status(503).json({error:'service-unavailable'});
  }
});
