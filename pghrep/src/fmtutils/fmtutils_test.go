package fmtutils

import (
    "testing"
    "strings"
)

func TestByteFormat(t *testing.T) {
    var value string
    value = ByteFormat(982, 0)
    if strings.Compare(value, "982 bytes") != 0 {
        t.Fatalf("ByteFormat 982 expected '982 bytes', got '%s'", value)
    }

    value = ByteFormat(1982, 0)
    if strings.Compare(value, "2 KiB") != 0 {
        t.Fatalf("ByteFormat 1982 expected '2 KiB', got '%s'", value)
    }

    value = ByteFormat(13820, 0)
    if strings.Compare(value, "14 KiB") != 0 {
        t.Fatalf("ByteFormat 13820 expected '14 KiB', got '%s'", value)
    }

    value = ByteFormat(135820, 0)
    if strings.Compare(value, "133 KiB") != 0 {
        t.Fatalf("ByteFormat 135820 expected '133 KiB', got '%s'", value)
    }

    value = ByteFormat(1735820, 0)
    if strings.Compare(value, "2 MiB") != 0 {
        t.Fatalf("ByteFormat 1735820 expected '2 MiB', got '%s'", value)
    }

    value = ByteFormat(173583220, 0)
    if strings.Compare(value, "166 MiB") != 0 {
        t.Fatalf("ByteFormat 173583220 expected '166 MiB', got '%s'", value)
    }

    value = ByteFormat(1735823330, 0)
    if strings.Compare(value, "2 GiB") != 0 {
        t.Fatalf("ByteFormat 1735823330 expected '2 GiB', got '%s'", value)
    }

    value = ByteFormat(173500823330, 0)
    if strings.Compare(value, "162 GiB") != 0 {
        t.Fatalf("ByteFormat 173500823330 expected '162 GiB', got '%s'", value)
    }

    value = ByteFormat(17350082330230, 0)
    if strings.Compare(value, "16 TiB") != 0 {
        t.Fatalf("ByteFormat 17350082330230 expected '16 TiB', got '%s'", value)
    }
}

func TestGetUnit(t *testing.T) {
    var value int64
    value = GetUnit("8kB");
    if value != 8192 {
        t.Fatalf("GetUnit 8kB expected 8192, got %d", value)
    }

    value = GetUnit("8MB");
    if value != 8388608 {
        t.Fatalf("GetUnit 8MB expected 8388608, got %d", value)
    }

    value = GetUnit("8GB");
    if value != 8589934592 {
        t.Fatalf("GetUnit 8GB expected 8589934592, got %d", value)
    }

    value = GetUnit("8TB");
    if value != 8796093022208 {
        t.Fatalf("GetUnit 8TB expected 8796093022208, got %d", value)
    }
}

func TestGetUnit2(t *testing.T) {
    var value int64
    value = GetUnit("kB");
    
    if value != 1024 {
        t.Fatalf("GetUnit kB expected 1024, got %d", value)
    }

    value = GetUnit("MB");
    if value != 1024*1024 {
        t.Fatalf("GetUnit MB expected %d, got %d", 1024*1024, value)
    }

    value = GetUnit("GB");
    if value != 1024*1024*1024 {
        t.Fatalf("GetUnit GB expected %d, got %d", 1024*1024*1024, value)
    }

    value = GetUnit("TB");
    if value != 1024*1024*1024*1024 {
        t.Fatalf("GetUnit TB expected %d, got %d", 1024*1024*1024*1024, value)
    }

}