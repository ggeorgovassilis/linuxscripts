# clamav in docker container

Runs the [clamav](https://www.clamav.net/) daemon in a docker container and provides scripts for running scans and updating signature databases.

1. Edit config.sh for paths. "base" should be the full path to the directory where the scripts are located. "dirtoscan" should be the directory you want to scan.

2. Run run-clamav-daemon.sh to start the daemon. You might want to do this once in a while to get newer container images. Note that ClamAV requires up to 4GB of RAM (especially during database reloads).

3. Run freshclam.sh to manually update the signature database. Ensure you do this before starting a scan if the local database might be stale.

4. Run clamscan.sh to start a scan.


 

