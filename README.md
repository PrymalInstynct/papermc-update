# papermc-update
Bash Script to update PaperMC and Waterfall across all Service instances

Expects Minecraft instances are lated under the /opt/minecraft/* directory and waterfall is located at /opt/waterfall

Also expects that Minecraft services are manged by the systemd scripts found in this repo

- Install `minecraft@.service` and `waterfall.service` in /etc/systemd/system/
