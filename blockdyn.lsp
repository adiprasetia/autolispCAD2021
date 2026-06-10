(vl-load-com)

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
;; 2. CONTOH CARA PENGGUNAANNYA UNTUK BLOCK "DINDING BETON"
;; =========================================================================
(defun c:TesDinding ( / ptAwal panjang)
  
  ;; Minta titik dan panjang dari user
  (setq ptAwal (getpoint "\nKlik titik penempatan dinding beton: "))
  
  (if ptAwal
    (progn
      (setq panjang (getreal "\nMasukkan panjang dinding (Distance 1): "))
      
      (if panjang
        (progn
          ;; Langkah 1: Insert Blocknya terlebih dahulu (Skala 1, Sudut 0)
          (command "._-INSERT" "dinding beton" "_non" ptAwal 1 1 0)
          
          ;; Langkah 2: Ubah panjangnya dengan memanggil fungsi bantuan di atas
          ;; (entlast) berfungsi untuk mengambil objek terakhir yang digambar (yaitu block yg baru di-insert)
          (UbahDynamicBlock (entlast) "Distance 1" panjang)
          
          (princ (strcat "\nDinding beton berhasil dibuat dengan panjang " (rtos panjang 2 2)))
        )
      )
    )
  )
  (princ)
)