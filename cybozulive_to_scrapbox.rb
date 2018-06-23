# cybozulive_to_scrapbox

require "csv"
require "json"
require "date"

class String
  def append_date_link!
    sub!( %r!((\d+)/(\d+)/(\d+))(.*)$!) {
      r=$5
      a=$1
      y=$2
      m=("00"+$3).slice(-2,2)
      d=("00"+$4).slice(-2,2)
      a+r+" ["+y+"-"+m+"-"+d+"]"
    }
  end

  def replace_braces!
    gsub!(%r!\[!, "［")
    gsub!(%r!\]!, "］")
  end
end

# Events イベント
#  0         1         2        3         4            5         6     7       8
# "開始日付","開始時刻","終了日付","終了時刻","予定メニュー","タイトル","メモ","作成者","コメント"
def process_events(csvfile,cygroup,csv)
  pages=[]
  csv.each do |e|
    lines=[]
      i=5
      lines.push csv.headers[i]+" : "+e[i]
      i=7
      lines.push csv.headers[i]+" : ["+e[i]+"]"

    sdatetime=e[0]+" "+e[1]
    sdatetime.append_date_link!
    edatetime=e[2]+" "+e[3]
    edatetime.append_date_link!
      # i=0,1
      lines.push "開始日時 : "+sdatetime
      # i=2,3
      lines.push "終了日時 : "+edatetime

      i=4
      lines.push csv.headers[i]+" : "+e[i]

    [6,8].each do |i|
      lines.push csv.headers[i]
      e[i].each_line {|t| lines.push t.chomp }
      lines.push ""
    end

    lines.push "["+cygroup+"/"+csvfile+"]"
    # page title
    title=cygroup+":イベント:"+e[0]+":"+e[5]
    title.replace_braces!
    lines.unshift title
    page= { "title"=> title, "lines"=> lines }
    pages.push page
  end
  pages
end

# BB 掲示板
#  0     1          2      3        4          5       6          7
# "ID", "タイトル", "本文", "作成者", "作成日時", "更新者", "更新日時", "コメント"
def process_bbs(csvfile,cygroup,csv)
  pages=[]
  csv.each do |e|
    lines=[]
    #  0     1         3         4         5         6
    # "ID", "タイトル", "作成者", "作成日時", "更新者", "更新日時"
    [0,1,3,4,5,6].each do |i|
      case i
      when 4,6 # "作成日時", "更新日時"
        date_s=e[i].dup
        date_s.append_date_link!
        lines.push csv.headers[i]+" : "+date_s
      when 3,5 # "作成者", 更新者"
        lines.push csv.headers[i]+" : ["+e[i]+"]"
      else
        lines.push csv.headers[i]+" : "+e[i]
      end
    end
    # 2       7
    # "本文", "コメント"
    [2,7].each do |i|
      lines.push ""
      lines.push csv.headers[i]
      e[i].each_line do |text|
        text.chomp!
        text.append_date_link!
        lines.push text
      end
      lines.push ""
    end
    lines.push "["+cygroup+"/"+csvfile+"]"
    # page title
    title=cygroup+":掲示板:"+e[1]
    title.replace_braces!
    lines.unshift title
    page= { "title"=> title, "lines"=> lines }
    pages.push page
  end
  pages
end

def process_csv(from)
  from=File.expand_path(from)
  csvfile=File.basename(from)
  parent_d=File.dirname(from)
  cygroup=File.basename(parent_d)

  csv = CSV.read( from, headers: true )
  if csv.headers.nil?
    return []
  end

  case csv.headers[0]
  when "ID"       # 掲示板
    process_bbs(csvfile,cygroup,csv)
  when "開始日付"   # イベント
    process_events(csvfile,cygroup,csv)
  else
    []
  end
end

pages_all=[]
titles=[]

ARGV.each do |f|
  process_csv(f).each do |page|
    titles.push page["title"]
    pages_all.push page
  end
end

toc_title="Converted on "+DateTime.now.to_s
pages_all.each do |page|
  page["lines"].push "["+toc_title+"]"
end

lines=[ toc_title, "" ]
titles.each {|t| lines.push "["+t+"]"}
toc_page= { "title"=> toc_title, "lines"=> lines }
pages_all.push toc_page
puts JSON.generate( {"pages" => pages_all })
