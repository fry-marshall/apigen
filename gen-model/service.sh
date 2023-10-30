#!/bin/bash

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