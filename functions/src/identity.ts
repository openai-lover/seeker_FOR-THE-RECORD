import {PublicKey} from '@solana/web3.js';
import {z} from 'zod';
import {Fault, requireThat, uidFor} from './domain.js';

/** A Firebase UID created by this service; safe as one Firestore document ID. */
export const walletUid = z.string().regex(/^[a-f0-9]{64}$/);

/** A canonical, 32-byte Solana public key encoded as base58. */
export const walletKey = z.string().min(32).max(44).refine(value => {
  try {
    return new PublicKey(value).toBase58() === value;
  } catch {
    return false;
  }
});

export type WalletIdentity = {uid: string; wallet: string};

/**
 * Bind an Auth UID to the wallet stored in its single user document.
 *
 * This intentionally runs after the UID shape check but before the caller can
 * use either value as an authenticated identity.  The UID regex makes slashes
 * and nested Firestore paths impossible; the hash comparison prevents a valid
 * wallet from being substituted under somebody else's UID.
 */
export function verifiedWalletIdentity(uid: unknown, wallet: unknown): WalletIdentity {
  const parsedUid = walletUid.safeParse(uid);
  requireThat(parsedUid.success, 'sign-in-expired', 401);
  const parsedWallet = walletKey.safeParse(wallet);
  requireThat(parsedWallet.success, 'sign-in-required', 401);
  requireThat(uidFor(parsedWallet.data) === parsedUid.data, 'sign-in-required', 401);
  return {uid: parsedUid.data, wallet: parsedWallet.data};
}

export function verifiedTokenUid(uid: unknown): string {
  const parsed = walletUid.safeParse(uid);
  if (!parsed.success) throw new Fault('sign-in-expired', 401);
  return parsed.data;
}
