const { execSync } = require('child_process');
const path = require('path');

const blueprintPath = process.argv[2];

if (!blueprintPath) {
    console.error("No blueprint path provided. Usage: yarn sync <blueprint-path>");
    process.exit(1);
}

try {
    // Construct command with all arguments
    const args = process.argv.slice(2).join(' '); // Join all arguments starting from index 2
    const command = `(yarn || true) && yarn sync-skills-from-blueprint ${args} && (yarn install --ignore-engines || true) && (yarn run build || true) && yarn build.heartwood`;
    execSync(command, { stdio: 'inherit', cwd: process.cwd() });
} catch (error) {
    console.error('Error running sync', error);
}
