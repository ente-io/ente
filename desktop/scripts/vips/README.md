Experimenting with libvips.

```sh
docker build -t vips-test .
docker run -it --rm -v $(pwd):/w vips-test vips copy /w/1.heic /w/1.jpeg
```
