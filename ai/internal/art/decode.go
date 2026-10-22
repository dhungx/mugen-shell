package art

import (
	"errors"
	"fmt"
	"image"
	"io"
	"os"
)

// Far above any cover art that fits curl's 8 MiB cap; a 16-bit PNG this size still decodes to 320 MB.
const maxPixels = 40_000_000

var errTooLarge = errors.New("art: image is over the pixel limit")

// decodeImage rejects a canvas too large to hold before allocating it: art
// arrives from MPRIS artUrl, where a few KB of PNG can declare gigabytes.
func decodeImage(file *os.File) (image.Image, string, error) {
	cfg, _, err := image.DecodeConfig(file)
	if err != nil {
		return nil, "", err
	}
	if pixels := int64(cfg.Width) * int64(cfg.Height); pixels > maxPixels {
		return nil, "", fmt.Errorf("%w: %dx%d", errTooLarge, cfg.Width, cfg.Height)
	}
	if _, err := file.Seek(0, io.SeekStart); err != nil {
		return nil, "", err
	}
	return image.Decode(file)
}
