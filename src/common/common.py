from perfetto.trace_processor import TraceProcessor
import os
import sys
import re
#import pandas as pd
import csv
import mimetypes
#import filetype

#trace_dir = ""
#root_dir = ""
#out_dir = ""
#orig_outFile = ""
#orig_outTabText = ""
#orig_outHTML = ""
#final_outFile = ""
#final_outTabText = ""
#final_outHTML = ""
#target_sql = ""


def init_para(path, perf_type):
  global trace_dir
  trace_dir=path
  #print(f"trace_dir: {trace_dir}")

  global root_dir
  global out_dir
  global orig_outFile
  global orig_outTabText
  global orig_outHTML
  global final_outFile
  global final_outTabText
  global final_outHTML
  global target_sql
  global src_json
  try:
    files = os.path.isfile(trace_dir) or (os.path.isdir(trace_dir) and os.listdir(trace_dir)) 
  except FileNotFoundError:
    print(f'trace Directory {trace_dir} does not exist!')
    sys.exit()  # 终止程序
  except PermissionError:
    print(f'Permission denied for {trace_dir}!') 
    sys.exit()
  #pwd_dir=os.getcwd()
  script_path = os.path.abspath(__file__)
  script_dir = os.path.dirname(script_path)
  script_root_dir = os.path.abspath(os.path.join(script_dir, os.pardir, os.pardir))
  #print(f"pwd: {pwd_dir}")
  print(f"script_dir: {script_dir}")
  print(f"script_root_dir: {script_root_dir}")
  #assert False, "test..."
  #target_sql=script_root_dir + "\\sql\\" + sql_str
  # 要求 sql 目录里的格式为: `数字_ + 字符串 + '.sql'`, 数字和 bat 文件的选择菜单对应
  sql_dir=script_root_dir + "\\sql"
  template_sql=os.path.join(sql_dir, "query.sql")

  # 硬启
  #src_json=os.path.join(sql_dir, "1_hardOpen.json")
  # 热启
  #src_json=os.path.join(sql_dir, "2_warmOpen.json")
  # 不同 camera ID 切换
  #src_json=os.path.join(sql_dir, "3_diffCamSwitch.json")
  # 同 camera ID 切换
  #src_json=os.path.join(sql_dir, "4_sameCamSwitch.json")
  # shot2shot
  #src_json=os.path.join(sql_dir, "6_shot2shot.json")
  #for f in os.listdir(sql_dir) if os.path.isfile(os.path.join(sql_dir, f)):
  for f in os.listdir(sql_dir):
    if os.path.isfile(os.path.join(sql_dir, f)):
      if f.startswith(str(perf_type) + '_') and mimetypes.guess_type(f)[0].endswith("json"):
        print(f"{mimetypes.guess_type(f)[0]}, {f}")
        src_json = os.path.join(sql_dir, f)
        #assert False, "json path error"
        break
  file_dir=trace_dir
  if os.path.isfile(trace_dir):
    file_dir = os.path.dirname(trace_dir)
  #root_dir=trace_dir
  out_dir = os.path.join(file_dir, 'out')
  print(f"out_dir: {out_dir}")
  #assert False, "test..."
  if not os.path.exists(out_dir):
    os.mkdir(out_dir)
  final_sql=os.path.join(out_dir, "final.sql")
  orig_outFile=os.path.join(out_dir, "orig_out.txt")
  final_outFile=os.path.join(out_dir, "final_out_tab.txt")
  dir_file_list = [trace_dir, src_json, template_sql, final_sql, orig_outFile, final_outFile]
  return dir_file_list

def read_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        text = f.read()
    return text

