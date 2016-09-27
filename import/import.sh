#!/bin/bash

ISMYSQL=0
ISMONGO=0
URI=''
FRAMEWORK=''
FTPUSER=''
FTPPASSWD=''
FTPHOST='nextdeploy'
PATHURI="server"
DOCROOT="$(pwd)/"
BRANCH=""
PROJECTNAME=""

# display helpn all of this parametes are setted during vm install
posthelp() {
  cat <<EOF
Usage: $0 [options]

-h                this is some help text.
--framework xxxx  framework targetting
--branch xxxx       specify branch name
--path xxxx       uniq path for the framework
--ftpuser xxxx    ftp user on nextdeploy ftp server
--ftppasswd xxxx  ftp password on nextdeploy ftp server
--ftphost xxxx    override nextdeploy ftp host
--ismysql x       1/0 if mysql-server present (default is 0)
--ismongo x       1/0 if mongo-server present (default is 0)
--uri xxxx        main uri of the website (used by wordpress import)
--projectname xxx identified project
EOF

exit 0
}


# Parse cmd options
while (($# > 0)); do
  case "$1" in
    --framework)
      shift
      FRAMEWORK="$1"
      shift
      ;;
    --ftpuser)
      shift
      FTPUSER="$1"
      shift
      ;;
    --ftppasswd)
      shift
      FTPPASSWD="$1"
      shift
      ;;
    --ftphost)
      shift
      FTPHOST="$1"
      shift
      ;;
    --ismysql)
      shift
      ISMYSQL="$1"
      shift
      ;;
    --ismongo)
      shift
      ISMONGO="$1"
      shift
      ;;
    --path)
      shift
      PATHURI="$1"
      shift
      ;;
    --projectname)
      shift
      PROJECTNAME="$1"
      shift
      ;;
    --branch)
      shift
      BRANCH="$1"
      shift
      ;;
    --uri)
      shift
      URI="$1"
      shift
      ;;
    -h)
      shift
      posthelp
      ;;
    *)
      shift
      ;;
  esac
done

DOCROOT="${DOCROOT}${PATHURI}"

# get current branch
pushd ${DOCROOT} >/dev/null
[[ -z "$BRANCH" ]] && [[ -d ".git" ]] && BRANCH="$(git rev-parse --abbrev-ref HEAD | tr -d "\n")"
[[ -z "$BRANCH" ]] && BRANCH='master'
popd >/dev/null

# drupal actions
postdrupal() {
  # decompress assets archive
  assetsarchive "${DOCROOT}/sites/default/files"
  (( $? != 0 )) && echo "No assets archive or corrupt file"

  # import data
  importdatas
}

# symfony actions
postsymfony2() {
  # decompress assets archive
  if [[ -d "${DOCROOT}/web/upload" ]]; then
    assetsarchive "${DOCROOT}/web/upload"
  else
    assetsarchive "${DOCROOT}/web/uploads"
  fi

  (( $? != 0 )) && echo "No assets archive or corrupt file"

  # import data
  importdatas
}

# wordpress actions
postwordpress() {
  # decompress assets archive
  if [[ -d "${DOCROOT}/git-wp-content/uploads" ]]; then
    assetsarchive "${DOCROOT}/git-wp-content/uploads"
  else
    assetsarchive "${DOCROOT}/wp-content/uploads"
  fi

  (( $? != 0 )) && echo "No assets archive or corrupt file"

  # import data
  importdatas
}

# static actions
poststatic() {
  importdatas
}

# import sql or mongo dump
importdatas() {
  # sql part
  if (( ISMYSQL == 1 )); then
    importsql
    if (( $? != 0 )); then
      echo "No sql file or corrupt file"
      (( ISMONGO == 0 )) && exit 0
    fi
  fi

  # mongo part
  if (( ISMONGO == 1 )); then
    importmongo
    if (( $? != 0 )); then
      echo "No mongo file or corrupt file"
      exit 0
    fi
  fi
}

