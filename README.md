# Cardio

![87](https://user-images.githubusercontent.com/29115431/193304861-3eb9f323-8d9e-46d9-a539-26565a655832.png)

App for changing Apple Pay images using an integrated DarkSword + KFS workflow.
Current testing baseline: iOS 18.6.2.

Legacy app for changing Apple Pay card artwork. Originally based on the old
CoreTrust/TrollStore era, now adapted for modern exploit-driven workflows.

## Darksword/lara integration status (this branch)

- Cardio now checks at launch whether `/var/mobile/Library/Passes/Cards` is
	writable.
- Cardio now includes darksword + KFS modules directly in-app.
- You can run exploit and KFS from Cardio's own UI (`Run Darksword`, `Init KFS`,
	`Run All`) without launching lara separately.

## Permanence model

- App install permanence depends on your install/signing path, not on darksword.
- Card artwork replacement is persistent on disk after it is written.
- Darksword kernel privileges are session-based; after reboot, run Cardio's
	`Run All` again before making new writes.

## iOS 18.6.2 revival notes

This codebase was originally built for the old CoreTrust/TrollStore era. The
updates in this workspace aim to make the app logic itself usable again on
modern systems, but with an important caveat:

- You still need a method that grants write access to
	`/var/mobile/Library/Passes/Cards` (for example, a jailbreak or an exploit
	flow that enables kernel-backed file writes).

What was updated:

- Removed the external carousel dependency in favor of native `TabView` paging.
- Fixed image path handling so previews and writes use real file paths.
- Fixed PDF replacement flow (it previously wrote to an empty path).
- Added daemon refresh flow (`passd`, `walletd`, `PassbookUIService`) before
	SpringBoard restart fallback.

What this does not include:

- Automatic sandbox escape by itself.

## Recommended workflow (all-in-one in Cardio)

1. Open Cardio and press `Run All`.
2. Wait until exploit/KFS state shows ready.
3. Ensure your environment grants write access to
	`/var/mobile/Library/Passes/Cards`.
4. Pick a card, set an image, and let the app refresh Wallet services.
5. If changes do not appear immediately, re-open Wallet after the UI restart.

## Credits:
cisc0disco (https://github.com/cisc0disco/Cardio)
opa334 (https://github.com/opa334/darksword-kexploit)
rooootdev (https://github.com/rooootdev/lara)
