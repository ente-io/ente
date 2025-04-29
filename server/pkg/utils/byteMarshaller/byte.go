package byteMarshaller

import (
	"bytes"
	"encoding/binary"
)

func ConvertInt64ToByte(i int64) (b []byte, err error) {
	buf := new(bytes.Buffer)
	err = binary.Write(buf, binary.BigEndian, i)
	if err != nil {
		return
	}

	b = buf.Bytes()

	return
}

func ConvertBytesToInt64(b []byte) (int64, error) {
	buf := bytes.NewReader(b)
	var num int64
	err := binary.Read(buf, binary.BigEndian, &num)
	if err != nil {
		return 0, err
	}
	return num, nil
}
