#!/bin/bash

function buildprompt {
    PS1="${lightblue}\u${reset}@${green}\h:${yellow}\w \$(addgit)${reset}$ "
}

function addgit {
	status=$(git status --porcelain 2>/dev/null)
    if [[ $status = "" ]]; then
        echo -n ""
    else
		echo ${reset}  $(git-branch-name) $(git-dirty) $(git-unpushed) $(git-modified)
	fi
}

function git-unpushed {
    brinfo=$(git branch -v | grep git-branch-name)
    if [[ $brinfo =~ ("[ahead "([[:digit:]]*)]) ]]
    then
        echo "李(${BASH_REMATCH[2]})"
    fi
}

function git-dirty {
    st=$(git status 2>/dev/null | tail -n 1)
    if [[ $st != "nothing to commit (working directory clean)" ]]; then
    	echo "${red}${reset}"
    else
      	echo "${green}${reset}"
    fi
}

function git-branch-name {	
    echo $(git symbolic-ref HEAD 2>/dev/null | awk -F/ {'print $NF'})
}

function  git-modified {
	modified=$(git diff --stat 2>/dev/null | tail -n 1)
	my_array=($(echo $modified | tr "," "\n"))
	for i in "${my_array[@]}"
	do
	    if [ ! -z "${i##*[!0-9]*}" ]; then
	    	echo -n $i
	    else
	    	render-icon $i
	    fi
	done
}

function render-icon {
	clean=$(echo -n $1 | tr -cd [:alpha:])
	case $clean in
		changed)
			echo -n "${yellow} ${reset}"
			;;
		insertions)
			echo -n "${green} ${reset}"
			;;	 
		deletions)
			echo -n "${red} ${reset}"
			;;
		esac
}

buildprompt