const fs = require('fs');
const yaml = require('js-yaml');

const section = process.argv[2];

if (!section) {
    console.error("No section provided. Usage: node blueprint.js <section-name>");
    process.exit(1);
}

const file = fs.readFileSync('./blueprint.yml', 'utf8');
const data = yaml.load(file);

if (data[section]) {
    data[section].forEach(item => {
        console.log(item);
    });
} else {
    console.error(`Section "${section}" not found in blueprint.yml`);
    process.exit(1);
}
