---
title: Building your Museum.yaml
description: Guide to writing a museum.yaml
---

## Configuring `museum.yaml`

`Museum.yaml` is a YAML configuration file used to configure various things for museum. 
By default, [`local.yaml`](https://github.com/ente-io/ente/tree/main/server/configurations/local.yaml) 
is also available, but  it is overridden if `museum.yaml` file is found. We highly 
recommend creating and building your own `museum.yaml` instead of editing `configurations/local.yaml`. 
The `my-ente` directory will include a `museum.yaml` file with some configurations around encryption 
keys and secrets, postgres DB, and MinIO.

> [!TIP]
> Always do `docker compose down` inside `my-ente` directory, if you've made any changes to `museum.yaml`
> and then restart the containers with `docker compose up -d ` to see the changes in action.

### S3 Buckets

By default, the `s3` section is configured to use local minIO buckets and for the same reason 
`are_local_buckets`  is set to `true`.  If you wish to bring any external S3 provider, 
you just have to edit the configuration with appropriate credentails and details given by the provider. 
And set `are_local_buckets` to false.  Check out [Configuring S3](/self-hosting/guides/configuring-s3.md) 
to understand more on how to configure S3 buckets and how the communication happens.

MinIO makes use of the port `3200` for API Endpoints and the Client Web App is run over `:3201` 
(both on localhost). You can login to MinIO Console Web UI by accessing `localhost:3201` in your web-browser
and setting up all the things related to regions there itself.

If you face any issues related to uploads then checkout 
[Troubleshooting Bucket CORS](/self-hosting/troubleshooting/bucket-cors) and 
[Frequently Answered Error related to S3](/self-hosting/guides/configuring-s3#fae-frequently-answered-errors)

### App Endpoints

Ente Photos Web app is divided into multiple sub-apps like albums, cast, auth, etc.
These endpoints are configurable in the museum.yaml under the `apps.*` section.

For example, 

```yaml
apps:
    public-albums: albums.myente.xyz
    cast: cast.myente.xyz
    accounts: accounts.myente.xyz
    family: family.myente.xyz
```

By default, all the values redirect to our publicly hosted production services. 
After you are done with filling the values, restart museum and the App will start utilizing
those endpoints for everything instead of the Ente's prod instances.

Once you configure all the necessary endpoints, `cd` into `my-ente` and  stop all the docker 
containers with `docker compose down` to completely stop all the containers and restart them 
with `docker compose up -d`. 

Similarly, you can read the default [`local.yaml`](https://github.com/ente-io/ente/tree/main/server/configurations/local.yaml) 
and build a functioning `museum.yaml` for many other functionalities like SMTP, Discord
Notifications, Hardcoded-OTT's, etc.