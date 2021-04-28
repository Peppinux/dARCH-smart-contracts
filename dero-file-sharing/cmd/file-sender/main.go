package main

import (
	"bufio"
	"encoding/base64"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"unicode/utf8"

	"github.com/ybbus/jsonrpc"

	"github.com/deroproject/derohe/rpc"
	"github.com/deroproject/derohe/transaction"

	fileSharing "dero-file-sharing"
)

func main() {
	var (
		filename    string
		destination string
		rpcAddress  string
	)
	flag.StringVar(&filename, "file", "", "REQUIRED: path of the file to send")
	flag.StringVar(&destination, "destination", "", "REQUIRED: dero address of the receiver")
	flag.StringVar(&rpcAddress, "rpc-address", fileSharing.DefaultRPCAddress, "OPTIONAL: address of the wallet RPC server")
	flag.Parse()

	isTextFile, err := isTextFile(filename)
	if err != nil {
		log.Fatalf("Error determining file type: %s\n", err)
	}

	f, err := os.Open(filename)
	if err != nil {
		log.Fatalf("Error opening file %s: %s\n", filename, err)
	}

	rpcEndpoint := fmt.Sprintf("%s/json_rpc", rpcAddress)
	rpcClient := jsonrpc.NewClient(rpcEndpoint)

	var (
		transferParams = rpc.Transfer_Params{Transfers: []rpc.Transfer{}}
		payload        rpc.Arguments
		payloadSize    int
		freeBytes      int
		content        string
		filePart       = uint64(1)
		r              = bufio.NewReader(f)
		b              []byte
		n              int
	)

	for {
		payload = rpc.Arguments{
			{Name: fileSharing.RPC_FILE_NAME, DataType: rpc.DataString, Value: filename},
			{Name: fileSharing.RPC_FILE_PART, DataType: rpc.DataUint64, Value: filePart},
			{Name: fileSharing.RPC_CONTENT, DataType: rpc.DataString, Value: ""},
		}

		payloadSize, err = sizeArgs(payload)
		if err != nil {
			log.Fatalf("Error calculating payload size: %s\n", err)
		}

		freeBytes = (transaction.PAYLOAD0_LIMIT - payloadSize - 1)
		if freeBytes == 0 {
			log.Fatalf("No free space in payload for file part %d contents\n", filePart)
		}
		if !isTextFile {
			freeBytes /= 2
		}

		b = make([]byte, freeBytes)
		n, err = r.Read(b)
		if err != nil {
			if err == io.EOF {
				filePart--
				break
			} else {
				log.Fatalf("Error reading file part %d: %s\n", filePart, err)
			}
		}

		if isTextFile {
			content = string(b[:n])
		} else {
			content = base64.StdEncoding.EncodeToString(b[:n])
		}

		payload[2] = rpc.Argument{Name: fileSharing.RPC_CONTENT, DataType: rpc.DataString, Value: content}

		addTransfer(destination, uint64(1), payload, &transferParams)

		filePart++
	}

	err = f.Close()
	if err != nil {
		log.Fatalf("Error closing file %s: %s\n", filename, err)
	}

	var fileType string
	if isTextFile {
		fileType = fileSharing.RPC_FILE_TYPE_TEXT
	} else {
		fileType = fileSharing.RPC_FILE_TYPE_BINARY
	}

	checksum, err := fileSharing.FileChecksum(filename)
	if err != nil {
		log.Fatalf("Error generating checksum: %v\n", err)
	}

	payload = rpc.Arguments{
		{Name: fileSharing.RPC_FILE_NAME, DataType: rpc.DataString, Value: filename},
		{Name: fileSharing.RPC_FILE_TYPE, DataType: rpc.DataString, Value: fileType},
		{Name: fileSharing.RPC_FILE_PARTS_COUNT, DataType: rpc.DataUint64, Value: filePart},
		{Name: fileSharing.RPC_CHECKSUM, DataType: rpc.DataString, Value: checksum},
	}

	addTransfer(destination, uint64(1), payload, &transferParams)

	var res string
	err = rpcClient.CallFor(&res, "Transfer", transferParams)
	if err != nil {
		log.Fatalf("Error sending transfers: %s\n", err)
	}

	fmt.Printf("File %s sent in %d TXs.\nChecksum: %s\n", filename, len(transferParams.Transfers), checksum)
}

func sizeArgs(args rpc.Arguments) (int, error) {
	packed, err := args.MarshalBinary()
	if err != nil {
		return 0, err
	}
	return len(packed), nil
}

func addTransfer(destination string, amount uint64, payload rpc.Arguments, transferParams *rpc.Transfer_Params) {
	transfer := rpc.Transfer{
		Destination: destination,
		Amount:      amount,
		Payload_RPC: payload,
	}
	transferParams.Transfers = append(transferParams.Transfers, transfer)
}

// IsTextFile reports whether a significant chunk of the specified file looks like
// correct UTF-8; that is, if it is likely that the file contains human-readable text.
// Credits to: https://pkg.go.dev/golang.org/x/tools/godoc/util#IsTextFile
func isTextFile(filename string) (bool, error) {
	// read an initial chunk of the file and check if it looks like text
	f, err := os.Open(filename)
	if err != nil {
		return false, err
	}
	defer f.Close()

	var buf [1024]byte
	n, err := f.Read(buf[0:])
	if err != nil {
		return false, err
	}

	return isText(buf[0:n]), nil
}

// IsText reports whether a significant prefix of s looks like correct UTF-8;
// that is, if it is likely that s is human-readable text.
// Credits to: https://pkg.go.dev/golang.org/x/tools/godoc/util#IsText
func isText(s []byte) bool {
	const max = 1024 // at least utf8.UTFMax
	if len(s) > max {
		s = s[0:max]
	}
	for i, c := range string(s) {
		if i+utf8.UTFMax > len(s) {
			// last char may be incomplete - ignore
			break
		}
		if c == 0xFFFD || c < ' ' && c != '\n' && c != '\t' && c != '\f' {
			// decoding error or control character - not a text file
			return false
		}
	}
	return true
}
