jq '.name |= sub("^lieux?[ -]?dits? "; ""; "i")' | \
jq '.name |= sub("^hameau (des |de la |de |du |le |les |la |l'"'"'|d'"'"')?"; ""; "i")'  | \
jq '.name |= sub("^quartier (des |de la |de |du |le |les |la |l'"'"'|d'"'"')?"; ""; "i")' | \
jq '.name |= sub("^ferme (des |de la |de |du |le |les |la |l'"'"'|d'"'"')?"; ""; "i")' | \
jq '.name |= sub("^domaine (des |de la |de |du |le |les |la |l'"'"'|d'"'"')?"; ""; "i")' | \
jq '.name |= sub("^village (des |de la |de |du |le |les |la |l'"'"'|d'"'"')?"; ""; "i")' | \
jq '.name |= sub("^chemin rural(( n°?)? ?[0-9]+)?( dit)? "; "chemin "; "i")' | \
jq -c 'del(.housenumbers[]?.id)'
