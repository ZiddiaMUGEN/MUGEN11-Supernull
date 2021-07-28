[bits 32]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Finalization:                                                        ;;
;; For ST finalization is a bit more complex. It expects 0 in EDI,      ;;
;; character base address in ESI, proper ESP (obviously), and           ;;
;; a statedef data structure in EAX. Statedef data structure is         ;;
;; completely trashed by the supernull... however we can regenerate it  ;;
;; empty (just have correct size/ptrs) and the game will use it no      ;;
;; issues.                                                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
push 0x4
push 0x1
call dword [0x004DE1F8] ;; need to alloc space for a pointer to comply with MUGEN datastructure (uses calloc)
add esp,0x8 ;; pass over args
mov ebp,eax ;; save ptr
xor eax,eax
sub eax,0xFFFFFF64 ;; some annoying math required due to sequential 0x00 bytes
push eax ;; push arg
xor eax,eax
inc eax ;; eax=1 (statedef count, irrelevant, just need the structure to exist)
mov ebx,0x00466000 ;; function to alloc memory for the statedef structure
call ebx
add esp,0x04 ;; pass over args
mov dword [ebp],eax ;; save statedef structure in pointer alloc'd earlier
mov eax,ebp ;; return data
xor edi,edi	;; required to continue processing properly
pop esp		;; restore proper esp
mov esi,dword [esp+0x04] ;; get old esi value (char base) loaded
ret