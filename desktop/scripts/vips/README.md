Experimenting with libvips.

```sh
docker build -t vips-test .
docker run -it --rm -v $(pwd):/w vips-test vips copy /w/1.heic /w/1.jpeg
```

---

## Notes

Everything disabled + static

```sh
meson setup _build --prefix=/target --default-library=static --buildtype=release -Ddeprecated=false -Dexamples=false -Dcplusplus=false -Dauto_features=disabled -Dmodules=disabled -Dintrospection=disabled -Dfftw=disabled -Dcgif=disabled -Dexif=disabled -Dfftw=disabled -Dfontconfig=disabled -Darchive=disabled -Dheif=disabled -Dheif-module=disabled -Dimagequant=disabled -Djpeg=disabled -Djpeg-xl=disabled -Djpeg-xl-module=disabled -Dlcms=disabled -Dmagick=disabled -Dmagick-module=disabled -Dmatio=disabled -Dnifti=disabled -Dopenexr=disabled -Dopenjpeg=disabled -Dopenslide=disabled -Dopenslide-module=disabled -Dhighway=disabled -Dorc=disabled -Dpangocairo=disabled -Dpdfium=disabled -Dpng=disabled -Dpoppler=disabled -Dpoppler-module=disabled -Dquantizr=disabled -Drsvg=disabled -Dspng=disabled -Dtiff=disabled -Dwebp=disabled -Dzlib=disabled -Dnsgif=false -Dppm=false -Danalyze=false -Dradiance=false
```

Patch meson.build

```patch
+glib_dep = dependency('glib-2.0', version: '>=2.52', static: true)
+gio_dep = dependency('gio-2.0', static: true)
+gobject_dep = dependency('gobject-2.0', static: true)
+gmodule_dep = dependency('gmodule-no-export-2.0', required: get_option('modules'), static: true)
+expat_dep = dependency('expat', static: true)
+thread_dep = dependency('threads', static: true)
```
---

Creates an otherwise statically linked executable but still depends on system
libs

```sh
meson setup _build --prefix=/target --default-library=static --buildtype=release -Ddeprecated=false -Dexamples=false -Dcplusplus=false -Dauto_features=disabled -Dmodules=disabled -Dcgif=disabled -Dexif=disabled -Dheif=disabled -Dheif-module=disabled -Dimagequant=disabled -Djpeg=disabled -Djpeg-xl=disabled -Djpeg-xl-module=disabled -Dlcms=disabled -Dhighway=disabled -Dspng=disabled -Dtiff=disabled -Dwebp=disabled -Dnsgif=false -Dppm=false -Danalyze=false -Dradiance=false -Dzlib=disabled

cd build && meson compile && meson install
```
