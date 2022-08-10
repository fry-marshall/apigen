var fs = require('fs');

const myArgs = process.argv.slice(2);

const importName = `const ${myArgs} = require('../models/${myArgs}')`
const sync = `await ${myArgs}.sync()`
var data = fs.readFileSync('utils/database/migrations.js').toString().split("\n");
let line

let alreadyImport = false


for(let i = 0; i < data.length; i++){
    if(data[i].includes(importName)){
        alreadyImport = true
    }
}


if(!alreadyImport){
    for(let i = 0; i < data.length; i++){
        if(data[i].includes('}')){
            line = i
        }
       
    }
    
    
    data.splice(line, 0, `\t${sync}`);
    data.splice(line, 0, `\t${importName}`);

    var text = data.join("\n");
    
    fs.writeFile('utils/database/migrations.js', text, function (err) {
      if (err) return console.log(err);
    });
}