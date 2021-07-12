AssertSpecial Flag parameter has a stack smash exploit. We can ROP into arbitrary code execution from the stack.
The flag parameter has a buffer of 0x40 bytes, followed immediately by return address. Since this is not a formatted string, the 0x80 bytes have to be filled manually.

The ROP chain is quite complex due to some limitations involved:
- cannot use gadgets from mugen.exe or zlib1.dll due to 0x00 bytes
- cannot use several other gadgets due to the string being forced lowercase - very limited in move gadgets
- no available VirtualAlloc/VirtualProtect/etc. pointer

Regarding the gadgets, the issue is that all bytes get converted to lowercase by parser. So 0x41 ~ 0x5A are unusable. Additionally 0x20 is unusable.
On the bright side, problem bytes like 0x22 from classic Void exploits are usable, as the flag value is not quote-delimited.

In order to VirtualProtect the stack, the address to VirtualProtect needs to be obtained and executed.

This can be done with 2x API calls in a (very) long chain - one to GetProcAddress to get VirtualProtect addr, one to VirtualProtect itself. The VirtualProtect call will add execute permissions to the stack, allowing arbitrary code execution.

The flag field is 64 bytes long. This means it's not very easy to use, and definitely not long enough to fit this ROP chain. There is also no pivot to easily move ESP backwards.
However, since it's supernull (runs at parse time), we can just corrupt the entire statedef loading or even file loading portion of the stack and drop out. This gives more space.

Even after VProt'ing the stack, running code under these conditions feels bad. Although stack code execution is already supernull, the next step should be removing protection in another region of memory (or just running SetProcessDEPPolicy if possible) and jumping out.

Please review the following documentation for details:
`ROP Chain Documentation.txt` - The chain of ROP gadgets used to eventually gain stack code execution.
`Flag Bytes to Enable Stack Execution.txt` - Assembled bytes that allow for stack code execution, including the leading 0x40 bytes of padding.
`supernull_kfm.cns` - An example supernull implementation, which discards the results of the entire file parsing.