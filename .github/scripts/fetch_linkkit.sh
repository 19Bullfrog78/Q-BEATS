#!/usr/bin/env bash
# Scarica l'SDK di Ableton Link (LinkKit) dalla release ufficiale e lo mette
# in Vendors/AbletonLink/, dove lo cerca ios_app/project.yml.
#
# Perche': la licenza dell'SDK vieta di ridistribuirlo e Ableton (richiesta
# #3167257, 14/10/2026) chiede che la CI lo prenda dal repository LinkKit a
# ogni build. Vendors/AbletonLink/ e' in .gitignore: il deposito non lo porta.
#
# Versione e impronta stanno qui e solo qui. Se l'impronta non torna lo
# script esce con errore e la pipeline diventa rossa: nessun altro indirizzo,
# nessuna copia di riserva.
#
# Lo chiamano iOS Signed Build e F1 Build Check prima di «xcodegen generate».

set -euo pipefail

LINKKIT_VERSION="4.0"
LINKKIT_SHA256="4983eb3da13d107a42476cc53630774341172e53a0081c7e0335fc6553e1dd3c"
LINKKIT_URL="https://github.com/Ableton/LinkKit/releases/download/LinkKit-${LINKKIT_VERSION}/LinkKit.zip"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEST="${REPO_ROOT}/Vendors/AbletonLink"

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

echo "LinkKit ${LINKKIT_VERSION}: scarico ${LINKKIT_URL}"
curl --fail --location --silent --show-error --output "${WORK}/LinkKit.zip" "${LINKKIT_URL}"

ACTUAL_SHA256="$(shasum -a 256 "${WORK}/LinkKit.zip" | awk '{print $1}')"
echo "sha256 atteso:   ${LINKKIT_SHA256}"
echo "sha256 scaricato: ${ACTUAL_SHA256}"
if [ "${ACTUAL_SHA256}" != "${LINKKIT_SHA256}" ]; then
  echo "::error::LinkKit.zip non ha l'impronta attesa: build fermata"
  exit 1
fi

unzip -q "${WORK}/LinkKit.zip" -d "${WORK}/unzipped"
for part in LinkKit.xcframework LinkKitResources.bundle; do
  if [ ! -d "${WORK}/unzipped/LinkKit/${part}" ]; then
    echo "::error::La release non contiene LinkKit/${part}"
    exit 1
  fi
done

mkdir -p "${DEST}"
for part in LinkKit.xcframework LinkKitResources.bundle; do
  rm -rf "${DEST:?}/${part}"
  cp -R "${WORK}/unzipped/LinkKit/${part}" "${DEST}/${part}"
done

echo "LinkKit ${LINKKIT_VERSION} in ${DEST}:"
find "${DEST}" -type f | sed "s#^${REPO_ROOT}/##" | sort
shasum -a 256 "${DEST}"/LinkKit.xcframework/*/libLinkKit.a | sed "s#${REPO_ROOT}/##"
