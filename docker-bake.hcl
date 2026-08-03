# 💭 DreamContainer — multi-arch image builds
# Local:  docker buildx bake
# CI:     docker buildx bake --push  (see .github/workflows/build-images.yml)

variable "REGISTRY" { default = "ghcr.io/ahelme/dream-container" }
variable "TAG"      { default = "latest" }

group "default" {
  targets = ["base", "browser"]
}

target "base" {
  context    = "images/base"
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64", "linux/arm64"]
  tags = [
    "${REGISTRY}:${TAG}",
    "${REGISTRY}:base",
  ]
}

target "browser" {
  context    = "images/browser"
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64", "linux/arm64"]
  args = {
    BASE_IMAGE = "${REGISTRY}:base"
  }
  tags = [
    "${REGISTRY}:browser",
  ]
  # browser depends on base being available in the registry
  contexts = {
    "${REGISTRY}:base" = "target:base"
  }
}
