source ./support/hero.sh

yarn shutdown

echo "Cleaning out node_modules, package-lock.json, npm install.lock, .processes, .pm2, and all packages..."

rm -rf node_modules/ package-lock.json npm install.lock .processes .pm2

find ./packages -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +

hero "Reset complete. You are now ready to start from scratch."
