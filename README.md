## Overview
The AssertSpecial Flag parameter has a stack smash exploit. We can perform a ROP technique in order to achieve arbitrary code execution from the stack.
The flag parameter has a buffer of 0x40 bytes, followed immediately by return address. Since this is not a formatted string, the 0x40 bytes have to be filled manually.
The flag parameter is read using a standard library function that does not perform buffer range checking, thus allowing the overflow.

The technique used is a more complicated version of the ROP chain developed in https://www.fuzzysecurity.com/tutorials/expDev/7.html - this article is a great first look at what ROP is and how it works.

## How do I use this?

The simplest way is to grab a copy of `supernull_kfm.cns` and `asm/supernull.asm`. Use `supernull.asm` as a base and write your code. Then, place the assembled code directly above the Statedef line in `supernull_kfm.cns`, replacing the existing payload. You should **never** touch anything below the Statedef declaration, as that is the ROP chain + bootstrap fragment.

The file parser breaks the file into lines based on the presence of a NULL byte (0x00) in your code. Raw NULL bytes in your code will not be loaded properly.
However, if you replace these with newlines (0x0D 0x0A), the file parser will create a NULL byte in its place for you.
So you can freely use 0x00 bytes in your code, provided you do some post-processing to turn them into newlines.

You must also make sure to leave a newline (0x0D 0x0A) between your code and the Statedef line, or else the parser will complain.

## Some Useful Offsets

As a part of the ROP chain, the following addresses are populated with useful data:

0x67BD0324 - Pointer to the VirtualProtect function
0x67BD0210 - "VirtualProtect" as a string (likely not to be too useful)

These addresses can also be helpful:

0x10008044 - Pointer to the KERNEL32 module handle
0x004DE030 - Pointer to the GetProcAddress function

## Technicals

The ROP chain is quite complex due to some limitations involved:
- cannot use gadgets from mugen.exe or pthreadVC2.dll due to 0x00 bytes in the addresses
- cannot use several other gadgets due to the string being forced lowercase - very limited in move gadgets
- no available VirtualAlloc/VirtualProtect/etc. pointer

Regarding the gadgets, the issue is that all bytes get converted to lowercase by parser. So 0x41 ~ 0x5A are unusable. Additionally 0x20 is unusable.
On the bright side, problem bytes like 0x22 from classic Void exploits are usable, as the flag value is not quote-delimited.

In order to VirtualProtect the stack, the address to VirtualProtect needs to be obtained and executed. This can be done with 2x API calls in a (very) long chain - one to GetProcAddress to get VirtualProtect addr, one to call VirtualProtect itself. The VirtualProtect call will add execute permissions to the stack, allowing arbitrary code execution.

Since this technique is supernull (runs at parse time), we can just corrupt the entire statedef loading or even file loading portion of the stack and drop out. This gives a lot of stack space for the ROP chain and code.

Even after VProt'ing the stack, running code under these conditions feels bad. Although stack code execution is already supernull, the next step should be removing protection in another region of memory (or just running SetProcessDEPPolicy if possible) and jumping out.

I opted for running VirtualProtect against the location of the CNS file in memory to then jump to the file and start executing restriction-free. VirtualProtect was easier than SetProcessDEPPolicy as I had a pointer to the handle for VirtualProtect prepared already. Additionally, SetProcessDEPPolicy tended to fail in my tests. This means the entire buffer overflow exploit involves running the ROP chain and additionally a short bootstrap ASM fragment to jump to the real payload in the file in memory.

By executing from the top of the file which triggered the supernull exploit, I can just position arbitrary code at the beginning of the file as a payload.

## Documents

Please review the following documentation for details:
`ROP Chain Documentation.txt` - The chain of ROP gadgets used to eventually gain stack code execution.
`Flag Bytes to Enable Stack Execution.txt` - Assembled bytes that allow for stack code execution, including the leading 0x40 bytes of padding. This is ONLY the ROP chain and includes neither bootstrap nor payload.
`asm/bootstrap.asm` - Short Assembly code to execute VirtualProtect against the CNS file location in memory and jump to it.
`asm/supernull.asm` - Assembly code fragment which fixes the stack/EIP/etc. after ROP and bootstrap.
`supernull_kfm.cns` - An example supernull payload, which discards the results of the entire file parsing. It does nothing, but allows MUGEN to continue to run.

The assembly fragments and the bytes for the ROP chain are positioned in `supernull_kfm.cns` based on how they are executed. The contents of `supernull.bin` appears in the file first, followed by a stub statedef/assertspecial in order to load a flag value, followed further by the ROP bytes in the flag field, and finished off with the contents of `bootstrap.bin` immediately after the ROP chain.