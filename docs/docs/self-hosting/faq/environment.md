---
title: "Environment Variables and Ports"
description: "Information about all the Environment Variables needed to run Ente"
---

# Environment Variables and Ports

The self hosted instance relies on few endpoints in Museum as well as on the Web
App. Additionally, this document also covers information about what ports are mapped
to which Web app and etc. 

Here's the list of important variables that the self hoster should know about:

## Museum

1. `NEXT_PUBLIC_ENTE_ENDPOINT`

The above endpoint is used to configure Museums endpoint. Where Museum is running
and which port it is listening on. This endpoint should be configured for all the
apps to connect to your self hosted endpoint. 

All the apps (regardless of platform) by default connect to api.ente.io - which is 
our production instance of Museum.

## Web Apps

> [!IMPORTANT]
> Web apps don't need to be configured with the below endpoints. Web App Environment
> variables are being documented here just so that the users know everything in detail.
> Checkout [Configuring your Server](/self-hosting/museum) to configure endpoints for
> particular app.

In Ente, all the web apps are separated into different NextJS Apps. Hence, all of them
are configured via Environment Variables. The photos app is the Ente Photos which has
the information and knowledge of all the other needful web apps like albums, cast and etc.

1. `NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT`

This environment variable is used to configure and declare the endpoint for the Albums
Web App.

# Ports

The below format is according to how ports are mapped in Docker. 
Typically,`<host>:<container-port>`

1. `8080:8080`: Museum (Ente's Server)
2. `3000:3000`: Ente Photos Web App
3. `3001:3001`: Ente Accounts Web App
4. `3003:3003`: [Ente Auth](https://ente.io/auth/)
5. `3004:3004`: [Ente Cast Web App](http://ente.io/cast)
