#!/bin/bash
#
# Build toc for markdown automatically
#
# $ build-toc.sh file.md
#

md=$1
[ ! -f "$md" ] && exit "ERROR: No such file" && exit 1

# Generate a random toc id to avoid conflict
toc="toc_${RANDOM}_${RANDOM}_"

# Insert entry
ins_line=`grep -n -m1 "^#" $md | cut -d':' -f1`
sed -i -e "${ins_line}i\\\\" ${md}

((ins_line--))

# Generate table of content

echo > toc.tmp

grep "^###* " -ur $md | grep -v "## 目录" | grep -n "^#" | \
	sed -e "s/:/a/g;" |\
	sed -e "s/\([0-9]*\)a\(#[^ ]*\) \(.*\)/\1a\2 [\3](#$toc\1)/g" |\
	sed -e "s/#####/+            -   /g;s/####/+        -   /g" |\
	sed -e "s/###/+    -   /g;s/##/-   /g" |\
	xargs -i sed -i -e "{}" toc.tmp;

sed -i -e "${ins_line}i\\" toc.tmp
sed -i -e "s/^+   /   /g;" toc.tmp

# Insert the toc

sed -i -e "${ins_line}r toc.tmp" ${md}
sed -i -e "${ins_line}a## 目录\\" ${md}
sed -i -e "${ins_line}a\\\\" ${md}

# Replace the #* with h* + id info
t=0
for line in `grep -n "^##" $md | grep -v "## 目录" | cut -d':' -f1`
do
	((line+=t))
	((t++))
	sed -i -e "${line}i<span id=\"$toc$t\"></span>" $md
done

# Remove the tmp toc
rm toc.tmp
