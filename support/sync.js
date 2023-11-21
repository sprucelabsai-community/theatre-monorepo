const { execSync } = require('child_process');
const path = require('path');

const blueprintPath = process.argv[2]

if (!blueprintPath) {
    console.error("No blueprint path provided. Usage: yarn sync <blueprint-path>");
    process.exit(1);
}

try {
    const fullPath = path.resolve(process.cwd(), blueprintPath);
    const command = `yarn add-skills-from-blueprint ${fullPath} && yarn --force && yarn build`;
    execSync(command, { stdio: 'inherit', cwd: process.cwd(), env: env });
} catch (error) {
    console.error('Error running sync', error);
}
