package flutter_image_compress

import (
	"image"
	"image/color"
	_ "image/gif"
	_ "image/jpeg"
	_ "image/png"
	"io"
	"os"

	"github.com/disintegration/imaging"
	"github.com/nfnt/resize"
	_ "golang.org/x/image/webp"
)

// Rotate image
func RotateImage(img image.Image, degree int) image.Image {
	return imaging.Rotate(img, float64(degree), color.Transparent)
}

// Scale image
func ScaleImage(reader io.Reader, minWidth, minHeight int32) (img image.Image, err error) {
	img, _, err = image.Decode(reader)
	if err != nil {
		return
	}

	w, h := calcTargetSize(img, minHeight, minHeight)

	img = resize.Resize(w, h, img, resize.Lanczos3)
	return
}

func calcTargetSize(img image.Image, minWidth, minHeight int32) (uint, uint) {
	srcW := float32(img.Bounds().Size().X)
	srcH := float32(img.Bounds().Size().Y)

	scaleW := srcW / float32(minWidth)
	scaleH := srcH / float32(minHeight)

	scale := scaleW
	if scaleH < scaleW {
		scale = scaleH
	}

	if scale < 1 {
		scale = 1
	}

	return uint(srcW / scale), uint(srcH / scale)
}

func pathExists(path string) (bool, error) {
	_, err := os.Stat(path)
	if err == nil {
		return true, nil
	}
	if os.IsNotExist(err) {
		return false, nil
	}
	return false, err
}
