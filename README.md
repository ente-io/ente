# cli for exporting ente.io data

## Install

You can either download the binary from the [release page](https://github.com/ente-io/cli/releases) or build it yourself.

### Build from source

```shell
 go build -o "bin/ente-cli" main.go
```

### Getting Started

Run the help command to see all available commands.
```shell
ente-cli --help
```

#### Accounts
If you wish, you can add multiple accounts (your own and your family members) and export all using this tool.
* Add an account
    ```shell
    ente-cli account add
    ```

* List accounts
    ```shell
    ente-cli account list
    ```
  
* Change export directory
    ```shell
    ente-cli account update --email yourEmail@example.com --dir ~/photos 
    ```

### Export
* Start export
    ```shell
    ente-cli export
    ```

## Docker

### Configure
Modify the `docker-compose.yml` and add volume.
``cli-data`` volume is mandatory, you can add more volumes for your export directory.
  * Build the docker image
  ```shell
  docker build -t ente-cli:latest .
  ```
  * Start the container in detached mode
  ```bash 
  docker-compose up -d
  ```
exec into the container
```shell
  docker-compose exec ente-cli /bin/sh
```
  
    
#### How to directly execute the command

  ```shell
    docker run -it --rm ente-cli:latest ls 
  ```


## Releases

Run the release script to build the binary and run it.

```shell
  ./release.sh
```

