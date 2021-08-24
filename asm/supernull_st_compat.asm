;;;; Some constants
;;;; Made these adjustable to make it easier to put into other MUGEN versions.
;; builtin function pointers (exist either in MUGEN or in a non-rebase DLL)
%define HDL_KERNEL32 0x10008044
%define F_PTR_GETPROCADDR 0x10006080
%define F_PTR_CLOSEHANDLE 0x10006010
%define F_PTR_MEMCPY 0x62E95140
%define F_PTR_CALLOC 0x10006124
;; loaded function pointers (obtained via GetProcAddress)
%define F_PTR_VPROTECT 0x67BD0324
%define F_PTR_VALLOC 0x67BD0328
%define F_PTR_READFILE 0x67BD032C
%define F_PTR_CREATEFILEA 0x67BD0330
;; pointers to allocated memory segments
%define PTR_CODE 0x67BD0334
%define PTR_STRINGS 0x67BD0210
;; temp storage for file handles
%define TMP_FILE_HDL 0x67BD0338

[bits 32]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setup:                                                               ;;
;; 1. Get a VirtualAlloc function pointer to allocate space for         ;;
;;    the custom code.                                                  ;;
;; 2. Call VirtualAlloc to create section for custom code.              ;;
;; [PTR_CODE] = pointer to code                                         ;;
;; 3. Get a ReadFile function pointer to read the code                  ;;
;;    into memory.                                                      ;;
;; 4. Get a CreateFileA function pointer to open the file handle.       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Set up a VirtualAlloc function pointer - required for allocating memory
;;;; this is done by invoking GetProcAddress (this function pointer exists in MUGEN) with the KERNEL32 module handle + a string for VirtualAlloc
mov ebx,PTR_STRINGS                     ;; setting up VirtualAlloc string - location
mov dword [ebx],0x74726956              ;; Virt
mov dword [ebx+0x04],0x416C6175			;; ualA
mov dword [ebx+0x08],0x636F6C6C         ;; lloc
mov byte [ebx+0x0C],0x00                ;; (NULL)
push ebx                                ;; lpProcName = string VirtualAlloc
push dword [HDL_KERNEL32]               ;; hModule = KERNEL32
call dword [F_PTR_GETPROCADDR]          ;; call GetProcAddress function pointer
mov dword [F_PTR_VALLOC],eax            ;; stored VirtualAlloc pointer at 0x67BD0328 by default

;;;; Set up a ReadFile function pointer - required for reading assembled custom code/strings into memory
;;;; this is done by invoking GetProcAddress (this function pointer exists in MUGEN) with the KERNEL32 module handle + a string for ReadFile
mov ebx,PTR_STRINGS + 0x20              ;; setting up ReadFile string
mov dword [ebx],0x64616552              ;; Read
mov dword [ebx+0x04],0x656C6946         ;; File
mov byte [ebx+0x08],0x00                ;; NULL-terminated
push ebx                                ;; lpProcName = string ReadFile
push dword [HDL_KERNEL32]               ;; hModule = KERNEL32
call dword [F_PTR_GETPROCADDR]          ;; call GetProcAddress function pointer
mov dword [F_PTR_READFILE],eax          ;; stored ReadFile pointer at 0x67BD032C by default

;;;; Set up a CreateFileA function pointer - required for reading assembled custom code/strings into memory
;;;; this is done by invoking GetProcAddress (this function pointer exists in MUGEN) with the KERNEL32 module handle + a string for CreateFileA
mov ebx,PTR_STRINGS + 0x40              ;; setting up CreateFileA string
mov dword [ebx],0x61657243              ;; Crea
mov dword [ebx+0x04],0x69466574         ;; teFi
mov dword [ebx+0x08],0x0041656C         ;; leA(NULL)
push ebx                                ;; lpProcName = string CreateFileA
push dword [HDL_KERNEL32]               ;; hModule = KERNEL32
call dword [F_PTR_GETPROCADDR]          ;; call GetProcAddress function pointer
mov dword [F_PTR_CREATEFILEA],eax       ;; stored CreateFileA pointer at 0x67BD0330 by default

;;;; Call VirtualAlloc with size = 0x1000 (4096) for the code section
push 0x40                               ;; r/w/x permissions (can be adjusted back later) flProtect
mov eax,0xFFFFEFFF                      ;; workaround for duplicate 0x00 bytes
not eax
push eax                                ;; 0x1000 = flAllocationType
push eax                                ;; 0x1000 = dwSize
push 0                                  ;; lpAddress (NULL=OS decides where to allocate, location allocated to is placed in EAX)
call dword [F_PTR_VALLOC]               ;; invoke VirtualAlloc
mov dword [PTR_CODE],eax                ;; stored code section pointer at 0x67BD0334 by default

;; Load from the file data/CustomTriggerHandler.bin
;;    Requires first executing CreateFileA to get a file handle,
;;    then executing ReadFile to map the contents into memory.

mov ebx,PTR_STRINGS + 0x60              ;; pointer to an empty location we can write to
mov dword [ebx],0x61746164              ;; data
mov dword [ebx+0x04],0x7375432F         ;; /Cus
mov dword [ebx+0x08],0x546D6F74         ;; tomT
mov dword [ebx+0x0C],0x67676972         ;; rigg
mov dword [ebx+0x10],0x61487265         ;; erHa
mov dword [ebx+0x14],0x656C646E         ;; ndle
mov dword [ebx+0x18],0x69622E72         ;; r.bi
mov word [ebx+0x1C],0x006E              ;; n(NULL)

