source ./support/hero.sh

hero "Shutting down all skills..."
./support/shutdown.sh

hero "Killing PM2..."
./support/pm2.sh kill
rm -rf ./.pm2

yarn boot.serve
