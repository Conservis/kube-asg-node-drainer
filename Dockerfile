FROM gcr.io/google-containers/hyperkube-amd64:v1.15.3 AS hyperkube

FROM quay.io/coreos/awscli:edge

COPY --from=hyperkube /hyperkube /opt/bin/hyperkube

COPY bin/ /usr/local/bin/
