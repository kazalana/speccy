$binPath = "D:\speccy\speccy\.build\main.bin"
$address = 32768
$length = (Get-Item $binPath).Length
$command = "load-binary $binPath $address $length"

$command | ncat localhost 10000