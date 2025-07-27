base_dir="$HOME/.minecraft"
assets_dir="$base_dir/assets"
indexes_dir="$assets_dir/indexes"
objects_dir="$assets_dir/objects"
libraries_dir="$base_dir/libraries"

mkdir -p "$indexes_dir"

manifest_url="https://launchermeta.mojang.com/mc/game/version_manifest.json"
manifest=$(curl -s "$manifest_url")
latest_release_id=$(echo "$manifest" | grep -oP '"release"\s*:\s*"\K[^"]+')
latest_release_url=$(echo "$manifest" | sed -n "/\"id\"\s*:\s*\"$latest_release_id\"/,/url/ s/.*\"url\"\s*:\s*\"\(http[^\"]*\)\".*/\1/p" | head -n1)

latest_data=$(curl -s "$latest_release_url")
asset_index_url=$(echo "$latest_data" | grep -oP '"assetIndex"\s*:\s*{[^}]*"url"\s*:\s*"\K[^"]+')
assets_id=$(echo "$latest_data" | grep -oP '"assets"\s*:\s*"\K[^"]+')

client_url=$(echo "$latest_data" | grep -oP '"client"\s*:\s*{[^}]*"url"\s*:\s*"\K[^"]+')
client_jar="$base_dir/client.jar"
if [ ! -f "$client_jar" ]; then
    curl -s -o "$client_jar" "$client_url"
fi

index_file="$indexes_dir/$assets_id.json"
if [ ! -f "$index_file" ]; then
    curl -s -o "$index_file" "$asset_index_url"
fi

echo "$latest_data" | tr -d '\n' | sed 's/},[ \t]*{/}§{/g' | grep -oP '{"downloads".*?}' | while read -r lib; do
    artifact_url=$(echo "$lib" | grep -oP '"artifact"\s*:\s*{[^}]*"url"\s*:\s*"\K[^"]+')
    artifact_path=$(echo "$lib" | grep -oP '"path"\s*:\s*"\K[^"]+' | tr '[:upper:]' '[:lower:]')
    skip=$(echo "$lib" | grep -iE 'linux|macos|arm64')
    if [ -n "$artifact_url" ] && [ -z "$skip" ]; then
        dest_file="$libraries_dir/$artifact_path"
        dest_dir=$(dirname "$dest_file")
        mkdir -p "$dest_dir"
        if [ ! -f "$dest_file" ]; then
            curl -s -o "$dest_file" "$artifact_url"
            echo "Downloaded $artifact_path"
        fi
    fi
done

curl -s "$asset_index_url" | grep -oP '"[a-zA-Z0-9/_\.-]+\.json" *: *{"hash" *: *"[a-f0-9]{40}"' | while read -r line; do
    path=$(echo "$line" | cut -d':' -f1 | tr -d '" ')
    hash=$(echo "$line" | grep -oP '[a-f0-9]{40}')
    case "$path" in
        minecraft/sounds*) continue ;;
        minecraft/lang/*.json)
            case "$path" in
                *en_us.json) ;;
                *) continue ;;
            esac ;;
    esac
    subdir=${hash:0:2}
    dest="$objects_dir/$subdir/$hash"
    if [ ! -f "$dest" ]; then
        mkdir -p "$(dirname "$dest")"
        curl -s -o "$dest" "https://resources.download.minecraft.net/$subdir/$hash"
        echo "Downloaded $path"
    fi
done
