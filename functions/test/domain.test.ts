import {test} from 'node:test';
import assert from 'node:assert/strict';
import nacl from 'tweetnacl';
import bs58 from 'bs58';
import {siwsMessage,verifyChallenge,validSgt,SGT_AUTHORITY,SGT_GROUP,joinRoom,changeRoom,verifyReceipt, type Challenge,type Room,type Order,type Receipt} from '../src/domain.js';
import {validateSignedOrder} from '../src/chain.js';
import {Keypair,Transaction} from '@solana/web3.js';
import {createTransferCheckedInstruction,getAssociatedTokenAddressSync} from '@solana/spl-token';

const key=nacl.sign.keyPair();
const challenge:Challenge={wallet:bs58.encode(key.publicKey),domain:'workroom.test',uri:'https://workroom.test',nonce:'1234567890abcdef',issuedAt:1000,expiresAt:2000,consumed:false};
const message=siwsMessage(challenge);
const input={wallet:challenge.wallet,message,signature:Buffer.from(nacl.sign.detached(Buffer.from(message),key.secretKey)).toString('base64')};
test('SIWS accepts an exact issued message and valid Ed25519 signature',()=>verifyChallenge(challenge,input,challenge.domain,challenge.uri,1500));
for(const [label,change,request,domain,now] of [
  ['replayed nonce',{consumed:true},{},challenge.domain,1500],
  ['expired challenge',{}, {},challenge.domain,2000],
  ['future issue',{}, {},challenge.domain,999],
  ['domain substitution',{}, {},'evil.test',1500],
  ['different wallet',{}, {wallet:bs58.encode(nacl.sign.keyPair().publicKey)},challenge.domain,1500],
  ['modified signed message',{}, {message:message+' '},challenge.domain,1500],
  ['bad signature',{}, {signature:Buffer.alloc(64).toString('base64')},challenge.domain,1500],
] as const)test(`SIWS rejects ${label}`,()=>assert.throws(()=>verifyChallenge({...challenge,...change},{...input,...request},domain,challenge.uri,now)));

const evidence={program:'TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb',balance:1n,authority:SGT_AUTHORITY,metadataAuthority:SGT_AUTHORITY,metadataAddress:SGT_GROUP,group:SGT_GROUP};
test('SGT accepts all official on-chain fields together',()=>assert.equal(validSgt(evidence),true));
for(const field of ['program','authority','metadataAuthority','metadataAddress','group'] as const)test(`SGT rejects forged ${field}`,()=>assert.equal(validSgt({...evidence,[field]:'fake'}),false));
test('SGT excludes the zero-balance account left by a transfer',()=>assert.equal(validSgt({...evidence,balance:0n}),false));

const host={uid:'host',sgtMint:'sgt-1',category:'build',ready:false,finished:false,left:false};
const guest={...host,uid:'guest',sgtMint:'sgt-2'};
const room:Room={host:'host',seats:[host],memberUids:['host'],status:'waiting',expiresAt:2000,startAt:null,durationSec:1500,pack:false};
test('room accepts only two distinct SGT seats; admission is idempotent',()=>{
  const two=joinRoom(room,guest,1000);assert.equal(two.seats.length,2);
  assert.deepEqual(joinRoom(two,guest,1000),two);
  assert.throws(()=>joinRoom(two,{...guest,uid:'third',sgtMint:'sgt-3'},1000));
  assert.throws(()=>joinRoom(room,{...guest,sgtMint:host.sgtMint},1000));
  assert.throws(()=>joinRoom(room,guest,2000));
});
test('both ready, only host starts; early personal finish does not finish partner',()=>{
  let two=joinRoom(room,guest,1000);
  assert.throws(()=>changeRoom(two,'host','start',1000));
  two=changeRoom(two,'host','ready',1000);two=changeRoom(two,'guest','ready',1000);
  assert.equal(two.status,'ready');assert.throws(()=>changeRoom(two,'guest','start',1000));
  two=changeRoom(two,'host','start',1000);assert.equal(two.startAt,4000);
  assert.deepEqual(changeRoom(two,'host','start',1500),two);
  two=changeRoom(two,'guest','finish',9000);assert.equal(two.status,'running');
  two=changeRoom(two,'host','leave',10000);assert.equal(two.status,'finished');
});
test('room projection has no private notes',()=>{assert.deepEqual(Object.keys(host).sort(),['category','finished','left','ready','sgtMint','uid']);});
const order={wallet:'wallet',messageBase64:'fixed message',createdAt:100000,expiresAt:200000,mint:'skr',amountAtomic:'100',recipientAta:'merchant',sourceAta:'buyer',reference:'ref'} as Order;
const receipt:Receipt={messageBase64:'fixed message',error:null,blockTime:150,signers:['wallet'],mint:'skr',amountAtomic:'100',recipientAta:'merchant',sourceAta:'buyer',reference:'ref'};
test('payment accepts an exact successful receipt',()=>verifyReceipt(order,receipt));
test('delayed finalization honors the exact authorized payment after quote expiry',()=>verifyReceipt(order,{...receipt,blockTime:201}));
test('payment rejects a missing block time',()=>assert.throws(()=>verifyReceipt(order,{...receipt,blockTime:null})));
for(const [field,value] of Object.entries({messageBase64:'changed',error:'failed',blockTime:69,signers:['other'],mint:'fake',amountAtomic:'99',recipientAta:'thief',sourceAta:'other',reference:'other'}))test(`payment rejects ${field} mismatch`,()=>assert.throws(()=>verifyReceipt(order,{...receipt,[field]:value})));
test('signed transaction must preserve the exact order and signer',()=>{
  const buyer=Keypair.generate(),mint=Keypair.generate().publicKey,merchant=Keypair.generate().publicKey;
  const transaction=new Transaction({feePayer:buyer.publicKey,recentBlockhash:Keypair.generate().publicKey.toBase58()}).add(createTransferCheckedInstruction(getAssociatedTokenAddressSync(mint,buyer.publicKey),mint,getAssociatedTokenAddressSync(mint,merchant),buyer.publicKey,1n,6));
  transaction.sign(buyer);
  const valid={...order,wallet:buyer.publicKey.toBase58(),messageBase64:transaction.serializeMessage().toString('base64')};
  assert.doesNotThrow(()=>validateSignedOrder(valid,transaction.serialize().toString('base64')));
  assert.throws(()=>validateSignedOrder({...valid,messageBase64:'changed'},transaction.serialize().toString('base64')));
});
