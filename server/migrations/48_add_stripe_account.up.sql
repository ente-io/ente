UPDATE
    subscriptions
SET
    attributes = jsonb_set(
        attributes,
        '{stripeAccountCountry}',
        '"IN"'
    )
WHERE
    payment_provider = 'stripe';
