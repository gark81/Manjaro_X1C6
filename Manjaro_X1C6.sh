#!/bin/bash

##########################################################################
# Script de Configuración de Lenovo Thinkpad X1 6th Gen en Manjaro KDE
# Author: GARK
# Year: 2024
##########################################################################

##########
# COLORS #
##########
# Reset
Color_Off='\033[0m'       # Text Reset
# Bold High Intensity
    BIGreen='\033[1;92m'      # Green
    BIYellow='\033[1;93m'     # Yellow

################################
# ********** VARIABLES *********
################################
GRUB_FILE='/etc/default/grub'

#################################
# ********* Funciones *********
#################################

#################################################
# ********** Thinkpad X1 Carbon 6th Gen *********
#################################################

# **************
# Instalar TLP #
# **************
install_tlp(){
      sudo pacman -S --noconfirm tlp tlpui
      sudo systemctl enable tlp.service
      sudo systemctl status tlp.service
      echo -e "${BIGreen} ********** INSTALADO Base-Devel, YAY, Neofetch, TLP ********** ${Color_Off}"
      }

# *************
# Editar GRUB #
# *************
grub_edit(){
      sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/' $GRUB_FILE
      sudo sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/s/^/#/' $GRUB_FILE
      sudo sed -i '6i GRUB_CMDLINE_LINUX_DEFAULT="quiet udev.log_priority=3 apparmor=1 security=apparmor acpi.ec_no_wakeup=1 msr.allow_writes=on psmouse.synaptics_intertouch=1 snd_hda_codec_hdmi.enable_silent_stream=0"' $GRUB_FILE
      sudo update-grub
      echo -e "${BIGreen}********** GRUB Actualizado ********* ${Color_Off}"
      }

# *************************
# Intel-ucode , THROTTLED #
# *************************
install_throttled(){
      sudo pacman -S --noconfirm intel-ucode
      sudo grub-mkconfig -o /boot/grub/grub.cfg
      sudo pacman -S --noconfirm throttled
      sudo systemctl enable --now lenovo_fix.service
      sudo dmidecode -s system-version
      sudo dmesg | grep -i "acpi: (supports"
      echo -e "${BIGreen}********** Intel-Ucode, throttled instalado ********** ${Color_Off}"
      }

# *************************************************
# ALSA-BASE - Quitar limitacion volumen altavoces #
# *************************************************
alsabase_modify(){
      echo "options snd-hda-intel model=nofixup" | sudo tee -a /etc/modprobe.d/alsa-base.conf
      echo -e "${BIGreen}********** ALSA BASE modificado ********** ${Color_Off}"
      }

# ***********************
# Xorg - Screen tearing #
# ***********************
xorg_modify(){
      echo "#Section "Device"
      #  Identifier  "Intel Graphics"
      #  Driver      "intel"
      #  Option      "TearFree" "true"
      #EndSection" | sudo tee -a /etc/X11/xorg.conf.d/20-intel.conf
      echo -e "${BIGreen}********** SCREEN TEARING modificado ********** ${Color_Off}"
      }

# ***********************************************
# TLP blacklisting devices from USB autosuspend #
# ***********************************************
tlp_modify(){
      sudo sed -i '390i USB_DENYLIST="0000:1111 2222:3333 4444:5555"' /etc/tlp.conf
      echo -e "${BIGreen}********** TLP modificado ********** ${Color_Off}"
      }

