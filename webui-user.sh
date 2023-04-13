#!/bin/bash
#########################################################
# Uncomment and change the variables below to your need:#
#########################################################

# Install directory without trailing slash
#install_dir="/home/$(whoami)"

# Name of the subdirectory
#clone_dir="stable-diffusion-webui"

# Commandline arguments for webui.py, for example: export COMMANDLINE_ARGS="--medvram --opt-split-attention"
#export COMMANDLINE_ARGS=""

# python3 executable
#python_cmd="python3"

# git executable
#export GIT="git"

# python3 venv without trailing slash (defaults to ${install_dir}/${clone_dir}/venv)
#venv_dir="venv"

# script to launch to start the app
#export LAUNCH_SCRIPT="launch.py"

# install command for torch
#export TORCH_COMMAND="pip install torch==1.12.1+cu113 --extra-index-url https://download.pytorch.org/whl/cu113"

# Requirements file to use for stable-diffusion-webui
#export REQS_FILE="requirements_versions.txt"

# Fixed git repos
#export K_DIFFUSION_PACKAGE=""
#export GFPGAN_PACKAGE=""

# Fixed git commits
#export STABLE_DIFFUSION_COMMIT_HASH=""
#export TAMING_TRANSFORMERS_COMMIT_HASH=""
#export CODEFORMER_COMMIT_HASH=""
#export BLIP_COMMIT_HASH=""

# Uncomment to enable accelerated launch
#export ACCELERATE="True"

###########################################
echo "start webui-user.sh"
rm -r stable-diffusion-webui/models
rm -r stable-diffusion-webui/extensions
rm -r stable-diffusion-webui/embeddings

# user storage space sd
#      |-- models
# sd --|-- embeddings
#      |-- extensions
#      |-- styles.csv

mkdir -p /ark-contexts/data/sd/models /ark-contexts/data/sd/embeddings /ark-contexts/data/sd/extensions /ark-contexts/data/sd/outputs
touch /ark-contexts/data/sd/styles.csv

ln -s /ark-contexts/data/sd/models stable-diffusion-webui/models
ln -s /ark-contexts/data/sd/extensions stable-diffusion-webui/extensions
ln -s /ark-contexts/data/sd/embeddings stable-diffusion-webui/embeddings
ln -s /ark-contexts/data/sd/outputs stable-diffusion-webui/outputs
if [[ ! -e stable-diffusion-webui/styles.csv ]]; then
    ln -s /ark-contexts/data/sd/styles.csv stable-diffusion-webui/styles.csv
fi

# public dataset sd-base
#           |-- models
# sd-base --|-- embeddings
#           |-- extensions
#           |-- huggingface
#           |-- clip
#           |-- interrogate
if [[ -e /ark-contexts/imported_datasets/sd-base ]]
then
    #cp huggingface
    mkdir -p /home/user/.cache/huggingface
    cp -r /ark-contexts/imported_datasets/sd-base/huggingface/* /home/user/.cache/huggingface

    mkdir -p  /home/user/.cache/clip
    cp -r /ark-contexts/imported_datasets/sd-base/clip/* /home/user/.cache/clip
    #link models
    for dir in /ark-contexts/imported_datasets/sd-base/models/*; do
        if [ -d "${dir}" ]; then
            if [[ ! -d /app/stable-diffusion-webui/models/"$(basename $dir)" ]]; then
                mkdir -p /app/stable-diffusion-webui/models/"$(basename $dir)"
            fi
            for i in /ark-contexts/imported_datasets/sd-base/models/"$(basename $dir)"/*; do
                if [[ (-f "${i}") && (! -e /app/stable-diffusion-webui/models/"$(basename $dir)"/"$(basename $i)") ]]; then
                    #如果是.png文件，就拷贝，否则就建立软链接
                    if [[ "${i}" == *.png ]]; then
                        cp "${i}" /app/stable-diffusion-webui/models/"$(basename $dir)"/"$(basename $i)"
                    else
                        ln -s "${i}" /app/stable-diffusion-webui/models/"$(basename $dir)"/"$(basename $i)"
                    fi
                fi
            done
        fi
    done

    #link embeddings
    for file in /ark-contexts/imported_datasets/sd-base/embeddings/*; do
        if [[ (-f "${file}") && ! -e /app/stable-diffusion-webui/embeddings/"$(basename $file)" ]]; then
            #如果是.png文件，就拷贝，否则就建立软链接
            if [[ "${file}" == *.png ]]; then
                cp "${file}" /app/stable-diffusion-webui/embeddings/"$(basename $file)"
            else
                ln -s "${file}" /app/stable-diffusion-webui/embeddings/"$(basename $file)"
            fi
        fi
    done

    #link interrogate
    mkdir -p /app/stable-diffusion-webui/interrogate
    for file in /ark-contexts/imported_datasets/sd-base/interrogate/*; do
        if [[ (-f "${file}") && ! -e /app/stable-diffusion-webui/interrogate/"$(basename $file)" ]]; then
            ln -s "${file}" /app/stable-diffusion-webui/interrogate/"$(basename $file)"
        fi
    done

    #link extensions
    for dir in /ark-contexts/imported_datasets/sd-base/extensions/*; do
        if [[ ! -e /app/stable-diffusion-webui/extensions/"$(basename $dir)" ]]; then
            ln -s "${dir}" /app/stable-diffusion-webui/extensions/"$(basename $dir)"
        fi
    done

    #link codeformer facelib
    for file in /ark-contexts/imported_datasets/sd-base/facelib/*; do
        if [[ (-f "${file}") && ! -e /app/stable-diffusion-webui/repositories/CodeFormer/weights/facelib/"$(basename $file)" ]]; then
            ln -s "${file}" /app/stable-diffusion-webui/repositories/CodeFormer/weights/facelib/"$(basename $file)"
        fi
    done

    echo "simlink from sd-base done"
fi


rm /app/stable-diffusion-webui/venv/lib/python3.10/site-packages/gradio/routes.py
cp /app/routes.py /app/stable-diffusion-webui/venv/lib/python3.10/site-packages/gradio/

echo "gradio routes.py done"

git config --global http.sslVerify false