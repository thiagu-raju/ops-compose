#!/usr/bin/env bash

set -e

ACME="/data/acme.json"

if [ ! -f "$ACME" ]; then
  echo "🚨 Oops! acme.json file not found"
  exit 1
fi

echo "🚀 Extracting certificates from acme.json..."

EXTRACT=$1

DOMAINS=$(jq -r ".certs.Certificates[].domain.main" $ACME | sort | uniq)

for DOMAIN in $DOMAINS; do
  if [ "$EXTRACT" != "" ] && [ "$EXTRACT" != "$DOMAIN" ]; then
    continue
  fi

  echo "📦 Getting $DOMAIN certificate..."

  echo "📄 Extracting certificate..."
  jq -r ".certs.Certificates[] | select(.domain.main==\"""$DOMAIN""\") | .certificate" $ACME | base64 --decode > /vault/tls.crt

  echo "🔑 Extracting private key..."
  jq -r ".certs.Certificates[] | select(.domain.main==\"""$DOMAIN""\") | .key" $ACME | base64 --decode > /vault/tls.key

  echo "✅ $DOMAIN certificate extracted"
done

echo '🎉 All certificates extracted'