# *******************
# LECTOR DE HUELLAS #
# *******************
fingerprint(){
      yay -S --noconfirm python-validity
      sudo systemctl stop python3-validity
      sudo validity-sensors-firmware
      sudo python3 /usr/share/python-validity/playground/factory-reset.py
      sudo systemctl start python3-validity.service
      sudo systemctl status python3-validity.service
      fprintd-delete "$USER"
      # En caso que no reconozca por GUI probar por terminal con:
      #for finger in {left,right}-{thumb,{index,middle}-finger}; do fprintd-enroll -f "$finger" "$USER"; done

      # Kwallet-pam
      sudo pacman -S --noconfirm kwallet-pam

      # Backup archivos
      sudo cp /etc/pam.d/system-local-login /etc/pam.d/system-local-login.bak
      sudo cp /etc/pam.d/login /etc/pam.d/login.bak
      sudo cp /etc/pam.d/su /etc/pam.d/su.bak
      sudo cp /etc/pam.d/sudo /etc/pam.d/sudo.bak
      sudo cp /etc/pam.d/sddm /etc/pam.d/sddm.bak
      sudo cp /etc/pam.d/kde /etc/pam.d/kde.bak

      # Editar archivos
      sudo sed -i '3i ###\nauth            sufficient      pam_unix.so try_first_pass likeauth nullok\nauth            sufficient      pam_fprintd.so\n###\n' /etc/pam.d/system-local-login

      sudo sed -i '3i ###\nauth            sufficient      pam_unix.so try_first_pass likeauth nullok\nauth            sufficient      pam_fprintd.so\n###\n' /etc/pam.d/login

      sudo sed -i '7i ###\nauth            sufficient      pam_unix.so try_first_pass likeauth nullok\nauth            sufficient      pam_fprintd.so\n###\n' /etc/pam.d/su

      sudo sed -i '2i ###\nauth            sufficient      pam_unix.so try_first_pass likeauth nullok\nauth            sufficient      pam_fprintd.so\n###\n' /etc/pam.d/sudo

      sudo sed -i '3i ###\nauth            [success=1 new_authtok_reqd=1 default=ignore]   pam_unix.so try_first_pass likeauth nullok\nauth            sufficient      pam_fprintd.so\n###\n' /etc/pam.d/sddm

      sudo sed -i '3i ###\nauth            sufficient      pam_unix.so try_first_pass likeauth nullok\nauth            sufficient      pam_fprintd.so\n###\n' /etc/pam.d/kde

      sudo sed -i '9i auth            optional        pam_kwallet.so kdehome=.kde4' /etc/pam.d/kde

      echo 'session         optional        pam_kwallet.so' | sudo tee -a /etc/pam.d/kde

      echo -e "${BIGreen} ********* Lector de Hellas Instalado ********* ${Color_Off}"
      }

# *********************
# Arreglar Fallo SDDM #
# *********************
sddm_modify(){
      sudo chown -R sddm:sddm /var/lib/sddm/.config
      echo -e "${BIGreen}********** SDDM Arreglado ********** ${Color_Off}"
      }

# *********
# ERRORES #
# *********
errors_check(){
      echo -e "${BIBlue} Imprimiendo posibles ERRORES ${Color_Off}"
      echo -e "${BIBlue} Errores Systemctl ${Color_Off}"
      sudo systemctl --failed
      echo -e "${BIBlue} Errores journalctl -p 3 -x ${Color_Off}"
      sudo journalctl -p 3 -xb
      echo -e "${BIBlue} Errores systemd-suspend ${Color_Off}"
      sudo journalctl -p err -u systemd-suspend
      echo -e "${BIBlue} Errores dmesg -Tl err ${Color_Off}"
      sudo dmesg -Tl err
      }

# ***********************
# FIN DE LA INSTALACION #
# ***********************
end_message(){
      echo -e "${BIGreen} ==> RECUERDA configurar FIREFOX --> about:config --> browser.cache.disk.parent_directory --> indica la ruta /tmp/firefox ${Color_Off}"
      echo -e " "
      echo -e "${BIGreen} <<<<<<<<<< FIN >>>>>>>>>> ${Color_Off}"
      }



##########################################
# ********** FUNCIÓN PRINCIPAL ********* #
##########################################

# Llamada a funciones
main() {
    ############
    # Thinkpad #
    ############
    install_tlp
    grub_edit
    install_throttled
    alsabase_modify
    xorg_modify
    tlp_modify
    fingerprint

    # SDDM
    sddm_modify

    #######
    # FIN #
    #######

    # Errores
    errors_check

    # Final de instalacion
    end_message
}

# ******************************
# Llama a la función principal #
# ******************************
main
