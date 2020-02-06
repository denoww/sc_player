#!/bin/bash
# pegando PID dos processos do sc_player
pids=$(ps aux | grep "sc_player" | grep -v grep | cut -c10-15)

# loop para matar os processos
for pid in ${pids[@]}
do
  sudo kill -9 $pid
done
