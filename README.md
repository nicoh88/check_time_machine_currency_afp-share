# Check_MK / Nagios - Alter des letzten TimeMachine Backups auf einem lokalen AFP-Share prüfen

##### Quick 'n Dirty Scripting | nicht schön, aber selten

Bei diesem Bash-Skript handelt es sich um einen klassischen Nagios Check, welchen man in Nagios bzw. Check_MK verwenden kann.

![screenshot_cmk_status.png](screenshot_cmk_status.png?raw=true "screenshot_cmk_status.png")

Das Skript gehört bei einer OMD-Installation in das Verzeichnis `/omd/sites/mon/local/lib/nagios/plugins/` und muss natürlich mit `chmod` sowie `chown` für den OMD-User ausführbar gemacht werden. Des Weiteren muss der OMD-User Zugriff auf den Pfad des TimeMachine-Backups haben und die Datei `com.apple.TimeMachine.SnapshotHistory.plist` lesen können.
In den Check_MK WATO Einstellungen unter "*Host & Service Parameters*" > "*Active checks (HTTP, TCP, etc.)*" > "*Classical active and passive Monitoring checks*" kann dann eine neue Regel erstellen und die Parameter festlegen.

![screenshot_cmk_wato-classic-nagios-checks-1.png](screenshot_cmk_wato-classic-nagios-checks-1.png?raw=true "screenshot_cmk_wato-classic-nagios-checks-1.png")

Beispiel: `$USER2$/check_time_machine_currency_afp-share.sh -p /mnt/data/backup/TimeMachine -h hedwig -w 4320 -c 10080`

![screenshot_cmk_wato-classic-nagios-checks-2.png](screenshot_cmk_wato-classic-nagios-checks-2.png?raw=true "screenshot_cmk_wato-classic-nagios-checks-2.png")

Viel Spaß!

##### Inspiration & Dank
 * [yesdevnull - check_time_machine_currency.sh](https://github.com/yesdevnull/OSX-Monitoring-Tools/blob/master/check_time_machine_currency.sh)
 * [jedda - check_time_machine_currency.sh](https://github.com/jedda/OSX-Monitoring-Tools/blob/master/check_time_machine_currency.sh)