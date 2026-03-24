#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
server_dir="$(cd "${script_dir}/.." && pwd)"

cd "${server_dir}"

mode="${1:-all}"

user_unit_pattern='TestNextInactivityEmailStage|TestHasAnyStageSuccess|TestBuildInactiveUserRunSummary|TestIsInInactiveUserRollout|TestProcessCandidateBatchRecoversPanics'
user_full_pattern="${user_unit_pattern}|TestProcessInactiveUsersWarn2mIntegration"
email_unit_pattern='TestBucketStorageWarning|TestComputeStorageWarningMetrics|TestResolveExpiredWarningStage|TestResolveActiveOverageWarningStage|TestStorageWarning|TestBuildStorageWarningRunSummary'
email_full_pattern="${email_unit_pattern}|TestSendStorageWarningMailsActiveOverageIntegration|TestSendStorageWarningMailsExpiredIntegration"
template_pattern='TestInactiveUserDeletionTemplatesIncludeAccountEmail|TestStorageWarningTemplatesIncludeAccountEmail'

run_cmd() {
    printf '\n==> %s\n' "$*"
    "$@"
}

run_and_assert_no_skips() {
    local skip_fragments=()
    while [[ "$1" != "--" ]]; do
        skip_fragments+=("$1")
        shift
    done
    shift

    local output
    printf '\n==> %s\n' "$*"
    if ! output="$("$@" 2>&1)"; then
        printf '%s\n' "${output}"
        return 1
    fi
    printf '%s\n' "${output}"
    for skip_fragment in "${skip_fragments[@]}"; do
        if grep -Fq -- "${skip_fragment}" <<<"${output}"; then
            printf 'unexpected skipped test detected: %s\n' "${skip_fragment}" >&2
            return 1
        fi
    done
}

run_unit_suites() {
    run_cmd go test -count=1 -v ./pkg/controller/user -run "${user_unit_pattern}"
    run_cmd go test -count=1 -v ./pkg/controller/email -run "${email_unit_pattern}"
    run_cmd go test -count=1 -v ./pkg/utils/email -run "${template_pattern}"
}

run_integration_suites() {
    export ENV=test
    "${script_dir}/setup-test-db.sh"

    run_and_assert_no_skips '--- SKIP: TestProcessInactiveUsersWarn2mIntegration' -- \
        go test -count=1 -v ./pkg/controller/user -run "${user_full_pattern}"
    run_and_assert_no_skips \
        '--- SKIP: TestSendStorageWarningMailsActiveOverageIntegration' \
        '--- SKIP: TestSendStorageWarningMailsExpiredIntegration' \
        -- \
        go test -count=1 -v ./pkg/controller/email -run "${email_full_pattern}"
    run_and_assert_no_skips '--- SKIP: TestGetStorageWarningCandidates' -- \
        go test -count=1 -v ./pkg/repo -run 'TestGetStorageWarningCandidates'
    run_cmd go test -count=1 -v ./pkg/utils/email -run "${template_pattern}"
}

case "${mode}" in
    unit)
        run_unit_suites
        ;;
    integration)
        run_integration_suites
        ;;
    all)
        run_unit_suites
        run_integration_suites
        ;;
    *)
        printf 'usage: %s [unit|integration|all]\n' "$0" >&2
        exit 1
        ;;
esac
