;; Kandang Laktasi AutoCAD Script (AutoLISP + DCL)
;; Deskripsi: Script ini akan menggambar denah kandang laktasi dengan parameter yang bisa diinput melalui kotak dialog. 
;; Script ini menggunakan AutoLISP dan DCL untuk membuat interface input.
;; Dibuat oleh : Adi Prasetia @2026
;; Catatan: Pastikan block "WF350-P", "stall-2row-5400-dyn", "Dinding Beton", "Gate Removable S Top", 
;; "Headlock 6-1", "Headlock 6-2", '"bak-minum-kanan" dan "bak-minum-kiri" sudah ada di dalam drawing sebelum menjalankan script ini.

(vl-load-com) ; Memastikan fungsi vl-* (Visual LISP) aktif

;; =========================================================================
;; 1. FUNGSI BANTUAN UNTUK MENGUBAH PROPERTI DYNAMIC BLOCK (SIMPAN INI)
;; =========================================================================
;; Cara pakai: (UbahDynamicBlock entitas "Nama Parameter" nilaiAngka)
(defun UbahDynamicBlock (ent namaProperti nilaiBaru / obj props propName) 
  (setq obj (vlax-ename->vla-object ent))

  ;; Cek apakah objek tersebut benar-benar Dynamic Block
  (if (= (vla-get-IsDynamicBlock obj) :vlax-true) 
    (progn 
      ;; Ambil daftar semua properti dinamis di dalam block
      (setq props (vlax-invoke obj 'GetDynamicBlockProperties))

      ;; Cari properti yang namanya sesuai
      (foreach prop props 
        (setq propName (vla-get-PropertyName prop))
        (if (= (strcase propName) (strcase namaProperti)) 
          ;; Timpa nilainya (harus dikonversi ke format Double Variant)
          (vla-put-Value prop (vlax-make-variant nilaiBaru vlax-vbDouble))
        )
      )
    )
  )
  (princ)
)

;; =========================================================================
;; FUNGSI UTAMA: c:kandanglaktasi
;; =========================================================================
(defun c:kandanglaktasi (/ dcl_id dcl_file file P L Jarak ptAwal ptX ptY batasX jml 
                         panjang panjangFrstl oldOsnap oldAttreq oldCmdecho result Jrk 
                         Pdx Pdy GrFrst DFrst Caw1 Fcaw Taw CrssTp CrssTgh ptX1 ptY1 
                         ptY2 totgrup
                        ) 

  ;; =========================================================================
  ;; 1. BUAT FILE KOTAK DIALOG (DCL) SEMENTARA SECARA OTOMATIS
  ;; =========================================================================
  (setq dcl_file (vl-filename-mktemp "autokolom.dcl")) ; Buat file temp unik
  (setq file (open dcl_file "w"))
  (write-line "autokolom_dlg : dialog {" file)
  (write-line "  label = \"Dimensi Denah Gudang\";" file)
  (write-line "  : boxed_column { label = \"Dimensi (Angka)\";" file)
  (write-line "    : edit_box { key = \"val_P\"; label = \"Panjang Bangunan (Sumbu X):\"; edit_width = 6; }" file  )
  (write-line "    : edit_box { key = \"val_L\"; label = \"Lebar Bangunan (Sumbu Y):\"; edit_width = 6; }" file  )
  (write-line "    : edit_box { key = \"val_J\"; label = \"Jarak Antar Kolom:\"; edit_width = 6; }" file  )
  (write-line "    : edit_box { key = \"val_Pdx\"; label = \"Lebar Pedestal\"; edit_width = 6; }" file  )
  (write-line "    : edit_box { key = \"val_Pdy\"; label = \"Panjang Pedestal\"; edit_width = 6; }" file  )
  (write-line "    : edit_box { key = \"val_F\"; label = \"Jumlah Freestall (1baris):\"; edit_width = 6; }" file  )
  (write-line "    : edit_box { key = \"val_GF\"; label = \"Group Freestall (1baris):\"; edit_width = 6; }" file  )
  (write-line "    : edit_box { key = \"val_D\"; label = \"Lebar Double Freestall\"; edit_width = 6; }" file  )
  (write-line "    : edit_box { key = \"val_C\"; label = \"Lebar Cow Alley Way\"; edit_width = 6; }"  file  )
  (write-line "    : edit_box { key = \"val_FC\"; label = \"Lebar Feed Cow Alley Way\"; edit_width = 6; }" file  )
  (write-line "    : edit_box { key = \"val_FT\"; label = \"Lebar Feed Truck Alley Way\"; edit_width = 6; }" file  )
  (write-line "    : edit_box { key = \"val_COT\"; label = \"Cross Over Tengah\"; edit_width = 6; }" file  )
  (write-line "    : edit_box { key = \"val_COE\"; label = \"Cross Over Tepi\"; edit_width = 6; }" file  )
  (write-line "  }" file)
  (write-line "  errtile;" file)
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
  (set_tile "val_Pdx" "300")
  (set_tile "val_Pdy" "450")
  (set_tile "val_F" "27")
  (set_tile "val_GF" "3")
  (set_tile "val_D" "5400")
  (set_tile "val_C" "3600")
  (set_tile "val_FC" "4500")
  (set_tile "val_FT" "5400")
  (set_tile "val_COT" "5800")
  (set_tile "val_COE" "5150")

  ;; VALIDASI SAAT TOMBOL OK DIKLIK
  (action_tile "accept" 
               "(progn
             ;; Ambil nilai dari dialog dan ubah teks ke angka (atof)
             (setq P (atof (get_tile \"val_P\"))
             L (atof (get_tile \"val_L\"))
             Jrk (atof (get_tile \"val_J\"))
             Pdx (atof (get_tile \"val_Pdx\"))
             Pdy (atof (get_tile \"val_Pdy\"))
             jml (atof (get_tile \"val_F\"))
             GrFrst (atof (get_tile \"val_GF\"))
             DFrst (atof (get_tile \"val_D\"))
             Caw1 (atof (get_tile \"val_C\"))
             Fcaw (atof (get_tile \"val_FC\"))
             Taw (atof (get_tile \"val_FT\"))
             CrssTgh (atof (get_tile \"val_COT\"))
             CrssTp (atof (get_tile \"val_COE\")))

       ;; Validasi 1: Pastikan angka tidak 0 atau negatif
       (if (or (<= P 0.0) (<= L 0.0) (<= Jrk 0.0) (< jml 15.0) (< GrFrst 2.0))
         (alert \"PERHATIAN:\\nNilai P/L/J harus > 0\\nFreestall minimal 15\\nGrup Freestall minimal 2\")
         ; Validasi 2: Pastikan panjang bangunan habis dibagi jarak antar kolom (P harus habis dibagi Jrk)
         (if (not (equal (rem P Jrk) 0.0 1e-4))
           (alert \"PERHATIAN:\\nPanjang Bangunan harus habis dibagi Jarak Antar Kolom!\")
           ; Validasi 3: Pastikan panjang total freestall + cross over tidak melebihi panjang bangunan, dan lebar alley way tidak melebihi lebar bangunan    
           (progn
             (setq panjangFrstl (+ (* jml 1200.00) 300.00))
              (if (> (+ (* panjangFrstl GrFrst) (* CrssTgh (- GrFrst 1)) (* CrssTp 2)) P)
              (alert \"PERHATIAN:\\nPanjang/Group Freestall TIDAK BOLEH melebihi Panjang Bangunan!\")
               ; Validasi 4: lebar alley way (Caw1 + DFrst + Fcaw + Taw + Fcaw) tidak boleh melebihi lebar bangunan L
               (if (> (+ Caw1 DFrst Fcaw 150 Taw 150 Fcaw DFrst Caw1) L)
                 (alert \"PERHATIAN:\\nJumlah Lebar Alley Way TIDAK BOLEH MELEBIHI Lebar Bangunan!\")
                 (done_dialog 1)
               )
             )
           )
         )
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
      ;; --- MINTA USER UNTUK KLIK TITIK AWAL AS BANGUNAN ---
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
          (setq ptX (car ptAwal)) ;ambil koordinat X dari titik awal
          (setq ptY (cadr ptAwal)) ;ambil koordinat Y dari titik awal
          (setvar "CLAYER" "tipis")
          (command "._RECTANG" ptAwal (list (+ ptX P) (+ ptY L))) ;buat rectangle dengan panjang P dan lebar L dari titik awal
          (setvar "CLAYER" "0") ; Kembali ke layer "0" untuk gambar selanjutnya

        ;; --- PROSES LOOPING MENGGAMBAR KOLOM ---

          (setq ptX (car ptAwal)) ;ambil koordinat X dari titik awal
          (setq ptY (cadr ptAwal)) ;ambil koordinat Y dari titik awal
          (setq batasX (+ ptX P)) ;batas koordinat X untuk looping (sampai ujung rectangle)

          (while (<= ptX (+ batasX 1e-4)) 
            ;; Insert Line A (Bawah)
            (command "._-INSERT" "WF350-P" "_non" (list ptX ptY) 1 1 0)
            ;; Insert Line B (Atas)
            (command "._-INSERT" "WF350-P" "_non" (list ptX (+ ptY L)) 1 1 0)

            (setq ptX (+ ptX Jrk)) ;Geser koordinat X untuk kolom berikutnya sesuai jarak
          )

          
        ;; --- MASUKKAN FREESTALL ---
          

          ;; Hitung panjang untuk panjang total freestall (1 plong = 1200 mm) (panjang total - 1 jarak untuk buffer di ujung)
          (setq panjang (- (* jml 1200.00) 1200.00))
          (setq panjangFrstl (+ (* jml 1200.00) 300.00))

          ;; koordinat freestall line A (bawah)
          (setq ptX1 (+ (car ptAwal) CrssTp)) ; Geser 5150 mm dari titik awal (sesuai layout freestall)
          (setq ptY1 (+ (cadr ptAwal) Caw1)) ; Geser 3600 mm dari titik awal (sesuai layout freestall)

          ;; koordinat freestall line B (atas) Y nya adalah ptY
          (setq ptY2 (+ (cadr ptAwal) Caw1 DFrst Fcaw 150 Taw 150 Fcaw))

          (setq totgrup 1) ; Inisialisasi total grup freestall yang sudah dibuat

          ;looping freestall di area bawah (Line A)
          (while (< totgrup (+ GrFrst 1e-4)) 
            ;; Insert Block Freestall (Line A)
            (command "._-INSERT" 
                     "stall-2row-5400-dyn"
                     "_non"
                     (list ptX1 ptY1)
                     1
                     1
                     0
            )
            ;; Ubah parameter dinamis "JARAK" di Line A
            (UbahDynamicBlock (entlast) "JARAK" panjang)

            ;; Insert Block Freestall (Line B)
            (command "._-INSERT" 
                     "stall-2row-5400-dyn"
                     "_non"
                     (list ptX1 ptY2)
                     1
                     1
                     0
            )
            ;; Ubah parameter dinamis "JARAK" di Line B
            (UbahDynamicBlock (entlast) "JARAK" panjang)

            (setq totgrup (+ totgrup 1)) ; Tambahkan jumlah grup yang sudah dibuat
            (setq ptX1 (+ ptX1 panjangFrstl CrssTgh)) ; Geser koordinat X untuk freestall berikutnya (panjang freestall + cross over tengah)
          )

          (princ 
            (strcat "\nJumlah Total = " 
                    (rtos (* GrFrst jml 2) 2 0)
                    " Sapi, dengan jumlah tiap grup freestall = "
                    (rtos (* jml 2) 2 0)
            )
          )

        
        ;; --- MASUKKAN RECTANGLE ALLEY WAY ---
        

          (setq ptX (car ptAwal)) ;ambil koordinat X dari titik awal
          (setq ptY (cadr ptAwal)) ;ambil koordinat Y dari titik awal

          ; == Border Luar
          (command "._RECTANG" 
                   (list (- ptX (/ Pdx 2)) (- ptY (/ Pdy 2))) ; Titik awal rectangle (pojok kiri alley way)
                   (list (+ ptX P (/ Pdx 2)) (+ ptY L (/ Pdy 2))) ; Titik akhir rectangle (pojok kanan alley way)
          ) ;buat rectangle dengan panjang P dan lebar L dari titik awal

          ; == Cow Alley Way (Caw1)
          (command "._RECTANG" 
                   (list ptX (+ ptY (/ Pdy 2))) ; Titik awal rectangle (pojok kiri alley way)
                   (list (+ ptX P) (+ ptY Caw1)) ; Titik akhir rectangle (pojok kanan alley way)
          ) ;buat rectangle dengan panjang P dan lebar L dari titik awal

          ; warna untuk hatch alley way
          (command "._-COLOR" "151") ; Ubah warna ke  (151)

          ; == Hatch Cow Alley Way (ANSI32, Scale 40, Angle 135)
          (command "._HATCH" "P" "ANSI32" 40 135 "S" (entlast) "")

          (command "._-COLOR" "250") ; Ubah warna ke black (7) untuk gambar selanjutnya

          ; == Feed Cow Alley Way (Fcaw)
          (command "._RECTANG" 
                   (list ptX (+ ptY Caw1 DFrst)) ; Titik awal rectangle (pojok kiri alley way)
                   (list (+ ptX P) (+ ptY Caw1 DFrst Fcaw)) ; Titik akhir rectangle (pojok kanan alley way)
          ) ;buat rectangle dengan panjang P dan lebar L dari titik awal

          ; warna untuk hatch alley way
          (command "._-COLOR" "151") ; Ubah warna ke  (151)

          ; == Hatch Cow Alley Way (ANSI32, Scale 40, Angle 135)
          (command "._HATCH" "P" "ANSI32" 40 135 "S" (entlast) "")

          (command "._-COLOR" "250") ; Ubah warna ke black (7) untuk gambar selanjutnya

          ; Kerb Feed Truck Alley Way 1
          (command "._RECTANG" 
                   (list ptX (+ ptY Caw1 DFrst Fcaw)) ; Titik awal rectangle (pojok kiri alley way)
                   (list (+ ptX P) (+ ptY Caw1 DFrst Fcaw 150)) ; Titik akhir rectangle (pojok kanan alley way)
          ) ;buat rectangle dengan panjang P dan lebar L dari titik awal

          ; == Truck Alley Way (Taw)
          (command "._RECTANG" 
                   (list ptX (+ ptY Caw1 DFrst Fcaw 150)) ; Titik awal rectangle (pojok kiri alley way)
                   (list (+ ptX P) (+ ptY Caw1 DFrst Fcaw 150 Taw)) ; Titik akhir rectangle (pojok kanan alley way)
          ) ;buat rectangle dengan panjang P dan lebar L dari titik awal

          ; == Kerb Feed Truck Alley Way 2
          (command "._RECTANG" 
                   (list ptX (+ ptY Caw1 DFrst Fcaw 150 Taw)) ; Titik awal rectangle (pojok kiri alley way)
                   (list (+ ptX P) (+ ptY Caw1 DFrst Fcaw 150 Taw 150)) ; Titik akhir rectangle (pojok kanan alley way)
          ) ;buat rectangle dengan panjang P dan lebar L dari titik awal

          ; == Feed Alley Way 2
          (command "._RECTANG" 
                   (list ptX (+ ptY Caw1 DFrst Fcaw 150 Taw 150)) ; Titik awal rectangle (pojok kiri alley way)
                   (list (+ ptX P) (+ ptY Caw1 DFrst Fcaw 150 Taw 150 Fcaw)) ; Titik akhir rectangle (pojok kanan alley way)
          ) ;buat rectangle dengan panjang P dan lebar L dari titik awal

          ; warna untuk hatch alley way
          (command "._-COLOR" "151") ; Ubah warna ke  (151)

          ; Hatch Cow Alley Way 2 (ANSI32, Scale 40, Angle 135)
          (command "._HATCH" "P" "ANSI32" 40 135 "S" (entlast) "")

          (command "._-COLOR" "250") ; Ubah warna ke black (7) untuk gambar selanjutnya

          ; == Cow Alley Way 2
          (command "._RECTANG" 
                   (list ptX (+ ptY Caw1 DFrst Fcaw 150 Taw 150 Fcaw DFrst)) ; Titik awal rectangle (pojok kiri alley way)
                   (list (+ ptX P) 
                         (+ ptY Caw1 DFrst Fcaw 150 Taw 150 Fcaw DFrst (- Caw1 (/ Pdy 2)))
                   ) ; Titik akhir rectangle (pojok kanan alley way)
          ) ;buat rectangle dengan panjang P dan lebar L dari titik awal

          (command "._-COLOR" "151") ; Ubah warna ke  (151)

          ; Hatch Cow Alley Way 2 (ANSI32, Scale 40, Angle 135)
          (command "._HATCH" "P" "ANSI32" 40 135 "S" (entlast) "")

          (setvar "CLAYER" "tipis") ; Kembali ke layer "0"

          ; == Center line
          (command "._PLINE" 
                   (list ptX (+ ptY (/ L 2))) ; Titik awal line (tengah bawah)
                   (list (+ ptX P) (+ ptY (/ L 2))) ; Titik akhir line (tengah atas)
                   ;format line center line: start point (tengah bawah) dan end point (tengah atas)
                   ""
          ) ;buat line di tengah bangunan

          ; Set linetype dan linetype scale untuk center line
          (vla-put-linetype (vlax-ename->vla-object (entlast)) "Center")
          (vla-put-linetypescale (vlax-ename->vla-object (entlast)) 0.25)

          ; Kembalikan ke layer dan color asli
          (setvar "CLAYER" "0") ; Kembali ke layer "0"
          (command "._-COLOR" "250") ; Kembali ke "ByLayer"

          (setq i 0)

          ;== looping headlock
          (while (< i (- (+ (/ P Jrk) 1e-4) 1)) 
            ;; Insert Block Headlock 1
            (command "._-INSERT" 
                     "Headlock 6-2" ; Nama block headlock 1
                     "_non"
                     (list (+ ptX (* i Jrk)) (+ ptY Caw1 DFrst Fcaw 75))
                     1
                     0
            )

            (command "._-INSERT" 
                     "Headlock 6-1" ; Nama block headlock 1
                     "_non"
                     (list (+ ptX (* i Jrk)) (+ ptY Caw1 DFrst Fcaw 150 Taw 75))
                     1
                     0
            )

            (setq i (+ i 1)) ; Tambahkan jumlah grup yang sudah dibuat
          )

        
        ;; INSERT DINDING BETON (DISESUAIKAN DENGAN LAYOUT ALLEY WAY)
          ;==Insert dinding beton 1
          (command "._-INSERT" 
                   "Dinding Beton"
                   "_non"
                   (list ptX (+ ptY Caw1))
                   1
                   90
          )
          ;; Ubah parameter dinamis "Distance1"
          (UbahDynamicBlock (entlast) "Distance1" Dfrst)

          ;==Insert dinding beton 2
          (command "._-INSERT" 
                   "Dinding Beton"
                   "_non"
                   (list ptX (+ ptY Caw1 DFrst Fcaw 150 Taw 150 Fcaw))
                   1
                   90
          )
          ;; Ubah parameter dinamis "Distance1"
          (UbahDynamicBlock (entlast) "Distance1" Dfrst)

          ;==Insert dinding beton 3
          (command "._-INSERT" 
                   "Dinding Beton"
                   "_non"
                   (list (+ ptX P) (+ ptY Caw1))
                   1
                   90
          )
          ;; Ubah parameter dinamis "Distance1"
          (UbahDynamicBlock (entlast) "Distance1" Dfrst)

          ;==Insert dinding beton 4
          (command "._-INSERT" 
                   "Dinding Beton"
                   "_non"
                   (list (+ ptX P) (+ ptY Caw1 DFrst Fcaw 150 Taw 150 Fcaw))
                   1
                   90
          )
          ;; Ubah parameter dinamis "Distance1"
          (UbahDynamicBlock (entlast) "Distance1" Dfrst)
          
        ;; INSERT GATE KIRI
          ;==Insert gate 1 kiri bawah
          (command "._-INSERT" 
                   "Gate Removable S Top"
                   "_non"
                   (list ptX (+ ptY 290.00))
                   1
                   1
                   90
          )
          ;; Ubah parameter dinamis "Distance1"
          (UbahDynamicBlock (entlast) "Distance1" (- Caw1 400.00))
          
          ;==Insert gate 1 kiri tengah 1
          (command "._-INSERT" 
                   "Gate Removable S Top"
                   "_non"
                   (list ptX (+ ptY Caw1 Dfrst Fcaw 75))
                   1
                   1
                   270
          )
          ;; Ubah parameter dinamis "Distance1"
          (UbahDynamicBlock (entlast) "Distance1" (- Fcaw 50.00))
          
          ;==Insert gate 1 kiri tengah 2
          (command "._-INSERT" 
                   "Gate Removable S Top"
                   "_non"
                   (list ptX (+ ptY Caw1 Dfrst Fcaw 150 Taw 75))
                   1
                   1
                   90
          )
          ;; Ubah parameter dinamis "Distance1"
          (UbahDynamicBlock (entlast) "Distance1" (- Fcaw 50.00))
          
          ;==Insert gate 1 kiri atas 2
          (command "._-INSERT" 
                   "Gate Removable S Top"
                   "_non"
                   (list ptX (- (+ ptY L) 290.00))
                   1
                   1
                   270
          )
          ;; Ubah parameter dinamis "Distance1"
          (UbahDynamicBlock (entlast) "Distance1" (- Caw1 400.00))
          
        ;; INSERT GATE KANAN
          ;==Insert gate 1 kanan bawah
          (command "._-INSERT" 
                   "Gate Removable S Top"
                   "_non"
                   (list (+ ptX P) (+ ptY 290.00))
                   1
                   1
                   90
          )
          ;; Ubah parameter dinamis "Distance1"
          (UbahDynamicBlock (entlast) "Distance1" (- Caw1 400.00))
          
          ;==Insert gate 1 kanan tengah 1
          (command "._-INSERT" 
                   "Gate Removable S Top"
                   "_non"
                   (list (+ ptX P) (+ ptY Caw1 Dfrst Fcaw 75))
                   1
                   1
                   270
          )
          ;; Ubah parameter dinamis "Distance1"
          (UbahDynamicBlock (entlast) "Distance1" (- Fcaw 50.00))
          
          ;==Insert gate 1 kanan tengah 2
          (command "._-INSERT" 
                   "Gate Removable S Top"
                   "_non"
                   (list (+ ptX P) (+ ptY Caw1 Dfrst Fcaw 150 Taw 75))
                   1
                   1
                   90
          )
          ;; Ubah parameter dinamis "Distance1"
          (UbahDynamicBlock (entlast) "Distance1" (- Fcaw 50.00))
          
          ;==Insert gate 1 kanan atas 2
          (command "._-INSERT" 
                   "Gate Removable S Top"
                   "_non"
                   (list (+ ptX P) (- (+ ptY L) 290.00))
                   1
                   1
                   270
          )
          ;; Ubah parameter dinamis "Distance1"
          (UbahDynamicBlock (entlast) "Distance1" (- Caw1 400.00))
          
        ;; RECTANGLE CROSS OVER TEPI
          ;==buat rectangle untuk menandai area cross over tepi kiri
          (command "._RECTANG" 
                   (list ptX (+ ptY Caw1)) ; Titik awal rectangle (pojok kiri)
                   (list (+ ptX CrssTp) (+ ptY Caw1 DFrst)) ; Titik akhir rectangle (pojok kanan)
          ) 

          ; warna untuk hatch alley way
          (command "._-COLOR" "151") ; Ubah warna ke  (151)

          ; Hatch Cow Alley Way 2 (ANSI32, Scale 40, Angle 135)
          (command "._HATCH" "P" "ANSI32" 40 45 "S" (entlast) "")

          (command "._-COLOR" "250") ; Ubah warna ke black (7) untuk gambar selanjutnya
          
          ;==buat rectangle untuk menandai area cross over tepi kiri 2
          (command "._RECTANG" 
                   (list ptX (+ ptY Caw1 Dfrst Fcaw 150 Taw 150 Fcaw )) ; Titik awal rectangle (pojok kiri alley way)
                   (list (+ ptX CrssTp) (+ ptY Caw1 DFrst Fcaw 150 Taw 150 Fcaw Dfrst)) ; Titik akhir rectangle (pojok kanan alley way)
          ) ;buat rectangle dengan panjang P dan lebar L dari titik awal

          ; warna untuk hatch alley way
          (command "._-COLOR" "151") ; Ubah warna ke  (151)

          ; Hatch Cow Alley Way 2 (ANSI32, Scale 40, Angle 135)
          (command "._HATCH" "P" "ANSI32" 40 45 "S" (entlast) "")

          (command "._-COLOR" "250") ; Ubah warna ke black (7) untuk gambar selanjutnya
          
          ;==buat rectangle untuk menandai area cross over tepi kanan
          (command "._RECTANG" 
                   (list (+ ptX (- P CrssTp)) (+ ptY Caw1)) ; Titik awal rectangle (pojok kiri)
                   (list (+ ptX P) (+ ptY Caw1 DFrst)) ; Titik akhir rectangle (pojok kanan)
          ) 

          ; warna untuk hatch alley way
          (command "._-COLOR" "151") ; Ubah warna ke  (151)

          ; Hatch Cow Alley Way 2 (ANSI32, Scale 40, Angle 135)
          (command "._HATCH" "P" "ANSI32" 40 45 "S" (entlast) "")

          (command "._-COLOR" "250") ; Ubah warna ke black (7) untuk gambar selanjutnya
          
          ;==buat rectangle untuk menandai area cross over tepi kanan 2
          (command "._RECTANG" 
                   (list (+ ptX (- P CrssTp)) (+ ptY Caw1 Dfrst Fcaw 150 Taw 150 Fcaw )) ; Titik awal rectangle (pojok kiri alley way)
                   (list (+ ptX P) (+ ptY Caw1 DFrst Fcaw 150 Taw 150 Fcaw Dfrst)) ; Titik akhir rectangle (pojok kanan alley way)
          ) ;buat rectangle dengan panjang P dan lebar L dari titik awal

          ; warna untuk hatch alley way
          (command "._-COLOR" "151") ; Ubah warna ke  (151)

          ; Hatch Cow Alley Way 2 (ANSI32, Scale 40, Angle 135)
          (command "._HATCH" "P" "ANSI32" 40 45 "S" (entlast) "")

          (command "._-COLOR" "250") ; Ubah warna ke black (7) untuk gambar selanjutnya
          
                   
          ;==Looping buat rectangle untuk menandai area cross over tengah
          (setq i 1)
          (setq j 0)
          
          (while (< i (+ (- GrFrst 1) 1e-4))
          
            (command "._RECTANG" 
                    (list (+ ptX (+ CrssTp (* (+ (* jml 1200) 300) i) (* CrssTgh j))) (+ ptY Caw1)) ; Titik awal rectangle (pojok kiri)
                    (list (+ ptX (+ CrssTp (* (+ (* jml 1200) 300) i) (* CrssTgh (+ j 1)))) (+ ptY Caw1 DFrst)) ; Titik akhir rectangle (pojok kanan)
            )

            ; warna untuk hatch alley way
            (command "._-COLOR" "151") ; Ubah warna ke  (151)

            ; Hatch Cow Alley Way 2 (ANSI32, Scale 40, Angle 135)
            (command "._HATCH" "P" "ANSI32" 40 45 "S" (entlast) "")
            
            (command "._-COLOR" "250") ; Ubah warna ke black (7) untuk gambar selanjutnya
                                
            ;==buat rectangle untuk menandai area cross over tepi tengah 2
            (command "._RECTANG" 
                    (list (+ ptX (+ CrssTp (* (+ (* jml 1200) 300) i) (* CrssTgh j))) (+ ptY Caw1 Dfrst Fcaw 150 Taw 150 Fcaw )) ; Titik awal rectangle (pojok kiri alley way)
                    (list (+ ptX (+ CrssTp (* (+ (* jml 1200) 300) i) (* CrssTgh (+ j 1)))) (+ ptY Caw1 DFrst Fcaw 150 Taw 150 Fcaw Dfrst)) ; Titik akhir rectangle (pojok kanan alley way)
            ) ;buat rectangle dengan panjang P dan lebar L dari titik awal

            ; warna untuk hatch alley way
            (command "._-COLOR" "151") ; Ubah warna ke  (151) 
            
            ; Hatch Cow Alley Way 2 (ANSI32, Scale 40, Angle 135)
            (command "._HATCH" "P" "ANSI32" 40 45 "S" (entlast) "")

            (command "._-COLOR" "250") ; Ubah warna ke black (7) untuk gambar selanjutnya
            
            (setq i (+ i 1))
            (setq j (+ j 1))               
          )
          
        ;; INSERT BAK MINUM
          (setq i 0)
          (setq panjangFrstl (+ (* jml 1200.00) 300.00))

          (while (< i (- (+ GrFrst 1e-4) 1)) 
            ;; Insert Block Bak Minum kiri
            (command "._-INSERT" 
                     "bak-minum-kiri" ; Nama block bak minum kiri 1
                     "_non"
                     (list (+ ptX (- CrssTp 50) (* i (+ panjangFrstl CrssTgh))) 
                           (+ ptY Caw1 (/ DFrst 2))
                     )
                     1
                     0
            )

            (command "._-INSERT" 
                     "bak-minum-kiri" ; Nama block bak minum kiri 2
                     "_non"
                     (list (+ ptX (- CrssTp 50) (* i (+ panjangFrstl CrssTgh))) 
                           (+ ptY Caw1 DFrst Fcaw 150 Taw 150 Fcaw (/ DFrst 2))
                     )
                     1
                     0
            )

            ;; Insert Block Bak Minum kanan
            (command "._-INSERT" 
                     "bak-minum-kanan" ; Nama block bak minum kanan 1
                     "_non"
                     (list 
                       (+ ptX (+ CrssTp 50) (* (+ i 1) panjangFrstl) (* i CrssTgh))
                       (+ ptY Caw1 (/ DFrst 2))
                     )
                     1
                     0
            )

            (command "._-INSERT" 
                     "bak-minum-kanan" ; Nama block bak minum kanan 2
                     "_non"
                     (list 
                       (+ ptX (+ CrssTp 50) (* (+ i 1) panjangFrstl) (* i CrssTgh))
                       (+ ptY Caw1 DFrst Fcaw 150 Taw 150 Fcaw (/ DFrst 2))
                     )
                     1
                     0
            )

            (setq i (+ i 1)) ; Tambahkan jumlah grup yang sudah dibuat
          )
  
          
          ;;========================================
          ;; --- KEMBALIKAN PENGATURAN AUTOCAD ---
          ;;========================================

          (setvar "OSMODE" oldOsnap)
          (setvar "ATTREQ" oldAttreq)
          (setvar "CMDECHO" oldCmdecho)
        )

        ;; Else, jika user tidak mengklik titik awal (misal klik Cancel atau tekan Esc saat diminta klik titik)
        (princ "\nProses dibatalkan: Anda tidak mengklik titik awal.")
      )
    )

    ;; Else, jika user mengklik tombol Cancel di dialog atau menutup dialog tanpa klik OK
    (princ "\nProses dibatalkan oleh pengguna (Tombol Cancel diklik).")
  )

  (princ)
)
