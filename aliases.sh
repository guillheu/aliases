
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
function clnp {
  clear
  eval "$(history -p !!)"
}
alias loop='function _loop() { sleep_duration=$1; shift; while true; do "$@"; sleep $sleep_duration; done }; _loop'
alias list-aliases='alias | awk -F"=" '\''$1 ~ /^alias / {print $1}'\'''
alias dc-reset='function _docker-compose-reset-function() { if [[ $* == *"-v"* ]]; then docker-compose down -v && docker-compose up -d; else docker-compose down && docker-compose up -d; fi }; _docker-compose-reset-function()'
alias docker-build-run='function _docker_build_run() { image_name=$1; shift; docker build -t $image_name . && docker run --rm "$@" $image_name; }; _docker_build_run'
alias get-eth-info='_get_eth_info'
alias start-http='python -m http.server $1'
alias let-it-rip='cdda2wav -cddbp-server=gnudb.gnudb.org -cddbp-port=8080 -vall cddb=-1 speed=4 -paranoia paraopts=proof -B -D /dev/sr0'
alias extract-gif-frames='for f in *.gif; do mkdir "${f%.*}" && ffmpeg -i "$f" -fps_mode:v vfr "${f%.*}/%03d.png" && convert "${f%.*}"/*.png +append "${f%.*}_combined.png" && rm -r "${f%.*}"; done'
alias git-config='git config user.name guillheu && git config user.email guillheu@gmail.com'
function _get_eth_info() {
while true; do
    block=$(curl --silent -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' $1 | jq '.result.number'  | tr -d '"' | echo "$((16#$(cut -c 3-)))")
    peer=$(curl --silent -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":2}' $1 | jq '.result'  | tr -d '"' | echo "Peer count : $((16#$(cut -c 3-)))")
    block_formatted=$(printf "Block number: %'d" $block)
    echo -ne "$block_formatted | $peer \r"
    sleep 1
done
};
alias rename-tracks='
readarray -t new_names < songlist
for i in "${!new_names[@]}"
do
    old_audio_name="audio_$(printf '%02d' $((i+1))).wav"
    new_audio_name="${i}-${new_names[$i]}"
    new_audio_name=${new_audio_name// /_}
    new_audio_name=${new_audio_name//\//-} 
    mv "$old_audio_name" "$new_audio_name".wav
    old_inf_name="audio_$(printf '%02d' $((i+1))).inf"
    new_inf_name="${i}-${new_names[$i]}"
    new_inf_name=${new_inf_name// /_}
    new_inf_name=${new_inf_name//\//-}
    mv "$old_inf_name" "$new_inf_name".inf
done'
