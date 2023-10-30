#!/bin/bash

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
import_router_line=$(grep -n "(app: Express) => {" "$routerFile" | cut -d ":" -f 1)
import_router_line=$import_router_line+2

if [ -n "$import_router_line" ]; then
    printf "%s\n" "${import_model_line}i" "$importModel" . w | ed -s "$routerFile"
    printf "%s\n" "${import_router_line}i" "$(printf '\t')$importRouter" . w | ed -s "$routerFile"
fi

cd ../..