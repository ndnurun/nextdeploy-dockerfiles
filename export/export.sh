#!/bin/bash


ISMYSQL=0
ISMONGO=0
FRAMEWORK=''
FTPUSER=''
FTPPASSWD=''
URI=''
BRANCHS=('default')
FTPHOST='nextdeploy'
PATHURI="server"
DOCROOT="$(pwd)/"

# display helpn all of this parametes are setted during vm install
posthelp() {
  cat <<EOF
Usage: $0 [options]

-h                this is some help text.
--framework xxxx  framework targetting
--path xxxx       uniq path for the framework
--ftpuser xxxx    ftp user on nextdeploy ftp server
--ftppasswd xxxx  ftp password on nextdeploy ftp server
--ftphost xxxx    override nextdeploy ftp host
--ismysql x       1/0 if mysql-server present (default is 0)
--ismongo x       1/0 if mysql-server present (default is 0)
--branchs xxxx    set branch(s) destination for export
--uri xxxx        uri of the website
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
    --uri)
      shift
      URI="$1"
      shift
      ;;
    --branchs)
      shift
      BRANCHS="$*"
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

# drupal actions
postdrupal() {
  # compress assets archive
  assetsarchive "${DOCROOT}/sites/default/files"
  (( $? != 0 )) && echo "No assets archive or corrupt file"

  # export data
  exportdatas
}

# symfony actions
postsymfony2() {
  # decompress assets archive
  assetsarchive "${DOCROOT}/web/uploads"
  (( $? != 0 )) && echo "No assets archive or corrupt file"

  # export datas
  exportdatas
}

# wordpress actions
postwordpress() {
  # decompress assets archive
  assetsarchive "${DOCROOT}/wp-content/uploads"
  (( $? != 0 )) && echo "No assets archive or corrupt file"

  # export datas
  exportdatas
}

# static actions
poststatic() {
  exportdatas
}

# export sql or mongo dump
exportdatas() {
  # sql part
  if (( ISMYSQL == 1 )); then
    exportsql
    if (( $? != 0 )); then
      echo "No sql file or corrupt file"
      (( ISMONGO == 0 )) && exit 0
    fi
  fi

  # mongo part
  if (( ISMONGO == 1 )); then
    exportmongo
    if (( $? != 0 )); then
      echo "No mongo file or corrupt file"
      exit 0
    fi
  fi
}

# export a sql dump into mysql server
exportsql() {
  local ret=0

  # prepare tmp folder
  rm -rf /tmp/dump
  mkdir /tmp/dump

  pushd /tmp/dump > /dev/null
  echo "show databases" | mysql -u s_bdd -ps_bdd | grep -v -e "^Database$" | grep -v -e "^information_schema$" | grep "${PATHURI}" | while read dbname; do
    mysqldump -u s_bdd -ps_bdd $dbname > ${dbname}.sql
    [[ "$FRAMEWORK" = 'wordpress'* ]] && sed -i "s;$URI;ndwpuri;g" ${dbname}.sql
    gzip ${dbname}.sql

    for branch in ${BRANCHS[@]}; do
      mv ${dbname}.sql.gz "${branch}_${dbname}.sql.gz"
      ncftpput -S .tmp -u $FTPUSER -p $FTPPASSWD $FTPHOST dump/ "${branch}_${dbname}.sql.gz"
      (( $? != 0 )) && ret=1
      mv "${branch}_${dbname}.sql.gz" ${dbname}.sql.gz
    done
  done
  popd > /dev/null
  rm -rf /tmp/dump
  return $ret
}

# export a mongo dump into mongoserver
exportmongo() {
  local ret=0

  # prepare tmp folder
  rm -rf /tmp/dump
  mkdir /tmp/dump

  pushd /tmp/dump > /dev/null
  echo "show dbs" | mongo --quiet | grep -v "local" | grep "${PATHURI}" | sed "s; .*$;;" | while read dbname; do
    mongodump --db $dbname
    pushd dump >/dev/null
    tar cvfz ${dbname}.tar.gz $dbname
    for branch in ${BRANCHS[@]}; do
      mv ${dbname}.tar.gz "${branch}_${dbname}.tar.gz"
      ncftpput -S .tmp -u $FTPUSER -p $FTPPASSWD $FTPHOST dump/ "${branch}_${dbname}.tar.gz"
      (( $? != 0 )) && ret=1
      mv "${branch}_${dbname}.tar.gz" ${dbname}.tar.gz
    done

    # test if default exist
    echo "ls dump/" | ncftp -u $FTPUSER -p $FTPPASSWD $FTPHOST | grep default_${dbname}.tar.gz
    if (( $? != 0 )); then
      mv ${dbname}.tar.gz default_${dbname}.tar.gz
      ncftpput -S .tmp -u $FTPUSER -p $FTPPASSWD $FTPHOST dump/ default_${dbname}.tar.gz
    fi
    popd >/dev/null
    rm -rf dump
  done
  popd > /dev/null
  rm -rf /tmp/dump
  return $ret
}

# update website asset folder from archive file
assetsarchive() {
  local ret=0
  local archivefile=''
  local destfolder="$1"

  # prepare tmp folder
  rm -rf /tmp/assets
  mkdir /tmp/assets

  pushd /tmp/assets > /dev/null
  if (( $? == 0 )); then
    rsync -av --exclude config_* --exclude css --exclude js --exclude styles --exclude php ${destfolder}/ .
    rm -f assets.tar.gz
    tar cvfz assets.tar.gz *
    if (( $? == 0 )); then
      for branch in ${BRANCHS[@]}; do
        mv assets.tar.gz "${branch}_${PATHURI}_assets.tar.gz"
        ncftpput -S .tmp -u $FTPUSER -p $FTPPASSWD $FTPHOST assets/ "${branch}_${PATHURI}_assets.tar.gz"
        mv "${branch}_${PATHURI}_assets.tar.gz" assets.tar.gz
      done

      # test if default exist
      echo "ls assets/" | ncftp -u $FTPUSER -p $FTPPASSWD $FTPHOST | grep default_assets.tar.gz
      if (( $? != 0 )); then
        mv $assets.tar.gz default_assets.tar.gz
        ncftpput -S .tmp -u $FTPUSER -p $FTPPASSWD $FTPHOST assets/ default_assets.tar.gz
      fi
    else
      ret=1
    fi
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
