import {test,after,before} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {initializeTestEnvironment,assertFails,assertSucceeds,type RulesTestEnvironment} from '@firebase/rules-unit-testing';
import {doc,setDoc,getDoc,collection,getDocs} from 'firebase/firestore';
import {initializeApp,deleteApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import {joinRoom,type Room} from '../src/domain.js';
let env:RulesTestEnvironment;
const admin=initializeApp({projectId:'demo-workroom'});
const db=getFirestore(admin);
before(async()=>{
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST,'Requires Firestore emulator, never production');
  env=await initializeTestEnvironment({projectId:'demo-workroom',firestore:{rules:readFileSync(new URL('../../firestore.rules',import.meta.url),'utf8')}});
});
after(async()=>{await env?.cleanup();await deleteApp(admin);});
test('Firestore allows only member get; no list or client authority writes',async()=>{
  await env.withSecurityRulesDisabled(async ctx=>{await setDoc(doc(ctx.firestore(),'rooms/private-room'),{memberUids:['host','guest']});await setDoc(doc(ctx.firestore(),'users/host'),{wallet:'wallet'});});
  const host=env.authenticatedContext('host').firestore(),other=env.authenticatedContext('other').firestore();
  await assertSucceeds(getDoc(doc(host,'rooms/private-room')));
  await assertFails(getDoc(doc(other,'rooms/private-room')));
  await assertFails(getDocs(collection(host,'rooms')));
  await assertFails(setDoc(doc(host,'rooms/private-room'),{memberUids:['host'],pack:true}));
  await assertFails(setDoc(doc(host,'users/host'),{entitlement:'shared-exhibition-v1'}));
  await assertFails(getDoc(doc(host,'orders/order')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'rooms/private-room')));
});
test('two concurrent admissions yield one guest and never a third seat',async()=>{
  const seat={uid:'host',sgtMint:'sgt-1',category:'build',ready:false,finished:false,left:false};
  const room:Room={host:'host',seats:[seat],memberUids:['host'],status:'waiting',expiresAt:Date.now()+60000,startAt:null,durationSec:1500,pack:false};
  const ref=db.doc('rooms/race');await ref.set(room);
  const admit=(uid:string,mint:string)=>db.runTransaction(async t=>{const existing=(await t.get(ref)).data() as Room;t.set(ref,joinRoom(existing,{...seat,uid,sgtMint:mint},Date.now()));});
  const results=await Promise.allSettled([admit('a','sgt-2'),admit('b','sgt-3')]);
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);assert.equal((await ref.get()).data()!.seats.length,2);
});
test('atomic nonce consumption permits exactly one concurrent verifier',async()=>{
  const ref=db.doc('challenges/race');await ref.set({consumed:false});
  const consume=()=>db.runTransaction(async t=>{assert.equal((await t.get(ref)).data()!.consumed,false);t.update(ref,{consumed:true});});
  const outcomes=await Promise.allSettled([consume(),consume()]);assert.equal(outcomes.filter(o=>o.status==='fulfilled').length,1);
});
test('atomic signature reservation cannot grant two different orders',async()=>{
  const ref=db.doc('receipts/reused');await ref.delete();
  const consume=(orderId:string)=>db.runTransaction(async t=>{const previous=await t.get(ref);assert.equal(previous.exists,false);t.create(ref,{orderId});});
  const outcomes=await Promise.allSettled([consume('a'),consume('b')]);assert.equal(outcomes.filter(o=>o.status==='fulfilled').length,1);
});
