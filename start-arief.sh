#!/usr/bin/env bash
clear
cp -f ~/.telegram-cli/auth-arief ~/.telegram-cli/auth
cp -f ~/.telegram-cli/state-arief ~/.telegram-cli/state
# telegram-cli -k ~/tg-server.pub --lua-script ./bot/bot.lua --logname tg-arief.log --disable-colors --bot --disable-output --verbosity 99 --log-level 99
telegram-cli -k ~/tg-server.pub --lua-script ./bot/bot.lua --logname tg-arief.log --disable-colors --bot --disable-output
cp -f ~/.telegram-cli/auth ~/.telegram-cli/auth-arief
cp -f ~/.telegram-cli/state ~/.telegram-cli/state-arief

# untuk pemakaian dengan config        telegram-cli -c '/home/iza/Software/internet/Telegram/tg-cli-accounts/tg-cli.config' -p kuncen