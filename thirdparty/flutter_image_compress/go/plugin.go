package flutter_image_compress

import (
	"bytes"
	"fmt"
	"image"
	"image/jpeg"
	"image/png"
	"io"
	"os"

	"github.com/chai2010/webp"
	flutter "github.com/go-flutter-desktop/go-flutter"
	"github.com/go-flutter-desktop/go-flutter/plugin"
)

const (
	channelName         = "flutter_image_compress"
	methodListToList    = `compressWithList`
	methodListToFile    = `compressWithFile`
	methodFileToFile    = `compressWithFileAndGetFile`
	methodLog           = `showLog`
	methodSystemVersion = `getSystemVersion`
)

// FlutterImageCompressPlugin implements flutter.Plugin and handles method.
type FlutterImageCompressPlugin struct{}

var _ flutter.Plugin = &FlutterImageCompressPlugin{} // compile-time type check

// InitPlugin initializes the plugin.
func (p *FlutterImageCompressPlugin) InitPlugin(messenger plugin.BinaryMessenger) error {
	channel := plugin.NewMethodChannel(messenger, channelName, plugin.StandardMethodCodec{})

	channel.HandleFunc(methodListToList, listToList)
	channel.HandleFunc(methodListToFile, listToFile)
	channel.HandleFunc(methodFileToFile, fileToFile)
	channel.HandleFunc(methodLog, showLog)
	channel.HandleFunc(methodSystemVersion, getSystemVersion)

	return nil
}

func showLog(arguments interface{}) (reply interface{}, err error) {
	return nil, nil
}

func encode(targetType int32, img image.Image, quality int, writer io.Writer) error {
	switch targetType {
	case 0:
		return jpeg.Encode(writer, img, &jpeg.Options{Quality: quality})
	case 1:
		return png.Encode(writer, img)
	case 2:
		return fmt.Errorf("Not support heic")
	case 3:
		return webp.Encode(writer, img, &webp.Options{
			Lossless: false,
			Quality:  float32(quality),
			Exact:    false,
		})
	}

	return fmt.Errorf("Not support format")
}

func listToList(arguments interface{}) (reply interface{}, err error) {
	args := arguments.([]interface{})
	img := args[0].([]uint8)
	minWidth := args[1].(int32)
	minHeight := args[2].(int32)
	quality := int(args[3].(int32))
	rotate := int(args[4].(int32))
	targetType := args[6].(int32)

	reader := bytes.NewReader(img)

	scaled, err := ScaleImage(reader, minWidth, minHeight)
	if err != nil {
		return
	}

	scaled = RotateImage(scaled, rotate)

	writer := bytes.Buffer{}

	err = encode(targetType, scaled, quality, &writer)
	if err != nil {
		return
	}

	reply = writer.Bytes()

	return
}

func listToFile(arguments interface{}) (reply interface{}, err error) {
	args := arguments.([]interface{})
	srcPath := args[0].(string)
	minWidth := args[1].(int32)
	minHeight := args[2].(int32)
	quality := int(args[3].(int32))
	rotate := int(args[4].(int32))
	targetType := args[6].(int32)

	reader, err := os.Open(srcPath)

	if err != nil {
		return
	}

	scaled, err := ScaleImage(reader, minWidth, minHeight)
	if err != nil {
		return
	}

	scaled = RotateImage(scaled, rotate)

	writer := bytes.Buffer{}

	err = encode(targetType, scaled, quality, &writer)
	if err != nil {
		return
	}

	reply = writer.Bytes()

	return
}

func fileToFile(arguments interface{}) (reply interface{}, err error) {
	args := arguments.([]interface{})
	srcPath := args[0].(string)
	minWidth := args[1].(int32)
	minHeight := args[2].(int32)
	quality := int(args[3].(int32))
	targetPath := args[4].(string)
	rotate := int(args[5].(int32))
	targetType := args[7].(int32)

	reader, err := os.Open(srcPath)

	if err != nil {
		return
	}

	scaled, err := ScaleImage(reader, minWidth, minHeight)
	if err != nil {
		return
	}

	scaled = RotateImage(scaled, rotate)

	exists, err := pathExists(targetPath)
	if err != nil {
		return
	}

	if exists {
		_ = os.Remove(targetPath)
	}

	writer, _ := os.OpenFile(targetPath, os.O_RDWR|os.O_CREATE, 777)

	err = encode(targetType, scaled, quality, writer)
	if err != nil {
		return
	}

	reply = targetPath

	return
}

func getSystemVersion(arguments interface{}) (reply interface{}, err error) {
	args := arguments.([]interface{})
	showAllArgsType(args)
	panic("not implements")
}

func typeof(v interface{}) string {
	return fmt.Sprintf("%T", v)
}

func showAllArgsType(args []interface{}) {
	for i, v := range args {
		fmt.Printf("%d, type = %s \n", i, typeof(v))
	}
}
