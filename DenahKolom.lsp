(defun c:denahKolom ( / ptAwal P L Jarak ptX ptY batasX oldOsnap oldAttreq oldCmdecho )
  
  ;; --- 1. SIMPAN PENGATURAN AWAL AUTOCAD ---
  ;; PENTING: Simpan status DULU sebelum nilainya diubah ke 0
  (setq oldCmdecho (getvar "CMDECHO"))
  (setq oldOsnap (getvar "OSMODE"))  
  (setq oldAttreq (getvar "ATTREQ")) 
  
  ;; --- 2. MATIKAN FITUR YANG MENGGANGGU LOOPING ---
  (setvar "CMDECHO" 0)
  (setvar "OSMODE" 0)  ; Matikan semua Object Snap
  (setvar "ATTREQ" 0)  ; Abaikan prompt pengisian attribute block

  ;; 1. MEMINTA INPUT DARI USER
  (setq ptAwal (getpoint "\nKlik titik awal as bangunan (pojok kiri bawah / awal Line A): "))

  (if ptAwal 
    (progn
      (initget 1) (setq P (getreal "\nMasukkan Panjang Bangunan (Sumbu X): "))
      (initget 1) (setq L (getreal "\nMasukkan Lebar Bangunan / Jarak Antara Line A & B (Sumbu Y): "))
      (initget 1) (setq Jarak (getreal "\nMasukkan Jarak Antar Kolom: "))

      ;; 2. MENGGAMBAR AS BANGUNAN (RECTANGLE)
      (setq ptX (car ptAwal))
      (setq ptY (cadr ptAwal))
      (command "._RECTANG" ptAwal (list (+ ptX P) (+ ptY L)))

      ;; 3. PROSES LOOPING SEPANJANG LINE A DAN LINE B
      ;; Validasi dengan fungsi equal (memberi toleransi 0.0001) agar lebih aman untuk angka desimal
      (if (equal (rem P Jarak) 0.0 1e-4)
        (progn
          ;; Menentukan Kursor Awal dan Batas
          (setq ptX (car ptAwal)) 
          (setq ptY (cadr ptAwal)) 
          (setq batasX (+ ptX P))
          
          ;; Kondisi Batas (ditambah toleransi kecil agar kolom terakhir pas di sudut selalu tergambar)
          (while (<= ptX (+ batasX 1e-4))
            
            ;; Eksekusi Penempatan (Insert) Kolom di Line A (Bawah)
            (command "._-INSERT" "WF350-P" "_non" (list ptX ptY) 1 1 0)
            
            ;; Eksekusi Penempatan (Insert) Kolom di Line B (Atas)
            (command "._-INSERT" "WF350-P" "_non" (list ptX (+ ptY L)) 1 1 0)
            
            ;; Penambahan Jarak Dinamis
            ;; Variabel ptX harus ditambahkan agar batasX bisa tercapai dan looping berhenti
            (setq ptX (+ ptX Jarak))
          )
          
          (princ "\nLooping Array arah X selesai!")
          (princ "\nAs Bangunan dan Kolom WF pada Line A & B berhasil dibuat!")
        )
        ;; Jika Jarak tidak habis dibagi Panjang
        (princ "\nJarak tidak sesuai dengan panjang total! Hanya menggambar As Bangunan.")
      )
    )
    (princ "\nProses dibatalkan: Anda tidak mengklik titik awal.")
  )
  
  ;; --- 4. KEMBALIKAN PENGATURAN AUTOCAD SEPERTI SEMULA ---
  (setvar "OSMODE" oldOsnap)
  (setvar "ATTREQ" oldAttreq)
  (setvar "CMDECHO" oldCmdecho)

  (princ) ; Keluar dari script dengan bersih agar tidak ada output ganda di command line
)