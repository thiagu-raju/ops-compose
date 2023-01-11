#!/usr/bin/env bash

set -e

ACME="/certs/data/acme.json"
DOMAINS_DIR="/certs/domains"

if [ ! -f "$ACME" ]; then
  echo "🚨 Oops! acme.json file not found"
  exit 1
fi

echo "🚀 Extracting certificates from acme.json..."

DOMAINS=$(jq -r ".certs.Certificates[].domain.main" $ACME | sort | uniq)

for DOMAIN in $DOMAINS; do
  echo "📦 Getting $DOMAIN certificate..."

  mkdir -p $DOMAINS_DIR/"$DOMAIN"

  OUTPUT=$DOMAINS_DIR/$DOMAIN

  echo "📄 Extracting certificate..."
  jq -r ".certs.Certificates[] | select(.domain.main==\"""$DOMAIN""\") | .certificate" $ACME | base64 --decode >"$OUTPUT/cert.pem"

  echo "🔑 Extracting private key..."
  jq -r ".certs.Certificates[] | select(.domain.main==\"""$DOMAIN""\") | .key" $ACME | base64 --decode >"$OUTPUT/key.pem"

  echo "✅ $DOMAIN certificate extracted"
done

echo '🎉 All certificates extracted'
