# Fichier de donnees pour le script 'zbxcheck'
# Auteur : 		S. Perrot (ATR-OutilsMdw)
# Date de creation : 	Mars 2022

# pour avoir une liste de machines par env, au lieu d'une liste unique dans un fichier txt   

# a date kx03aflx05 ne peut communiquer avec le serveur nim
typeset -A hosts_by_env=(

 #[acores]="kx03aflx01 kx03aihm01 kx03aflx03 kx03aflx05"
 [acores]="kx03aflx01 kx03aihm01 kx03aflx03"

 # on 

# [eukal2]="kx03aflx01 kx03aihm01 kx03aflx03 kx03aflx05
#             kx3eucore2 kx3eusip02 kx3eupac02 kx3euldap2 kx3eupxy02"

 [eukal2]="kx03aflx01 kx03aihm01 kx03aflx03 
           kx3eucore2 kx3eusip02 kx3eupac02 kx3euldap2 kx3eupxy02"

 # En attendant 
 #[frkal2]="kx3frcore2 kx3frsip02 kx3frpac02 kx3frldap2 kx3frpxy02"
 [frkal2]="kx3frcore2 kx3frsip02 kx3frpac02 kx3frldap2 "
)


