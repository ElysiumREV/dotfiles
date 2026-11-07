if status is-interactive
    # Starship
    starship init fish | source

    # Eza aliases
    alias ls='eza --icons=auto'
    alias ll='eza -l --icons=auto'
    alias la='eza -la --icons=auto'
    alias lt='eza --tree --icons=auto'
end

test -f /usr/share/aur-scan/integration.fish; and source /usr/share/aur-scan/integration.fish

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/ely/.lmstudio/bin
# End of LM Studio CLI section
