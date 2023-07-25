#!/bin/bash

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
import sequelize from \"../../config/database\";

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

#service
cd services
touch $1-service.ts
serviceClass=$capitalize"Service"
echo "import { ModelStatic } from \"sequelize\";
import Service from \"./service\";

        
class $serviceClass extends Service {
        
    constructor(model: ModelStatic<any>) {
        super(model)
    }
}

export default $serviceClass" >$1"-service.ts"

cd ..

#controller
cd controllers
touch $1-controller.ts
controllerClass=$capitalize"Controller"
echo "import Service from \"../services/service\";
import ${capitalize}Service from \"../services/${1}-service\";
import Controller from \"./controller\";
import $capitalize from \"../models/$1\";

        
class $controllerClass extends Controller {
        
    constructor(service: Service) {
        super(service);
    }
}

export default new $controllerClass(new ${capitalize}Service($capitalize));" >$1"-controller.ts"

cd ..

#route
cd routes
mkdir -p -- $1
cd $1
touch $1".ts"
touch middlewares.ts

echo "import Express from \"express\"
import ${capitalize}Controller from \"../../controllers/$1-controller\"

const router = Express.Router()

router.post('/create', Express.json(), $controllerClass.insert)
router.get('/', $controllerClass.getAll)
router.put('/update',Express.json(),$controllerClass.update)
router.delete('/delete',Express.json(), $controllerClass.delete)

export default router" >$1".ts"

cd ..

#add router
routerFile="router.ts"
importModel="import ${importName}Router from \"./$1/$1\""
importRouter="app.use(\"/$1\", ${importName}Router)"
import_model_line=1
import_router_line=$(grep -n "app.use(express." "$routerFile" | cut -d ":" -f 1)
import_router_line=$import_router_line+2

if [ -n "$import_router_line" ]; then
    printf "%s\n" "${import_model_line}i" "$importModel" . w | ed -s "$routerFile"
    printf "%s\n" "${import_router_line}i" "$(printf '\t')$importRouter" . w | ed -s "$routerFile"
fi

cd ../..

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
