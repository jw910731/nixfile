# shellcheck shell=bash

buildAccelPre() {
    export BUILDACCEL_SYSTEM="${system:-}"
    export BUILDACCEL_LOCAL_CORES="${NIX_BUILD_CORES:-1}"
    buildAccelJobs=$BUILDACCEL_LOCAL_CORES
    buildAccelMode=local
    buildAccelSavedCores=$BUILDACCEL_LOCAL_CORES
    mkdir -p "${TMPDIR:-/tmp}/.buildaccel" >/dev/null 2>&1 || true

    local slots
    if [[ -e ${BUILDACCEL_ROOT:-/run/buildaccel/v1}/enabled ]] \
        && slots=$('@launcher@/bin/buildaccel-launcher' --probe 2>/dev/null) \
        && [[ $slots =~ ^[1-9][0-9]{0,3}$ ]] \
        && ((slots <= 1024)); then
        NIX_BUILD_CORES=$((buildAccelSavedCores + slots))
        buildAccelJobs=$NIX_BUILD_CORES
        buildAccelMode=remote
    fi
    if [[ -z ${enableParallelBuilding:-} ]]; then
        buildAccelJobs=1
    fi
    return 0
}

buildAccelPost() {
    if [[ ${buildAccelMode:-local} == remote ]]; then
        NIX_BUILD_CORES=$buildAccelSavedCores
    fi
    return 0
}

buildAccelSummary() {
    local summary
    summary=$('@launcher@/bin/buildaccel-launcher' --summary 2>/dev/null) || true
    printf 'buildaccel: mode=%s jobs=%s %s\n' \
        "${buildAccelMode:-local}" "${buildAccelJobs:-${NIX_BUILD_CORES:-1}}" "$summary" || true
    return 0
}

preBuildHooks+=(buildAccelPre)
postBuildHooks+=(buildAccelPost)
exitHooks+=(buildAccelSummary)
