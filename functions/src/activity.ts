import {createHash} from 'node:crypto';
import bs58 from 'bs58';
import {z} from 'zod';
import {Fault, requireThat} from './domain.js';

export const JUPITER = 'JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4';
const TOKEN = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
const COMPUTE = 'ComputeBudget111111111111111111111111111111';
const ASSOCIATED = 'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL';
export const WSOL = 'So11111111111111111111111111111111111111112';
const symbols: Record<string,string> = {
  [WSOL]:'wSOL',
  EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v:'USDC',
  SKRbvo6Gf7GondiT3BbTfuRDPqLWei4j2Qy2NPGZhW3:'SKR',
};
export type Asset = {mint:string; symbol:string; amount:string};
export type WalletActivity = {
  id:string; signature:string; blockTime:number|null; status:'success'|'failed'|'unavailable';
  type:'swap'|'transfer'|'other'; source:string|null; fee:string|null;
  input:Asset|null; output:Asset|null; issue:string|null; explorerUrl:string;
};
export type ActivityPage = {wallet:string; items:WalletActivity[]; nextCursor:string|null};
export type SignatureInfo = {signature:string; blockTime:number|null; err:unknown};
export interface ActivityProvider {
  signatures(wallet:string, before?:string):Promise<SignatureInfo[]>;
  transaction(signature:string):Promise<unknown>;
}
const publicKey = z.string().regex(/^[1-9A-HJ-NP-Za-km-z]{32,44}$/);
const tokenBalance = z.object({accountIndex:z.number().int().nonnegative(),mint:publicKey,
  owner:publicKey.optional(),programId:z.string().optional(),
  uiTokenAmount:z.object({amount:z.string().regex(/^\d+$/),decimals:z.number().int().min(0).max(18)})});
const safeNumber = z.number().int().nonnegative().max(Number.MAX_SAFE_INTEGER);
const transaction = z.object({blockTime:z.number().nullable(), transaction:z.object({signatures:z.array(z.string()),
  message:z.object({accountKeys:z.array(z.object({pubkey:publicKey, signer:z.boolean(),writable:z.boolean()})),
  instructions:z.array(z.object({programId:publicKey,accounts:z.array(z.string()).optional(),data:z.string().optional(),parsed:z.unknown().optional()}))})}),
  meta:z.object({err:z.unknown(),fee:safeNumber,preTokenBalances:z.array(tokenBalance),postTokenBalances:z.array(tokenBalance)})});
export function decimal(amount:bigint, places:number):string {
  const digits=amount.toString().padStart(places+1,'0');
  return places ? `${digits.slice(0,-places)}.${digits.slice(-places)}`.replace(/\.?0+$/,'') : digits;
}
// Only documented v6 route instructions, with their user-authority/source/destination positions.
// No name/log-string matching and no inference from two opposite balances alone.
const routes = [
  {name:'route',authority:1,source:2,destination:3},
  {name:'exact_out_route',authority:1,source:2,destination:3},
  {name:'shared_accounts_route',authority:2,source:3,destination:6},
  {name:'shared_accounts_exact_out_route',authority:2,source:3,destination:6},
].map(r=>({...r,tag:createHash('sha256').update(`global:${r.name}`).digest().subarray(0,8).toString('hex')}));
export function normalizeActivity(wallet:string, info:SignatureInfo, raw:unknown):WalletActivity {
  const base:WalletActivity={id:info.signature,signature:info.signature,blockTime:info.blockTime,status:info.err!=null?'failed':'unavailable',
    type:'other',source:null,fee:null,input:null,output:null,issue:null,explorerUrl:`https://explorer.solana.com/tx/${info.signature}`};
  if(info.err!=null) return base;
  const parsed=transaction.safeParse(raw);
  if(!parsed.success) return {...base,issue:raw==null?'transaction-unavailable':'parse-unavailable'};
  const tx=parsed.data;
  if(tx.transaction.signatures[0]!==info.signature) return {...base,issue:'parse-unavailable'};
  base.fee=decimal(BigInt(tx.meta.fee),9);
  if(tx.meta.err!==null) return {...base,status:'failed'};
  base.status='success';
  const keys=tx.transaction.message.accountKeys;
  if(!keys.some(k=>k.pubkey===wallet && k.signer)) return {...base,issue:'unsupported-activity'};
  const instructions=tx.transaction.message.instructions;
  const jupiter=instructions.filter(i=>i.programId===JUPITER);
  if(jupiter.length!==1) return {...base,issue:'unsupported-activity'};
  const ix=jupiter[0]!;
  let tag='';
  try {tag=Buffer.from(bs58.decode(ix.data??'')).subarray(0,8).toString('hex');} catch {return {...base,issue:'parse-unavailable'};}
  const route=routes.find(r=>r.tag===tag);
  if(!route || !ix.accounts || ix.accounts[route.authority]!==wallet) return {...base,issue:'unsupported-activity'};
  // Reject bundles with external transfers/other protocols: their deltas are not attributable to this swap.
  // Only idempotent ATA creation and compute-budget instructions may surround the single route.
  for(const other of instructions.filter(i=>i!==ix)) {
    if(other.programId===COMPUTE) continue;
    if(other.programId===ASSOCIATED && typeof other.parsed==='object' && other.parsed!==null &&
      (other.parsed as {type?:string}).type==='createIdempotent') continue;
    return {...base,issue:'unsupported-activity'};
  }
  const pre=tx.meta.preTokenBalances, post=tx.meta.postTokenBalances;
  const delta=new Map<string,{value:bigint;decimals:number}>();
  for(const [list,sign] of [[pre,-1n],[post,1n]] as const) {
    for(const b of list) {
      if(b.owner!==wallet) continue;
      if(b.programId && b.programId!==TOKEN) return {...base,issue:'unsupported-activity'};
      const old=delta.get(b.mint);
      if(old && old.decimals!==b.uiTokenAmount.decimals) return {...base,issue:'parse-unavailable'};
      delta.set(b.mint,{value:(old?.value??0n)+sign*BigInt(b.uiTokenAmount.amount),decimals:b.uiTokenAmount.decimals});
    }
  }
  const changed=[...delta].filter(([,d])=>d.value!==0n);
  const input=changed.filter(([,d])=>d.value<0n),output=changed.filter(([,d])=>d.value>0n);
  if(input.length!==1 || output.length!==1) return {...base,issue:'unsupported-activity'};
  const [inMint,inDelta]=input[0]!,[outMint,outDelta]=output[0]!;
  // Prove that the changing assets are the actual route endpoints owned by this wallet.
  const endpoint=(address:string|undefined,mint:string,list:typeof pre)=>list.some(b=>
    keys[b.accountIndex]?.pubkey===address && b.owner===wallet && b.mint===mint);
  if(!endpoint(ix.accounts[route.source],inMint,pre) || !endpoint(ix.accounts[route.destination],outMint,post))
    return {...base,issue:'unsupported-activity'};
  const asset=(mint:string,value:bigint,decimals:number):Asset=>({mint,symbol:symbols[mint]??`${mint.slice(0,4)}…${mint.slice(-4)}`,amount:decimal(value,decimals)});
  return {...base,type:'swap',source:'Jupiter',input:asset(inMint,-inDelta.value,inDelta.decimals),output:asset(outMint,outDelta.value,outDelta.decimals)};
}

