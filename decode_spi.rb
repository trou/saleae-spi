#!/usr/bin/env ruby
require "pp"

module SPI_STATE
    CMD_WAIT = 0
    READ_CMD = 1
    DATA_READ = 2
    READ_STATUS = 3
    PP = 4
    WRITE_STATUS = 5
    SECTOR_ERASE = 6
    BLOCK_ERASE = 7
    CHIP_ERASE = 8
    READ_ID = 9
end

def next_state(mosi)
    case mosi
        when 2 then
            return SPI_STATE::PP
        when 3 then
            return SPI_STATE::READ_CMD
        when 1 then
            return SPI_STATE::WRITE_STATUS
        when 5 then
            return SPI_STATE::READ_STATUS
        when 0x20 then
            return SPI_STATE::SECTOR_ERASE
        when 0xD8 then
            return SPI_STATE::BLOCK_ERASE
        when 0x60 then
            return SPI_STATE::CHIP_ERASE
        when 0x9F then
            return SPI_STATE::READ_ID
        when 0xC7 then
            return SPI_STATE::CHIP_ERASE
        else
#            puts "Unkown : %x" % mosi
            return SPI_STATE::CMD_WAIT
    end
end

lines = File.readlines(ARGV.shift)
dump = File.open(ARGV[0], 'wb+') if ARGV[0]
state = SPI_STATE::CMD_WAIT
address = []
data = []
last_time = 0
last_read = 0
add_int = 0
lines.each do |l|
    if l =~ %r{^-?[0-9.]+,} then
        time, _proto, mosi_miso = l.split(',')
        mosi, miso = mosi_miso.split(';') 
        time = time.to_f
        #puts mosi
        #puts miso
        mosi = mosi[/.*(0x[0-9A-F]+)/,1].to_i(16)
        miso = miso[/.*(0x[0-9A-F]+)/,1].to_i(16)
        #puts ("%x %x\n" % [mosi, miso])
        case state
            when SPI_STATE::CMD_WAIT
                state = next_state(mosi)
                case mosi
                    when 2, 3 then
                        address = []
                    when 4 then
                        puts "%f : WRITE DISABLE" % time
                    when 6 then
                        puts "%f : WREN" % time
                    when 0x60 then
                        puts "%f : CHIP_ERASE" % time
                    when 0x9f then
                        puts "%f : JEDEC READ ID" % time
                    when 0xC7 then
                        puts "%f : CHIP_ERASE" % time
                end
            when SPI_STATE::READ_STATUS
                puts "%f : RSR : %x" % [time, mosi]
                state = SPI_STATE::CMD_WAIT
            when SPI_STATE::WRITE_STATUS
                puts "%f : WSR : %x" % [time, mosi]
                state = SPI_STATE::CMD_WAIT
            when SPI_STATE::READ_ID
                if data.length < 3 then
                    data << miso
                else
                    data << miso
                    puts "%f : ID 0x%02x 0x%02x 0x%02x" % [time, data[0], data[1], data[2]]
                    state = SPI_STATE::CMD_WAIT
                    data = []
                end
            when SPI_STATE::PP
                if address.length < 2 then
                    address << mosi
                else
                    address << mosi
                    add_int = (address[0]<<16)|(address[1]<<8)|address[2]
                    puts "%f : PP @ 0x%x" %  [time, add_int ]
                    state = SPI_STATE::DATA_READ
                    data = []
                end
            when SPI_STATE::SECTOR_ERASE
                if address.length < 2 then
                    address << mosi
                else
                    address << mosi
                    add_int = (address[0]<<16)|(address[1]<<8)|address[2]
                    state = SPI_STATE::CMD_WAIT
                    puts "%f : SECTOR_ERASE @ 0x%x" %  [time, add_int]
                end
            when SPI_STATE::BLOCK_ERASE
                if address.length < 2 then
                    address << mosi
                else
                    address << mosi
                    add_int = (address[0]<<16)|(address[1]<<8)|address[2]
                    state = SPI_STATE::CMD_WAIT
                    puts "%f : BLOCK_ERASE @ 0x%x" %  [time, add_int]
                end
            when SPI_STATE::READ_CMD
                if address.length < 2 then
                    address << mosi
                else
                    address << mosi
                    add_int = (address[0]<<16)|(address[1]<<8)|address[2]
                    state = SPI_STATE::DATA_READ
                    puts "---------------------" if time-last_read > 2e-5
                    puts "%f : READ @ 0x%x" %  [time, add_int]
                    last_read = time
                    data = []
                end
            when SPI_STATE::DATA_READ
               if (time-last_time) > 3.0e-6 then
                   if dump then
                       dump.seek(add_int)
                       dump.write(data.pack('C*'))
                   end
                   puts data.map {|p| "0x%02x" % p}.join(',')
                   state = next_state(mosi)
                   address = []
               else
                   data << miso
               end
        end
        last_time = time
    end
end
