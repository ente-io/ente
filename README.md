# cli tool for exporting ente photos

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



## Testing

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


## Docker
  Build the docker image
  ```shell
  docker build -t ente-cli:latest .
  ```
  Run the commands using:
  ```shell
    docker run -it --rm ente-cli:latest ./ente-cli --help 
  ```
