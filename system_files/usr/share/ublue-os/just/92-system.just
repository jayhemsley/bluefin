# vim: set ft=make :

check-idle-power-draw:
    #!/usr/bin/bash
    run0 powerstat -a -r
