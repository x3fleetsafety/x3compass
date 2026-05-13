#!/bin/bash
# Pull latest 100 skills from x3fleetsafety/skills for local development
# (Production loads skills at runtime via raw.githubusercontent.com)
set -e
rm -rf /tmp/x3-skills-sync
git clone --depth 1 https://github.com/x3fleetsafety/skills.git /tmp/x3-skills-sync
mkdir -p docs/skills-mirror
cp -r /tmp/x3-skills-sync/skills/* docs/skills-mirror/
echo "Skills synced: $(ls docs/skills-mirror/ | wc -l) skills available"
