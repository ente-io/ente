---
title: Legacy FAQ
description: Common questions about digital inheritance and trusted contact recovery in Ente Locker
---

# Legacy FAQ

Answers to common questions about the Legacy feature for digital inheritance
and account recovery.

## General

### What is Legacy? {#locker-legacy-what-is}

Legacy is Ente's digital inheritance system. It allows you to designate trusted
contacts who can recover your account after a waiting period (7, 14, or 30
days). This ensures your encrypted data can be passed on to loved ones or
recovered if you lose access to your account.

### What happens after the waiting period? {#locker-legacy-waiting-period}

After the waiting period passes without the account owner blocking the recovery:

1. The trusted contact can set a new password for the account
2. They gain full access to the account with the new password
3. All data in the account (Photos, Auth, Locker) becomes accessible

### Can I customize the waiting period? {#locker-legacy-custom-waiting-period}

Yes. You can choose from three waiting period options:

- **7 days**: Faster recovery
- **14 days**: Balanced protection
- **30 days** (default): Maximum protection

Configure this in `Settings > Account > Legacy`.

### Can I have multiple trusted contacts? {#locker-legacy-multiple-contacts}

Yes. You can add multiple trusted contacts. Each can independently initiate
recovery, and any one of them can access your account after the waiting period
if you don't block the recovery.

### What data can trusted contacts access? {#locker-legacy-data-access}

After successful recovery, trusted contacts have full access to your Ente
account, including:

- All Locker items (documents, notes, credentials, physical records)
- All Ente Photos data
- All Ente Auth data

They effectively become the account owner with the ability to view, edit, and
delete content.

## Setting Up Legacy

### How do I add a trusted contact? {#locker-legacy-add-contact}

1. Open Ente Locker
2. Open `Settings > Account > Legacy`
3. Tap **Add Trusted Contact**
4. Enter their Ente email address
5. Wait for them to accept the invite

The contact must have an Ente account to be added.

### Do trusted contacts need an Ente account? {#locker-legacy-need-account}

Yes. Trusted contacts must have their own Ente account. They don't need an
active subscription, but they must have an account to participate in the
Legacy system.

### Why do trusted contacts need to accept the invite? {#locker-legacy-accept-invite}

Accepting the invite confirms that the trusted contact understands their
responsibility and agrees to participate. They can decline if they don't want
the responsibility.

## Recovery Process

### How does a trusted contact initiate recovery? {#locker-legacy-initiate-recovery}

1. Open Ente Locker (or any Ente app)
2. Open `Settings > Account > Legacy`
3. Find the account under Legacy accounts
4. Tap the email address
5. Confirm to initiate recovery

The account owner is immediately notified.

### Can I block a recovery attempt? {#locker-legacy-block-recovery}

Yes. During the waiting period:

1. Open `Settings > Account > Legacy`
2. You'll see a notification about the recovery attempt
3. Tap to block the recovery

Blocking is immediate and stops the recovery process.

### What notifications are sent during recovery? {#locker-legacy-notifications}

When recovery is initiated:

- The account owner receives an email notification immediately
- The account owner sees an alert in the app
- The trusted contact can see the recovery status

### Can I initiate recovery if the account owner is alive? {#locker-legacy-alive-owner}

Technically yes, but the account owner will be notified and can block the
recovery. Only initiate recovery when appropriate (the owner is incapacitated,
deceased, or has requested help).

## Managing Legacy

### How do I remove a trusted contact? {#locker-legacy-remove-contact}

1. Open `Settings > Account > Legacy`
2. Tap on the trusted contact
3. Select **Remove**

They immediately lose the ability to initiate recovery.

### Can I change who my trusted contacts are? {#locker-legacy-change-contacts}

Yes. You can add and remove trusted contacts at any time. There's no limit to
how many trusted contacts you can have.

### What happens if I remove a trusted contact during recovery? {#locker-legacy-remove-during-recovery}

Removing a trusted contact who has initiated recovery will block that recovery
attempt. They lose the ability to complete the recovery.

## Security

### Is Legacy secure? {#locker-legacy-security}

Yes. The waiting period provides protection against unauthorized recovery:

- Account owners are immediately notified of recovery attempts
- Recovery can be blocked at any time during the waiting period
- Trusted contacts must have verified Ente accounts

### What if someone tries to recover my account without permission? {#locker-legacy-unauthorized}

You'll be notified immediately when recovery is initiated. Log in to your
account and block the recovery through `Settings > Account > Legacy`. Consider
removing the trusted contact if the attempt was unauthorized.

### Does Legacy work across all Ente apps? {#locker-legacy-all-apps}

Legacy can be configured in any Ente app and applies to your entire Ente
account. If recovered, the trusted contact gains access to:

- Ente Photos
- Ente Auth
- Ente Locker

## Related Features

- [Legacy feature overview](/locker/features/legacy/)
- [Encryption](/locker/features/security/encryption)
- [Account security FAQ](/locker/faq/security)
