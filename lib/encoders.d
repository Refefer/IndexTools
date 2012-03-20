import std.algorithm, std.conv, std.stdio, std.range, std.array;

ubyte bit_count(ulong number) {
    char count = 0;
    while(number) {
        count++;
        number >>= 1;
    }
    return count;
}

unittest {
    assert(bit_count(2) == 2);
    assert(bit_count(1) == 1);
    assert(bit_count(0) == 0);
}

string vlq_encode(ulong number) {
    if(number == 0) return "\0";
    auto bits = bit_count(number);
    char[] vlq;
    vlq.length = bits/7 + (bits % 7 ? 1 : 0);
    vlq[vlq.length-1] = number & 127;
    if(vlq.length > 1) {
        number >>= 7;
        for(auto i = vlq.length-1; i > 0; --i) {
            vlq[i-1] = number & 127 | 128;
            number >>= 7;
        }
    }
    return to!string(vlq);
}

string vlq_encoder(R)(in R r) {
    return to!string(joiner(map!vlq_encode(r), ""));
}

unittest {
    for(auto i = 0; i < 128;++i) {
        auto number = vlq_encode(i);
        assert(number.length == 1);
        assert(to!ubyte(number[0]) == i);
    }
    assert(vlq_encode(128) == x"81 00");
    
    foreach(i, c; vlq_encoder([0,1,2,3,4,5,6])) {
        assert(i == to!ubyte(c));
    }
    assert(vlq_encoder([10,65,66,67,68]) == "\nABCD");
}

string bitpack_encode(R)(ref R numbers) {
    auto max_num = reduce!max(numbers);
    auto bits = max(bit_count(max_num), cast(ubyte)1);
    char[] bitpack;
    bitpack.length = (bits * numbers.length) / 8 
                   + (numbers.length % 8 ? 1 : 0) + 1;
    bitpack[0] = bits;
    ulong index = 1, cur_number = 0, cur_bits = 0;
    foreach(ulong number; numbers) {
        cur_number = (cur_number << bits) +number;
        cur_bits += bits;
        while(cur_bits >= 8) {
            bitpack[index] = (cur_number >> (cur_bits - 8)) & 0xFF;
            number >>= 8;
            ++index;
            cur_bits -= 8;
        }
    }

    if(cur_bits) {
        bitpack[index] = (cur_number << (8 - cur_bits)) & 0xFF;
    }
    return to!string(bitpack);
}


ulong bitpack_decode(OR)(ref OR results, in string buffer, ulong offset, ulong amount) {
    uint num_bits = buffer[offset++];
    ulong cur_num = 0;
    uint cur_bits = 0;
    while(true) {
        
        cur_num  += buffer[offset++];
        cur_bits += 8;

        while(cur_bits >= num_bits) {
            auto bit_shift = cur_bits - num_bits;
            results.put(cur_num >> (bit_shift));
            cur_num = cur_num & ((1 << bit_shift) - 1);
            cur_bits -= num_bits;
            if(!(--amount)) return offset;
        }
        cur_num <<= 8;
    }
}

unittest {
    auto d = [0,1,2,3,4]; 
    auto encoded = bitpack_encode(d);
    assert(encoded.length == 3);
    assert(encoded[0] == '\3');
    auto app = appender!(ulong[])();
    auto offset = bitpack_decode(app, encoded, 0, 5);
    assert(offset == 3);
    assert(app.data == d);

    d = [0,0,0,0];
    encoded = bitpack_encode(d);
    assert(encoded == x"01 00");
}

void main(){}
