(defun c:ArrayArahX ( / ptAwal P Jarak ptY curX batasX oldOsnap oldAttreq)
  
  ;; --- 1. SIMPAN PENGATURAN AWAL AUTOCAD ---
  (setq oldOsnap (getvar "OSMODE")) ; Simpan status OSNAP user
  (setq oldAttreq (getvar "ATTREQ")) ; Simpan status Attribute user
  
  ;; Meminta input dari pengguna
  (setq ptAwal (getpoint "\nKlik titik awal pemasangan: "))
  (setq P (getreal "\nMasukkan panjang total area (arah X): "))
  (setq Jarak (getreal "\nMasukkan jarak antar objek: "))
  
  ;; --- BAGIAN VALIDASI ---
  (if (= (rem P Jarak) 0.0)
    (progn
      ;; Menentukan Kursor Awal dan Batas
      (setq curX (car ptAwal)) 
      (setq ptY (cadr ptAwal)) 
      (setq batasX (+ curX P))
      
      ;; --- 2. MATIKAN FITUR YANG MENGGANGGU LOOPING ---
      (setvar "CMDECHO" 0)
      (setvar "OSMODE" 0)  ; Matikan semua Object Snap
      (setvar "ATTREQ" 0)  ; Abaikan prompt pengisian attribute block

      ;; Kondisi Batas (Syarat Looping)
      (while (<= curX batasX)
        
        ;; Eksekusi Penempatan (Insert)
        ;; Tambahan "_non" memaksa AutoCAD untuk tidak melakukan snapping apapun di titik ini
        (command "._-INSERT" "WF350-P" "_non" (list curX ptY) 1 1 0)
        
        ;; Penambahan Jarak Dinamis
        (setq curX (+ curX Jarak))
      )
      
      ;; --- 3. KEMBALIKAN PENGATURAN AUTOCAD SEPERTI SEMULA ---
      (setvar "OSMODE" oldOsnap)
      (setvar "ATTREQ" oldAttreq)
      (setvar "CMDECHO" 1)
      
      (princ "\nLooping Array arah X selesai!")
    )
    ;; Jika tidak habis dibagi
    (princ "\nJarak tidak sesuai dengan panjang total! Tidak ada objek yang digambar.")
  )

  (princ) ; Keluar dari script dengan bersih
)