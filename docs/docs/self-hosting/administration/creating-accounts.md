---
title: Creating Accounts - Self-hosting
description: Creating accounts on your deployment
---

# Creating accounts

Once Ente is up and running, the Ente Photos web app will be accessible on
`http://localhost:3000`. Open this URL in your browser and proceed with creating
an account.

The default API endpoint for museum will be `localhost:8080`.

![endpoint](/endpoint.png)

To complete your account registration you will need to enter a 6-digit
verification code.

This code can be found in the server logs, which should already be shown in your
quickstart terminal. Alternatively, you can open the server logs with the
following command from inside the `my-ente` folder:

```sh
sudo docker compose logs
```

![otp](/otp.png)
