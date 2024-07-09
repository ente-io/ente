---
title: Security and Privacy FAQ
description: Comprehensive information about security and privacy measures in Ente Photos
---

# Security and Privacy FAQ

Welcome to Ente Photos' Security and Privacy FAQ. This document provides detailed information about our security practices, privacy measures, and how we protect your data. We are committed to maintaining the highest standards of data protection and transparency.

## Data Encryption and Storage

### Can Ente see my photos and videos?
No. Your files are encrypted on your device before being uploaded to our servers. The encryption keys are derived from your password using advanced key derivation functions. Since only you know your password, only you can decrypt your files. For technical details, please see our [architecture document](https://ente.io/architecture).

### How is my data encrypted?
We use state-of-the-art encryption algorithms:
- File encryption: XChaCha20 stream cipher
- Authentication: Poly1305 message authentication code (MAC)
- Key derivation: Argon2id with high memory and computation parameters

These algorithms are implemented using [libsodium](https://libsodium.gitbook.io/doc/), a well-audited cryptographic library. Our [architecture document](https://ente.io/architecture) provides full technical specifications.

### Where is my data stored?
Your encrypted data is stored redundantly across multiple providers in the EU:
- Amsterdam, Netherlands
- Paris, France
- Frankfurt, Germany

We use a combination of object storage and distributed databases to ensure high availability and durability. Our [reliability document](https://ente.io/reliability) provides in-depth information about our storage infrastructure and data replication strategies.

### How does Ente's encryption compare to industry standards?
Our encryption model goes beyond industry standards. While many services use server-side encryption, we implement end-to-end encryption. This means that even in the unlikely event of a server breach, your data remains protected. Our use of XChaCha20 is particularly forward-looking, as it's designed to be quantum-computer resistant.

## Account Security

### How are passwords handled?
Passwords are never stored in plain text. We use the Argon2id algorithm to hash passwords, which is resistant to both computational and memory-hard attacks. The resulting hash is then split and stored across separate systems to further enhance security.

### What happens if I forget my password?
You can reset your password using your recovery key. This key is a randomly generated string provided to you during account creation. Store it securely, as it's your lifeline if you forget your password. If you lose both your password and recovery key, we cannot recover your account or data due to our zero-knowledge architecture.

### Can I change my password?
Yes, you can change your password at any time from our apps. Our architecture allows password changes without re-encrypting your entire library. When you change your password:
1. A new master key is derived from your new password
2. Your file encryption keys are re-encrypted with this new master key
3. The new encrypted keys are uploaded to our servers

### Do you support two-factor authentication (2FA)?
Yes, we strongly recommend enabling 2FA for an additional layer of security. We support:
- Time-based One-Time Passwords (TOTP)
- WebAuthn/FIDO2 for hardware security keys

You can set up 2FA in the settings of our mobile or desktop apps.

## Sharing and Collaboration

### How does sharing work securely?
When you share an album:
1. A new encryption key is generated for the shared album
2. This key is encrypted with the recipient's public key
3. The encrypted key is stored on our servers
4. The recipient can decrypt this key using their private key

For shareable links, the decryption key is included in the URL fragment, which is never sent to our servers. Only paid users can initiate sharing, but recipients can use a free account.

### Are shared albums as secure as private ones?
Shared albums use the same strong encryption as private albums. However, remember that shared content is only as secure as the least secure account with access to it. We recommend sharing only with users who maintain good security practices.

## Security Audits and Compliance

### Has Ente Photos been independently audited?
Yes, Ente Photos underwent a comprehensive security audit by Cure53, a respected German cybersecurity firm, in collaboration with Symbolic Software, specialists in applied cryptography. The full audit report is available [here](https://ente.io/blog/cryptography-audit/). We are committed to regular third-party audits and will publish results transparently.

### Is Ente compliant with privacy regulations?
Yes, Ente is designed to comply with major privacy regulations including GDPR (European Union), CCPA (California), and PIPEDA (Canada). Key compliance measures include:
- Data minimization: We collect only essential data
- Purpose limitation: Your data is used only for providing our service
- Data portability: You can export your data at any time
- Right to erasure: You can permanently delete your account and data

For specific compliance questions, please contact our Data Protection Officer at dpo@ente.io.

## Ongoing Security Practices

### How does Ente handle security vulnerabilities?
We maintain a bug bounty program to encourage responsible disclosure of security vulnerabilities. Our security team promptly investigates all reported issues. Critical vulnerabilities are typically addressed within 24 hours.

### Does Ente perform regular security assessments?
Yes, we conduct:
- Weekly automated security scans of our infrastructure
- Monthly manual penetration testing by our internal security team
- Annual third-party security audits

### How would Ente respond to a data breach?
While we have multiple safeguards to prevent breaches, we maintain an incident response plan:
1. Immediate containment and investigation of the breach
2. Patching of any discovered vulnerabilities
3. Notification to affected users within 72 hours
4. Collaboration with law enforcement if necessary

Remember, due to our encryption model, a server breach would not expose your actual data or passwords.

## Third-Party Integrations

### How is security maintained with third-party integrations?
We minimize third-party integrations to reduce potential vulnerabilities. When integrations are necessary:
1. We thoroughly vet the security practices of the third party
2. Integration is done via secure APIs with minimal data exposure
3. Regular security assessments are performed on the integration points

## Account Management and Data Control

### How can I delete my account?
You can delete your account at any time through the app settings. This will:
1. Immediately revoke your access tokens
2. Queue your data for permanent deletion
3. Remove your account information from our systems

Data deletion is irreversible and completes within 14 days. For details on our deletion process, see our [data deletion policy](https://ente.io/blog/how-ente-deletes-data/).

### What is Ente's policy on data backups and recovery?
We maintain encrypted backups of your data to ensure reliability. However:
- These backups are encrypted with your keys, which we don't have access to
- Backups are cycled out and permanently deleted after 30 days
- We cannot recover specific files you delete from your account, but you can recover them from the trash folder within 30 days

## Limitations and Transparency

### Are there any limitations to Ente's security model?
While we strive for maximum security, it's important to acknowledge potential limitations:
1. The security of your account ultimately depends on your password strength and your device's security
2. If you lose both your password and recovery key, your data becomes irrecoverable
3. In the unlikely event of a catastrophic loss of all our data centers simultaneously, data recovery would be challenging

We believe in being transparent about these limitations so you can make informed decisions about your data security.

## Additional Support

For any security or privacy questions not covered here, please contact our support team at security@ente.io. We're committed to addressing your concerns and continuously improving our security measures.
