# vim: set ft=make :

check-idle-power-draw:
    #!/usr/bin/bash
    powerstat -a -r
