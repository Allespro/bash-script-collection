#!/bin/bash
SRC_DIR="/home/dev/project"
DEST_SERVER="dev@10.0.12.19"
DEST_SSH_PORT="2222"
DEST_SSH_KEY="./ssh.key"
DEST_DIR="/home/dev/project"

if [ -n "$DEST_SSH_KEY" ] && [ -f "$DEST_SSH_KEY" ]; then
    SSH_KEY_PARAM="-i $DEST_SSH_KEY"
    SCP_KEY_PARAM="-i $DEST_SSH_KEY"
    echo "Using SSH key: $DEST_SSH_KEY"
else
    SSH_KEY_PARAM=""
    SCP_KEY_PARAM=""
    echo "Using password authentication"
fi

VOLUME_CONFIGS=$(docker compose config | grep -A5 "volumes:")

BIND_MOUNTS=$(grep -o "\./[^:]*\ | /[^:]*" docker-compose.yaml | grep -v "^#")

for path in $BIND_MOUNTS ; do
    if [ -d "$path" ] || [ -f "$path" ] ; then
        tar czf "${path//\//_}.tar.gz" "$path"
    fi
done

# NAMED_VOLUMES=$(docker volume ls -q --filter name=$(basename $(pwd)))
NAMED_VOLUMES=$(docker volume ls -q)

for volume in $NAMED_VOLUMES ; do
    docker run --rm -v $volume:/data -v $(pwd):/backup alpine \
    tar czf /backup/${volume}.tar.gz -C /data .
done

scp $SCP_KEY_PARAM -P $DEST_SSH_PORT docker-compose.yaml .env $DEST_SERVER:$DEST_DIR/

scp $SCP_KEY_PARAM -P $DEST_SSH_PORT *.tar.gz $DEST_SERVER:$DEST_DIR/

cat > restore.sh << 'EOF'

#!/bin/bash
for archive in ./*.tar.gz ; do
    if [[ $archive =~ ^\./\. ]] ; then
        dir_name="${archive#./}"
        dir_name="${dir_name%.tar.gz}"
        dir_name="${dir_name//_//}"
        mkdir -p "$(dirname "$dir_name")"
        tar xzf "$archive" -C "$(dirname "$dir_name")"
    fi
done

for archive in ./[a-z]*.tar.gz ; do
    if [ -f "$archive" ] ; then
        vol_name="${archive%.tar.gz}"
        vol_name="${vol_name#./}"
        docker volume create "$vol_name"
        docker run --rm -v "$vol_name":/data -v $(pwd):/backup alpine \
        tar xzf "/backup/${archive}" -C /data
    fi
done

# docker compose -f docker-compose.yaml up -d

EOF

scp $SCP_KEY_PARAM -P $DEST_SSH_PORT restore.sh $DEST_SERVER:$DEST_DIR/

ssh $SSH_KEY_PARAM -p $DEST_SSH_PORT $DEST_SERVER "cd $DEST_DIR && chmod +x restore.sh && ./restore.sh"
