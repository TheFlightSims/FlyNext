#!/bin/bash

echo "["
THEMES=`ls 3rdparty/jquery-ui-themes-1.11.2/themes/`
set -- $THEMES
while [ $# -gt 0 ]; do
echo "{"
echo "\"theme_name\": \"$1\","
echo "\"theme_url\": \"3rdparty/jquiery-ui-themes-1.11.2/themes/$1/jquery-ui.css\","
echo "\"group\": \"Official\","
echo "\"active\": \"yes\","
echo "\"author\": \"jQuery Project\","
echo "\"license\": \"http://jquery.org/license\""
echo "},"
  shift
done
echo "]"

