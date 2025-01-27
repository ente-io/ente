Experimenting with libvips.

```sh
docker build -t vips-test .
docker run -it --rm -v $(pwd):/w vips-test vips copy /w/1.heic /w/1.jpeg
```

---

## Notes

---

Creates an otherwise statically linked executable but still depends on system
libs

```sh
meson setup _build --prefix=/target --default-library=static --buildtype=release -Ddeprecated=false -Dexamples=false -Dcplusplus=false -Dauto_features=disabled -Dmodules=disabled -Dcgif=disabled -Dexif=disabled -Dheif=disabled -Dheif-module=disabled -Dimagequant=disabled -Djpeg=disabled -Djpeg-xl=disabled -Djpeg-xl-module=disabled -Dlcms=disabled -Dhighway=disabled -Dspng=disabled -Dtiff=disabled -Dwebp=disabled -Dnsgif=false -Dppm=false -Danalyze=false -Dradiance=false -Dzlib=disabled

cd build && meson compile && meson install
```
