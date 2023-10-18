# cli tool for exporting data from ente.io

#### You can configure multiple accounts for export

### Getting Started

#### Accounts

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

## Export
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


## Build locally

Run the release script to build the binary and run it.

```shell
  ./release.sh
```

or you can run the following command

```shell
 go build -o "bin/ente-cli" main.go
```

```shell
./bin/ente-cli --help
```
