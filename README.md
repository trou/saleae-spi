## About

Trivial tool in Ruby to parse the result from the SPI analyzer from Saleae, exported in CSV.

It analyzes (some) commands and allows you to export the data that is read from
the SPI to a binary file, very useful to check an SPI flash content.

## Example
```
$ ./decode_spi.rb boot_spi1.csv dump
0.039776 : WRITE DISABLE
0.039777 : JEDEC READ ID
0.039784 : ID 0x7f 0x9d 0x21
---------------------
0.039788 : READ @ 0x0
0x12,0x42,0x00,0xd3,0x22,0x00,0x00,0x00,0x00,0x00
[...]
```
