import test from 'node:test';
import assert from 'node:assert/strict';
import bs58 from 'bs58';
import {ActivityService, SolanaActivityProvider, normalizeActivity, JUPITER, WSOL} from '../src/activity.js';
const wallet='11111111111111111111111111111111';
const source='SysvarRent111111111111111111111111111111111';
const destination='SysvarC1ock11111111111111111111111111111111';
const usdc='EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';
const token='TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
const signature=bs58.encode(new Uint8Array(64).fill(7));
const info={signature,blockTime:1700000000,err:null};
const config=()=>({computeUnitLimit:30000,heapSize:null,loadedAccountsDataSizeLimit:200000,priorityFee:2500});
function fixture(version:unknown='legacy',transactionConfig?:unknown) {
  const balance=(accountIndex:number,mint:string,amount:string,decimals:number)=>({
    accountIndex,mint,owner:wallet,programId:token,uiTokenAmount:{amount,decimals}});
  return {version,blockTime:1700000000,transaction:{signatures:[signature],message:{
    ...(transactionConfig===undefined?{}:{transactionConfig}),
    accountKeys:[wallet,source,destination].map((pubkey,index)=>({pubkey,signer:index===0,writable:true})),
    instructions:[{programId:JUPITER,accounts:[token,wallet,source,destination],
      data:bs58.encode(Buffer.from([229,23,203,151,122,227,173,42,0,0,0,0]))}]}},
    meta:{err:null as unknown,fee:7500,preTokenBalances:[balance(1,usdc,'300000000',6),balance(2,WSOL,'0',9)],
      postTokenBalances:[balance(1,usdc,'50000000',6),balance(2,WSOL,'1420000000',9)]}};
}
for(const version of ['legacy',0,1]) {
  test('known version '+version+' preserves swap evidence and meta fee',()=>{
    const a=normalizeActivity(wallet,info,fixture(version,version===1?config():undefined));
    assert.equal(a.type,'swap');assert.equal(a.status,'success');
    assert.equal(a.input!.amount,'250');assert.equal(a.output!.amount,'1.42');
    assert.equal(a.fee,'0.0000075');
  });
}
for(const [name,version] of Object.entries({
  future:2,negative:-1,string:'1',null:null,boolean:true,floating:1.5,object:{},array:[],
})) {
  test('unknown/malformed '+name+' version has no assets',()=>{
    const a=normalizeActivity(wallet,info,fixture(version,config()));
    assert.equal(a.status,'unavailable');assert.equal(a.type,'other');
    assert.equal(a.issue,'parse-unavailable');assert.equal(a.fee,null);
    assert.equal(a.input,null);assert.equal(a.output,null);
  });
}
test('missing version, absent v1 config and legacy/v0 config mismatches fail closed',()=>{
  const {version:_omitted,...missing}=fixture();
  for(const tx of [missing,fixture(1),fixture('legacy',null),fixture(0,config())]) {
    assert.equal(normalizeActivity(wallet,info,tx).status,'unavailable');
  }
});
const {heapSize:_missing,...missingField}=config();
for(const [name,value] of Object.entries({
  null:null,array:[],string:'config',missingField,extra:{...config(),futureBudget:1},
  negative:{...config(),computeUnitLimit:-1},floating:{...config(),computeUnitLimit:1.5},
  tooLarge:{...config(),loadedAccountsDataSizeLimit:4294967296},booleanHeap:{...config(),heapSize:true},
  stringPriority:{...config(),priorityFee:'2500'},negativePriority:{...config(),priorityFee:-1},
  floatingPriority:{...config(),priorityFee:1.5},unsafePriority:{...config(),priorityFee:9007199254740992},
})) {
  test('malformed v1 config '+name+' is not classified',()=>{
    const a=normalizeActivity(wallet,info,fixture(1,value));
    assert.equal(a.status,'unavailable');assert.equal(a.type,'other');assert.equal(a.fee,null);
  });
}
test('nullable bounded config shapes never replace total meta fee',()=>{
  const a=normalizeActivity(wallet,info,fixture(1,{
    computeUnitLimit:4294967295,heapSize:null,loadedAccountsDataSizeLimit:0,priorityFee:null}));
  assert.equal(a.type,'swap');assert.equal(a.fee,'0.0000075');
});
test('v1 retains authority, endpoint, balance and compound rejections',()=>{
  const txs=[fixture(1,config()),fixture(1,config()),fixture(1,config()),fixture(1,config())];
  txs[0]!.transaction.message.instructions[0]!.accounts[1]=source;
  txs[1]!.meta.preTokenBalances[0]!.owner=source;
  txs[2]!.meta.postTokenBalances[1]!.programId=source;
  txs[3]!.transaction.message.instructions.push({programId:wallet,accounts:[],data:''});
  for(const tx of txs)assert.equal(normalizeActivity(wallet,info,tx).type,'other');
});
test('future RPC version unavailable; failed listings never fetched',async t=>{
  const methods:string[]=[];
  t.mock.method(globalThis,'fetch',async (_url:unknown,init?:RequestInit)=>{
    const body=JSON.parse(init!.body as string);methods.push(body.method);
    let result:unknown;
    if(body.method==='getGenesisHash')result='5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp';
    else if(body.method==='getSignaturesForAddress')result=[info,{...info,signature:bs58.encode(new Uint8Array(64).fill(8)),err:{failed:true}}];
    else if(body.method==='getTransaction') {
      assert.equal(body.params[1].maxSupportedTransactionVersion,1);
      assert.equal(typeof body.params[1].maxSupportedTransactionVersion,'number');
      return new Response(JSON.stringify({error:{code:-32015}}),{status:200});
    } else throw new Error('Unexpected method');
    return new Response(JSON.stringify({result}),{status:200});
  });
  const service=new ActivityService(async()=>({uid:'synthetic',wallet}),async()=>{},()=>new SolanaActivityProvider('https://rpc.example.invalid'));
  const page=await service.query('synthetic-token',{});
  assert.equal(page.items[0]!.status,'unavailable');assert.equal(page.items[1]!.status,'failed');
  assert.deepEqual(methods,['getGenesisHash','getSignaturesForAddress','getTransaction']);
});
