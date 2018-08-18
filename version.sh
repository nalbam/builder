#!/bin/bash

USERNAME=${1}
REPONAME=${2}
GITHUB_TOKEN=${3}
CHANGED=

echo "USERNAME: ${USERNAME}"
echo "REPONAME: ${REPONAME}"

git config --global user.name "bot"
git config --global user.email "ops@nalbam.com"

get_version() {
    REPO=$1
    NAME=$2
    STRIP=$3

    mkdir -p versions
    touch versions/${NAME}

    NOW=$(cat versions/${NAME} | xargs)

    if [ "${NAME}" == "awscli" ]; then
        mkdir -p target

        pushd target
        curl -sLO https://s3.amazonaws.com/aws-cli/awscli-bundle.zip
        unzip awscli-bundle.zip
        popd

        NEW=$(ls target/awscli-bundle/packages/ | grep awscli | sed 's/awscli-//' | sed 's/.tar.gz//' | xargs)
    elif [ "${NAME}" == "kubectl" ]; then
        NEW=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt | xargs)
    else
        NEW=$(curl -s https://api.github.com/repos/${REPO}/${NAME}/releases/latest | grep tag_name | cut -d'"' -f4 | xargs)
    fi
    if [ ! -z ${STRIP} ]; then
        NEW=$(echo "${NEW}" | cut -c 2-)
    fi

    printf '# %-10s %-10s %-10s\n' "${NAME}" "${NOW}" "${NEW}"

    if [ "${NOW}" != "${NEW}" ]; then
        CHANGED=true

        printf "${NEW}" > versions/${NAME}
        sed -i -e "s/ENV ${NAME} .*/ENV ${NAME} ${NEW}/g" Dockerfile

        printf '# %-10s: %-10s\n' "${NAME}" "${NEW}"

        git add --all
        git commit -m "${NAME} ${NEW}"
    fi
}

get_version aws awscli
get_version kubernetes kubectl
# get_version kubernetes kops
get_version helm helm
get_version Azure draft
# get_version GoogleContainerTools skaffold
# get_version hashicorp terraform true
# get_version istio istio

if [ ! -z ${CHANGED} ]; then
    echo "# git push github.com/${USERNAME}/${REPONAME}"
    git push -q https://${GITHUB_TOKEN}@github.com/${USERNAME}/${REPONAME}.git master
fi
