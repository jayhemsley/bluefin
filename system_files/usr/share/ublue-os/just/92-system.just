# vim: set ft=make :

check-idle-power-draw:
    #!/usr/bin/bash
    sudo powerstat -a -r
