;CODING BEGINS HERE

(defun c:ColorToLayer ()

;clear the loop control variables
(setq i 0 n 0)

;prompt the user
(prompt "\n Select entities to analyze ")


;get the selection set
(setq sel (ssget))

;get the number of objects
(setq n (sslength sel))

   ;start the loop
   (repeat n

      ;get the entity name
      (setq entity (ssname sel i))

      ;now get the entity list
      (setq name (entget entity))

      ;if not Bylayer
      (if (not (assoc 6 name))

         ;do the following
         (progn

            ;retrieve the layer name
            (setq layer (cdr (assoc 8 name)))

            ;get the layer data
            (setq layerinf (tblsearch "LAYER" layer))
 
            ;extract the default layer colour
            (setq layercol (cdr (assoc 62 layerinf)))

            ;construct an append the new list
            (setq name (append name (list (cons 62 layercol))))

            ;update the entity
            (entmod name)

            ;update the screen
            (entupd entity)

         );progn

      );if

      ;increment the counter
      (setq i (1+ i))

   ;loop
   );repeat

   (princ)

);defun

(princ)

;CODING END HERE