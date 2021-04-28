package main

import (
	"bufio"
	"encoding/base64"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/boltdb/bolt"
	"github.com/ybbus/jsonrpc"

	"github.com/deroproject/derohe/rpc"

	fileSharing "dero-file-sharing"
)

func main() {
	var rpcAddress string
	flag.StringVar(&rpcAddress, "rpc-address", fileSharing.DefaultRPCAddress, "OPTIONAL: address of the wallet RPC server")
	flag.Parse()

	dbName := "file_receiver.bbolt.db"
	db, err := bolt.Open(dbName, 0600, nil)
	if err != nil {
		log.Fatalf("Error opening db: %s\n", err)
	}
	interceptSigTerm(db)

	err = db.Update(func(tx *bolt.Tx) error {
		_, err := tx.CreateBucketIfNotExists([]byte("TXs"))
		return err
	})
	if err != nil {
		log.Fatalf("Error creating bucket: %s\n", err)
	}

	fmt.Printf("Persistent store: %s\n", dbName)

	rpcEndpoint := fmt.Sprintf("%s/json_rpc", rpcAddress)
	rpcClient := jsonrpc.NewClient(rpcEndpoint)

	processingThread(db, rpcClient)
}

func processingThread(db *bolt.DB, rpcClient jsonrpc.RPCClient) {
	var (
		files              = make(fileSharing.Files)
		f                  *fileSharing.File
		ok                 bool
		isFilePart         bool
		filename           string
		filePart           uint64
		content            string
		fileType           string
		filePartsCount     uint64
		checksum           string
		expectedChecksum   string
		actualFile         *os.File
		actualFileChecksum string
		err                error
	)

	fmt.Println("Waiting for files...")

	for {
		time.Sleep(time.Second)

		var transfers rpc.Get_Transfers_Result
		err = rpcClient.CallFor(&transfers, "GetTransfers", rpc.Get_Transfers_Params{In: true})
		if err != nil {
			log.Printf("Error getting transfers from wallet: %s\n", err)
			continue
		}

		for _, e := range transfers.Entries {
			if e.Coinbase || !e.Incoming {
				continue
			}

			if e.TopoHeight <= 211468 { // todo rimuovere
				continue
			}

			var alreadyProcessed bool
			db.View(func(tx *bolt.Tx) error {
				if b := tx.Bucket([]byte("TXs")); b != nil {
					if ok := b.Get([]byte(e.TXID)); ok != nil {
						alreadyProcessed = true
					}
				}
				return nil
			})

			if alreadyProcessed {
				continue
			}

			if !e.Payload_RPC.Has(fileSharing.RPC_FILE_NAME, rpc.DataString) {
				continue
			}
			filename = e.Payload_RPC.Value(fileSharing.RPC_FILE_NAME, rpc.DataString).(string)

			if e.Payload_RPC.Has(fileSharing.RPC_FILE_PART, rpc.DataUint64) && e.Payload_RPC.Has(fileSharing.RPC_CONTENT, rpc.DataString) {
				isFilePart = true
				filePart = e.Payload_RPC.Value(fileSharing.RPC_FILE_PART, rpc.DataUint64).(uint64)
				content = e.Payload_RPC.Value(fileSharing.RPC_CONTENT, rpc.DataString).(string)
			} else if e.Payload_RPC.Has(fileSharing.RPC_FILE_TYPE, rpc.DataString) && e.Payload_RPC.Has(fileSharing.RPC_CHECKSUM, rpc.DataString) &&
				e.Payload_RPC.Has(fileSharing.RPC_FILE_PARTS_COUNT, rpc.DataUint64) {
				isFilePart = false
				fileType = e.Payload_RPC.Value(fileSharing.RPC_FILE_TYPE, rpc.DataString).(string)
				filePartsCount = e.Payload_RPC.Value(fileSharing.RPC_FILE_PARTS_COUNT, rpc.DataUint64).(uint64)
				checksum = e.Payload_RPC.Value(fileSharing.RPC_CHECKSUM, rpc.DataString).(string)
			} else {
				continue
			}

			if isFilePart {
				if filePart == 1 {
					files[filename] = &fileSharing.File{
						LastPart:     1,
						PartsContent: []string{},
					}
					files[filename].PartsContent = append(files[filename].PartsContent, content)
				} else {
					f, ok = files[filename]
					if !ok {
						continue
					}
					if filePart != (f.LastPart + 1) {
						continue
					}
					f.LastPart++
					f.PartsContent = append(f.PartsContent, content)
				}
			} else { // is final TX
				f, ok = files[filename]
				if !ok {
					continue
				}
				if filePartsCount != f.LastPart {
					continue
				}

				actualFile, err = os.Create("./" + filename)
				if err != nil {
					log.Printf("Error opening file %s: %s\n", filename, err)
					continue
				}

				w := bufio.NewWriter(actualFile)
				var vBytes []byte

				for i, v := range f.PartsContent {
					part := i + 1
					if fileType == fileSharing.RPC_FILE_TYPE_TEXT {
						vBytes = []byte(v)
					} else {
						vBytes, err = base64.StdEncoding.DecodeString(v)
						if err != nil {
							log.Printf("Error decoding file part %d: %s\n", part, err)
							continue
						}
					}
					_, err = w.Write(vBytes)
					if err != nil {
						log.Printf("Error writing file part %d: %s\n", part, err)
						continue
					}
					fmt.Printf("Part %d written to file %s.\n", part, filename)
				}

				w.Flush()

				err = actualFile.Close()
				if err != nil {
					log.Printf("Error closing file %s: %s\n", filename, err)
					continue
				}

				actualFileChecksum, err = fileSharing.FileChecksum("./" + filename)
				if err != nil {
					log.Printf("Error generating checksum: %v\n", err)
				}

				expectedChecksum = checksum
				if expectedChecksum == actualFileChecksum {
					fmt.Printf("Checksums match!\nChecksum: %s.\n", actualFileChecksum)
				} else {
					fmt.Printf("Something went wrong.\nExpected checksum: %s.\nActual checksum: %s.\n", expectedChecksum, actualFileChecksum)
				}

				delete(files, filename)
			}

			err = db.Update(func(tx *bolt.Tx) error {
				b := tx.Bucket([]byte("TXs"))
				return b.Put([]byte(e.TXID), []byte("ok"))
			})
			if err != nil {
				log.Printf("Error updating DB: %s\n", err)
			}
		}
	}
}

func interceptSigTerm(db *bolt.DB) {
	c := make(chan os.Signal)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		fmt.Println("Ctrl+C pressed. SIGTERM received.")
		fmt.Println("Exiting from application...")
		err := db.Close()
		if err != nil {
			log.Printf("Error closing DB: %s\n", err)
		}
		os.Exit(0)
	}()
}
