#!/bin/bash

#############################################################################################
# IUT - Computer Science
# R1.04 - Introduction to Operating Systems

# SCRIPT : blogue.sh

# DESCRIPTION : A bash script that manages a blog, and that can handle creating, 
# listing, deleting, and generating PDF/HTML of Markdown pages, as well as visualizing them.
#AUTHORS : Rafael Sarrazain-Peeters, Valentin Gues, S1D

############################################################################################

#DIRECTIVES :
set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset # Exit if variable not set. 
IFS=$'\n\t'

#-----------------------------------------------------------------------------
# FUNCTION : main
# DESCRIPTION : The main function of the script that creates the folder,
# and makes a request to the relevant function.
#-----------------------------------------------------------------------------

function main {
    # We create the markdown folder.
    mkdir -p markdown
    # We check if a command is provided.
    if [ "$#" -eq 0 ]; then
        echo "[ERREUR] Une action est attendue.
    Usage : ./blogue.sh COMMANDE [PARAMETRE]" >&2
        exit 1
    fi
    
    # We make sure that the command is insentitive to breakage.
    local command_name
    command_name=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    
    # Case that manages access to the functions.
    case "$command_name" in
        usage) 
            usage ;;
        edit)
            if [ "$#" -eq 2 ]; then
                edit "$2"
            else
                echo "[ERREUR] Nom du fichier non spécifié." >&2
                exit 1
            fi ;;
        delete)
            if [ "$#" -eq 2 ]; then
                delete "$2"
            else
                echo "[ERREUR] Nom du fichier non spécifié." >&2
                exit 1
            fi ;;
        list)
            list ;;
        build) 
            build ;;
        visualize)
            visualize "${2-}";;
        *)
            echo "[ERREUR] Commande non reconnue : $1" >&2
            exit 1 ;;
    esac
}
#-----------------------------------------------------------------------------
# FUNCTION : usage
# DESCRIPTION : Shows/explains how to use the script.
#-----------------------------------------------------------------------------

function usage {
echo "-Éditer un document : ./blog.sh editer [PAGE]
- Supprimer un document : ./blog.sh supprimer [PAGE]
- Lister les documents : ./blog.sh lister
- Générer les fichiers PDF/HTML : ./blog.sh construire
- Visualiser le site : ./blog.sh visualiser [pdf]"
}

#-----------------------------------------------------------------------------
# FUNCTION : edit
# DESCRIPTION : Checks for available text editor and opens the specified 
# markdown file.
#-----------------------------------------------------------------------------

function edit { 
   # Making sure to not create an index. (build)
   if [ "$1" = "index" ]; then
        echo "[ERREUR] La page index ne peut pas être créée manuellement." >&2
        exit 1
   fi
   
   # Check if the user provided an extension.
   if [[ "$1" == *.* ]]; then
        echo "[ERREUR] Ne pas préciser l’extension." >&2
        exit 1
   fi
   
   # Check if the EDITOR environment variable is set.
   if [ -n "${EDITOR-}" ] && command -v "$EDITOR" >/dev/null 2>&1; then
      "$EDITOR" "markdown/$1.md"
   
   # Check if the system default editor exists.
   elif [ -x /usr/bin/editor ]; then
      /usr/bin/editor" markdown/$1.md"
   
   # Check standard editors (vim, nano, vi) 
   else 
    if command -v vim >/dev/null 2>&1; then
        editor="vim"
        "$editor" "markdown/$1.md"
    elif command -v nano >/dev/null 2>&1; then
        editor="nano"
        "$editor" "markdown/$1.md"
    elif command -v vi >/dev/null 2>&1; then
        editor="vi"
        "$editor" "markdown$1.md"
    fi
   fi
}

#-----------------------------------------------------------------------------
# FUNCTION : delete
# DESCRIPTION : Deletes the markdown file chosen by the user, after
# double checking.
#-----------------------------------------------------------------------------

function delete {
    # Making sure to not delete the index. (build)
    if [ "$1" = "index" ]; then
        echo "[ERREUR] La page index ne peut pas être supprimée." >&2
        exit 1
   
    # Making sure there is no extension.
    elif [[ "$1" == *.* ]]; then
        echo "[ERREUR] Ne pas préciser l’extension." >&2
        exit 1
   
    # Making sure the file exists.
    elif [ ! -f "markdown/$1.md" ]; then
        echo "[ERREUR] Le fichier n’existe pas." >&2
        exit 1       
   
    # Delete page while asking for confirmation.
    else
         echo "Voulez-vous vraiment supprimer le fichier '$1' ? (y/n)"
         read -r reponse
         if [ "$reponse" = "y" ]; then
              rm -- "markdown/$1.md"
             echo "Fichier supprimé."
         else
             echo "Abandon."
         fi
    fi
}

#-----------------------------------------------------------------------------
#FUNCTION : list
#DESCRIPTION : Lists all existing markdown pages as long as the folder isn't empty.
#-----------------------------------------------------------------------------

function list {
    # Checks if the markdown folder is empty.
    if [ $(ls markdown/*.md | wc -l) -eq 0 ]; then
        echo "[ERREUR] Il n'y a pas de fichiers."
        exit 1
  
    # Lists all markdown files in the folder.
    else
        for f in markdown/*.md; do
            echo "${f#markdown/}"
        done
    fi
}

#-----------------------------------------------------------------------------
#FUNCTION : build
#DESCRIPTION : Generates a PDF file of the blog's contents.
#-----------------------------------------------------------------------------

function build {
    # Checks if the markdown folder is empty.
    if [ $(ls markdown/*.md | wc -l) -eq 0 ]; then
        echo "[ERREUR] Aucun fichier Markdown à générer." >&2
        exit 1
    fi
    rm -rf web
    mkdir -p web
    # Creating the Markdown index file.
    echo "# Sommaire du site" > markdown/index.md
    for filepath in markdown/*.md; do
        filename=$(basename "$filepath" .md)  
        if [ "$filename" != "index" ]; then
           echo "- [$filename]($filename.html)" >> markdown/index.md
        fi
    done
    echo "" >> markdown/index.md
    echo "Contenu actualisé le $(date) par $USER" >> markdown/index.md
    
    # Generating HTML pages for each Markdown file.
    for filepath in markdown/*.md; do
        filename=$(basename "$filepath" .md)   
        if [ "$filename" != "index" ]; then
            pandoc "$filepath" -o "web/$filename.html"
        fi
    done
    
    # Generating the HTML and PDF files.
    pandoc markdown/index.md -o web/index.html
    pandoc markdown/*.md -o blog.pdf
}

#-----------------------------------------------------------------------------
#FUNCTION : visualize
#DESCRIPTION : Launches the visualization of either the HTML or PDF file.
#-----------------------------------------------------------------------------

function visualize {
    # If argument is pdf then visualize pdf.
    if [ "${1-}" = "pdf" ]; then
        xdg-open blog.pdf 2> /dev/null
    
    # If any other argument given.
    elif [ -n "${1-}" ]; then
        echo "[ERREUR] Argument invalide : $1, seul pdf est accepté." >&2
        exit 1 
    
    # If no argument then visualize html.
    else
        xdg-open web/index.html 
    fi
}

main "$@"


