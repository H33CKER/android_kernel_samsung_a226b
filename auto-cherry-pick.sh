#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: $0 <start_commit> <end_commit>"
  exit 1
fi

START_COMMIT=$1
END_COMMIT=$2

LOG_FILE="cherry_pick_$(date +%Y%m%d_%H%M%S).log"
echo "Cherry-picking from $START_COMMIT to $END_COMMIT" | tee "$LOG_FILE"

# Disable editor for commit messages so cherry-pick --continue doesn't hang
export GIT_EDITOR=true

commits=$(git rev-list --reverse ${START_COMMIT}^..${END_COMMIT})

for commit in $commits; do
  echo "----------------------------------------" | tee -a "$LOG_FILE"
  echo "Cherry-picking $commit" | tee -a "$LOG_FILE"

  git cherry-pick $commit >>"$LOG_FILE" 2>&1
  status=$?

  if [ $status -ne 0 ]; then
    echo "Conflict or error during cherry-pick of $commit" | tee -a "$LOG_FILE"

    conflicted_files=$(git diff --name-only --diff-filter=U)
    if [ -n "$conflicted_files" ]; then
      echo "Auto-resolving conflicts by accepting incoming changes..." | tee -a "$LOG_FILE"
      echo "$conflicted_files" | xargs -I{} git checkout --theirs "{}"
      git add .

      output=$(git cherry-pick --continue 2>&1)
      status=$?
      echo "$output" >>"$LOG_FILE"

      if [ $status -ne 0 ]; then
        if echo "$output" | grep -q "The previous cherry-pick is now empty"; then
          echo "Empty commit detected, skipping commit $commit" | tee -a "$LOG_FILE"
          git cherry-pick --skip >>"$LOG_FILE" 2>&1
        else
          echo "Failed to continue cherry-pick. Exiting." | tee -a "$LOG_FILE"
          exit 1
        fi
      fi

    else
      echo "No conflicted files found but cherry-pick failed, attempting to skip commit $commit" | tee -a "$LOG_FILE"
      git cherry-pick --skip >>"$LOG_FILE" 2>&1
      status=$?
      if [ $status -ne 0 ]; then
        echo "Failed to skip commit. Exiting." | tee -a "$LOG_FILE"
        exit 1
      fi
    fi

  else
    echo "Successfully cherry-picked $commit" | tee -a "$LOG_FILE"
  fi
done

echo "All commits cherry-picked." | tee -a "$LOG_FILE"
