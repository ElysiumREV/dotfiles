# warp-svc is off at boot; start it on demand before talking to it.
function warp-cli --wraps warp-cli --description 'warp-cli that starts warp-svc when needed'
    if not systemctl is-active --quiet warp-svc.service
        systemctl start warp-svc.service; or return 1
        # give the daemon a moment to open its socket
        for i in (seq 20)
            test -S /run/cloudflare-warp/warp_service; and break
            sleep 0.25
        end
    end
    command warp-cli $argv
end
