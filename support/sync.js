const { execSync } = require('child_process');
const path = require('path');

const blueprintPath = process.argv[2]

if (!blueprintPath) {
    console.error("No blueprint path provided. Usage: yarn sync <blueprint-path>");
    process.exit(1);
}

try {
    const fullPath = path.resolve(process.cwd(), blueprintPath);
    const command = `npm run add-skills-from-blueprint ${fullPath} && npm install --force && npm run build`;
    execSync(command, { stdio: 'inherit', cwd: process.cwd() });
} catch (error) {
    console.error('Error running sync', error);
}
