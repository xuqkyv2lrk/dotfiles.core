#!/bin/bash

session=$1

tmux has-session -t $session 2>/dev/null

if [ $? != 0 ]; then
    tmux new-session -d -s $session -n scratchpad -c $HOME
		
	window=1
	tmux split-window -t $session:$window.1 -v -c $HOME
	tmux split-window -t $session:$window.2 -h -c $HOME

    #tmux set-window-option -t $session:$window synchronize-panes
	#tmux send-keys -t $session:$window "clear" Enter
	#tmux set-window-option -t $session:$window synchronize-panes off

	tmux select-pane -t $session:$window.1

	window=2
	tmux new-window -t $session -n workspace -c ~/work

	window=3
	tmux new-window -t $session -n ranger -c $HOME
	tmux send-keys -t $sessing:$window "ranger" Enter

	tmux select-window -t $session:1
fi

tmux attach-session -t $session

