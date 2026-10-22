package art

import (
	"image"
	"image/color"
	"image/png"
	"os"
	"testing"
)

func TestTrimBarsPeelsBothFramesInOnePass(t *testing.T) {
	src := image.NewGray(image.Rect(0, 0, 160, 160))
	for i := range src.Pix {
		src.Pix[i] = 40
	}
	for y := 35; y < 125; y++ {
		for x := 35; x < 125; x++ {
			src.SetGray(x, y, color.Gray{Y: uint8(x*7 + y*13)})
		}
	}
	path := writePNG(t, "framed.png", src)

	if err := TrimBars(path); err != nil {
		t.Fatalf("TrimBars: %v", err)
	}
	file, err := os.Open(path)
	if err != nil {
		t.Fatal(err)
	}
	defer file.Close()
	got, err := png.Decode(file)
	if err != nil {
		t.Fatal(err)
	}
	if b := got.Bounds(); b.Dx() != 90 || b.Dy() != 90 {
		t.Fatalf("trimmed size = %v, want 90x90", b)
	}
	for y := 0; y < 90; y++ {
		for x := 0; x < 90; x++ {
			gr, _, _, _ := got.At(x, y).RGBA()
			wr, _, _, _ := src.At(x+35, y+35).RGBA()
			if gr != wr {
				t.Fatalf("pixel (%d,%d) = %d, want %d", x, y, gr, wr)
			}
		}
	}
}
