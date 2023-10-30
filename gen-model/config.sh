#!/bin/bash

cd config
#config
configFile='migrations.ts'
import_model_line=1
importModel="import $capitalize from \"../app/models/$1\""
importConfig="await $capitalize.sync({ alter: true });"
import_migration_line=$(grep -n "})();" "$configFile" | cut -d ":" -f 1)+1

if [ -n "$import_migration_line" ]; then
    printf "%s\n" "${import_model_line}i" "$importModel" . w | ed -s "$configFile"
    printf "%s\n" "${import_migration_line}i" "$(printf '\t')$importConfig" . w | ed -s "$configFile"
fi

cd ..