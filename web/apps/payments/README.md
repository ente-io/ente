This is a [Next.js](https://nextjs.org/) project bootstrapped with
[`create-next-app`](https://github.com/vercel/next.js/tree/canary/packages/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
```

## Notes

If you're running this to test out the payment flows end-to-end, please do a
`yarn build`, that will place the output within the `out` folder.

Then use any tool to serve this over HTTP. For example, `python3 -m http.server
3001` will serve this directory over port `3001`.

Aside that, these are the necessary configuration changes.

### Local configuration

Update the `.env.local` to point to the local museum instance, and to define the
necessary Stripe keys that can be fetched from [Stripe's developer
dashboard](https://dashboard.stripe.com).

Assuming that your local museum instance is running on `192.168.1.2:8080`, your
`.env.local` should look as follows.

```
NEXT_PUBLIC_ENTE_ENDPOINT = http://192.168.1.2:8080
NEXT_PUBLIC_STRIPE_US_PUBLISHABLE_KEY = stripe_publishable_key
```

### Museum

1. Install the [stripe-cli](https://docs.stripe.com/stripe-cli) and capture the
   webhook signing secret.

2. Define this secret within your `musuem.yaml`

3. Update the `whitelisted-redirect-urls` so that it supports redirecting to this locally running project

Assuming that your local payments app is running on `192.168.1.2:3001`, your
`museum.yaml` should look as follows.
   
```yaml
stripe:
    us:
        key: stripe_dev_key
        webhook-secret: stripe_dev_webhook_secret
    whitelisted-redirect-urls: ["http://192.168.1.2:3001/frameRedirect"]
    path:
        success: ?status=success&session_id={CHECKOUT_SESSION_ID}
        cancel: ?status=fail&reason=canceled
```
