#!/bin/bash
export SERVER_BASE_URL=${SERVER_BASE_URL:-"localhost:80/api"}
export BACKEND=${BACKEND:-core}
./node_modules/.bin/webpack
nginx
exec trypurescript 8081 "./staging/$BACKEND/.psc-package/*/*/*/src/**/*.purs"
