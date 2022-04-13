#!/usr/bin/env bash


IFS=: read base_i base_t <<<$base
IFS=: read image_i image_t <<<$image

# echo "getting docker token"
token=$(curl 'https://auth.docker.io/token?service=registry.docker.io&scope=repository:'${base_i}':pull' 2>/dev/null | jq -r '.token')
# echo $token

# echo "getting docker base layers"
# echo "curl -H 'Authorization: Bearer ${token}' -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' 'https://index.docker.io/v2/${base_i}/manifests/${base_t}'"
docker_manifest=$(curl -H "Authorization: Bearer ${token}" -H "Accept: application/vnd.docker.distribution.manifest.v2+json" "https://index.docker.io/v2/${base_i}/manifests/${base_t}" 2>/dev/null)
# echo "docker_manifest:"
# echo $docker_manifest
base_layers=$(jq -r '[.layers[].digest]' <<<"$docker_manifest")
# echo "docker base layers:"
# echo $base_layers


# echo "getting ghcr.io layers"
ghcr_manifest=$(curl -H "Authorization: Bearer $(echo $ACCESS_TOKEN | base64)" -H "Accept: application/vnd.docker.distribution.manifest.list.v2+json" https://ghcr.io/v2/${image_i}/manifests/${image_t} 2>/dev/null)
#echo "ghcr manifest:"
#echo $ghcr_manifest
images_layers=$(jq -r '[.layers[].digest]' <<<"$ghcr_manifest")
#echo "ghcr layers:"
#echo $images_layers



result=$(jq -cn "$images_layers - ($images_layers - $base_layers) | .!=[]")
echo "::set-output name=result::${result}"


