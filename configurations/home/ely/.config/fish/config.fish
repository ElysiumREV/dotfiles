if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
end

source /usr/share/aur-scan/integration.fish

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/ely/.lmstudio/bin
# End of LM Studio CLI section
