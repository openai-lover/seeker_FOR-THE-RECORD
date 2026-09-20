import test from 'node:test';
import assert from 'node:assert/strict';
import bs58 from 'bs58';
import {ActivityService, normalizeActivity, decimal, JUPITER, WSOL, type SignatureInfo} from '../src/activity.js';
import {Fault} from '../src/domain.js';
const wallet='11111111111111111111111111111111';
const usdc='EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';
const src='SysvarRent111111111111111111111111111111111';
const dst='SysvarC1ock11111111111111111111111111111111';
const signature=bs58.encode(new Uint8Array(64).fill(7));
const info:SignatureInfo={signature,blockTime:1700000000,err:null};
function fixture() {
  const balance=(accountIndex:number,mint:string,amount:string,decimals:number)=>({accountIndex,mint,owner:wallet,programId:'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA',uiTokenAmount:{amount,decimals}});
  return {blockTime:1700000000,transaction:{signatures:[signature],message:{
    accountKeys:[wallet,src,dst].map((pubkey,index)=>({pubkey,signer:index===0,writable:true})),
    instructions:[{programId:JUPITER,accounts:['TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA',wallet,src,dst],
      data:bs58.encode(Buffer.from([229,23,203,151,122,227,173,42,0,0,0,0]))}]}},
    meta:{err:null as unknown,fee:5000,preTokenBalances:[balance(1,usdc,'300000000',6),balance(2,WSOL,'0',9)],
      postTokenBalances:[balance(1,usdc,'50000000',6),balance(2,WSOL,'1420000000',9)]}};
}
test('Jupiter route endpoints and owner deltas produce an asset-to-asset snapshot',()=>{
  const a=normalizeActivity(wallet,info,fixture());
  assert.equal(a.type,'swap');assert.equal(a.status,'success');
  assert.deepEqual(a.input,{mint:usdc,symbol:'USDC',amount:'250'});
  assert.deepEqual(a.output,{mint:WSOL,symbol:'wSOL',amount:'1.42'});
  assert.equal(a.fee,'0.000005');
});
test('failed signatures and failed metadata can never become a successful swap',()=>{
  assert.equal(normalizeActivity(wallet,{...info,err:{InstructionError:[1,'error']}},fixture()).status,'failed');
  const tx=fixture();tx.meta.err={InstructionError:[1,'error']};
  const a=normalizeActivity(wallet,info,tx);assert.equal(a.status,'failed');assert.equal(a.type,'other');assert.equal(a.input,null);
});
test('unknown program, instruction, missing source ownership, multi-asset and bundles fail closed',()=>{
  const txs=[fixture(),fixture(),fixture(),fixture(),fixture()];
  txs[0]!.transaction.message.instructions[0]!.programId=wallet;
  txs[1]!.transaction.message.instructions[0]!.data=bs58.encode(new Uint8Array(8));
  txs[2]!.meta.preTokenBalances[0]!.owner=src;
  txs[3]!.meta.postTokenBalances.push({...txs[3]!.meta.postTokenBalances[0]!,mint:src});
  txs[4]!.transaction.message.instructions.push({programId:wallet,accounts:[],data:''});
  for(const tx of txs) assert.equal(normalizeActivity(wallet,info,tx).type,'other');
});
test('missing metadata, unsupported future versions and signature mismatch are unavailable',()=>{
  assert.equal(normalizeActivity(wallet,info,null).status,'unavailable');
  assert.equal(normalizeActivity(wallet,info,{}).issue,'parse-unavailable');
  const tx=fixture();tx.transaction.signatures=['different'];
  assert.equal(normalizeActivity(wallet,info,tx).type,'other');
});
test('raw token amounts do not lose precision',()=>{
  assert.equal(decimal(900719925474099300000001n,6),'900719925474099300.000001');
  assert.equal(decimal(0n,9),'0');
});
function harness() {
  const calls:{wallet:string;before?:string}[]=[];let count=0;let transactions=0;
  const service=new ActivityService(async token=>{if(token!=='Bearer alice' && token!=='Bearer bob')throw new Fault('sign-in-required',401);return {uid:token,wallet:token==='Bearer alice'?wallet:src};},
    async (_label,cap)=>{if(++count>cap)throw new Fault('too-many-requests',429);},
    ()=>({signatures:async(address,before)=>{calls.push({wallet:address,before});return Array.from({length:20},(_,i)=>({...info,signature:bs58.encode(new Uint8Array(64).fill(i+1)),err:{failed:true}}));},transaction:async()=>{transactions++;return null;}}));
  return {service,calls,transactions:()=>transactions};
}
test('auth rejects an unauthenticated request before any provider call',async()=>{
  const h=harness();await assert.rejects(h.service.query('',{}),/sign-in-required/);assert.equal(h.calls.length,0);
});
test('wallet is always obtained from authenticated user and body wallet is rejected',async()=>{
  const h=harness();await assert.rejects(h.service.query('Bearer alice',{wallet:src}),/invalid-input/);
  const a=await h.service.query('Bearer alice',{}),b=await h.service.query('Bearer bob',{});
  assert.equal(a.wallet,wallet);assert.equal(b.wallet,src);assert.equal(h.calls[0]!.wallet,wallet);assert.equal(h.calls[1]!.wallet,src);
});
test('page size, exact cursor, failed tx short circuit, per-wallet cache and bounded rate',async()=>{
  const h=harness();const page=await h.service.query('Bearer alice',{});
  assert.equal(page.items.length,20);assert.equal(page.nextCursor,page.items.at(-1)!.signature);assert.equal(h.transactions(),0);
  await h.service.query('Bearer alice',{});assert.equal(h.calls.length,1);
  await h.service.query('Bearer alice',{before:page.nextCursor});assert.equal(h.calls[1]!.before,page.nextCursor);
  for(let i=0;i<3;i++)await h.service.query('Bearer alice',{});
  await assert.rejects(h.service.query('Bearer alice',{}),/too-many-requests/);
});
test('invalid cursor rejected without RPC',async()=>{
  const h=harness();await assert.rejects(h.service.query('Bearer alice',{before:'not-a-signature'}),/invalid-input/);assert.equal(h.calls.length,0);
});
