const fs = require('fs');
const yaml = require('js-yaml');
const path = require('path')

const blueprintPath = process.argv[2];
const section = process.argv[3];

if (!blueprintPath) {
    console.error("No section provided. Usage: node blueprint.js <section-name>");
    process.exit(1);
}

// Assuming the script is always run from the theatre-monorepo directory:
const resolvedPath = blueprintPath[0] === '/' ? blueprintPath : path.join(__dirname, '..', blueprintPath);
const file = fs.readFileSync(resolvedPath, 'utf8');
const data = yaml.load(file);

if (Array.isArray(data[section])) {
    const asObject = {};
    let shouldOutputAsObject = true;
    data[section].forEach(item => {
        if (typeof item !== 'object') {
            shouldOutputAsObject = false;
            console.log(JSON.stringify(item));
        } else {

            for (const key in item) {
                asObject[key] = item[key];
            }
        }
    });
    if (shouldOutputAsObject) {
        console.log(JSON.stringify(asObject));
    }
} else if (typeof data[section] === 'object') {
    console.log(JSON.stringify(data[section]));
} else {
    console.error(`Section "${section}" not found or not iterable in blueprint.yml`);
    process.exit(1);
}