"""
Converts an Intel hex file (like what would be generated
by avr-gcc or Arduino IDE) into a format readable by Verilog's
$readmemh function. Will also convert the file into segments of
64 bytes, and strip away the colon & checksum.
See https://developer.arm.com/documentation/ka003292/latest/
"""
import sys
import math
from intelhex import IntelHex

def split_to_bytes(val, n_bytes=2):
    b = []

    for i in range(n_bytes):
        b.append(val & 0xFF)
        val >>= 8

    return b

def main():
    if len(sys.argv) != 3:
        print(f"Usage: python3 {sys.argv[0]} [input file] [output file]")
        return

    in_file = sys.argv[1]
    out_file = sys.argv[2]
    
    # load Intel hex file
    ihex = IntelHex()
    ihex.loadhex(in_file)

    # buffer for file, will be converted to text representing the values in hex
    wr_bytes = []

    # go through each segment, fill buffer
    for segment in ihex.segments():
        start, end = segment
        seg_len = end - start
        print(f"Processing segment from 0x{start:04X} to 0x{end:04X} ({seg_len} bytes)...")

        # split segment into chunks of 64 bytes
        n_chunks = math.ceil(seg_len / 64)
        remaining = seg_len
        addr = start

        for i in range(n_chunks):
            chunk_size = min(64, remaining)
            remaining -= chunk_size

            print(f"Filling chunk #{i+1}: 0x{addr:04X} to 0x{addr+chunk_size:04X} ({chunk_size} bytes)...")
            
            # follow Intel hex format order
            wr_bytes.append(chunk_size)
            wr_bytes += split_to_bytes(addr)
            wr_bytes.append(0x00) # indicates data record

            for j in range(addr, addr+chunk_size):
                wr_bytes.append(ihex[j])

            addr += chunk_size

    # convert buffer to text & write to file
    print("Writing to file...")
    out_str = " ".join(format(x, "02X") for x in wr_bytes)

    with open(out_file, "w") as f:
        f.write(out_str)

    print("Done")


if __name__ == "__main__":
    main()
