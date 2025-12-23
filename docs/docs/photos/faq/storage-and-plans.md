---
title: Storage and Plans FAQ
description: Frequently asked questions about storage, subscription plans, and pricing in Ente Photos
---

# Storage and Plans

## Understanding Storage

### Why does Ente consume less storage than other providers? {#less-storage-usage}

Most storage providers compute your storage quota in GigaBytes (GBs) by dividing your total bytes uploaded by `1000 x 1000 x 1000`.

Ente on the other hand, computes your storage quota in GibiBytes (GiBs) by dividing your total bytes uploaded by `1024 x 1024 x 1024`.

We decided to leave out the **i** from **GiBs** to reduce noise on our interfaces.

This means that the same file appears to take up less "storage" on Ente compared to providers using GB (base-1000) calculation.

### How does Ente deduplicate photos? {#deduplication}

Ente automatically detects and handles duplicate files during backup to save storage space:

**During uploads:**

- If you try to upload the same file to the same album, Ente will skip it entirely
- If you upload the same file to different albums, Ente creates a symlink (reference) instead of storing it again
- This means storage is only counted once, even if the photo appears in multiple albums

This happens automatically in the background without any action required from you.

Learn more in the [Duplicate detection guide](/photos/features/backup-and-sync/duplicate-detection).

### Does Ente deduplicate across different albums? {#dedup-albums}

Yes! During the initial upload, if the same file is being uploaded to multiple albums, Ente creates symlinks (references) instead of uploading duplicates. This means the storage is only counted once, even if the photo appears in multiple albums.

Learn more in the [Duplicate detection guide](/photos/features/backup-and-sync/duplicate-detection).

### How can I optimize my storage usage? {#optimize-storage}

Ente provides several tools to help you optimize both your device storage and cloud storage:

**Free up device space:**

- Remove backed-up photos from your phone to reclaim device storage
- Photos remain in Ente and can be re-downloaded anytime

**Remove exact duplicates:**

- Find and remove duplicate files across your entire library
- Maintains your album structure while freeing up storage

**Remove similar images:**

- Use ML to find visually similar (but not identical) photos
- Keep only the best shots and delete the rest

Learn more in the [Storage optimization guide](/photos/features/albums-and-organization/storage-optimization).

### Do items in trash count against my storage? {#trash-storage-count}

Yes, items in trash are included in your storage quota calculation. To free up storage space, you can:

- Manually empty your trash
- Permanently delete specific items
- Wait for automatic deletion after 30 days

Once files are permanently deleted (either manually or after 30 days), the storage space will be freed up and reflected in your account.

