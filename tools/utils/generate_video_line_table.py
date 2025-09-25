def get_video_addr(y):
    return 0x4000 | ((y & 0xC0) << 5) | ((y & 0x07) << 8) | ((y & 0x38) << 2)

with open("./vid_out/video_line_table.inc", "w") as f:
    f.write("        IFNDEF __VIDEO_LINE_TABLE__\n")
    f.write("        DEFINE __VIDEO_LINE_TABLE\n")
    f.write("VideoLineAddrTable:\n")
    for y in range(192):
        addr = get_video_addr(y)
        low = addr & 0xFF
        high = (addr >> 8) & 0xFF
        f.write(f"        db 0x{low:02X}, 0x{high:02X} ; Y={y}\n")
    f.write("        ENDIF\n")