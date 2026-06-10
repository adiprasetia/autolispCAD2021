(defun c:kotak (/ ptAwal P L Caw1)
  
(setq ptAwal (getpoint "\nTitik Awal: "))
(setq P (getdist ptAwal "\nPanjang Bangunan: "))
(setq Caw1 3600.00)
  
  
  ; Alley Way Cow (Caw1)
  (command "._RECTANG" 
            (list (car ptAwal) (cadr ptAwal)) ; Titik awal rectangle (pojok dalam alley way)
            (list (+ (car ptAwal) P) (+ (cadr ptAwal) Caw1)) ; Titik akhir rectangle (pojok dalam alley way)
  )
  
  ;== looping bak minum
  (setq i 0)
  (setq GrFrst 3)
  (setq CrssTp 5150.00)
  (setq CrssTgh 5800.00)
  (setq DFrst 5400.00 )
  (setq Taw 5600.00)
  (setq Fcaw 4500.00 )
  (setq panjangFrstl (+ (* 27 1200.00) 300.00))+
  (setq ptX (car ptAwal))
  (setq ptY (cadr ptAwal))  
  
  
  
  ; (while (< i (- (+ GrFrst 1e-4) 1)) 
  ;   ;; Insert Block Bak Minum 1
  ;   (command "._-INSERT" 
  ;             "Wa-flat-10" ; Nama block bak minum 1
  ;             ;"_non"
  ;             (list (+ ptX (- CrssTp 50) (* i(+ panjangFrstl CrssTgh))) (+ ptY Caw1 (/ DFrst 2))) 1 1 0
  ;   )
    
  ;   (command "._-INSERT" 
  ;             "Wa-flat-10" ; Nama block bak minum 2
  ;             ;"_non"
  ;             (list (+ ptX (- CrssTp 50) (* i(+ panjangFrstl CrssTgh))) (+ ptY Caw1 DFrst Fcaw 150 Taw 150 Fcaw (/ DFrst 2))) 1 1 0
  ;   )
    
  ;   (setq i (+ i 1)) ; Tambahkan jumlah grup yang sudah dibuat
  
  ; )
  
  ;==Insert dinding beton 1
      (command "._-INSERT" 
                "Dinding Beton"
                "_non"
                (list  ptX (+ ptY Caw1)) 1 90
      )
      ;; Ubah parameter dinamis "Distance1" 
      (UbahDynamicBlock (entlast) "Distance1" Dfrst)

  ;==Insert dinding beton 2
      (command "._-INSERT" 
                "Dinding Beton"
                "_non"
                (list  ptX (+ ptY Caw1 DFrst Fcaw 150 Taw 150 Fcaw )) 1 90
      )
      ;; Ubah parameter dinamis "Distance1" 
      (UbahDynamicBlock (entlast) "Distance1" Dfrst)

  ;==Insert dinding beton 3
      (command "._-INSERT" 
                "Dinding Beton"
                "_non"
                (list  (+ ptX P) (+ ptY Caw1)) 1 90
      )
      ;; Ubah parameter dinamis "Distance1" 
      (UbahDynamicBlock (entlast) "Distance1" Dfrst)

  ;==Insert dinding beton 4
      (command "._-INSERT" 
                "Dinding Beton"
                "_non"
                (list  (+ ptX P) (+ ptY Caw1 DFrst Fcaw 150 Taw 150 Fcaw )) 1 90
      )
      ;; Ubah parameter dinamis "Distance1" 
      (UbahDynamicBlock (entlast) "Distance1" Dfrst)

)