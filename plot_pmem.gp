# ==============================================================================
# Used to work, doesn't anymore
# ==============================================================================

set term qt size 1500,1000

set title	"Top N pmem by processus"

set xdata	time
set timefmt	"%s"

# Very nice looking !!
#set xtics format "%b %d\n%H:%M"
set xtics format "%b %d\n%H:%M\n(%s)"

# WORKS!
# The idea is to alertane on x
# After that we have to add

# SHOULD BE AUTOMATED !!
# or graph 0,0 instead of screen 0,0

filename="pmem.dat"

plot \
     filename using ($1 + 3600):($12) with points, \
     filename using ($1 + 3600):($11) with points, \
     filename using ($1 + 3600):($10) with points, \
     filename using ($1 + 3600):($9)  with points, \
     filename using ($1 + 3600):($8)  with points, \
     filename using ($1 + 3600):($7)  with points, \
     filename using ($1 + 3600):($6)  with points, \
     filename using ($1 + 3600):($5)  with points

