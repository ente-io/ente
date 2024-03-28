Code that runs on `payments.ente.io`. It brokers between our services and
Stripe's API for payments.

## Development / New

There are three pieces that need to be connected to have a working local setup:

- A client app
- This web app
- Museum

### Client app

For the client, let us consider the Photos web app (similar configuration can be
done in the mobile client too).

Add the following to `web/apps/photos/.env.local`:

```env
NEXT_PUBLIC_ENTE_ENDPOINT = http://localhost:8080
NEXT_PUBLIC_ENTE_PAYMENTS_ENDPOINT = http://localhost:3001
```
Then start it locally

```sh
yarn dev:photos
```

This tells it to connect to the museum and payments app running on localhost.

> For connecting from the mobile app, you'll need to run museum on a local IP
> instead localhost. If so, just replace "http://localhost:8080" with (say)
> "http://192.168.1.2:8080" wherever mentioned.

### Payments app

For this (payments) web app, configure it to connect to the local museum, and
use a set of (development) Stripe keys which can be found in [Stripe's developer
dashboard](https://dashboard.stripe.com).

Add the following to
`web/apps/payments/.env.local`

```env
NEXT_PUBLIC_ENTE_ENDPOINT = http://localhost:8080
NEXT_PUBLIC_STRIPE_US_PUBLISHABLE_KEY = stripe_publishable_key
```

Then start it locally

```sh
yarn dev:payments
```

### Museum

1. Install the [stripe-cli](https://docs.stripe.com/stripe-cli) and capture the
   webhook signing secret.

2. Define this secret within your `musuem.yaml`

3. Update the `whitelisted-redirect-urls` so that it supports redirecting to
   the locally running payments app.

Assuming that your local payments app is running on `localhost:3001`, your
`server/museum.yaml` should look as follows.

```yaml
stripe:
    us:
        key: stripe_dev_key
        webhook-secret: stripe_dev_webhook_secret
    whitelisted-redirect-urls: ["http://localhost:3001/gallery", "http://192.168.1.2:3001/frameRedirect"]
    path:
        success: ?status=success&session_id={CHECKOUT_SESSION_ID}
        cancel: ?status=fail&reason=canceled
```

Finally, start museum, for example:

```
docker compose up
```

Now if you try to purchase a plan from your locally running photos web client,
it should redirect to the locally running payments app, and from there to
Stripe. Once the test purchase completes it should redirect back to the local
web client.

## Development

If you're running this to test out the payment flows end-to-end, please do a
`yarn build`, that will place the output within the `out` folder.

Then use any tool to serve this over HTTP. For example, `python3 -m http.server
3001` will serve this directory over port `3001`.

Aside that, these are the necessary configuration changes.

### Local configuration

Create an `.env` in this directory to point to the local museum instance, and to
define the necessary Stripe keys that can be fetched from [Stripe's developer
dashboard](https://dashboard.stripe.com).

Assuming that your local museum instance is running on `192.168.1.2:8080`, your
`.env` should look as follows.

```
NEXT_PUBLIC_ENTE_ENDPOINT = http://192.168.1.2:8080
NEXT_PUBLIC_STRIPE_US_PUBLISHABLE_KEY = stripe_publishable_key
```

### Museum

1. Install the [stripe-cli](https://docs.stripe.com/stripe-cli) and capture the
   webhook signing secret.

2. Define this secret within your `musuem.yaml`

3. Update the `whitelisted-redirect-urls` so that it supports redirecting to
   this locally running project.

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
