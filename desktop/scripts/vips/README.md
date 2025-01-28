Experimenting with libvips.

```sh
docker build -t vips-test .
docker run -it --rm -v $(pwd):/w vips-test vips copy /w/1.heic /w/1.jpeg
```

---

## Notes 3

Added a fork at https://github.com/ente-io/libvips-packaging.git

```sh
git clone https://github.com/ente-io/libvips-packaging
cd libvips-packaging
docker build -t vips-dev-linux-arm64 platforms/linux-arm64
docker run -it --rm -e VERSION_VIPS=8.16.0 -e VERSION_LATEST_REQUIRED=false -v $(pwd):/packaging vips-dev-linux-arm64 /bin/bash
# In the container
$ /packaging/build/lin.sh
```

(ditto `linux-x64`)

Meanwhile, to recreate the existing imagemagick thumbnail conversion pipeline

```sh
./vips --help-operation thumbnail
./vips thumbnail sample.heic sample.heic.thumb.jpeg 720
./vips thumbnail sample.heic sample.heic.thumb.jpeg[Q=50] 720
```

> The output image will fit within a square of size width x width
>
> https://www.libvips.org/API/current/libvips-resample.html#vips-thumbnail

> You can pass options to the implicit load and save operations enclosed in
> square brackets after the filename:
>
>     vips affine k2.jpg x.jpg[Q=90,strip] "2 0 0 1"
>
> https://www.libvips.org/API/current/using-cli.html

For Windows,

```sh
git clone --depth 1 https://github.com/libvips/build-win64-mxe
cd build-win64-mxe
docker build -t libvips-build-win-mxe container
docker run --rm -e VERSION_VIPS=8.16.0 -e FFI_COMPAT=false -e JPEG_IMPL=mozjpeg -e DISP=false -e HEVC=true -e DEBUG=false -e LLVM=true -e ZLIB_NG=true -v $(pwd)/build:/data libvips-build-win-mxe all x86_64-w64-mingw32.static
docker run --rm -e VERSION_VIPS=8.16.0 -e FFI_COMPAT=false -e JPEG_IMPL=mozjpeg -e DISP=false -e HEVC=true -e DEBUG=false -e LLVM=true -e ZLIB_NG=true -v $(pwd)/build:/data libvips-build-win-mxe all aarch64-w64-mingw32.static
```

when testing, the following might be useful

```sh
docker run --rm -e VERSION_VIPS=8.16.0 -e FFI_COMPAT=false -e JPEG_IMPL=mozjpeg -e DISP=false -e HEVC=true -e DEBUG=false -e LLVM=true -e ZLIB_NG=true -v $(pwd)/build:/data --entrypoint /bin/bash libvips-build-win-mxe
# Then in the container
/data/build.sh all x86_64-w64-mingw32.static
```

## Notes 2

Try using libvips-packaging, see if it builds vips tools binaries too.

```sh
git clone https://github.com/kleisauke/libvips-packaging
cd libvips-packaging
docker build -t vips-dev-linux-arm64 platforms/linux-arm64
docker run -it --rm -e VERSION_VIPS=8.16.0 -e VERSION_LATEST_REQUIRED=false -v $(pwd):/packaging vips-dev-linux-arm64 /bin/bash
# In the container
$ /packaging/build/lin.sh
```

This too is only producing the library, not the CLI tools.

The following patch can be made to make it work (need to cleanup). It

1. Builds `--default-library=static`
2. Builds the tools and includes them in the package
3. Adds libde265 for HEIC decoding

