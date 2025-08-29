# FHE Private IDO Launchpad

A privacy-preserving token sale launchpad built on **Zama’s FHEVM**.  
All contributions and allocations are encrypted end-to-end while settlement remains auditable.

## Why
Public IDOs often suffer from whales front-running, doxxed allocations, and privacy concerns.  
With **Fully Homomorphic Encryption (FHE)** we can accept contributions and compute allocations **on ciphertext**, revealing only the necessary outcomes (e.g., total raised, final allocation proofs) without leaking anyone’s raw numbers.

## Key Features
- 🔒 **Encrypted contributions** — amount and participant data stored as ciphertext on-chain.
- 🗳️ **Policy checks on ciphertext** — caps/whitelists verifiable without exposing user data (FHE).
- 📊 **Transparent aggregates** — totals & events remain auditable.
- 🧩 **Composable** — events/interfaces for indexers and settlement tooling.

## How It Works (High Level)
1. Project creates a sale window (start/end).
2. Users send **encrypted contributions** (`bytes` ciphertext) on-chain.
3. After the window closes, the sale is **finalized**; allocations are computed via FHE and distributed as **encrypted outputs**.
4. Users **claim encrypted allocations**, decrypt locally.

## Contracts
- `contracts/Launchpad.sol` — demo contract that stores encrypted contributions, finalizes a sale, and emits encrypted allocation events.

> **Note:** In a real FHEVM flow, arithmetic and checks are performed on ciphertext. This demo uses `bytes` placeholders and emits events to illustrate the pattern.

## Minimal API
- `createSale(bytes token, uint256 start, uint256 end)`  
- `contributeEncrypted(uint256 saleId, bytes encAmount)`  
- `finalizeSale(uint256 saleId, bytes encSummary)`  
- `claimAllocationEncrypted(uint256 saleId, bytes encAllocation)`

## Roadmap
- Frontend: connect wallet, submit ciphertext, view claim receipt.
- Encrypted whitelists, per-wallet caps, and vesting schedules.
- Merkle proofs for allocation verification (encrypted leaves).
- Settlement adapter to real token contracts on FHEVM.

## Disclaimer
This is a **non-production** proof-of-concept showcasing FHEVM design patterns for launchpads.
