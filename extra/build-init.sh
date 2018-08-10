#!/bin/bash

PATH=${HOME}

NAME=${1:-sample}
BRANCH=${2:-master}
NAMESPACE=${3:-devops}

get_version() {
    NAME=${1:-sample}
    BRANCH=${2:-master}

    VERSION=
    REVISION=

    NODE=$(kubectl get ing -n default -o wide | grep sample-node | head -1 | awk '{print $2}')

    if [ ! -z ${NODE} ]; then
        VERSION=$(curl -sL -X POST http://${NODE}/counter/${NAME} | xargs)
    fi

    if [ -z ${VERSION} ]; then
        VERSION=0
        REVISION=$(date +%Y%m%d-%H%M%S)
    else
        REVISION=$(git rev-parse --short=6 HEAD)
    fi

    if [ "${BRANCH}" == "master" ]; then
        printf "0.1.${VERSION}-${REVISION}" > ${PATH}/VERSION
    else
        printf "0.0.${VERSION}-${BRANCH}" > ${PATH}/VERSION
    fi

    echo "# VERSION: $(cat ${PATH}/VERSION)"
}

get_domain() {
    NAME=${1}
    SAVE=${2}
    NAMESPACE=${3}

    DOMAIN=$(kubectl get ing -n ${NAMESPACE} -o wide | grep ${NAME} | head -1 | awk '{print $2}' | cut -d',' -f1)

    printf "${DOMAIN}" > ${PATH}/${SAVE}

    if [ ! -z ${DOMAIN} ] && [ "${NAME}" == "jenkins" ]; then
        BASE_DOMAIN=${DOMAIN:$(expr index $DOMAIN \.)}
        printf "$BASE_DOMAIN" > ${PATH}/BASE_DOMAIN
        echo "# BASE_DOMAIN: $(cat ${PATH}/BASE_DOMAIN)"
    fi

    echo "# ${SAVE}: $(cat ${PATH}/${SAVE})"
}

get_language() {
    NAME=${1}
    LANG=${2}

    FIND=$(find . -name ${NAME} | head -1)

    if [ ! -z ${FIND} ]; then
        ROOT=$(dirname ${FIND})

        if [ ! -z ${ROOT} ]; then
            printf "$ROOT" > ${PATH}/SOURCE_ROOT
            printf "$LANG" > ${PATH}/SOURCE_LANG

            echo "# SOURCE_LANG: $(cat ${PATH}/SOURCE_LANG)"
            echo "# SOURCE_ROOT: $(cat ${PATH}/SOURCE_ROOT)"
        fi
    fi
}

get_version ${NAME} ${BRANCH}

get_domain jenkins JENKINS ${NAMESPACE}
get_domain chartmuseum CHARTMUSEUM ${NAMESPACE}
get_domain docker-registry REGISTRY ${NAMESPACE}
get_domain sonarqube SONARQUBE ${NAMESPACE}
get_domain sonatype-nexus NEXUS ${NAMESPACE}

cat ${PATH}/SOURCE_LANG > /dev/null 2>&1 || get_language pom.xml java
cat ${PATH}/SOURCE_LANG > /dev/null 2>&1 || get_language package.json nodejs
cat ${PATH}/SOURCE_LANG > /dev/null 2>&1 || printf "" > ${PATH}/SOURCE_LANG
