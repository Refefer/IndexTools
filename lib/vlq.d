import std.algorithm, std.conv, std.stdio, std.range;

uint bit_count(ulong number) {
    int count = 0;
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

string vlq_encode_number(ulong number) {
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
    return to!string(joiner(map!vlq_encode_number(r), ""));
}

string bitpack_encode(R)(in R numbers) {
    auto max_num = max(numbers);
    auto bits = bit_count(numbers);
    char[] bitpack;
    bitpack.length = (bits * numbers.length) / 8 
                   + (numbers.length % 8 ? 1 : 0) + 1;
    bitpack[0] = bits;
    size_t index = 1, cur_number = 0, cur_bits = 0;
    foreach(size_t number; numbers) {
        cur_number += number;
        cur_bits += bits;
        while(cur_bits > 7) {
            bitpack[index] = cur_number >> (cur_bits - 8) & 0xFF;
            ++index;
            cur_bits -= 8;
        }
    }
    return bitpack;
}

struct BitUnpacker {

    this(in string buffer, size_t offset) {
        bits_ = buffer[offset];
        buffer_ = buffer;
        offset_ = ++offset;
    }
    string buffer_;
    size_t offset_;
    char bits_;
}

unittest {
    for(auto i = 0; i < 128;++i) {
        auto number = vlq_encode_number(i);
        assert(number.length == 1);
        assert(to!ubyte(number[0]) == i);
    }
    assert(vlq_encode_number(128) == x"81 00");
    
    foreach(i, c; vlq_encoder!(ulong[])([0,1,2,3,4,5,6])) {
        assert(i == to!ubyte(c));
    }
    assert(vlq_encoder([10,65,66,67,68]) == "\nABCD");
}


void main(){}
