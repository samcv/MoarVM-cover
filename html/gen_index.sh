#!/usr/bin/env sh
VAR="$(cat nqp.txt)"
cat index_template.html | sed -e "s|<!--replace_me-->|$VAR|" > index_nqp.html
VAR="$(cat roast.txt)"
cat index_template.html | sed -e "s|<!--replace_me-->|$VAR|" > index_roast.html
