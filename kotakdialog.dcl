gp_mainDialog : dialog {
  label = "Garden Path Tile Specifications"; 
  : boxed_radio_column {     // defines the radio button areas
    label = "Outline Polyline Type";
    : radio_button {         // defines the Lightweight radio button
      label = "&Lightweight";
      key = "gp_lw";
      value = "1";
    }
    : radio_button {         // defines the "legacy" polyline radio button
      label = "&Legacy";
      key = "gp_hw";
    }
  }

  : boxed_radio_column {     // defines the radio button areas
    label = "Tile Creation Method";
    : radio_button {         // defines the ActiveX radio button
      label = "&ActiveX Automation";
      key = "gp_actx";
      value = "1";
    }
    : radio_button {         // defines the (entmake) radio button
      label = "&Entmake";
      key = "gp_emake";
    }
    : radio_button {         // defines the (command) radio button
      label = "&Command";
      key = "gp_cmd";
    }
  }

  : edit_box {               // defines the Radius of Tile edit box
    label = "&Radius of tile";
    key = "gp_trad";
    edit_width = 6;
  }
  : edit_box {               // defines the Spacing Between Tiles edit box
    label = "&Spacing between tiles";
    key = "gp_spac";
    edit_width = 6;
  }
  : row {                    // defines the OK/Cancel button row
    : spacer { width = 1; }
    : button {               // defines the OK button
      label = "OK";
      is_default = true;
      key = "accept";
      width = 8;
      fixed_width = true;
   }
   : button {                // defines the Cancel button
     label = "Cancel";
     is_cancel = true;
     key = "cancel";
     width = 8;
     fixed_width = true;
   }
   : spacer { width = 1;}
  }
}