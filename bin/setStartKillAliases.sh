#!/bin/bash
alias killer="ps | grep -v grep | grep 'ruby app_red_green.rb' | awk '{print $1}' | xargs kill -9"
alias starter='nohup ruby app_red_green.rb 2>&1 > app_red_green.log&'
