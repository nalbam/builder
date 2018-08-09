#!/bin/bash

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
        printf "0.1.${VERSION}-${REVISION}" > /home/jenkins/VERSION
    else
        printf "0.0.${VERSION}-${BRANCH}" > /home/jenkins/VERSION
    fi

    echo "# VERSION: $(cat /home/jenkins/VERSION)"
}

get_domain() {
    NAME=${1}
    SAVE=${2}
    NAMESPACE=${3}

    DOMAIN=$(kubectl get ing -n ${NAMESPACE} -o wide | grep ${NAME} | head -1 | awk '{print $2}' | cut -d',' -f1)

    printf "${DOMAIN}" > ${HOME}/${SAVE}

    if [ ! -z ${DOMAIN} ] && [ "${NAME}" == "jenkins" ]; then
        BASE_DOMAIN=${DOMAIN:$(expr index $DOMAIN \.)}
        printf "$BASE_DOMAIN" > ${HOME}/BASE_DOMAIN
        echo "# BASE_DOMAIN: $(cat ${HOME}/BASE_DOMAIN)"
    fi

    echo "# ${SAVE}: $(cat ${HOME}/${SAVE})"
}

get_language() {
    NAME=${1}
    LANG=${2}

    FIND=$(find . -name ${NAME} | head -1)

    if [ ! -z ${FIND} ]; then
        ROOT=$(dirname ${FIND})

        if [ ! -z ${ROOT} ]; then
            printf "$ROOT" > ${HOME}/SOURCE_ROOT
            printf "$LANG" > ${HOME}/SOURCE_LANG

            echo "# SOURCE_LANG: $(cat ${HOME}/SOURCE_LANG)"
            echo "# SOURCE_ROOT: $(cat ${HOME}/SOURCE_ROOT)"
        fi
    fi
}

NAME=${1:-sample}
BRANCH=${2:-master}

NAMESPACE=${3:-devops}

get_version ${NAME} ${BRANCH}

get_domain jenkins JENKINS ${NAMESPACE}
get_domain chartmuseum CHARTMUSEUM ${NAMESPACE}
get_domain docker-registry REGISTRY ${NAMESPACE}
get_domain sonarqube SONARQUBE ${NAMESPACE}
get_domain sonatype-nexus NEXUS ${NAMESPACE}

cat ${HOME}/SOURCE_LANG > /dev/null 2>&1 || get_language pom.xml java
cat ${HOME}/SOURCE_LANG > /dev/null 2>&1 || get_language package.json nodejs