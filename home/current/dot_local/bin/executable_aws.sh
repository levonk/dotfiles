#!/usr/bin/env bash
# EC2 instance metadata quick info
# - Uses IMDSv2 with short TTL token
# - Fast timeouts to avoid hanging outside EC2
# - Output formats: raw (legacy), labeled (default), json
#
# Usage:
#   aws.sh               # labeled human-readable output
#   aws.sh --json        # JSON output
#   aws.sh --raw         # raw values only (preserves legacy order/behavior)
#   aws.sh --allow-imds-v1  # attempt IMDSv1 if v2 token not available

set -euo pipefail

IMDS_HOST="169.254.169.254"
BASE_URL="http://${IMDS_HOST}/latest"
TOKEN_TTL=300
ALLOW_IMDS_V1=false
FORMAT="labeled"

for arg in "${@:-}"; do
  case "${arg}" in
    --json) FORMAT="json" ;;
    --raw) FORMAT="raw" ;;
    --allow-imds-v1) ALLOW_IMDS_V1=true ;;
    -h|--help)
      sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Unknown option: ${arg}" >&2; exit 2 ;;
  esac
done

curl_quick() {
  curl -fsSL --connect-timeout 1 --max-time 2 "$@"
}

get_token() {
  curl_quick -X PUT "${BASE_URL}/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: ${TOKEN_TTL}" || true
}

imds_get() {
  local path="$1"; shift || true
  if [[ -n "${IMDS_TOKEN:-}" ]]; then
    curl_quick -H "X-aws-ec2-metadata-token: ${IMDS_TOKEN}" \
      "${BASE_URL}/meta-data/${path}"
  elif [[ "${ALLOW_IMDS_V1}" == true ]]; then
    curl_quick "${BASE_URL}/meta-data/${path}"
  else
    return 1
  fi
}

# Acquire IMDSv2 token (preferred)
IMDS_TOKEN="$(get_token)"
if [[ -z "${IMDS_TOKEN}" && "${ALLOW_IMDS_V1}" != true ]]; then
  echo "IMDSv2 token not available. Are you on EC2? Use --allow-imds-v1 to try v1." >&2
  exit 1
fi

# Collect fields (keep legacy order)
ACCOUNT_ID=""
# identity-credentials info is JSON; prefer jq but fall back to awk
INFO_JSON="$(imds_get 'identity-credentials/ec2/info' || true)"
if [[ -n "${INFO_JSON}" ]]; then
  if command -v jq >/dev/null 2>&1; then
    ACCOUNT_ID="$(printf '%s' "${INFO_JSON}" | jq -r '.AccountId // empty')"
  else
    ACCOUNT_ID="$(printf '%s' "${INFO_JSON}" | grep -m1 'AccountId' | awk -F'"' '{print $4}')"
  fi
fi

AMI_ID="$(imds_get 'ami-id' || true)"
AVAILABILITY_ZONE="$(imds_get 'placement/availability-zone' || true)"
AVAILABILITY_ZONE_ID="$(imds_get 'placement/availability-zone-id' || true)"
HOSTNAME="$(imds_get 'hostname' || true)"
INSTANCE_ID="$(imds_get 'instance-id' || true)"
INSTANCE_TYPE="$(imds_get 'instance-type' || true)"
LOCAL_IPV4="$(imds_get 'local-ipv4' || true)"
MAC_ADDRESS="$(imds_get 'mac' || true)"
SECURITY_GROUPS="$(imds_get 'security-groups' || true)"

emit_raw() {
  printf '%s\n' \
    "${ACCOUNT_ID}" \
    "${AMI_ID}" \
    "${AVAILABILITY_ZONE}" \
    "${AVAILABILITY_ZONE_ID}" \
    "${HOSTNAME}" \
    "${INSTANCE_ID}" \
    "${INSTANCE_TYPE}" \
    "${LOCAL_IPV4}" \
    "${MAC_ADDRESS}" \
    "${SECURITY_GROUPS}"
}

emit_labeled() {
  printf 'AccountId: %s\n'        "${ACCOUNT_ID}"
  printf 'AmiId: %s\n'            "${AMI_ID}"
  printf 'AZ: %s\n'               "${AVAILABILITY_ZONE}"
  printf 'AZId: %s\n'             "${AVAILABILITY_ZONE_ID}"
  printf 'Hostname: %s\n'         "${HOSTNAME}"
  printf 'InstanceId: %s\n'       "${INSTANCE_ID}"
  printf 'InstanceType: %s\n'     "${INSTANCE_TYPE}"
  printf 'LocalIPv4: %s\n'        "${LOCAL_IPV4}"
  printf 'MacAddress: %s\n'       "${MAC_ADDRESS}"
  printf 'SecurityGroups: %s\n'   "${SECURITY_GROUPS}"
}

emit_json() {
  # Build JSON without jq (simple escaping for common cases)
  printf '{'
  printf '"AccountId":"%s",'      "${ACCOUNT_ID//\"/\\\"}"
  printf '"AmiId":"%s",'          "${AMI_ID//\"/\\\"}"
  printf '"AZ":"%s",'             "${AVAILABILITY_ZONE//\"/\\\"}"
  printf '"AZId":"%s",'           "${AVAILABILITY_ZONE_ID//\"/\\\"}"
  printf '"Hostname":"%s",'       "${HOSTNAME//\"/\\\"}"
  printf '"InstanceId":"%s",'     "${INSTANCE_ID//\"/\\\"}"
  printf '"InstanceType":"%s",'   "${INSTANCE_TYPE//\"/\\\"}"
  printf '"LocalIPv4":"%s",'      "${LOCAL_IPV4//\"/\\\"}"
  printf '"MacAddress":"%s",'     "${MAC_ADDRESS//\"/\\\"}"
  printf '"SecurityGroups":"%s"'  "${SECURITY_GROUPS//\"/\\\"}"
  printf '}\n'
}

case "${FORMAT}" in
  raw) emit_raw ;;
  json) emit_json ;;
  *) emit_labeled ;;
esac
