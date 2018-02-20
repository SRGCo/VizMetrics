#!/bin/bash
lftp <<SCRIPT
set ftps:initial-prot ""
set ftp:ssl-force true
set ftp:ssl-protect-data true
open ftps://<hostname>:990
user <user> <password>
lcd /tmp
cd <ftp_folder_hierarchy>
put foo.txt
exit
SCRIPT


lftp ftp://$(FTP_USER)@$(FTP_HOST) -e "set ftp:ssl-allow no; mirror -R $(OUTPUTDIR) $(FTP_TARGET_DIR) ; quit
