---
title: "Environment Variables and Ports"
description: "Information about all the Environment Variables needed to run Ente"
---

# Environment variables and ports
A self-hosted Ente instance requires specific endpoints in both Museum (the server) and web apps. This document outlines the essential environment variables and port mappings of the web apps.

Here's the list of important variables that a self hoster should know about:

### Museum

1. `NEXT_PUBLIC_ENTE_ENDPOINT`

The above environment variable is used to configure Museums endpoint. Where Museum is 
running and which port it is listening on. This endpoint should be configured for 
all the apps to connect to your self hosted endpoint. 

All the apps (regardless of platform) by default connect to api.ente.io - which is 
our production instance of Museum.

### Web Apps

> [!IMPORTANT]
> Web apps don't need to be configured with the below endpoints. Web app environment
> variables are being documented here just so that the users know everything in detail.
> Checkout [Configuring your Server](/self-hosting/museum) to configure endpoints for
> particular app.

In Ente, all the web apps are separate NextJS applications. Therefore, they are all 
configured via environment variables. The photos app (Ente Photos) has information 
about and connects to other web apps like albums, cast, etc.


1. `NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT`

This environment variable is used to configure and declare the endpoint for the Albums
web app.

## Ports

The below format is according to how ports are mapped in Docker. 
Typically,`<host>:<container-port>`

1. `8080:8080`: Museum (Ente's server)
2. `3000:3000`: Ente Photos web app
3. `3001:3001`: Ente Accounts web app
4. `3003:3003`: [Ente Auth web app](https://ente.io/auth/)
5. `3004:3004`: [Ente Cast web app](http://ente.io/cast)
