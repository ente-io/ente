Run from `web`:

```sh
npm exec --workspace space -- playwright install --with-deps webkit
npm run test:browser --workspace space
```

The test mounts the real inline video component in WebKit and exposes half of the
inactive second slide. It checks screenshot pixels for both colors in the decoded
video while that slide remains paused at time zero. A cover or blank preview fails.

`preview.mp4` is a generated, silent H.264 video with a green upper half and blue
lower half. Regenerate it from this directory with:

```sh
ffmpeg -f lavfi -i 'color=c=0x00ff00:s=320x240:r=2:d=1' -vf 'drawbox=x=0:y=120:w=320:h=120:color=0x0000ff:t=fill' -c:v libx264 -pix_fmt yuv420p -movflags +faststart preview.mp4
```
