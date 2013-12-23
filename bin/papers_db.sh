#! /usr/bin/env bash

die() {
    echo "$1"
    exit 1
}

md5cmd() {
    $MD5SUM_CMD "$1" | awk '{ print $1 }'
}

init() {
    sqlite3 papers.db 'CREATE TABLE papers (doc_id STRING PRIMARY KEY, path STRING)'
    sqlite3 papers.db 'CREATE TABLE tags (tag STRING, doc_id STRING, PRIMARY KEY (tag, doc_id), FOREIGN KEY (doc_id) REFERENCES papers(doc_id))'
}

delete() {
    md5=$(md5cmd "$paper")
    sqlite3 papers.db "DELETE FROM tags WHERE doc_id = \"$md5\""
    sqlite3 papers.db "DELETE FROM papers WHERE doc_id = \"$md5\""
}

all_papers() {
    sqlite3 papers.db "SELECT path FROM papers"
}

add() {
    paper="$1"
    [ -f "$paper" ] || die "$paper does not exist"
    md5=$(md5cmd "$paper")
    sqlite3 papers.db "INSERT INTO papers (doc_id, path) VALUES(\"$md5\", \"$paper\")"
}

tag_add() {
    paper="$1"
    tag="$2"

    md5=$(md5cmd "$paper")

    sqlite3 papers.db "INSERT INTO tags (tag, doc_id) VALUES (\"$tag\", \"$md5\")"
}

tag_show() {
    paper="$1"
    md5=$(md5cmd "$paper")
    sqlite3 papers.db "SELECT tag FROM tags WHERE doc_id = \"$md5\""
}

tag_search() {
    arg=("$@")

    subselect=""
    if [ "$#" -gt "1" ]; then
	tag="${arg[1]}"
	subselect="SELECT doc_id FROM tags WHERE tag = \"$tag\""
    fi

    for ((i=2;i<=$1;i++)); do
	subselect=$subselect" INTERSECT SELECT doc_id FROM tags WHERE tag = \"${arg[i]}\""
    done

    select="SELECT path FROM papers WHERE doc_id IN ($subselect)"

    sqlite3 papers.db "$select"
}

tag_all() {
    sqlite3 papers.db "SELECT DISTINCT tag FROM tags"
}