Learn more in [Albums and Organization FAQ](/photos/faq/albums-and-organization#trash).

### What happens if I exceed my storage limit? {#exceed-storage}

Ente will stop backing up your files and you will receive an email alerting you of the same.

Your backed up files will remain accessible for as long as you have an active subscription.

To continue backing up:

- Upgrade to a higher storage plan, OR
- Delete files you no longer need and empty trash to free up space

## Subscription Plans

### What plans does Ente offer? {#available-plans}

See our [website](https://ente.io#pricing) for the complete list of supported plans and pricing.

We offer:

- **Free plan**: 10 GB storage
- **Paid plans**: Multiple tiers ranging from 50 GB to multiple TBs
- **Monthly and annual billing**: Annual plans offer better value
- **Family plans**: Share your storage with up to 5 family members

### Does Ente offer regional pricing? {#regional-pricing}

No. We keep a single price globally because our infrastructure and payment costs are billed to us in USD/EUR and remain constant across regions. This helps us maintain predictable, sustainable pricing for everyone. If our cost structure changes in the future, we will reassess and update our pricing fairly.

### Is there a forever-free plan? {#free-plan}

Yes, we offer 10 GB of storage for free, forever.

### What are the limitations of the free plan? {#free-plan-limits}

On the free plan, you cannot:

- Set up family plans

All other features work on the free plan, including:

- Unlimited devices
- End-to-end encryption
- Map view
- Machine learning (face recognition, magic search)
- Creating /receiving shared albums
- Public links (device limit of 5)
- Background sync

### Is there an x GB plan? {#specific-plan-size}

We have experimented quite a bit and have found it hard to design a single structure that fits all needs. Some customers wish for many options, some even wish to go to an extreme of dynamic per GB pricing. Other customers wish to keep everything simple, some even wish for a single unlimited plan.

To keep things fair, our plans don't increase linearly, and the tiers are such that they cover the most requested patterns.

In addition, we also offer [family plans](/photos/features/account/family-plans) so that you can gain more value out of a single subscription.

If you need a custom plan, please contact [support@ente.io](mailto:support@ente.io).

## Family Plans

### Does Ente have Family Plans? {#family-plans-faq}

Yes we do! Please check out our announcement post [here](https://ente.io/blog/family-plans).

In brief:

- Your family members can use storage space from your plan without paying extra.
- Ask them to sign up for Ente, and then just add them to your existing plan using the "Manage family" option within your Subscription settings.
- Each member gets their own private space, and cannot see each other's files unless they're shared.
- You can invite 5 family members. So including yourself, it will be 6 people who can share a single subscription, paying only once.

Note that family plans are meant as a way to share storage. For sharing photos, you can create [shared albums and links](/photos/features/sharing-and-collaboration/share).

Learn more in the [Family plans guide](/photos/features/account/family-plans).

### How many family members can I add to my plan? {#family-members-limit}

You can invite up to 5 family members to your plan. Including yourself, a total of 6 people can share a single subscription while paying only once.

### Do family plan storage amounts stack across members? {#family-storage-stacking}

No. Storage from different accounts does not stack.

When you create a family and add members, everyone in the family shares the storage of the admin's subscription.

(Example: If you have a 1 TB plan and add someone with a 200 GB plan, your family will still have 1 TB total shared storage. Their 200 GB does not combine with yours. Once they join your family, their own individual subscription becomes redundant— they will use the shared family storage instead.)

Family plans are designed to allow multiple people to use a single subscription, not to combine multiple plans into a larger pool.

### Can family members see each other's photos? {#family-privacy}

No. Each family member gets their own private space, and members cannot see each other's files unless they are explicitly shared using Ente's sharing features. Family plans are only for sharing storage space, not for sharing photos automatically.

### Can I set storage limits for family members? {#family-storage-limits}

Yes! As the family plan admin, you can set storage limits for each member:

1. Open Subscription > Manage family
2. Find the member you want to limit
3. Click the edit icon
4. Set the storage limit (e.g., 10 GB)
5. Save

If you want to remove any storage limit from a member's account, you can click "Remove Limit" and they can upload photos without any limit (up to the total family plan storage).

### Why does my family member show 0 GB storage after accepting the invite? {#family-member-zero-storage}

If a family member accepted your invitation but their account shows 0 GB of available storage, try these solutions:

**Solution 1: Check if they actually accepted the invite**

Open `Settings > General > Family plans`, check the "Members" list, and confirm their status shows "Active" (not "Invited" or "Pending"). If still showing as "Invited", ask them to check their email and accept the invitation.

**Solution 2: Check if you've set a storage limit**

Open `Settings > General > Family plans`, find the member in the list, click the edit icon next to their name, and check if a storage limit is set to 0 GB or a very low amount. Either increase the limit or click "Remove Limit" to give them unlimited access to the family plan storage.

**Solution 3: Have the member log out and log back in**

1. Ask the family member to log out of their Ente account
2. Have them log back in
3. The storage quota should refresh and show correctly

**Solution 4: Check your total family plan storage**

1. Verify your family plan has available storage
2. If you've exceeded your total plan storage, family members may not be able to upload
3. Consider upgrading your plan or deleting unwanted files

**If the issue persists:**

Contact [support@ente.io](mailto:support@ente.io) with:

- Your email address (family plan admin)
- The family member's email address
- Screenshot of the "Manage family" screen showing the member's status

### Why can't I add a family member? {#cannot-add-family-member}

Common reasons and solutions:

**Problem 1: "You've reached the maximum number of family members"**

- Family plans allow up to 5 additional members (6 total including you)
- Remove an existing member before adding a new one

**Problem 2: "This user is already part of another family plan"**

- Each Ente account can only be part of one family plan at a time
- The person needs to leave their current family plan first
- Or create a new Ente account with a different email

**Problem 3: "Invalid email address" or invitation fails**

- Make sure the email address is correct
- The person must have an Ente account already (ask them to sign up first at [ente.io](https://ente.io))
- Free accounts can be invited to family plans

**Problem 4: Family plan not available**

- Family plans are only available for paid subscriptions
- Free plan users cannot create family plans
- Upgrade to any paid plan to access family sharing

**Problem 5: Purchased through App Store**

- Family plans may have limited functionality for App Store purchases
- Consider managing your subscription through [web.ente.io](https://web.ente.io) instead

### How do I remove someone from my family plan? {#remove-family-member}

Open `Settings > General > Family plans`, find the member you want to remove, click the remove/trash icon next to their name, and confirm the removal.

**What happens when you remove someone:**

- They lose access to the shared family storage
- Their photos remain in their account but they'll need their own subscription to continue uploading
- They'll revert to the free 10 GB plan unless they purchase their own subscription
- Photos they've already uploaded remain accessible to them

## Student Discounts

### Does Ente offer discounts to students? {#student-discount}

Yes we do!

We believe that privacy should be made accessible to everyone. In this spirit, we offer **30% off** our subscription plans to students.

To apply for this discount, please verify your enrollment status in a school / college / university by writing to [students@ente.io](mailto:students@ente.io) from the email address assigned to you by your institute.

In case you do not have access to such an email address, please send us proof (such as your institute's identity card) that verifies your identity as a student.

Please note that these discounts are valid for a year, after which you may reapply to reclaim the discount.

## Discount Codes and Referrals

### How do I apply a discount code to my subscription? {#apply-discount-code}

If you have a discount code (e.g., from partnerships like Kagi Friends 25% off), follow these steps carefully:

⚠️ **CRITICAL: You MUST apply the discount code BEFORE purchasing your subscription.** Discount codes cannot be applied retroactively to existing purchases.

**Step-by-step process:**

1. **Do NOT purchase through the iOS/Android App Store** - App Stores don't support discount codes
2. Go to [web.ente.io](https://web.ente.io) on a desktop or laptop computer
3. Log in to your Ente account
4. Open `Settings > Account > Manage subscription`
5. Click "Buy subscription" or "Change plan"
6. **BEFORE clicking "Purchase"**, look for the "Apply discount code" field
7. Enter your discount code in the field
8. Click "Apply" to verify the code works
9. Verify the discounted price is shown
10. Complete your purchase

**Important notes:**

- Discount codes only work for **NEW paying customers** (first-time purchases)
- Cannot be applied to existing paid subscriptions
- Cannot be combined with cryptocurrency payments
- Must purchase from web.ente.io or desktop app, NOT mobile app stores

**If you already purchased without applying a code:**

Unfortunately, we cannot apply discount codes retroactively. However, you can:

1. Cancel your current subscription
2. Wait for the subscription period to end
3. Resubscribe using the discount code

Contact [support@ente.io](mailto:support@ente.io) if you have questions about your specific situation.

## Referral Program

### How can I earn free storage? {#earn-storage-referrals}

Use our [referral program](/photos/features/account/referral-program/):

Open `Settings > General > Referrals`, share your referral code with friends, and when they upgrade to a paid plan, both you and your friend get 10 GB free.

### How much storage can I earn through referrals? {#referral-storage-limit}

For each friend you refer who upgrades to a paid plan, both you and your friend receive **10 GB** of free storage.

The amount of free storage you can earn is capped to your current plan. This means you can at most **double your storage**. For example, if you're on a 100 GB plan, you can earn another 100 GB (by referring 10 friends), taking your total available storage to 200 GB.

You can keep track of your earned storage and referral details on the _Claim free storage_ screen.

If you refer more paid customers than is allowed by your current plan, the extra storage earned will be reserved and will become usable once you upgrade your plan.

Learn more in the [Referral program](/photos/features/account/referral-program/) guide.

### For how long do I have access to referred storage? {#referral-duration}

Earned storage will be accessible as long as your subscription is active, provided there has been no abuse.

### What happens if I refer more people than my plan allows? {#referral-overflow}

If you refer more paid customers than your current plan allows, the extra storage earned will be reserved. This reserved storage will become usable once you upgrade to a higher storage plan.

For example, if you're on a 100 GB plan (max 100 GB earned storage) but refer 15 friends (150 GB worth), the extra 50 GB will be held in reserve until you upgrade to a plan that allows more referral storage.

### What counts as abuse of the referral program? {#referral-abuse}

In case our systems detect abuse, we may notify you and take back credited storage. Examples of abuse include:

- Low quality referrals (users who don't renew their plans)
- Creation of fake accounts
- Coordinated schemes to game the referral system

Legitimate referrals of real users who maintain active subscriptions are never affected by abuse detection.

## Payment Methods

### What payment methods does Ente support? {#supported-payment-methods}

On Web, Desktop and Android, Stripe helps us process payments from all major prepaid and credit card providers.

On iOS, we (have to) use the billing platforms provided by the app store.

Apart from these, we also support PayPal and crypto currencies (more details below).

### Can I pay with PayPal? {#paypal-payment}

We support **annual** subscriptions over PayPal.

**How to purchase with PayPal:**

1. Email **paypal@ente.io** from your registered Ente email address
2. In your email, mention the [storage plan](https://ente.io#pricing) of your choice (e.g., "100 GB annual plan")
3. We will send you an invoice with a PayPal payment link
4. Complete the payment through PayPal
5. Your account will be upgraded once payment is confirmed

**Important notes:**

- Only annual plans are available via PayPal (monthly plans not supported)
- You must email from the same email address registered with your Ente account
- Invoice generation is manual, so expect a response within 1-2 business days

### Does Ente accept crypto payments? {#crypto-payment}

Yes! We support *annual plans* with crypto payments and accept the following cryptocurrencies:

- **Bitcoin** (BTC)
- **Ethereum** (ETH)
- **Dogecoin** (DOGE)

**How to purchase with cryptocurrency:**

1. Email **crypto@ente.io** from your registered Ente email address
2. In your email, specify:
    - The [storage plan](https://ente.io#pricing) of your choice
    - Your preferred cryptocurrency
3. We will send you an invoice with payment instructions
4. Complete the payment using your crypto wallet
5. Your account will be upgraded once the transaction is confirmed

**Important limitations:**

⚠️ **Discount codes CANNOT be combined with cryptocurrency payments**. If you have a discount code, you must pay via credit card through web.ente.io instead.

⚠️ **Privacy note**: Ente does not provide anonymity. What we provide is privacy through end-to-end encryption. [Information we collect](https://ente.io/privacy/#3-what-information-do-we-collect) about you might make your identity deducible. We accept crypto to make Ente more accessible, not to provide anonymity.

**Processing time:**

- Invoice generation: 1-2 business days
- Payment confirmation: Depends on blockchain confirmation times (varies by cryptocurrency)

For questions about crypto payments, contact [support@ente.io](mailto:support@ente.io).

### Does Ente store my card details? {#card-security}

Ente does not store any of your sensitive payment related information.

We use [Stripe](https://stripe.com) to handle our card payments, and all of your payment information is sent directly to Stripe's PCI DSS validated servers.

Stripe has been audited by a PCI-certified auditor and is certified to [PCI Service Provider Level 1](https://www.visa.com/splisting/searchGrsp.do?companyNameCriteria=stripe). This is the most stringent level of certification available in the payments industry.

All of this said, if you would still like to pay without sharing your card details, you can pay using PayPal.

## Managing Your Subscription

### What happens when my subscription expires? {#subscription-expires}

When your subscription expires, you enter a **30-day grace period** before your data is deleted.

**Timeline after expiration:**

**Day 0 (Expiration day):**

- ✅ Your data remains accessible
- ✅ You can still view and download your photos
- ❌ New uploads are blocked
- 📧 You receive an email notification

**Days 1-30 (Grace period):**

- ✅ Your data remains accessible and downloadable
- ❌ New uploads are blocked
- 📧 You receive multiple reminder emails
- ✅ You can renew your subscription at any time to restore full access
- ✅ You can export your data using the desktop app or CLI

**Day 30+ (After grace period):**

- ❌ All your uploaded data is permanently deleted from our servers
- ❌ Recovery is not possible after deletion
- 📧 Final notification email sent

**To avoid losing your data:**

1. **Renew your subscription** before the grace period ends:
    - All your data will be immediately accessible again
    - Uploads will resume automatically
    - No data loss

2. **Export your data** during the grace period:
    - Use the desktop app's export feature
    - Or use the [CLI tool](https://github.com/ente-io/ente/tree/main/cli#readme) for automated export
    - Download all photos to your computer or NAS
    - Learn more in the [Export guide](/photos/migration/export/)

**Can I get my free plan back after subscription expires?**

Yes! If you had data exceeding the free 10 GB limit and your subscription expired:

- Your data enters the 30-day grace period
- To restore access to your data on the free plan, contact [support@ente.io](mailto:support@ente.io)
- We can restore your account to the free plan if you're within the grace period
- You'll need to delete data to get under the 10 GB limit

**What about subscriptions purchased through App Stores?**

If you purchased through iOS App Store or Google Play Store:

- Manage your subscription through the respective app store
- Cancellation policies follow the app store's terms
- The same 30-day grace period applies after expiration

### What happens when I upgrade my plan? {#upgrade-plan}

Your new plan will go into effect immediately, and you only have to pay the difference. We will adjust your remaining pro-rated balance on the old plan when invoicing you for the new plan.

**How prorating works for upgrades:**

When you upgrade, you receive credit for the unused portion of your current plan, which is applied toward the cost of your new plan.

**Example 1: Mid-year upgrade (yearly plans)**

You're 6 months into a 50 GB yearly plan ($20/year) and upgrade to 200 GB yearly ($48/year):

1. **Unused balance from old plan**: $20 ÷ 2 = $10 (6 months remaining)
2. **New plan cost**: $48/year
3. **Amount you pay now**: $48 - $10 = **$38**
4. **New plan duration**: 1 full year from today

**Example 2: Mid-month upgrade (monthly plans)**

You're 15 days into a 100 GB monthly plan ($2/month) and upgrade to 500 GB monthly ($5/month):

1. **Unused balance from old plan**: $2 × (15/30) = $1 (15 days remaining)
2. **New plan cost**: $5/month
3. **Amount you pay now**: $5 - $1 = **$4**
4. **New plan duration**: 1 full month from today

**Key points:**

- ✅ Upgrades take effect immediately
- ✅ You get credit for unused time on your old plan
- ✅ Your new renewal date starts from the upgrade date
- ✅ You pay the difference between plans (minus your credit)

### What happens when I downgrade my plan? {#downgrade-plan}

Your new plan will go into effect immediately. Any extra amount you have paid will be credited to your account. This credit will be discounted from your future invoices.

**How prorating works for downgrades:**

When you downgrade, you receive credit for the price difference between what you paid and what you would have paid on the lower plan.

**Example 1: Mid-year downgrade (yearly plans)**

You're 6 months into a 200 GB yearly plan ($48/year) and downgrade to 50 GB yearly ($20/year):

1. **What you paid for old plan**: $48
2. **What you would have paid for 6 months of new plan**: $20 ÷ 2 = $10
3. **What you paid for 6 months of old plan**: $48 ÷ 2 = $24
4. **Credit to your account**: $24 - $10 = **$14**
5. **When credit is used**: Applied to your next renewal in 6 months
6. **Next invoice (in 6 months)**: $20 - $14 = **$6**

**Example 2: Mid-month downgrade (monthly plans)**

You're 10 days into a 500 GB monthly plan ($5/month) and downgrade to 100 GB monthly ($2/month):

1. **What you paid for old plan**: $5
2. **What you would have paid for 10 days of new plan**: $2 × (10/30) = $0.67
3. **What you paid for 10 days of old plan**: $5 × (10/30) = $1.67
4. **Credit to your account**: $1.67 - $0.67 = **$1**
5. **When credit is used**: Applied to your next renewal in 20 days
6. **Next invoice (in 20 days)**: $2 - $1 = **$1**

**Key points:**

- ✅ Downgrades take effect immediately
- ✅ You get credit for overpayment
- ✅ Credit is automatically applied to future renewals
- ✅ Your renewal date remains the same
- ⚠️ Make sure you don't exceed your new storage limit

**Want a refund instead of credit?**

If you prefer to have your credit refunded to your original payment method instead of storing it for future invoices, contact [support@ente.io](mailto:support@ente.io) and we'll assist you.

### Can I switch between monthly and yearly plans? {#switch-billing-cycle}

Yes! Switching between monthly and yearly billing works the same as upgrading or downgrading:

**Monthly to yearly:**

- Treated as an upgrade (yearly plans are better value)
- You get credit for unused days on your monthly plan
- Pay the yearly price minus your credit
- New yearly renewal date starts immediately

**Yearly to monthly:**

- Treated as a downgrade
- You get credit for the price difference
- Credit applied to future monthly renewals
- Renewal date remains the same

The same prorating calculation applies as described above.

### How can I update my payment method? {#update-payment}

You can view and manage your payment method by clicking on the green subscription card within the Ente app, and selecting the "Manage payment method" button.

**Note:** On iOS, the "Manage payment method" option is not available. iOS users must manage their subscriptions and payment methods through the Apple App Store.

You will be able to see all of your previous invoices, with details regarding their payment status. In case of failed payments, you will also have an option to retry those charges.

### How can I cancel my subscription? {#cancel-subscription}

You can cancel your subscription by clicking on the green subscription card within the Ente app, and selecting the "Cancel subscription" button.

After cancellation, you'll have access to your data for 30 days, after which it will be deleted. Make sure to export your photos before the grace period ends if you want to keep them.

## Storage

### How can I earn free storage? {#earn-free-storage}

Use our [referral program](/photos/features/account/referral-program/). When friends sign up using your referral code and subscribe to a paid plan, both you and your friend earn additional free storage.