/** Read-only standard RPC provider. Intentionally exposes no signing or sending method. */
export class SolanaActivityProvider implements ActivityProvider {
  private readonly signal=AbortSignal.timeout(25000);
  constructor(private readonly url:string) {requireThat(url.startsWith('https://'),'rpc-not-configured',503);}
  private async call(method:string,params:unknown[]):Promise<unknown> {
    for(let attempt=0;attempt<2;attempt++) {
      try {
        const response=await fetch(this.url,{method:'POST',headers:{'Content-Type':'application/json'},
          body:JSON.stringify({jsonrpc:'2.0',id:1,method,params}),signal:AbortSignal.any([this.signal,AbortSignal.timeout(7000)])});
        if(response.status===429 || response.status>=500) {if(attempt===0 && !this.signal.aborted) continue;throw new Fault('rpc-unavailable',503);}
        requireThat(response.ok,'rpc-unavailable',503);
        const body=await response.json() as {result?:unknown;error?:{code?:number}};
        if(body.error?.code===-32015) return null; // Unsupported future transaction version.
        requireThat(!body.error && 'result' in body,'rpc-unavailable',503);
        return body.result;
      } catch(e) {
        if(e instanceof Fault) throw e;
        if(this.signal.aborted || attempt===1) throw new Fault('rpc-timeout',504);
      }
    }
    throw new Fault('rpc-unavailable',503);
  }
  async signatures(wallet:string,before?:string):Promise<SignatureInfo[]> {
    requireThat(await this.call('getGenesisHash',[])==='5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp','wrong-network',503);
    const result=await this.call('getSignaturesForAddress',[wallet,{commitment:'finalized',limit:20,...(before?{before}:{})}]);
    const parsed=z.array(z.object({signature:z.string().regex(/^[1-9A-HJ-NP-Za-km-z]{64,88}$/),blockTime:z.number().nullable(),err:z.unknown()})).max(20).safeParse(result);
    requireThat(parsed.success,'rpc-unavailable',503);
    return parsed.data.map(s => ({...s, err:s.err}));
  }
  transaction(signature:string):Promise<unknown> {return this.call('getTransaction',[signature,{commitment:'finalized',encoding:'jsonParsed',maxSupportedTransactionVersion:0}]);}
}
const request=z.object({before:z.string().refine(s=>{try{return bs58.decode(s).length===64;}catch{return false;}}).optional()}).strict();
export type ActivityUser={uid:string;wallet:string};
export class ActivityService {
  private cache=new Map<string,{until:number;page:ActivityPage}>();
  constructor(private readonly authenticate:(token:string)=>Promise<ActivityUser>,
    private readonly rateLimit:(label:string,cap:number)=>Promise<void>,
    private readonly provider:()=>ActivityProvider,private readonly now:()=>number=Date.now) {}
  async query(token:string,body:unknown):Promise<ActivityPage> {
    const user=await this.authenticate(token);
    const input=request.safeParse(body); requireThat(input.success,'invalid-input');
    await this.rateLimit(`activity:${user.uid}`,6);
    const cacheKey=`${user.uid}:${user.wallet}:${input.data.before??''}`;
    const cached=this.cache.get(cacheKey); if(cached && cached.until>this.now()) return cached.page;
    const provider=this.provider();
    const signatures=await provider.signatures(user.wallet,input.data.before);
    const items:WalletActivity[]=[];
    // Four bounded workers; no unbounded Promise.all over a wallet's full history.
    for(let start=0;start<signatures.length;start+=4) {
      items.push(...await Promise.all(signatures.slice(start,start+4).map(async s=>
        normalizeActivity(user.wallet,s,s.err!=null?null:await provider.transaction(s.signature)))));
    }
    const page={wallet:user.wallet,items,nextCursor:signatures.length===20?signatures.at(-1)!.signature:null};
    if(this.cache.size>=100) this.cache.delete(this.cache.keys().next().value!);
    this.cache.set(cacheKey,{until:this.now()+60000,page});
    return page;
  }
}

