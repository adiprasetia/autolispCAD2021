;;fungsi untuk memanggil kotakdialog.dcl
(vl-load-com) ; Memastikan fungsi vl-* (Visual LISP) aktif

(defun c:kotakdialog (/ dcl_id dcl_path)
  ;; Gunakan full path ke file kotakdialog.dcl
  (setq dcl_path "kotakdialog.dcl")
  
  (setq dcl_id (load_dialog dcl_path)) ; Memuat file DCL dengan full path
  
  (if (not (new_dialog "gp_mainDialog" dcl_id)) ; Membuka dialog dengan nama "gp_mainDialog" (sesuai di kotakdialog.dcl)
    (progn
      (alert "Gagal membuka dialog! Pastikan file kotakdialog.dcl ada di folder yang benar.")
    )
    (progn
      (start_dialog) ; Memulai dialog
      (unload_dialog dcl_id) ; Setelah dialog selesai, unload DCL
    )
  )
  (princ)
)