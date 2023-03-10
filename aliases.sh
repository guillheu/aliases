
alias ll='ls -l'
alias lta='ls -lta'
alias get-argocd-secret='kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d; echo'
alias get-grafana-secret='kubectl get secret grafana -n grafana -o jsonpath="{.data.admin-password}" | base64 -d; echo'
alias make-sealed-secret='cat secret.yaml | kubeseal --controller-name sealed-secrets --controller-namespace sealed-secrets -o yaml > sealed-secret.yaml'
alias k='kubectl'
alias kns='kubens'
alias get-docker-ip='docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}"'
alias cl='clear'
alias cln='clear &&'
alias loop='function _loop() { sleep_duration=$1; shift; while true; do "$@"; sleep $sleep_duration; done }; _loop'
alias list-aliases='alias | awk -F"=" '\''$1 ~ /^alias / {print $1}'\'''
alias dc-reset='function _docker-compose-reset-function() { if [[ $* == *"-v"* ]]; then docker-compose down -v && docker-compose up -d; else docker-compose down && docker-compose up -d; fi }; _docker-compose-reset-function()'
alias docker-build-run='function _docker_build_run() { image_name=$1; shift; docker build -t $image_name . && docker run --rm "$@" $image_name; }; _docker_build_run'
alias get-eth-info='_get_eth_info'
alias start-http='python -m http.server $1'
function _get_eth_info() {
while true; do
    block=$(curl --silent -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' $1 | jq '.result.number'  | tr -d '"' | echo "$((16#$(cut -c 3-)))")
    peer=$(curl --silent -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":2}' $1 | jq '.result'  | tr -d '"' | echo "Peer count : $((16#$(cut -c 3-)))")
    block_formatted=$(printf "Block number: %'d" $block)
    echo -ne "$block_formatted | $peer \r"
    sleep 1
done
};
