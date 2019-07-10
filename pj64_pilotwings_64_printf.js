var printf_function = 0x8022ED14

String.prototype.repeat = String.prototype.repeat || function(n){
    word = ''
    for(var i = 0; i < n; i++){
        word += this
    }
    return word
}

events.onexec(printf_function, function() {
    format = mem.getstring(gpr.a0).replace(/[\r\n]+$/g, '') // strip out newlines at end
    arg4 = mem.u32[gpr.sp + 0x10] // grab potential 4th arg from stack
    args = [gpr.a1, gpr.a2, gpr.a3, arg4]
    msg = format
    for (var i = 0; i < args.length; i++) {
        dec_idx = msg.indexOf('%7d')
        hex_idx = msg.indexOf('%08x')
        // primitive way to handle '%7d' and '%08x'
        if (dec_idx > -1 && (dec_idx < hex_idx || hex_idx < 0)) {
            arg_str = args[i].toString()
            str = ' '.repeat(7 - arg_str.length) + arg_str
            msg = msg.replace(/%7d/, str)
        }
        else if (hex_idx > -1 && (hex_idx < dec_idx || dec_idx < 0)) {
            arg_str = args[i].toString(16)
            str = '0'.repeat(8 - arg_str.length) + arg_str
            msg = msg.replace(/%08x/, str)
        }
    }
    console.log(msg)
});
