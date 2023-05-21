#!/usr/bin/env bash

# Constants
SOURCES_DIRECTORY="./source.d/"
DOWNLOAD_FILE="/tmp/adguard_update.download"
TEMP_FILE_PREFIX="/tmp/adguard_update.tmp."
FINAL_FILE_PREFIX="./release/"
FINAL_FILE_SUFFIX=".list"


function transform_to_adguard {

    echo "Transforming list to Adguard Home format (could take a while, please wait)"

    while IFS="" read -r line || [ -n "$p" ]
    do
        if [[ "${line}" == "" ]] || [[ "${line}" == "#"* ]] || [[ "${line}" == ";"* ]]
        then
            continue
        fi
        
        entry=$(parse_entry "${line}")
        if [ "${entry}" == "" ]
        then
            continue
        fi

        echo "${entry}" >> "${TEMP_FILE_PREFIX}${CATEGORY}"
    done < "${DOWNLOAD_FILE}"
}

function read_to_adguard {

    echo "Reading list to Adguard Home format (could take a while, please wait)"
    while IFS="" read -r line || [ -n "$p" ]
    do
        if [[ "${line}" == "" ]] || [[ "${line}" == "#"* ]] || [[ "${line}" == ";"* ]]
        then
            continue
        fi
        
        echo "${line}" >> "${TEMP_FILE_PREFIX}${CATEGORY}"
    done < "${DOWNLOAD_FILE}"
}

function fetch_from_file {

    # Clean temporary file
    rm -f "${DOWNLOAD_FILE}"

    # Fetch URI
    echo "Fetching '${1}'"
    cp "${1}" "${DOWNLOAD_FILE}"
}

function fetch_from_uri {

    # Clean temporary file
    rm -f "${DOWNLOAD_FILE}"

    # Fetch URI
    echo "Fetching '${1}'"
    curl --location "${1}" -o "${DOWNLOAD_FILE}"
}

function main {

    local -a processed_category_list=()

    # Clean temporary files
    rm -f "${TEMP_FILE_PREFIX}"*

    # Process all sources
    for source in `ls "${SOURCES_DIRECTORY}" | grep 'src'`
    do
        # Load variables from srv file
        source "${SOURCES_DIRECTORY}${source}" "$@"

        if [[ "${FORMAT_ADGUARD}" == "false" ]] && [[ $(type -t parse_entry) != function ]]
        then
            echo "Error: function 'parse_entry' is not defined in source file '${NAME}'"
            exit
        fi

        if [[ "${ENABLED}" == "true" ]]
        then
            echo "Processing source '${NAME}'"

            # Fetch source input file
            if [[ "${INPUT}" == "http"* ]]
            then
                fetch_from_uri "${INPUT}"
            else
                fetch_from_file "${INPUT}"
            fi

            # Append to category file
            if [[ "${FORMAT_ADGUARD}" != "true" ]]
            then
                transform_to_adguard
            else
                read_to_adguard
            fi

            # Track processed categories
            processed_category_list+=("${CATEGORY}")
        fi

        # Clean global variables
        unset NAME
        unset ENABLED
        unset CATEGORY
        unset INPUT
        unset FORMAT_ADGUARD
        unset parse_entry
    done

    # Replace old lists
    for category in "${processed_category_list[@]}"
    do
        echo "Writing list '${category}'"
        cat "${TEMP_FILE_PREFIX}${category}" | grep -v 'developerdan' | LC_ALL=C sort | LC_ALL=C uniq > "${FINAL_FILE_PREFIX}${category}${FINAL_FILE_SUFFIX}"
    done

    # Clean temporary files
    rm -f "${DOWNLOAD_FILE}"
    rm -f "${TEMP_FILE_PREFIX}"*

    echo "Done"
}


cd "$(dirname "${BASH_SOURCE[0]}")"
main @$
