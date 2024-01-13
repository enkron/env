#!/bin/bash

set -ueo pipefail

unset -v COLOUR_SCHEME_TAG

: "${1:?COLOUR_SCHEME_TAG is not supplied}"

COLOUR_SCHEME_TAG=$1

usage() {
    echo -e "usage: $0 COLOUR_SCHEME_TAG\n\nCOLOUR_SCHEME_TAG = [ecs, ecs_light]" && exit 0
}

if [ "${COLOUR_SCHEME_TAG}" != 'ecs' ] && [ "${COLOUR_SCHEME_TAG}" != 'ecs_light' ]; then
    usage
fi

if [ "${COLOUR_SCHEME_TAG}" = 'ecs' ]; then
    sed -i "s#ecs_light#ecs#g" -- ./alacritty.toml
    sed -i "s#colorscheme ecs_light#colorscheme ecs#g" -- ./vimrc
else
    sed -i "s#ecs#ecs_light#g" -- ./alacritty.toml
    sed -i "s#colorscheme ecs#colorscheme ecs_light#g" -- ./vimrc
fi
