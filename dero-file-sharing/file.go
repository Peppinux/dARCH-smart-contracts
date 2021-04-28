package fileSharing

import (
	"crypto/sha256"
	"fmt"
	"io"
	"os"
)

type File struct {
	LastPart     uint64
	PartsContent []string
}

type Files map[string]*File // Map filename to file

func FileChecksum(filename string) (string, error) {
	f, err := os.Open(filename)
	if err != nil {
		return "", fmt.Errorf("file checksum open %s: %v", filename, err)
	}
	defer f.Close()

	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", fmt.Errorf("file checksum copy file %s into hash: %v", filename, err)
	}

	sum := h.Sum(nil)

	return fmt.Sprintf("%x", sum), nil
}
