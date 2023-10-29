#!/bin/bash

#create the folders
echo "project initialization $1"
mkdir -p -- "$1"
cd $1

echo "create dist folder"
mkdir -p -- "dist"
cd dist
mkdir -p -- "assets"
cd ..


echo "create src folder"
mkdir -p -- "src"
cd src

#create app folder and his children
echo "create app folder and his children folders"
mkdir -p -- "app"
cd app

mkdir -p -- "controllers"
mkdir -p -- "models"
mkdir -p -- "routes"
mkdir -p -- "services"

cd ..

mkdir -p -- "config"

mkdir -p -- "helpers"
cd helpers
mkdir -p -- "templates"
 
cd ..
mkdir -p -- "tests"