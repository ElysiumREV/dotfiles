if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
end

alias ls 'eza -lh --group-directories-first --icons=auto'
alias lsa 'eza -lha --group-directories-first --icons=auto'
alias lt 'eza --tree --level=2 --long --icons --git'
alias lta 'eza --tree --level=2 --long --icons --git --all'
alias ll 'eza -lah --group-directories-first --icons=auto'
