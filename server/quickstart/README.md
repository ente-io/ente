A variant docker compose file that does not require cloning the repository, and
uses pre-built images instead.

## Quickstart

Copy paste the following command into your terminal

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ente-io/ente/main/server/quickstart.sh)"
```

Alternatively, you can run the following four steps manually (that's all the
command above does for you):

1. Create a directory on your system and switch to it. You can name it
   anything, and it can be at any place on your machine. In particular, you
   don't need to clone this repository.

   ```sh
   mkdir my-ente && cd my-ente
   ```

> [!TIP]
>
> "Ente" (pronounced _en-tay_) means "mine" in Malayalam, our Founder's mother
> tongue (the product literally thus means "My Photos"), so our example
> directory name `my-ente` would mean to "my-my".

2. Download the sample quickstart Docker compose file.

   ```sh
   curl -fsSOL https://raw.githubusercontent.com/ente-io/ente/HEAD/server/quickstart/compose.yaml
   ```

3. Create an empty `museum.yaml` (you can use it later to put your config).

   ```sh
   touch museum.yaml
   ```

4. Start your self hosted instance.

   ```sh
   docker compose up
   ```

That's it. You can now open http://localhost:3000 in your browser to use Ente's
web app.

## Details

The quickstart steps above created a Docker compose cluster containing:

- Ente's own server, museum
- Ente's web app
- Postgres (DB)
- Minio (S3 storage)

For each of these, it'll use the latest published Docker image.

You can do a quick smoke test by pinging the API:

```sh
curl localhost:8080/ping
```

And start using the web app by opening http://localhost:3000 in your browser.

The cluster will keep running as long as the `docker compose up` command (or the
`quickstart.sh` script you curl-ed) is running. If you want to keep it running
in the background, you can instead:

```sh
cd /path/to/my-ente # Or whichever directory you created
docker compose up -d
```

And then later, to stop the cluster, you can:

```sh
cd /path/to/my-ente
docker compose down
```

### Caveat

This sample setup is only intended to make it easy for people to get started. If
you're intending to use your self hosted instance for serious purposes, we
strongly recommend understanding all the moving parts. Some particular things to
call out:

1. Remember to change all hardcoded credentials.

2. Consider if you should use an external DB or an external S3 instead of the
   provided quickstart sample.

3. Keep a plaintext backup of your photos until you are sure of what you are
   doing and have a [backup
   strategy](https://help.ente.io/self-hosting/faq/backup) worked out.

## Next steps

* Get a login [verification
  code](https://help.ente.io/self-hosting/faq/otp#verification-code).

* Connect to your self hosted instance [from your mobile
  app](https://help.ente.io/self-hosting/guides/custom-server/).

* Modify your setup to allow [uploading from your mobile
  app](https://help.ente.io/self-hosting/guides/configuring-s3).
