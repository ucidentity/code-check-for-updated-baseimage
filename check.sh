#!/usr/bin/env bash


IFS=: read base_i base_t <<<$base
IFS=: read image_i image_t <<<$image

echo "::debug:: base_i: ${base_i} base_t: ${base_t}"
echo "::debug:: image_i: ${image_i} image_t: ${image_t}"

token=$(curl 'https://auth.docker.io/token?service=registry.docker.io&scope=repository:'${base_i}':pull' 2>/dev/null | jq -r '.token')

echo "::debug::getting docker base layers"
docker_manifest=$(curl -H "Authorization: Bearer ${token}" -H "Accept: application/vnd.docker.distribution.manifest.v2+json" "https://index.docker.io/v2/${base_i}/manifests/${base_t}" 2>/dev/null)
base_layers=$(jq -r '[.layers[].digest]' <<<"$docker_manifest")
echo "::debug::docker base layers: ${base_layers}"


ghcr_manifest=$(curl -H "Authorization: Bearer $(echo $gh_token | base64)" -H "Accept: application/vnd.docker.distribution.manifest.list.v2+json" https://ghcr.io/v2/${image_i}/manifests/${image_t} 2>/dev/null)
echo "::debug::ghcr manifest: ${ghcr_manifest}"
images_layers=$(jq -r '[.layers[].digest]' <<<"$ghcr_manifest")
echo "::debug::ghcr layers: ${images_layers}"

# # ([1, 2, 3] - ([1,2,3] - [1,2])) != [1, 2]
result=$(jq -cn "($images_layers - ($images_layers - $base_layers)) != $base_layers")
echo "::set-output name=result::${result}"