```patch
diff --git a/build/lin.sh b/build/lin-1-a.sh
index 4400503..5d363c2 100755
--- a/build/lin.sh
+++ b/build/lin-1-a.sh
@@ -9,7 +9,7 @@ case ${PLATFORM} in
     TARGET=/target
     PACKAGE=/packaging
     ROOT=/root
-    VIPS_CPP_DEP=libvips-cpp.so.42
+    VIPS_CPP_DEP=libvips.a
     ;;
   osx*)
     DARWIN=true
@@ -271,6 +271,14 @@ AOM_AS_FLAGS="${FLAGS}" cmake -G"Unix Makefiles" \
   ..
 make install/strip

+cd ${DEPS}
+git clone --depth 1 https://github.com/strukturag/libde265.git
+cd ${DEPS}/libde265
+CFLAGS="${CFLAGS} -O3" CXXFLAGS="${CXXFLAGS} -O3" cmake -G"Unix Makefiles" \
+  -DCMAKE_TOOLCHAIN_FILE=${ROOT}/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
+  -DBUILD_SHARED_LIBS=FALSE
+make install
+
 mkdir ${DEPS}/heif
 $CURL https://github.com/strukturag/libheif/releases/download/v${VERSION_HEIF}/libheif-${VERSION_HEIF}.tar.gz | tar xzC ${DEPS}/heif --strip-components=1
 cd ${DEPS}/heif
@@ -278,7 +286,7 @@ cd ${DEPS}/heif
 sed -i'.bak' "/^cmake_minimum_required/s/3.16.3/3.12/" CMakeLists.txt
 CFLAGS="${CFLAGS} -O3" CXXFLAGS="${CXXFLAGS} -O3" cmake -G"Unix Makefiles" \
   -DCMAKE_TOOLCHAIN_FILE=${ROOT}/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
-  -DBUILD_SHARED_LIBS=FALSE -DBUILD_TESTING=0 -DENABLE_PLUGIN_LOADING=0 -DWITH_EXAMPLES=0 -DWITH_LIBDE265=0 -DWITH_X265=0
+  -DBUILD_SHARED_LIBS=FALSE -DBUILD_TESTING=0 -DENABLE_PLUGIN_LOADING=0 -DWITH_EXAMPLES=0 -DWITH_LIBDE265=1 -DWITH_X265=0
 make install/strip
 if [ "$PLATFORM" == "linux-arm" ]; then
   # Remove -lstdc++ from Libs.private, it won't work with -static-libstdc++
@@ -468,8 +476,8 @@ if [ "$LINUX" = true ]; then
   printf "{local:g_param_spec_types;};" > vips.map
 fi
 # Disable building man pages, gettext po files, tools, and (fuzz-)tests
-sed -i'.bak' "/subdir('man')/{N;N;N;N;d;}" meson.build
-CFLAGS="${CFLAGS} -O3" CXXFLAGS="${CXXFLAGS} -O3" meson setup _build --default-library=shared --buildtype=release --strip --prefix=${TARGET} ${MESON} \
+# sed -i'.bak' "/subdir('man')/{N;N;N;N;d;}" meson.build
+CFLAGS="${CFLAGS} -O3" CXXFLAGS="${CXXFLAGS} -O3" meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
   -Ddeprecated=false -Dexamples=false -Dintrospection=disabled -Dmodules=disabled -Dcfitsio=disabled -Dfftw=disabled -Djpeg-xl=disabled \
   -Dmagick=disabled -Dmatio=disabled -Dnifti=disabled -Dopenexr=disabled -Dopenjpeg=disabled -Dopenslide=disabled \
   -Dpdfium=disabled -Dpoppler=disabled -Dquantizr=disabled \
@@ -478,7 +486,7 @@ CFLAGS="${CFLAGS} -O3" CXXFLAGS="${CXXFLAGS} -O3" meson setup _build --default-l
 meson install -C _build --tag runtime,devel

 # Cleanup
-rm -rf ${TARGET}/lib/{pkgconfig,.libs,*.la,cmake}
+# rm -rf ${TARGET}/lib/{pkgconfig,.libs,*.la,cmake}

 mkdir ${TARGET}/lib-filtered
 mv ${TARGET}/lib/glib-2.0 ${TARGET}/lib-filtered
@@ -524,20 +532,20 @@ function copydeps {
   done;
 }

-cd ${TARGET}/lib
-if [ "$LINUX" = true ]; then
-  # Check that we really linked with -z nodelete
-  readelf -Wd libvips.so.42 | grep -qF NODELETE || (echo "libvips.so.42 was not linked with -z nodelete" && exit 1)
-fi
-if [ "$PLATFORM" == "linux-arm" ]; then
-  # Check that we really didn't link libstdc++ dynamically
-  readelf -Wd ${VIPS_CPP_DEP} | grep -qF libstdc && echo "$VIPS_CPP_DEP is dynamically linked against libstdc++" && exit 1
-fi
-if [ "${PLATFORM%-*}" == "linux-musl" ]; then
-  # Check that we really compiled with -D_GLIBCXX_USE_CXX11_ABI=1
-  # This won't work on RHEL/CentOS 7: https://stackoverflow.com/a/52611576
-  readelf -Ws ${VIPS_CPP_DEP} | c++filt | grep -qF "::__cxx11::" || (echo "$VIPS_CPP_DEP mistakenly uses the C++03 ABI" && exit 1)
-fi
+# cd ${TARGET}/lib
+# if [ "$LINUX" = true ]; then
+#   # Check that we really linked with -z nodelete
+#   readelf -Wd libvips.so.42 | grep -qF NODELETE || (echo "libvips.so.42 was not linked with -z nodelete" && exit 1)
+# fi
+# if [ "$PLATFORM" == "linux-arm" ]; then
+#   # Check that we really didn't link libstdc++ dynamically
+#   readelf -Wd ${VIPS_CPP_DEP} | grep -qF libstdc && echo "$VIPS_CPP_DEP is dynamically linked against libstdc++" && exit 1
+# fi
+# if [ "${PLATFORM%-*}" == "linux-musl" ]; then
+#   # Check that we really compiled with -D_GLIBCXX_USE_CXX11_ABI=1
+#   # This won't work on RHEL/CentOS 7: https://stackoverflow.com/a/52611576
+#   readelf -Ws ${VIPS_CPP_DEP} | c++filt | grep -qF "::__cxx11::" || (echo "$VIPS_CPP_DEP mistakenly uses the C++03 ABI" && exit 1)
+# fi
 copydeps ${VIPS_CPP_DEP} ${TARGET}/lib-filtered

 # Create JSON file of version numbers
@@ -583,6 +591,7 @@ mv lib-filtered lib
 tar chzf ${PACKAGE}/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz \
   include \
   lib \
+  bin \
   versions.json \
   THIRD-PARTY-NOTICES.md
```

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
