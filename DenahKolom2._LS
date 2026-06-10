(vl-load-com) ; Memastikan fungsi vl-* (Visual LISP) aktif

(defun c:denahkolom2( / dcl_id dcl_file file P L Jarak ptAwal ptX ptY batasX oldOsnap oldAttreq oldCmdecho result )
  
  ;; =========================================================================
  ;; 1. BUAT FILE KOTAK DIALOG (DCL) SEMENTARA SECARA OTOMATIS
  ;; =========================================================================
  (setq dcl_file (vl-filename-mktemp "autokolom.dcl")) ; Buat file temp unik
  (setq file (open dcl_file "w"))
  (write-line "autokolom_dlg : dialog {" file)
  (write-line "  label = \"Dimensi Denah Gudang\";" file)
  (write-line "  : boxed_column { label = \"Dimensi (Angka)\";" file)
  (write-line "    : edit_box { key = \"val_P\"; label = \"Panjang Bangunan (Sumbu X):\"; edit_width = 15; }" file)
  (write-line "    : edit_box { key = \"val_L\"; label = \"Lebar Bangunan (Sumbu Y):\"; edit_width = 15; }" file)
  (write-line "    : edit_box { key = \"val_J\"; label = \"Jarak Antar Kolom:\"; edit_width = 15; }" file)
  (write-line "  }" file)
  (write-line "  errtile;" file) ; Baris khusus untuk pesan error jika input huruf/kosong
  (write-line "  ok_cancel;" file)
  (write-line "}" file)
  (close file)

  ;; =========================================================================
  ;; 2. LOAD DAN TAMPILKAN DIALOG
  ;; =========================================================================
  (setq dcl_id (load_dialog dcl_file))
  (if (not (new_dialog "autokolom_dlg" dcl_id))
    (progn (princ "\nGagal memuat kotak dialog.") (exit))
  )

  ;; NILAI DEFAULT (Angka awal saat dialog terbuka, silakan ganti jika mau)
  (set_tile "val_P" "120000")
  (set_tile "val_L" "32700")
  (set_tile "val_J" "6000")

  ;; VALIDASI SAAT TOMBOL OK DIKLIK
  (action_tile "accept" 
    "(progn
       ;; Ambil nilai dari dialog dan ubah teks ke angka (atof)
       (setq P (atof (get_tile \"val_P\"))
             L (atof (get_tile \"val_L\"))
             Jarak (atof (get_tile \"val_J\")))
             
       ;; Pastikan angka tidak 0 atau negatif (mencegah eror/huruf yg diinput)
       (if (or (<= P 0.0) (<= L 0.0) (<= Jarak 0.0))
         (set_tile \"error\" \"Perhatian: Semua nilai harus diisi dengan angka lebih dari 0!\")
         (done_dialog 1) ; Tutup dialog dengan kode sukses (1)
       )
     )"
  )
  
  ;; SAAT TOMBOL CANCEL DIKLIK
  (action_tile "cancel" "(done_dialog 0)")

  ;; MULAI JALANKAN DIALOG
  (setq result (start_dialog))
  
  ;; Hapus dialog dari memori dan hapus file sementaranya dari Windows
  (unload_dialog dcl_id)
  (vl-file-delete dcl_file)

  ;; =========================================================================
  ;; 3. PROSES MENGGAMBAR (Jika user mengklik tombol OK)
  ;; =========================================================================
  (if (= result 1)
    (progn
      (setq ptAwal (getpoint "\nKlik titik awal as bangunan (pojok kiri bawah / awal Line A): "))
      
      (if ptAwal 
        (progn
          ;; --- SIMPAN PENGATURAN AWAL AUTOCAD ---
          (setq oldCmdecho (getvar "CMDECHO"))
          (setq oldOsnap (getvar "OSMODE"))  
          (setq oldAttreq (getvar "ATTREQ")) 
          
          ;; --- MATIKAN FITUR YANG MENGGANGGU LOOPING ---
          (setvar "CMDECHO" 0)
          (setvar "OSMODE" 0)  
          (setvar "ATTREQ" 0)  
          
          ;; --- MENGGAMBAR AS BANGUNAN (RECTANGLE) ---
          (setq ptX (car ptAwal))
          (setq ptY (cadr ptAwal))
          (command "._RECTANG" ptAwal (list (+ ptX P) (+ ptY L)))

          ;; --- PROSES LOOPING MENGGAMBAR KOLOM ---
          (if (equal (rem P Jarak) 0.0 1e-4)
            (progn
              (setq ptX (car ptAwal)) 
              (setq ptY (cadr ptAwal)) 
              (setq batasX (+ ptX P))
              
              (while (<= ptX (+ batasX 1e-4))
                ;; Insert Line A (Bawah)
                (command "._-INSERT" "WF350-P" "_non" (list ptX ptY) 1 1 0)
                ;; Insert Line B (Atas)
                (command "._-INSERT" "WF350-P" "_non" (list ptX (+ ptY L)) 1 1 0)
                
                (setq ptX (+ ptX Jarak))
              )
              
              (princ "\nLooping selesai! As Bangunan & Kolom WF berhasil dibuat.")
            )
            ;; Jika jarak tidak habis membagi panjang (misal panjang 20000, jarak 3000)
            (princ "\nJarak tidak pas membagi panjang bangunan! Hanya menggambar As Bangunan.")
          )
          
          ;; --- KEMBALIKAN PENGATURAN AUTOCAD ---
          (setvar "OSMODE" oldOsnap)
          (setvar "ATTREQ" oldAttreq)
          (setvar "CMDECHO" oldCmdecho)
        )
        (princ "\nProses dibatalkan: Anda tidak mengklik titik awal.")
      )
    )
    (princ "\nProses dibatalkan oleh pengguna (Tombol Cancel diklik).")
  )

  (princ)
)