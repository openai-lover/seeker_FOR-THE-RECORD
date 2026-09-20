import {Connection, PublicKey, Transaction, Keypair} from '@solana/web3.js';
import {TOKEN_2022_PROGRAM_ID, TOKEN_PROGRAM_ID, getMint, getMetadataPointerState, getTokenGroupMemberState, getAssociatedTokenAddressSync, createTransferCheckedInstruction, decodeTransferCheckedInstruction, getAccount} from '@solana/spl-token';
import {Fault, requireThat, validSgt, SKR_MINT, SKU, verifyReceipt, type Order} from './domain.js';

export function connection(url: string) {
  requireThat(url.startsWith('https://'), 'rpc-not-configured', 503);
  return new Connection(url, {commitment: 'finalized', confirmTransactionInitialTimeout: 20000});
}
export async function assertMainnet(rpc: Connection) {
  requireThat(await rpc.getGenesisHash() === '5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp', 'wrong-network', 503);
}
export async function findSgt(rpc: Connection, wallet: string): Promise<string|null> {
  try {
    await assertMainnet(rpc);
    // Standard RPC returns the complete set (no provider-specific pagination API).
    const accounts = await rpc.getParsedTokenAccountsByOwner(new PublicKey(wallet), {programId: TOKEN_2022_PROGRAM_ID}, 'finalized');
    for (const account of accounts.value) {
      const info = account.account.data.parsed.info;
      if (info.owner !== wallet || BigInt(info.tokenAmount.amount) <= 0n) continue;
      const address = new PublicKey(info.mint);
      const mint = await getMint(rpc, address, 'finalized', TOKEN_2022_PROGRAM_ID);
      const metadata = getMetadataPointerState(mint);
      const member = getTokenGroupMemberState(mint);
      if (validSgt({program: account.account.owner.toBase58(), balance: BigInt(info.tokenAmount.amount), authority: mint.mintAuthority?.toBase58(), metadataAuthority: metadata?.authority?.toBase58(), metadataAddress: metadata?.metadataAddress?.toBase58(), group: member?.group?.toBase58()})) return address.toBase58();
    }
    return null;
  } catch (e) { if (e instanceof Fault) throw e; throw new Fault('sgt-check-unavailable', 503); }
}
export async function buildOrder(rpc: Connection, uid: string, wallet: string, merchant: string, amount: string, now: number): Promise<Order> {
  await assertMainnet(rpc);
  requireThat(/^[1-9][0-9]{0,18}$/.test(amount) && BigInt(amount) <= 18446744073709551615n, 'price-not-configured', 503);
  const owner = new PublicKey(wallet), recipient = new PublicKey(merchant), mintKey = new PublicKey(SKR_MINT);
  requireThat(!owner.equals(recipient), 'merchant-cannot-buy');
  const mint = await getMint(rpc, mintKey, 'finalized', TOKEN_PROGRAM_ID);
  const sourceAta = getAssociatedTokenAddressSync(mintKey, owner), recipientAta = getAssociatedTokenAddressSync(mintKey, recipient);
  try {
    const source = await getAccount(rpc, sourceAta);
    requireThat(source.amount >= BigInt(amount), 'insufficient-skr', 409);
    await getAccount(rpc, recipientAta);
  } catch (e) { if (e instanceof Fault) throw e; throw new Fault('token-account-missing', 409); }
  const reference = Keypair.generate().publicKey;
  const transfer = createTransferCheckedInstruction(sourceAta, mintKey, recipientAta, owner, BigInt(amount), mint.decimals);
  transfer.keys.push({pubkey: reference, isSigner: false, isWritable: false});
  const latest = await rpc.getLatestBlockhash('finalized');
  const tx = new Transaction({feePayer: owner, ...latest}).add(transfer);
  const fee = (await rpc.getFeeForMessage(tx.compileMessage(), 'finalized')).value;
  requireThat(fee !== null && await rpc.getBalance(owner, 'finalized') >= fee, 'insufficient-sol', 409);
  return {uid, wallet, sku: SKU, mint: SKR_MINT, amountAtomic: amount, decimals: mint.decimals, recipient: merchant, recipientAta: recipientAta.toBase58(), sourceAta: sourceAta.toBase58(), reference: reference.toBase58(), createdAt: now, expiresAt: now + 120000, messageBase64: tx.serializeMessage().toString('base64'), transactionBase64: tx.serialize({requireAllSignatures:false}).toString('base64'), blockhash: latest.blockhash, lastValidBlockHeight: latest.lastValidBlockHeight, status:'pending'};
}
export function validateSignedOrder(order: Order, raw: string) {
  const tx = Transaction.from(Buffer.from(raw, 'base64'));
  requireThat(tx.serializeMessage().toString('base64') === order.messageBase64 && tx.verifySignatures(), 'invalid-signed-order', 403);
  requireThat(tx.signatures.length === 1 && tx.signatures[0]?.publicKey.toBase58() === order.wallet, 'wrong-signer', 403);
  return tx;
}
export async function checkReceipt(rpc: Connection, order: Order, signature: string) {
  await assertMainnet(rpc);
  const receipt = await rpc.getTransaction(signature, {commitment:'finalized', maxSupportedTransactionVersion:0});
  if (!receipt) return false;
  if (receipt.meta?.err) return false;
  const message = receipt.transaction.message;
  requireThat('instructions' in message, 'unsupported-transaction');
  const tx = Transaction.populate(message);
  requireThat(tx.instructions.length === 1, 'unexpected-instructions');
  const instruction = tx.instructions[0]!;
  const transfer = decodeTransferCheckedInstruction(instruction, TOKEN_PROGRAM_ID);
  verifyReceipt(order, {messageBase64: Buffer.from(message.serialize()).toString('base64'), error: receipt.meta?.err ?? (receipt.meta ? null : 'missing-meta'), blockTime:receipt.blockTime ?? null, signers: message.accountKeys.slice(0, message.header.numRequiredSignatures).map(k => k.toBase58()), mint:transfer.keys.mint.pubkey.toBase58(), amountAtomic:transfer.data.amount.toString(), recipientAta:transfer.keys.destination.pubkey.toBase58(), sourceAta:transfer.keys.source.pubkey.toBase58(), reference:instruction.keys[4]?.pubkey.toBase58() ?? ''});
  requireThat(transfer.data.decimals === order.decimals, 'wrong-decimals');
  return true;
}
