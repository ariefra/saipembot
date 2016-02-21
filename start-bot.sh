#!/usr/bin/env bash
cp -f ~/.telegram-cli/auth-saipembot ~/.telegram-cli/auth
cp -f ~/.telegram-cli/state-saipembot ~/.telegram-cli/state
telegram-cli -k ~/tg-server.pub -s ./bot/bot.lua -l 1 -E -u @saipembot -b -C