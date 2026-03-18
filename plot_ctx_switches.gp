# ==============================================================================
# Used to work, doesn't anymore
# ==============================================================================

set term qt size 1500,1000

set title	"Top N context switches by processus"

set xdata	time
set timefmt	"%s"

# Very nice looking !!
set xtics format "%b %d\n%H:%M"

# WORKS!
# The idea is to alertane on x
# After that we have to add

# SHOULD BE AUTOMATED !!
# or graph 0,0 instead of screen 0,0
set object rectangle from screen 0.1,0.05 to screen 0.17,0.95 behind fillcolor rgb 'grey90' fillstyle solid noborder
set object rectangle from screen 0.25,0.05 to screen 0.35,0.95 behind fillcolor rgb 'grey90' fillstyle solid noborder
set object rectangle from screen 0.42,0.05 to screen 0.52,0.95 behind fillcolor rgb 'grey90' fillstyle solid noborder
set object rectangle from screen 0.61,0.05 to screen 0.69,0.95 behind fillcolor rgb 'grey90' fillstyle solid noborder
set object rectangle from screen 0.78,0.05 to screen 0.87,0.95 behind fillcolor rgb 'grey90' fillstyle solid noborder

filename="ctx_switches.dat"

plot \
     filename using ($1 + 3600):($12) with points, \
     filename using ($1 + 3600):($11) with points, \
     filename using ($1 + 3600):($10) with points, \
     filename using ($1 + 3600):($9)  with points, \
     filename using ($1 + 3600):($8)  with points, \
     filename using ($1 + 3600):($7)  with points, \
     filename using ($1 + 3600):($6)  with points, \
     filename using ($1 + 3600):($5)  with points
