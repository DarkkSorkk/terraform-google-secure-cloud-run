# Base image pinned by digest: the same build today and next month, with no tag moving underneath.
# python:3.14-slim-trixie, read from Docker Hub on 2026-11-09. To update, replace the digest and let CI
# (build and scan) check it: docker buildx imagetools inspect python:3.14-slim-trixie
FROM python:3.14-slim-trixie@sha256:9aaa474097d094040649f2162a627c0049b408f52138d980916788d80f04802f

# Security fixes newer than the base image, no pip (the service installs nothing at runtime) and a user
# without privileges.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && PIP_ROOT_USER_ACTION=ignore python -m pip uninstall --yes pip \
    && useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

WORKDIR /app
COPY main.py .

USER 10001
EXPOSE 8080
CMD ["python", "main.py"]
