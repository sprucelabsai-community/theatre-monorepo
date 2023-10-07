const fs = require('fs');
const yaml = require('js-yaml');
const path = require('path')

const blueprintPath = process.argv[2];
const section = process.argv[3];

if (!blueprintPath) {
    console.error("No section provided. Usage: node blueprint.js <section-name>");
    process.exit(1);
}

const resolvedPath = blueprintPath[0] === '/' ? blueprintPath : path.join(process.cwd(), '..', blueprintPath);

console.log('Using blueprint file: ' + resolvedPath)

const file = fs.readFileSync(resolvedPath, 'utf8');
const data = yaml.load(file);

if (data[section]) {
    data[section].forEach(item => {
        console.log(item);
    });
} else {
    console.error(`Section "${section}" not found in blueprint.yml`);
    process.exit(1);
}
