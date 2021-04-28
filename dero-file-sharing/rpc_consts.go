package fileSharing

import "github.com/deroproject/derohe/rpc"

const DefaultRPCAddress = "http://127.0.0.1:40403"

const (
	RPC_FILE_NAME = "F"
	RPC_FILE_PART = "P"
	RPC_CONTENT   = rpc.RPC_COMMENT // = "C"
)

const (
	// RPC_FILENAME      = "F"
	RPC_FILE_PARTS_COUNT = "PC"
	RPC_FILE_TYPE        = "T"
	RPC_CHECKSUM         = rpc.RPC_COMMENT // = "C"
)

const (
	RPC_FILE_TYPE_TEXT   = "TEXT"
	RPC_FILE_TYPE_BINARY = "BIN"
)
