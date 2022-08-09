var fs = require('fs');

const myArgs = process.argv.slice(2);

var data = fs.readFileSync('routes/index.js').toString().split("\n");
let lineRouter
let lineImport
for(let i = 0; i < data.length; i++){
    if(data[i].includes('}')){
        lineRouter = i
    }

    if(data[i].includes('fileUpload = ')){
        lineImport = i
    }
}


const route = "\"/"+myArgs+"\""
const routerName = myArgs+"Router"

const importName = `const ${routerName} = require('./${myArgs}/${myArgs}')`
data.splice(lineRouter, 0,`\tapp.use(${route}, ${routerName})`);
data.splice(lineImport, 0, `${importName}`);
var text = data.join("\n");

fs.writeFile('routes/index.js', text, function (err) {
  if (err) return console.log(err);
});