def parse_all_trace(strs, orig_f, sql_f):
  """
  解析指定目录下的所有 trace 文件, 并保存原始结果到 out.csv 文件中, 方便查看和解析
  """
  # 硬/冷启动
  # sql_path = 'sql/camHardOpen.sql'
  # 热启动
  #sql_path = 'sql/camWarmOpen.sql'
  sql_path = sql_f
  text = read_file(sql_path)

  # 写文件头
  #outputFd = open('outData\\out.csv', 'w')
  outputFd = open(orig_f, 'w', encoding="utf-8")
  headerLine = "slice_name,start_time,end_time,dur_time\n"
  #headerLine = "slice_name\tstart_time\tend_time\tdur_time\n"
  outputFd.write(headerLine)

  #files = [os.path.join(strs, f) for f in os.liststr(strs) if os.path.isfile(os.path.join(strs, f))]
  if os.path.isdir(strs):
    print(f"parse files under {strs}")
    files = sort_trace(strs)
    if files:
      # 按重命名后的文件名排序
      files.sort(key=os.path.getmtime)
      for file in files:
        outputFd.write('\ntrace file: ' + os.path.basename(file) + '\n')
        try:
          tp = TraceProcessor(trace=file)
          #print(text)
          #qr_it = tp.query('SELECT ts, dur, name FROM slice')
          qr_it = tp.query(text)
          for row in qr_it:
            # 替换 slice_name 里的 `,` 方便用 csv 格式查看
            #row_name = row.slice_name.replace(',', ' ')
            row_name = row.slice_name
            writeLine = row_name + "\t" + str(row.start_time) + "\t" + str(row.end_time) + "\t" + str(row.dur_time) + "\n"
            #writeLine = row.slice_name + "\t" + str(row.start_time) + "\t" + str(row.end_time) + "\t" + str(row.dur_time) + "\n"
            #print(row.slice_name, row.start_time, row.end_time, row.dur_time)
            print(writeLine, end='')
            outputFd.write(writeLine)
        except Exception as e:
          print(f"文件 {file} 不是 trace 文件. 不解析: {e}")
    else:
      print("no trace found")
      exit()
  elif os.path.isfile(strs):
    file = strs
    print(f"parse single file: {file}")
    #assert False, "test...."
    outputFd.write('\ntrace file: ' + os.path.basename(file) + '\n')
    try:
      tp = TraceProcessor(trace=file)
    except Exception as e:
      print(f"文件 {file} 不是 trace 文件. 出错: {e}")
    qr_it = tp.query(text)
    for row in qr_it:
      row_name = row.slice_name
      writeLine = row_name + "\t" + str(row.start_time) + "\t" + str(row.end_time) + "\t" + str(row.dur_time) + "\n"
      print(writeLine, end='')
      outputFd.write(writeLine)
  else:
    print("no trace found")
    exit()

  outputFd.close()

"""
def convert_csv(in_file, out_file, tab_out):
  # 转成 tab text
  with open(in_file) as f:
    lines = f.readlines()

  with open(tab_out, 'w') as f:
    for line in lines:
      line = line.replace(',', '\t')
      f.write(line)
  
  # 转成 html
  with open(in_file) as f:
    csv_reader = csv.reader(f)
    
    html = '<div style="text-align: left;">' 
    html += '<table>'
    first = True
    for row in csv_reader:
      html += '<tr>'
      for d in row:
        # 第一列左对齐, 其他居中对齐
        if first:
          html += f'<td>{d}</td>'
          first = False
        else:
          html += f'<td style="text-align: center;">{d}</td>' 
          first = True
      html += '</tr>'
    html += '</table>' 
    html += '</div>'

  with open(out_file, 'w') as f:
    f.write(html)
"""

def sort_trace(dir):
  """
  根据文件创建 trace 文件的时间排序后进行重命名
  只对 perfetto trace 和 systrace 进行排序
  """
  trace_files = []
  sorted_trace_files = []
  print(f"dir: {dir}")
  files = [os.path.join(dir, f) for f in os.listdir(dir) if os.path.isfile(os.path.join(dir, f))]
  """
  for ff in files:
    print(f"file type: {mimetypes.guess_type(ff)[0]}")
    with open(ff, 'rb') as f:
      # 目前前 perfetto 抓的文件前 32 个字节还不是固定的, 不能用来匹配
      # ptrace => b'\nj2\xe0\x80\x80\x00\x10\x06
      # html trace => b'<!DOCTYPE html>\n
      header = f.read(32)
      print(f"{header}, {ff}")
      assert False, "header error"
      if header.startswith(b'\nj2\xe0\x80\x80\x00\x10\x06') or header.startswith(b'<!DOCTYPE html>\n'):
        #print(f"trace file: {ff}")
        trace_files.append(ff)
  """
  trace_files = files
  if trace_files:
    trace_files.sort(key=os.path.getmtime)
    for index, orig_full in enumerate(trace_files, 1):
      new_full=orig_full
      """
      # 重命名
      # 前面有序号  `0~999 + 下划线` 的都去掉, 重新根据命令排序
      new_full = os.path.join(dir, str(index) + "_" + re.sub(r'^\d{1,3}[_-]*', '', os.path.basename(orig_full)))
      #print(orig_full)
      #print(new_full)
      try:
        os.rename(orig_full, new_full)
      except FileExistsException as err:
        print(f'File {new_full} already exists!')
        exit()  # 退出程序
      except FileNotFoundError as err:
        print(f'File {orig_full} not found!')
        exit()   # 退出程序
      except PermissionError as err:
        print(f'Permission denied to rename {orig_full}!')
        exit()   # 退出程序
      except Exception as err:
        print(f'Unknown error occurred: {err}')
        exit()   # 退出程序
      else:
        print(f'File renamed from {orig_full} \n    to {new_full}') 
      """
      sorted_trace_files.append(new_full)
  return sorted_trace_files
  """
  排序 dir 目录下的 trace, 并按时间戳的顺序重命名,
  如果用标准的工具抓取就不用这么麻烦, 直接在文件名就可以排序.
  文件排序好后, 按照排序的文件再依次解析, 就不再需要对解析结果排序, 排序其实没那么重要
  """
  """
  with os.scandir(dir) as entries:
    dictFiles={}
    for entry in entries:
      if entry.is_file():
        #print(entry.name)
        base_name=entry.name
        trace_absolute_name=dir+"\\"+entry.name
        print(trace_absolute_name)
        tp = TraceProcessor(trace=trace_absolute_name)
        qr_it = tp.query("SELECT ts FROM sched ORDER BY ts LIMIT 1")
        # 迭代器这里需要一个异常捕获
        dictFiles[base_name]=next(qr_it).ts
    sorted_files = sorted(dictFiles, key=dictFiles.get)
    #print(type(sorted_files))
    #for i in sorted_files:
    for i, file in enumerate(sorted_files, 1):
      #ext = os.path.splitext(file)[1]
      new_name = str(i) + "_" + file
      print("file:" + file + ", new_name:" + new_name)
      os.rename(os.path.join(dir, file), os.path.join(dir, new_name))
  """

