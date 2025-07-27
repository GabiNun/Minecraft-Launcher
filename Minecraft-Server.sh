manifest_url="https://launchermeta.mojang.com/mc/game/version_manifest.json"
manifest=$(curl -s "$manifest_url")
latest_release_id=$(echo "$manifest" | jq -r '.latest.release')
latest_release_url=$(echo "$manifest" | jq -r --arg id "$latest_release_id" '.versions[] | select(.id == $id) | .url')

base_dir="$HOME/Minecraft Launcher"
mkdir -p "$base_dir"
echo "eula=true" > "$base_dir/eula.txt"

server_jar="$base_dir/server.jar"
if [ ! -f "$server_jar" ]; then
    server_url=$(curl -s "$latest_release_url" | jq -r '.downloads.server.url')
    curl -s -o "$server_jar" "$server_url"
fi

cd "$base_dir"
java -jar server.jar nogui
