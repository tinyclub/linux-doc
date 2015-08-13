#!/bin/bash
#
# Build toc for markdown automatically
#
# $ build-toc.sh file.md
#

md=$1
[ ! -f "$md" ] && exit "ERROR: No such file" && exit 1

# Detect target language (only support en/ and zh-cn/ currently)
contents="Contents"
echo ${md} | grep -q "zh-cn"
if [ $? -eq 1 ]; then
	echo $PWD | grep -q "zh-cn"
	[ $? -eq 0 ] && contents="目录"
else
	contents="目录"
fi

# Drop old toc
start_line=`grep -n -m1 "^## ${contents}" $md | cut -d':' -f1`
end_line=`grep -n -m1 "^# " $md | cut -d':' -f1`
((end_line--))
sed -i -e "/<span /d" ${md}
sed -i -e "${start_line},${end_line}d" ${md}

# Generate a random toc id to avoid conflict
toc="toc_${RANDOM}_${RANDOM}_"

# Insert entry
ins_line=`grep -n -m1 "^#" $md | cut -d':' -f1`
sed -i -e "${ins_line}i\\\\" ${md}

((ins_line--))

# Generate table of content

echo > toc.tmp

grep "^###* " -ur $md | grep -v "## ${contents}" | grep -n "^#" | \
	sed -e "s/^\([0-9]*\):/\1a/g;" |\
	sed -e "s/\([0-9]*\)a\(#[^ ]*\) \(.*\)/\1a\2 [\3](#$toc\1)/g" |\
	sed -e "s/#####/+            -   /g;s/####/+        -   /g" |\
	sed -e "s/###/+    -   /g;s/##/-   /g" |\
	sed -e "s/'/-+-+-+-/g" | sed -e "s/: */: /g" |\
	xargs -i sed -i -e "{}" toc.tmp;

sed -i -e "s/-+-+-+-/'/g" toc.tmp
sed -i -e "${ins_line}i\\" toc.tmp
sed -i -e "s/^+   /   /g;" toc.tmp

# Insert the toc

sed -i -e "${ins_line}r toc.tmp" ${md}
sed -i -e "${ins_line}a## ${contents}\\" ${md}
sed -i -e "${ins_line}a\\\\" ${md}

# Replace the #* with h* + id info
t=0
for line in `grep -n "^##" $md | grep -v "## ${contents}" | cut -d':' -f1`
do
	((line+=t))
	((t++))
	sed -i -e "${line}i<span id=\"$toc$t\"></span>" $md
done

# Remove the tmp toc
rm toc.tmp
