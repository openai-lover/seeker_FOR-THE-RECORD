// Synthetic unsigned fixture for the Flutter transaction decoder; never submitted.
import {Keypair,PublicKey,Transaction} from '@solana/web3.js';
import {createTransferCheckedInstruction,getAssociatedTokenAddressSync} from '@solana/spl-token';
import {mkdirSync,writeFileSync} from 'node:fs';
import {SKR_MINT} from '../src/domain.js';
const buyer=Keypair.generate().publicKey,merchant=Keypair.generate().publicKey,reference=Keypair.generate().publicKey,mint=new PublicKey(SKR_MINT);
const source=getAssociatedTokenAddressSync(mint,buyer),recipient=getAssociatedTokenAddressSync(mint,merchant);
const ix=createTransferCheckedInstruction(source,mint,recipient,buyer,1234567n,6);ix.keys.push({pubkey:reference,isSigner:false,isWritable:false});
const blockhash=Keypair.generate().publicKey.toBase58();
const tx=new Transaction({feePayer:buyer,recentBlockhash:blockhash}).add(ix);
mkdirSync(new URL('../../test/fixtures/',import.meta.url),{recursive:true});
writeFileSync(new URL('../../test/fixtures/skr_order.json',import.meta.url),JSON.stringify({syntheticFixture:true,wallet:buyer.toBase58(),mint:SKR_MINT,recipient:merchant.toBase58(),recipientAta:recipient.toBase58(),sourceAta:source.toBase58(),reference:reference.toBase58(),blockhash,amountAtomic:'1234567',decimals:6,transactionBase64:tx.serialize({requireAllSignatures:false}).toString('base64')},null,2));
