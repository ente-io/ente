# Command Line Utility for exporting data from [Ente](https://ente.io)

## Install

You can either download the binary from the [GitHub releases
page](https://github.com/ente-io/ente/releases?q=cli&expanded=true) or build it
yourself.

### Build from source

```shell
 go build -o "bin/ente" main.go
```

### Getting Started

Run the help command to see all available commands.
```shell
ente --help
```

#### Accounts
If you wish, you can add multiple accounts (your own and that of your family members) and export all data using this tool.

##### Add an account
```shell
ente account add
```

##### List accounts
```shell
ente account list
```

##### Change export directory
```shell
ente account update --email email@domain.com --dir ~/photos
```

### Export
##### Start export
```shell
ente export
```

---

## Docker

If you fancy Docker, you can also run the CLI within a container.

### Configure

Modify the `docker-compose.yml` and add volume.
``cli-data`` volume is mandatory, you can add more volumes for your export directory.

Build the docker image
```shell
docker build -t ente:latest .
```

Start the container in detached mode
```bash
docker-compose up -d
```

`exec` into the container
```shell
docker-compose exec ente /bin/sh
```


#### Directly executing commands

```shell
docker run -it --rm ente:latest ls
```

---

## Releases

Run the release script to build the binary and run it.

```shell
./release.sh
```