# import a sql dump into mysql server
importsql() {
  local ret=0
  local sqlfile=''
  local branchname="${BRANCH}"
  local dbname=""

  # prepare tmp folder
  rm -rf /tmp/dump
  mkdir /tmp/dump

  pushd /tmp/dump > /dev/null
  ncftpget -u $FTPUSER -p $FTPPASSWD $FTPHOST . dump/${branchname}_${PATHURI}*.sql.gz 2>/dev/null
  if (( $? != 0 )); then
    branchname="default"
    ncftpget -u $FTPUSER -p $FTPPASSWD $FTPHOST . dump/${branchname}_${PATHURI}*.sql.gz 2>/dev/null
  fi

  sqlfiles="$(ls *.sql.gz 2>/dev/null)"
  for sqlf in ${sqlfiles[@]}; do
    dbname="${sqlf#*_}"
    dbname="${dbname%%.sql.gz}"

    echo "create database ${dbname} character set=utf8 collate=utf8_unicode_ci" | mysql -u root -p8to9or1 -h mysql_${PROJECTNAME} >/dev/null 2>&1
    #echo "grant all privileges on ${dbname}.* to s_bdd@'%' identified by 's_bdd'" | mysql -u root -p8to9or1 -h mysql_${PROJECTNAME} >/dev/null 2>&1
    zcat "$sqlf" | mysql -u root -p8to9or1 $dbname -h mysql_${PROJECTNAME}
    (( $? != 0 )) && ret=1
  done
  popd > /dev/null
  rm -rf /tmp/dump
  return $ret
}

# import a mongo dump into mongoserver
importmongo() {
  local ret=0
  local mongofile=''
  local mongofolder=''
  local branchname="${BRANCH}"

  # prepare tmp folder
  rm -rf /tmp/dump
  mkdir /tmp/dump

  pushd /tmp/dump > /dev/null
  ncftpget -u $FTPUSER -p $FTPPASSWD $FTPHOST . dump/${branchname}_${PATHURI}*.tar.gz 2>/dev/null
  if (( $? != 0 )); then
    branchname="default"
    ncftpget -u $FTPUSER -p $FTPPASSWD $FTPHOST . dump/${branchname}_${PATHURI}*.tar.gz 2>/dev/null
  fi

  if (( $? == 0 )); then
    # take the first one
    mongofile="$(ls *.tar.gz 2>/dev/null | head -n 1 | sed "s;.tar.gz;;" | tr -d "\n")"
    tar xvfz ${mongofile}.tar.gz
    rm -f *.tar.gz
    mongofolder="$(ls)"
    LC_ALL=en_US.UTF-8 mongorestore -d $mongofolder --drop $mongofolder --host mongodb_${PROJECTNAME}
    (( $? != 0 )) && ret=1
  else
    ret=1
  fi
  popd > /dev/null
  rm -rf /tmp/dump
  return $ret
}

# update website asset folder from archive file
assetsarchive() {
  local ret=0
  local archivefile=''
  local destfolder="$1"
  local branchname="${BRANCH}"

  # prepare tmp folder
  rm -rf /tmp/assets
  mkdir /tmp/assets

  pushd /tmp/assets > /dev/null
  ncftpget -u $FTPUSER -p $FTPPASSWD $FTPHOST . assets/${branchname}_${PATHURI}_assets.tar.gz 2>/dev/null
  if (( $? != 0 )); then
    branchname="default"
    ncftpget -u $FTPUSER -p $FTPPASSWD $FTPHOST . assets/${branchname}_${PATHURI}_assets.tar.gz 2>/dev/null
  fi

  if (( $? == 0 )); then
    # take the first one
    archivefile="$(ls *.tar.gz 2>/dev/null | head -n 1 | tr -d "\n")"
    tar xvfz "$archivefile" >/dev/null 2>&1
    rm -f "$archivefile"
    if (( $? == 0 )); then
      mkdir -p ${destfolder}
      rsync -av * ${destfolder}/ >/dev/null 2>&1
    else
      ret=1
    fi
    rm -f *.tar.gz
  else
    ret=1
  fi
  popd > /dev/null
  rm -rf /tmp/assets
  return $ret
}

case "$FRAMEWORK" in
  "drupal"*)
    postdrupal
    ;;
  "symfony"*)
    postsymfony2
    ;;
  "wordpress"*)
    postwordpress
    ;;
  *)
    poststatic
    ;;
esac
