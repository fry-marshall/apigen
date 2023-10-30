#!/bin/bash

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