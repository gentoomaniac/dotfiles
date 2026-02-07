if [[ -d /sys/module/zfs ]]; then
    ZFS_MIN_FREE_GB=3
    ZFS_SNAP_TTL_DAYS=90
    ZFS_MIN_KEEP_COUNT=3
    ZFS_GLOBAL_LOCK="/var/lock/portage_zfs_global.lock"
    ZFS_WORLD_LOCK="/var/lock/portage_zfs_world.lock"
    METADATA_FILE="/var/tmp/.emerge_cmd_metadata"
    ZFS_PROP="com.gentoo:command"

    pre_pkg_setup() {
        ZFS_PARENT_DATASET=$(df / | awk 'NR==2 {print $1}' | cut -d'/' -f1-2)
        ZFS_TARGET_DATASET="${ZFS_PARENT_DATASET:-rootpool/gentoo}"

        # 1. Stale Lock Recovery
        # If locks exist but only THIS emerge process is running, they are leftovers from a crash/Ctrl+C
        if [[ -f "$ZFS_GLOBAL_LOCK" ]]; then
            if [[ $(pgrep -xc emerge) -eq 1 ]]; then
                rm -f "$ZFS_GLOBAL_LOCK" "$ZFS_WORLD_LOCK"
            fi
        fi

        # 2. Context Detection: Read the metadata file created by the wrapper
        local EMERGE_CMD=""

        if [[ -f "$METADATA_FILE" ]]; then
            EMERGE_CMD=$(cat "$METADATA_FILE")
        else
            # If the file is missing (e.g. someone bypassed the wrapper),
            # try to get the current package atom as a fallback.
            EMERGE_CMD="emerge (atomic: ${CATEGORY}/${PN})"
        fi

        local IS_WORLD=false
        [[ "$EMERGE_CMD" == *"@world"* || "$EMERGE_CMD" == *"--depclean"* ]] && IS_WORLD=true

        # 3. Prevent Parallel Installs during World Updates
        if [[ -f "$ZFS_WORLD_LOCK" && "$IS_WORLD" == "false" ]]; then
            echo -e "\n\e[31m!!! ERROR: World Update/Depclean in progress.\e[0m"
            die "Parallel emerge blocked to maintain snapshot integrity."
        fi

        # 4. Space Guard
        local AVAIL_BYTES=$(zfs list -H -p -o avail rootpool)
        local MIN_BYTES=$(( ZFS_MIN_FREE_GB * 1024 * 1024 * 1024 ))

        if [[ "$AVAIL_BYTES" -lt "$MIN_BYTES" ]]; then
            eerror "ZFS: Pool space below ${ZFS_MIN_FREE_GB}GB safety limit."
            die "Insufficient disk space for safety snapshot."
        fi

        # 5. Snapshot Logic
        if [[ ! -f "$ZFS_GLOBAL_LOCK" ]]; then
            local SNAP_TIME=$(date +%Y%m%d-%H%M)
            local SNAP_NAME="pre-emerge-${SNAP_TIME}"

            # Clean up the command string for metadata
            local CMD_COMMENT=$(echo "$EMERGE_CMD" | xargs)

            einfo "ZFS: Creating recursive snapshot: ${ZFS_TARGET_DATASET}@${SNAP_NAME}"

            # Create recursive snapshot with the command stored in metadata
            if zfs snapshot -r -o "${ZFS_PROP}=${CMD_COMMENT}" "${ZFS_TARGET_DATASET}@${SNAP_NAME}"; then
                touch "$ZFS_GLOBAL_LOCK"
                [[ "$IS_WORLD" == "true" ]] && touch "$ZFS_WORLD_LOCK"

                # 6. Cleanup Logic
                _cleanup_emerge_snapshots "$ZFS_TARGET_DATASET"
            fi
        fi
    }

    _cleanup_emerge_snapshots() {
        local TARGET=$1
        # Check 'root' child to find snapshots reliably
        local CHECK_DS="${TARGET}/root"
        local SNAPS=($(zfs list -t snapshot -H -S creation -o name "$CHECK_DS" | grep "pre-emerge"))
        local COUNT=${#SNAPS[@]}

        if [[ $COUNT -gt $ZFS_MIN_KEEP_COUNT ]]; then
            for (( i=$ZFS_MIN_KEEP_COUNT; i<$COUNT; i++ )); do
                local SNAP=${SNAPS[$i]}
                local CREATION=$(zfs get -H -p -o value creation "$SNAP")
                local NOW=$(date +%s)
                local AGE=$(( (NOW - CREATION) / 86400 ))

                if [[ $AGE -gt $ZFS_SNAP_TTL_DAYS ]]; then
                    local SNAP_TAG=$(echo "$SNAP" | cut -d'@' -f2)
                    einfo "ZFS: Pruning snapshot (Age: ${AGE}d): ${TARGET}@${SNAP_TAG}"
                    zfs destroy -r "${TARGET}@${SNAP_TAG}"
                fi
            done
        fi
    }

    post_pkg_postinst() {
        # Final cleanup when the very last emerge finishes
        if [[ $(pgrep -xc emerge) -le 1 ]]; then
            rm -f "$ZFS_GLOBAL_LOCK" "$ZFS_WORLD_LOCK"
        fi
    }

fi

