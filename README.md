## Please follow the guidance below to setup the environment

1. Set up packages:
   ```sh
   # "/opt" is usually owned by root, so you have to first manually create the "/opt/nio" folder.
   sudo mkdir -p /opt/nio
   sudo chown $USER:$USER /opt/nio
   make install  # This will install packages to /opt/nio/
