The `dlib` folder is used for the plugins which use `cgo`.

If your go-flutter plugin dose't use `cgo`, just ignore this file and the `dlib` folder.

When you need to link prebuild dynamic libraries and frameworks,
you should copy the prebuild dynamic libraries and frameworks to `dlib`/${os} folder.

`hover plugins get` copy this files to path `./go/build/intermediates` of go-flutter app project.
`hover run` copy files from `./go/build/intermediates/${targetOS}` to `./go/build/outputs/${targetOS}`.
And `-L{./go/build/outputs/${targetOS}}` is appended to `cgoLdflags` automatically.
Also `-F{./go/build/outputs/${targetOS}}` is appended to `cgoLdflags` on Mac OS

Attention: `hover` can't resolve the conflicts
if two different go-flutter plugins have file with the same name in there dlib folder
