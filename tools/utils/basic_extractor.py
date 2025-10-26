import struct

def extract_basic_block(sna_path, output_path, asm_output):
    with open(sna_path, "rb") as f:
        data = f.read()

    # Адрес PROG в памяти
    prog_addr = 0x1CE6
    end = 0x1D32

   
    basic_block = data[prog_addr:end]

    with open(output_path, "wb") as out:
        out.write(basic_block)

        with open(asm_output, "w", encoding="utf-8") as out:
            out.write("basic_loader:\n")
            hex_bytes = [f"${b:02x}" for b in basic_block]
            line = "  db " + ",".join(hex_bytes)
            out.write(line + "\n")
            out.write("basic_loader_end:\n")

    
# Пример использования
extract_basic_block("D:\\speccy\\speccy\\.build\\tetris\\loader_basic_snap.sna", 
                    "D:\\speccy\\speccy\\.build\\tetris\\basic_block.bin",
                    "D:\\speccy\\speccy\\.build\\tetris\\basic_loader.asm")