;; Execute CreateFileA to get a file handle
push 0                                  ;; hTemplateFile
push 0x7F                               ;; dwFlagsAndAttributes  (FILE_ATTRIBUTE_NORMAL = 0x80)
inc dword [esp]                         ;; to avoid extra NULL bytes
push 0x03                               ;; dwCreationDisposition (OPEN_EXISTING = 0x03)
push 0                                  ;; lpSecurityAttributes
push 0                                  ;; dwShareMode
push 0x7FFFFFFF                         ;; dwDesiredAccess (GENERIC_READ = 0x80000000)
not dword [esp]                         ;; to avoid extra NULL bytes
push dword PTR_STRINGS + 0x60           ;; pointer to the start of the directory string `data/CustomTriggerHandler.bin`
call dword [F_PTR_CREATEFILEA]          ;; call CreateFileA
mov dword [TMP_FILE_HDL],eax            ;; store the file handle to the temp location

;; Execute ReadFile to get the contents into memory
push 0                                  ;; lpOverlapped
push 0x67BD0344                         ;; lpNumberOfBytesRead
push 0xFFFFEFFF                         ;; nNumberOfBytesToRead (not 0xFFFFEFFF = 0x1000, adjust as needed)
not dword [esp]
push dword [PTR_CODE]                   ;; lpBuffer
push dword [TMP_FILE_HDL]               ;; hFile
call dword [F_PTR_READFILE]             ;; call ReadFile

;; Execute CloseHandle to free the file handle
push dword [TMP_FILE_HDL]               ;; hObject
call dword [F_PTR_CLOSEHANDLE]          ;; call CloseHandle

;;; cleanup from 0x67BD0210 to 0x67BD0310
;;; this is a stupid way to do it but i dont really know how to use the repetition ops,
;;; to be improved later
xor eax,eax ;; zero value
mov ebx,0x67BD0210 ;; starting address
xor ecx,ecx
add ecx,0x7F
inc ecx
add ecx,ecx ;; get 0x100 into ecx without double 0x00 bytes and small instruction count
.loop_cleanup:
mov [ebx],eax ;; zero out
add ebx,0x04 ;; step
sub ecx,0x04 ;; step
cmp ecx,0 ;; terminator
jne .loop_cleanup

;; Jump over to the code in the read file
;; Prefer to do this with `call` so that the finalization below can be kept here, and the loaded file will just include a RET
;call dword [PTR_CODE]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Finalization:                                                        ;;
;; For ST finalization is a bit more complex. It expects 0 in EDI,      ;;
;; character base address in ESI, proper ESP (obviously), and           ;;
;; a statedef data structure in EAX. Statedef data structure is         ;;
;; completely trashed by the supernull... however we can regenerate it  ;;
;; empty (just have correct size/ptrs) and the game will use it no      ;;
;; issues.                                                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; trivial version checker to ensure the right return address is processed
;; checks the return address.
mov eax, dword [esp]
mov eax, dword [eax]
not eax
cmp eax,0xFFBC9EDD
je .mugen11b1
jmp .mugen11a4

.mugen11b1:
push 0x4
push 0x1
call dword [F_PTR_CALLOC] ;; need to alloc space for a pointer to comply with MUGEN datastructure (uses calloc)
add esp,0x8 ;; pass over args
mov ebp,eax ;; save ptr
xor eax,eax
sub eax,0xFFFFFF64 ;; some annoying math required due to sequential 0x00 bytes
push eax ;; push arg
xor eax,eax
inc eax ;; eax=1 (statedef count, irrelevant, just need the structure to exist)
mov ebx,0x00466550 ;; function to alloc memory for the statedef structure
call ebx
add esp,0x04 ;; pass over args
mov dword [ebp],eax ;; save statedef structure in pointer alloc'd earlier
mov eax,ebp ;; return data
xor edi,edi	;; required to continue processing properly
pop esp		;; restore proper esp
mov esi,dword [esp+0x04] ;; get old esi value (char base) loaded
ret

.mugen11a4:
cmp eax,0xFFBCA40D
jne .mugen10 ;; assume 1.0 if neither other version are matched
push 0x4
push 0x1
call dword [F_PTR_CALLOC] ;; need to alloc space for a pointer to comply with MUGEN datastructure (uses calloc)
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

.mugen10:
mov ecx,0xFFFFFEE7
not ecx
add dword [esp],ecx ;; 1.0-specific return addr correction
push 0x4
push 0x1
call dword [F_PTR_CALLOC] ;; need to alloc space for a pointer to comply with MUGEN datastructure (uses calloc)
add esp,0x8 ;; pass over args
mov esi,eax ;; save ptr
xor eax,eax
sub eax,0xFFFFFF68 ;; some annoying math required due to sequential 0x00 bytes
push eax ;; push arg
xor eax,eax
inc eax ;; eax=1 (statedef count, irrelevant, just need the structure to exist)
mov ebx,0x00402f10 ;; function to alloc memory for the statedef structure
call ebx
add esp,0x04 ;; pass over args
mov dword [esi],eax ;; save statedef structure in pointer alloc'd earlier
mov eax,esi ;; return data
xor esi,esi	;; required to continue processing properly
pop esp		;; restore proper esp
mov edi,dword [esp+0x04] ;; get old esi value (char base) loaded
ret