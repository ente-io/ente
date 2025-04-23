---
title: Creating Accounts
description: Creating accounts on your deployment
---

# Creating Accounts 

Once the docker containers are up and running on their desired ports. The Ente Photos 
web app will be accessible on `http://localhost:3000`. Open the URL in your browser 
and proceed with creating an account. By default, the API Endpoint will be `localhost:8080`
as Museum (our server endpoint) will listen on `:8080`.

![endpoint](/endpoint.png)

To complete your account registration you need to enter a 6-digit verification code. 
This can be found in the server logs, which should already be shown in your quickstart
terminal. Alternatively, you can open the server logs with the following command from 
inside the `my-ente` folder:

```sh 
sudo docker compose logs
```

It should look something like the below

![otp](/otp.png)