#!/bin/bash -
#
# Gestion de cours de programme d'etudes.


# Nom de fichier pour depot par defaut.
DEPOT_DEFAUT=.cours.txt

##########################################################################
# Fonctions pour debogage et traitement des erreurs.
##########################################################################

# Pour generer des traces de debogage avec la function debug, il
# suffit de supprimer le <<#>> au debut de la ligne suivante.
#DEBUG=1

#-------
# Affiche une trace de deboggage.
#
# Arguments: [chaine...]
#-------
function debug {
    [[ $DEBUG ]] || return

    echo -n "[debug] "
    for arg in "$@"
    do
        echo -n "'$arg' "
    done
    echo ""
}

#-------
# Affiche un message d'erreur.
#
# Arguments: msg
#-------
function erreur {
    msg=$1

    # A COMPLETER: Les erreurs doivent etre emises stderr...
    # mais ce n'est pas le cas pour l'instant!
    >&2 echo "*** Erreur: $msg"
    >&2 echo ""

    # On emet le message d'aide si commande fournie invalide.
    # Par contre, ce message doit etre emis sur stdout.
    [[ ! $msg =~ Commande\ inconnue ]] || aide

    exit 1
}


##########################################################################
# Fonction d'aide: fournie, pour uniformite.
#
# Arguments: Aucun
#
# Emet l'information sur stdout
##########################################################################
function aide {
    cat <<EOF
NOM
  $0 -- Script pour gestion academique (banque de cours)

SYNOPSIS
  $0 [--depot=fich] commande [options-commande] [argument...]

COMMANDES
  aide          - Emet la liste des commandes
  ajouter       - Ajoute un cours dans la banque de cours
                  (les prealables doivent exister)
  desactiver    - Rend inactif un cours actif
                  (ne peut plus etre utilise comme nouveau prealable)
  init          - Cree une nouvelle base de donnees pour gerer des cours
                  (dans './$DEPOT_DEFAUT' si --depot n'est pas specifie)
  lister        - Liste l'ensemble des cours de la banque de cours
                  (ordre croissant de sigle)
  nb_credits    - Nombre total de credits pour les cours indiques
  prealables    - Liste l'ensemble des prealables d'un cours
                  (par defaut: les prealables directs seulement)
  reactiver     - Rend actif un cours inactif
  supprimer     - Supprime un cours de la banque de cours
  trouver       - Trouve les cours qui matchent un motif
EOF
}

##########################################################################
# Fonctions pour manipulation du depot.
#
# Fournies pour simplifier le devoir et assurer au depart un
# fonctionnement minimal du logiciel.
##########################################################################

#-------
# Verifie que le depot indique existe, sinon signale une erreur.
#
# Arguments: depot
#-------
function assert_depot_existe {
    depot=$1
    [[ -f $depot ]] || erreur "Le fichier '$depot' n'existe pas!"
}


#-------
# Commande init.
#
# Arguments:  depot [--detruire]
#
# Erreurs:
#  - Le depot existe deja et l'option --detruire n'a pas ete indiquee
#-------
function init {
    depot=$1; shift
    nb_arguments=0

    if [[ $1 =~ --detruire ]]; then
      detruire=true
      nb_arguments=1
    fi

    if [[ -f $depot ]]; then
        [[ $detruire ]] || erreur "Le fichier '$depot' existe.\
 Si vous voulez le detruire, utilisez 'init --detruire'."
        \rm -f $depot
    fi

    touch $depot

    return $nb_arguments
}

##########################################################################
# Les fonctions pour les diverses commandes de l'application.
#
# A COMPLETER!
#
##########################################################################


# Separateur pour les champs d'un enregistrement specificant un cours.
readonly SEPARATEUR=,
readonly SEP=$SEPARATEUR # Alias, pour alleger le code

# Separateur pour les prealables d'un cours.
readonly SEPARATEUR_PREALABLES=:

#function pour valider si le sigle existe
#
#arguments: depot sigle [--avec_inactifs]
function sigle_existe {
    assert_depot_existe $1
    depot=$1; shift
    #echo sigle_existe $depot, $1
    if [[ $2 =~ --avec_inactifs ]]; then
      grep -q ^$1, $depot
      rep=$? # 0 si trouve
    else
      grep ^$1, $depot | grep -qv INACTIF$
      rep=$? # 0 si trouve
    fi
    #echo $rep
    return $rep
}

#function pour valider si le sigle est valide
#
#arguments: sigle

function sigle_valide {
    [[ $1 =~ [A-Z]{3}[0-9]{4} ]] || erreur "sigle invalide"
}

#-------
# Commande lister
#
# Arguments: depot [--avec_inactifs]
#
# Erreurs:
# - depot inexistant
#-------
function lister {
    nb_arguments=0
    assert_depot_existe $1
    depot=$1; shift

    if [[ $1 =~ --avec_inactifs ]]; then
      awk -F"$SEP" '/,INACTIF$/ {print $1"?", "\""$2"\"", "("$4")"}
                    /,ACTIF$/ {print $1, "\""$2"\"", "("$4")"}' $depot | sort
      nb_arguments=1
    else
      awk -F"$SEP" '/,ACTIF$/ {print $1, "\""$2"\"", "("$4")"}' $depot | sort
    fi

    return $nb_arguments
}


#-------
# Commande ajouter
#
# Arguments: depot sigle titre nb_credits [prealable...]
#
# Erreurs:
# - depot inexistant
# - nombre insuffisant d'arguments
# - sigle de forme invalide ou inexistant
# - sigles des prealables de forme invalide ou inexistants
# - cours avec meme sigle existe deja
#-------


function ajouter {
    nb_arguments=0
    assert_depot_existe $1
    depot=$1; shift

    [[ $# -lt 3 ]] && erreur "Besoin de 3 arguments minimum"
    nb_arguments=3

    sigle=$1; shift
    titre=$1; shift
    nb_credits=$1; shift

    sigle_valide $sigle
    inac=--avec_inactifs
    sigle_existe $depot $sigle $inac && erreur "Sigle existe deja"

    sigle_valide $1
    ! sigle_existe $depot $1 && erreur "Prealable n'existe pas"
    nouveau_cours="$sigle,$titre,$nb_credits,$1"; shift
    (( nb_arguments++ ))

    for prealables in "$@"; do
        sigle_valide $1
        ! sigle_existe $depot $1 && erreur "Prealable n'existe pas"
        nouveau_cours="$nouveau_cours$SEPARATEUR_PREALABLES$1"
        (( nb_arguments++ ))
    done

    echo "$nouveau_cours,ACTIF" >> "$depot"

    return $nb_arguments
}


#-------
# Commande trouver
#
# Arguments: depot [--avec_inactifs] [--cle_tri=sigle|titre]
# [--format=un_format] motif
#
# Erreurs:
# - depot inexistant
# - nombre incorrect d'arguments
# - cle_tri de valeur invalide
# - item de format invalide
#-------
function trouver {
    return 0
}

#-------
# Commande nb_credits
#
# Arguments: depot [sigle...]
#
# Erreurs:
# - depot inexistant
# - sigle inexistant
#-------
function nb_credits {
    nb_arguments=0
    nb_credits=0
    assert_depot_existe $1
    depot=$1; shift

    for cours in "$@"; do
      #echo $cours
      ! sigle_existe $depot $cours  && erreur "Sigle n'existe pas"
      (( nb_arguments++ ))
      (( nb_credits = nb_credits + $(awk -F"$SEP" '/^'$cours'/ {print $3}' $depot) ))
    done

    echo $nb_credits

    return $nb_arguments
}


#-------
# Commande supprimer
#
# Arguments: depot sigle
#
# Erreurs:
# - depot inexistant
# - nombre incorrect d'arguments
# - sigle inexistant
#-------
function supprimer {
    nb_arguments=0
    assert_depot_existe $1
    depot=$1; shift

    [[ $# != 1 ]] && erreur "Besoin de seulement 2 arguments"
    nb_arguments=1

    inac=--avec_inactifs
    ! sigle_existe $depot $1 $inac && erreur "Sigle n'existe pas"

    sed -i /^"$1"/d $depot

    return $nb_arguments
}


#-------
# Commande desactiver
#
# Arguments: depot sigle
#
# Erreurs:
# - depot inexistant
# - nombre incorrect d'arguments
# - sigle inexistant
# - cours deja inactif
#-------
function desactiver {
  nb_arguments=0
  assert_depot_existe $1
  depot=$1; shift

  [[ $# != 1 ]] && erreur "Besoin de seulement 2 arguments"
  nb_arguments=1

  inac=--avec_inactifs
  ! sigle_existe $depot $1 $inac && erreur "Sigle n'existe pas"

  grep -q ^$1.*INACTIF$ $depot && erreur "cours deja inactif"

  sed -i "/^"$1"/ s/ACTIF/INACTIF/" $depot

  return $nb_arguments
}

#-------
# Commande reactiver
#
# Arguments: depot sigle
#
# Erreurs:
# - depot inexistant
# - nombre incorrect d'arguments
# - sigle inexistant
# - cours deja actif
#-------
function reactiver {
  nb_arguments=0
  assert_depot_existe $1
  depot=$1; shift

  [[ $# != 1 ]] && erreur "Besoin de seulement 2 arguments"
  nb_arguments=1

  inac=--avec_inactifs
  ! sigle_existe $depot $1 $inac && erreur "Sigle n'existe pas"
  echo "hey"
  grep -q ^$1.*,ACTIF$ $depot && erreur "cours deja actif"

  sed -i "/^"$1"/ s/INACTIF/ACTIF/" $depot

  return $nb_arguments
}


#-------
# Commande prealables
#
# Arguments: depot [--directs|--tous] sigle
#
# Erreurs:
# - depot inexistant
# - nombre incorrect d'arguments
# - sigle inexistant
#-------
function prealables {
  nb_arguments=0
  assert_depot_existe $1
  depot=$1; shift

  inac=--avec_inactifs
  sigle_existe $depot $1 $inac && erreur "Sigle n'existe pas"

  return $nb_arguments
}

##########################################################################
# Le programme principal
#
# La strategie utilisee pour uniformiser le trairement des commande
# est la suivante : Une commande est mise en oeuvre par une fonction
# auxiliaire du meme nom que la commande. Cette fonction retourne
# comme statut le nombre d'arguments ou d'options (du programme
# principal) utilises par la commande --- mais  on ne compte pas l'argument
# $depot, transmis a chacune des fonctions.
#
# Ceci permet par la suite, dans le corps de la fonction principale,
# de "shifter" les arguments et, donc, de verifier si des arguments
# superflus ont ete fournis.
#
##########################################################################

function main {
  # On definit le depot a utiliser.
  # A COMPLETER: il faut verifier si le flag --depot=... a ete specifie.
  # Si oui, il faut modifier depot en consequence!
  if [[ $1 =~ --depot=* ]]; then
    #echo "dans le if"
    depot=${1#*=};shift
  else
    #echo "pas dans le if"
    depot=$DEPOT_DEFAUT
  fi
  #echo $depot
  debug "On utilise le depot suivant:", $depot


  # On analyse la commande (= dispatcher).
  commande=$1
  shift
  case $commande in
      ''|aide)
          aide;;

      ajouter|\
      desactiver|\
      init|\
      lister|\
      nb_credits|\
      prealables|\
      reactiver|\
      supprimer|\
      trouver|\
      sigle_existe)
          $commande $depot "$@";;

      *)
          erreur "Commande inconnue: '$commande'";;
  esac
  shift $?

  [[ $# == 0 ]] || erreur "Argument(s) en trop: '$@'"
}

main "$@"
exit 0
