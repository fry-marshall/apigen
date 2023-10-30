#!/bin/bash

#model
cd src/app/models
touch $1".ts"

capitalize="$(tr '[:lower:]' '[:upper:]' <<<${1:0:1})${1:1}"
caractere="-"
importName=$1

if [[ $capitalize == *"$caractere"* ]]; then
    capitalize=$(echo "$capitalize" | awk 'BEGIN{FS="-"; OFS=""} {for (i=2; i<=NF; i++) {$i = toupper(substr($i,1,1)) substr($i,2)}}1')
    premiere_lettre=$(echo "${capitalize:0:1}" | tr '[:upper:]' '[:lower:]')
    reste_chaine="${capitalize:1}"
    importName="${premiere_lettre}${reste_chaine}"
fi

echo "import { DataTypes, Model } from \"sequelize\";
import sequelize from \"../../config/sequelize\";

interface ${capitalize}Attributes{
    id?: string;
}

interface ${capitalize}Instance extends Model<${capitalize}Attributes>, ${capitalize}Attributes{}

const $capitalize = sequelize.define<${capitalize}Instance>('$1', {
    id: {
        type: DataTypes.STRING,
        primaryKey: true
    }
})

export default $capitalize;" >$1".ts"

cd ..