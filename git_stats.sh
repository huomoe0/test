#!/bin/bash

AUTHOR="$1"

if [ -z "$AUTHOR" ]; then
  echo "用法: $0 \"作者名称或邮箱片段\""
  echo "示例: $0 \"maddox.liu\""
  exit 1
fi

echo "🎯 作者过滤关键字: $AUTHOR"
echo

########## 总览统计 ##########
echo "================== 一、代码总览 =================="
git log --all --author="$AUTHOR" --pretty=tformat: --numstat |
  awk '{ add += $1; del += $2; net += $1 - $2 }
       END {
         printf "总添加行数: %d\n总删除行数: %d\n净增行数:   %d\n", add, del, net
       }'

echo
echo "================== 二、提交与文件统计 =================="
echo -n "总提交次数: "
git log --all --author="$AUTHOR" --pretty=format:"%H" | wc -l

echo -n "修改过的文件数: "
git log --all --author="$AUTHOR" --pretty=tformat: --name-only |
  grep -v '^$' | sort | uniq | wc -l

########## 时间维度 ##########
echo
echo "================== 三、按小时统计开发活跃度 =================="
git log --all --author="$AUTHOR" --pretty='%ad' --date=format:'%H' |
  sort | uniq -c |
  awk '{ printf "%02d:00-%02d:00 提交数: %d\n", $2, $2+1, $1 }'

echo
echo "================== 四、按星期统计开发活跃度 =================="
git log --all --author="$AUTHOR" --pretty='%ad' --date=format:'%A' |
  sort | uniq -c | sort -nr

echo
echo "================== 五、按月份统计提交趋势 =================="
git log --all --author="$AUTHOR" --date=format:'%Y-%m' --pretty='%ad' |
  sort | uniq -c

########## 每次提交 ##########
echo
echo "================== 六、每次提交变更详情 =================="
git log --all --author="$AUTHOR" --pretty="commit:%h %ad" --date=short --numstat |
  awk '
    /^commit:/ {
      if (commit != "")
        printf "%s %s 添加: %d 删除: %d 净增: %d\n", commit, date, add, del, add-del
      commit = $2; date = $3; add = 0; del = 0; next
    }
    NF==3 { add += $1; del += $2 }
    END {
      if (commit != "")
        printf "%s %s 添加: %d 删除: %d 净增: %d\n", commit, date, add, del, add-del
    }'

########## 每日提交曲线 ##########
echo
echo "================== 七、每天提交代码量 =================="
git log --all --author="$AUTHOR" --pretty="%ad" --date=short --numstat |
  awk '
    NF==1 { date = $1 }
    NF==3 { ins[date] += $1; del[date] += $2 }
    END {
      for (d in ins)
        printf "%s 添加: %d 删除: %d 净增: %d\n", d, ins[d], del[d], ins[d] - del[d]
    }' | sort

########## 热门文件 ##########
echo
echo "================== 八、最常修改的文件（次数前 20） =================="
git log --all --author="$AUTHOR" --pretty=tformat: --numstat |
  awk '{ cnt[$3]++ } END {
    for (f in cnt)
      if (f != "") printf "%-50s %d 次\n", f, cnt[f]
  }' | sort -k2 -n -r | head -20

echo
echo "================== 九、修改最多的文件（改动行数前 20） =================="
git log --all --author="$AUTHOR" --pretty=tformat: --numstat |
  awk '{ chg[$3] += $1 + $2 }
       END {
         for (f in chg)
           if (f != "") printf "%-50s %d 行\n", f, chg[f]
       }' | sort -k2 -n -r | head -20

########## 按文件类型 ##########
echo
echo "================== 🔟 按文件类型（后缀）统计 =================="
git log --all --author="$AUTHOR" --pretty=tformat: --numstat |
  awk '
    {
      split($3, arr, ".")
      ext = (length(arr) > 1) ? arr[length(arr)] : "无后缀"
      add[ext] += $1; del[ext] += $2
    }
    END {
      printf "%-12s %8s %8s %8s\n", "文件类型", "添加", "删除", "净增"
      for (e in add)
        printf "%-12s %8d %8d %8d\n", e, add[e], del[e], add[e]-del[e]
    }' | sort -k4 -n -r