def gen_desc(sql_json, final_out):
  """
  从 json 文件中解析各阶段描述
  """
  #print(f"orig_json: {sql_json}, final file: {final_out}")
  with open(sql_json, 'r', encoding="utf-8") as fin, open(final_out, 'w', encoding="utf-8") as fout:
    inside_comment = False
    for line in fin:
      if '/*' in line:
        inside_comment = True

      if inside_comment:
        fout.write(line)

      if '*/' in line:
        fout.write('\n')
        inside_comment = False
        break

def cal_stage_consumption(lines, ends):
  marks_list = []
  diffs = []
  print(f"ends: {ends}")
  for line, end in zip(lines, ends):
    if end == True:
      marks_list.append(float(line.split("\t")[2]))
    elif end == False:
      marks_list.append(float(line.split("\t")[1]))
    else:
      omit_slice = line.split('\t')[0]
      print(f"{omit_slice} 不参与计算")

  print(f"mark time: {marks_list}, len:{len(marks_list)}")
  
  for i in range(len(marks_list)-1):
    diff = round(marks_list[i+1] - marks_list[i], 2)
    diffs.append(diff)
  total_diff = round(marks_list[-1] - marks_list[0], 2)
  diffs.append(total_diff)
  writeLine = '\t'.join([str(diff) for diff in diffs])
  print(f"{writeLine}")
  #assert False, "数据错误"
  print(writeLine)
  return writeLine
  
def is_increase(lines, ends):
  """
  找到的数据是否有是升序的.
  硬启动和热启动中都存在 activityResume, 会使得用用热启动配置解析硬启动trace时出现负值的错误.
  """
  marks_list = []
  diffs = []
  print(f"ends: {ends}")
  for line, end in zip(lines, ends):
    if end == True:
      marks_list.append(float(line.split("\t")[2]))
    elif end == False:
      marks_list.append(float(line.split("\t")[1]))
    else:
      omit_slice = line.split('\t')[0]
      print(f"{omit_slice} 不参与计算")
  # Check if the elements in marks_list are in increasing order
  for i in range(len(marks_list) - 1):
    if marks_list[i] > marks_list[i + 1]:
      print(f"出现一组非递增数据, 舍弃: {marks_list}, len:{len(marks_list)}")
      return False
  return True

def gen_sql(sql_f, final_sql, names_str, threads_str):
  # 清空 "WHERE (" 行下的所有内容
  with open(sql_f, encoding="utf-8") as f:
    lines = f.readlines()
  #final_line_str = ") ORDER BY slice.ts;"
  final_line_str = lines[-1]
  #start_index = None
  #for i, line in enumerate(lines):
  #  if line.startswith('WHERE'):
  #    start_index = i
  #    break
  #if start_index is not None:
  #  lines = lines[:start_index+1]
  
  # 从 json 文件解析出的 names_str 和 threads_str 生成最终的 SQL 文件
  with open(final_sql, 'w', encoding="utf-8") as f:
    #print(lines[0:-1])
    f.writelines(lines[0:-1])
    cnt = 0
    for nameL, thread_str in zip(names_str, threads_str):
      for name_str in nameL:
        #print(f"{name_str}")
        if thread_str:
          line = "(slice.name LIKE " + "'" + name_str +  "' AND (" + "thread_name LIKE '" + thread_str + "' OR " + "proc_name LIKE '" + thread_str + "'))\n"
          #line = "(slice.name LIKE " + "'" + name_str +  "' AND " + "thread_name LIKE '" + thread_str + "')\n"
        else:
          line = "slice.name LIKE " + "'" + name_str +  "'\n"
        if 0 != cnt:
          line = "OR " + line
        print(f"{line}", end='')
        cnt += 1
        f.write(line)
    f.write(final_line_str)