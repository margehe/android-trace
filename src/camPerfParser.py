#from perfetto.batch_trace_processor.api import BatchTraceProcessor
#from perfetto.trace_processor import TraceProcessor
import os
import sys
import re
#import pandas as pd
import csv
import jstyleson as json
from common.common import *
#from common import common

def parser_json(file):
  # 用于计算 sql 的, 不能去掉为 None 的, 否则跟 thread name 不好对应上.
  global slices_name
  # 用于存储实际用于计算的 slice, 如 "first full buffer" 实际上不是用来计算阶段耗时的, 只是用来寻找其他 slice 的
  #global stage_slices
  global stages
  global owners
  global refer_points
  global thread_names
  global calc_ends
  global nearpre_cnts
  global multi_front_back_strs
  
  with open(file, encoding='utf-8') as f:
    data = json.load(f)
  slices_name = []
  #stage_slices = []
  stages = []
  owners = []
  refer_points = []
  thread_names = []
  calc_ends = []
  nearpre_cnts = []
  multi_front_back_strs = []
  for d in data:
    #if d['referPoint'] == 0:
    #  stage_slices.append(d['name'])
    slices_name.append(d['name'])
    #if d['stage']:
    #  stages.append(d['stage'])
    #  stage_slices.append(d['name'])
    stages.append(d['stage'])
      
    #if d['owner']:
    #  owners.append(d['owner'])
    owners.append(d['owner'])
    refer_points.append(d['referPoint'])
    thread_names.append(d['threadName'])
    calc_ends.append(d['calcEnd'])
    nearpre_cnts.append(d['nearPreviousCnt'])
    if d['multiFrontBack']:
      multi_front_back_strs += d['name']
    #print(d)
    #print(d['name'])
    #print(d['calcEnd'])
    #names += d['name']
  print(f"slices_name: {len(slices_name)} \n{slices_name}")
  print(f"nearpre_cnts: {len(nearpre_cnts)} \n{nearpre_cnts}")
  print(f"calc_ends: {len(calc_ends)} \n{calc_ends}")
  print(f"thread_names: {len(thread_names)} \n{thread_names}")
  #print(f"stage_slices: {len(stage_slices)} \n{stage_slices}")
  print(f"stages: {len(stages)} \n{stages}")
  print(f"owners: {len(owners)} \n{owners}")
  print(f"refer_points: {len(refer_points)} \n{refer_points}")
  # 1. 假如逆向查找的负值和正向查找的正值(不为 1111 和 2222 的正值)相邻, 就存在死循环, 
  # 2. 起始 slice 不应为正
  #json 文件定义不合理, 退出程序.
  if nearpre_cnts[0] > 0:
    print("slice 查找规则 err: 第一个 slice 不应从上一个开始查找.")
    exit()
  for i, cnt in enumerate(nearpre_cnts, 0):
    if i > 0:
      if nearpre_cnts[i] < 0:
        if (nearpre_cnts[i+1] > 0 and nearpre_cnts[i+1] != 1111 and nearpre_cnts[i+1] != 2222) or \
           (nearpre_cnts[i-1] > 0 and nearpre_cnts[i-1] != 1111 and nearpre_cnts[i-1] != 2222):
          print("slice 查找规则 err: 正向查找与逆序查找相邻, 会出现死循环, 不符合规则, \n请检查 json 文件的 nearPreviousCnt 属性的配置.")
          exit()

  #assert False, "参数错误"
  #print(f"multi_front_back_strs: {multi_front_back_strs}")

def get_regex_strs(strs, multi):
  """
  把配置文件中用于 SQL 查询的字符串的转化成正则字符串用于匹配目标行.
  """
  escape_dict = {
      '(': r'\(',
      ')': r'\)',
      '[': r'\[',
      ']': r'\]',
      '{': r'\{',
      '}': r'\}',
      #'<': r'\<',
      #'>': r'\>',
      #'_': r'\_',
      '*': r'\*',
      '+': r'\+', 
      '?': r'\?',
      '.': r'\.',
      '$': r'\$'
  }
  pattern = re.compile('|'.join(re.escape(key) for key in escape_dict.keys()))
  #print('|'.join(escape_dict.keys()))
  #assert(False)
  if multi:
    get_strs = []
    for i, str in enumerate(strs, 0):
      #print(str)
      #str = re.sub('|'.join(escape_dict.keys()), lambda m: escape_dict[m.group()], str)
      str = pattern.sub(lambda m: escape_dict[m.group()], str)
      if "%" in str:
        str = re.sub('%', '.*', str)
      #for line in lines:
      #  if re.search(str, line):
      #    slice_str = line.split("\t")[0]
      #    # 获取非重复的关键字
      #    if not bool(get_strs) or get_strs[-1] != slice_str:
      #      get_strs.append(slice_str)
      if not bool(get_strs) or get_strs[-1] != str:
        get_strs.append(str)
    return get_strs
  else:
    str = pattern.sub(lambda m: escape_dict[m.group()], strs)
    if "%" in str:
      str = re.sub('%', '.*', str)
    return str

def get_start_end_slice(file, names_str, refers_str):
  global multi_front_back_strs
  """
  根据起始特征点和终止特征点, 查找参考起始 slice 和 终止参考 slice
  最少有一个起始特征点和终止特征点
  """
  with open(file, encoding='utf-8') as f:
    lines = f.readlines()
  # 参考起始 slices 
  ref_start_slices = []
  # 参考结束 slices 
  ref_end_slices = []
  # 对参考起始 slice 重要的特征 slice
  particular_slices_for_ref_start = []
  # 对参考结束 slice 重要的特征 slice
  particular_slices_for_ref_end = []
  for nameL, refer_p in zip(names_str, refers_str):
    # 参考起始 slices 
    if 0 == refer_p:
      ref_start_slices = nameL
    if 1 == refer_p:
      particular_slices_for_ref_start += nameL
    if 2 == refer_p:
      particular_slices_for_ref_end += nameL
    # 参考终止 slices 
    if 3 == refer_p:
      ref_end_slices = nameL
  ref_start_slices = get_regex_strs(ref_start_slices, True)
  particular_slices_for_ref_start = get_regex_strs(particular_slices_for_ref_start, True)
  particular_slices_for_ref_end = get_regex_strs( particular_slices_for_ref_end, True)
  ref_end_slices = get_regex_strs(ref_end_slices, True)
  multi_front_back_strs=get_regex_strs(multi_front_back_strs, True)
  print(f"参考起始 slice: {ref_start_slices}")
  print(f"参考起始重要特征 slice: {particular_slices_for_ref_start}")
  print(f"参考结束重要特征 slice: {particular_slices_for_ref_end}")
  print(f"参考结束 slice: {ref_end_slices}")
  print(f"多次出现影响参考起始和参考终止点判断的 slice: {multi_front_back_strs}")
  
  #assert(False)

  # 字典保存行号和对应的内容
  global start_lines
  global end_lines
  start_lines = {}
  end_lines = {}
  start_line = ''
  end_line = ''
  start_line_num = 0
  end_line_num = 0
  # 判断是否找到起点和终点
  found_start_flag = False
  found_end_flag = False

  # 硬启动起始的 slice 和结束的 slice
  for index, line in enumerate(lines, 0):
    #if re.search('AppLaunch_dispatchPtr:Up', line):
    #print(line,end='')
    for s in ref_start_slices:
      #if line.startswith(s):
      if re.search(s, line):
        start_line = line
        #print(f"start slice: {start_line}")
        #assert(False)
        ref_start_cnt = 0
        for i in range(index+1, len(lines), 1): # 修改为遍历到文件结束
          #print("i:%d, index:%d, total line:%d" % (i, index, len(lines)))
          #print(lines[i], end='')
          # 类似这个 onDrawFrame 的在 json 中怎么表达呢? 这种在中间出现, 又不得不忽略的, 加个判定点可以忽略的标签
          #if lines[i].startswith('onDrawFrame'):
          for part_s in multi_front_back_strs:
            #if part_s in lines[i]:
            if re.search(part_s, lines[i]):
              #print(lines[i], end='')
              continue
          # 再次遇到伪起点, 提前退出循环, 可有可无
          if re.search(s, lines[i]):
            break
          # 起点的重要辅助判定, 类似 `connectDevice` 的最后一个找到起点的重要标志, 直接 break
          for part_start_s in particular_slices_for_ref_start[0: len(particular_slices_for_ref_start)-1]:
            #print(f"part_start_s: {part_start_s}")
            #if lines[i].startswith(part_start_s):
            #if re.search("\[PerformanceTrace\] onSwitchMode", lines[i]):
            if re.search(part_start_s, lines[i]):
              #print(lines[i], end='')
              ref_start_cnt += 1
              continue
            ##if lines[i].startswith('connectDevice'): # 一旦出现connectDevice,循环结束
            #if lines[i].startswith(particular_slices_for_ref_start[-1]): # 一旦出现connectDevice,循环结束
            if re.search(particular_slices_for_ref_start[-1], lines[i]):
              #print(f"particular end slices : {particular_slices_for_ref_start[-1]}")
              #print(lines[i], end='')
              break
            ## 只能放到最后, 如果起点关键字接下来几个 slice 不含有下面的几个关键字, 那么就不是真实的起点
            ##if not 'onDrawFrame' in lines[i] or not 'getCameraCharacteristics' in lines[i] or not 'activityStart' in lines[i]:
          #if 'onDrawFrame' in lines[i]:
          for part_s in multi_front_back_strs:
            #if part_s in lines[i]:
            if re.search(part_s, lines[i]):
              continue
          else:
            for part_start_s1 in particular_slices_for_ref_start[0: len(particular_slices_for_ref_start)-1]:
              if re.search(part_start_s1, lines[i]):
                break
        #print(f"ref_start_cnt: {ref_start_cnt}")
        # 起点字符串后至少含有两个关键字符串才能算是真正的起点
        
        # 此处要考虑拍照那种总共只有 4 个 slice 的情况, 那么参考起始和参考结束都最多只有一个.
        # 总共只有 3 个 slice 的怎么考虑
        # 那种总共只有起点和终点的怎么搞? 没有可以参考的, 只要成对出现就是一个完整的数据
        # 这个定位多少合适...
        #if ref_start_cnt >= 2:
        if ref_start_cnt >= (len(particular_slices_for_ref_start) - 1):
          found_start_flag = True
          #print(f"found_start_flag: {found_start_flag}")
          start_line_num = index
          
      #if 'first full buffer' in line:
      for s in ref_end_slices:
        #if line.startswith(s):
        if re.search(s, line):
        #  #print('*****************************')
        #  #print("start_line: %s" % start_line, end='')
        #  #print("end_line: %s" % end_line, end='')
        #  #print('*****************************')
          end_line = line
          if start_line and end_line:
            start_line_time = float(start_line.split("\t")[1])
            end_line_time = float(end_line.split("\t")[1])
            if found_start_flag and end_line_time > start_line_time:
              found_end_flag = True
              end_line_num = index
        else:
          # 如果没抓到起点, 又 open camera, 置找到起点 found_start_flag 为 False
          #if found_end_flag and (line.startswith('configureStreams') or line.startswith('finalizeOutputConfigurations')):
          if found_end_flag:
            for part_end_s in particular_slices_for_ref_end:
              #if lines[i].startswith(part_end_s):
              if re.search(part_end_s, lines[i]):
                found_start_flag = False
                found_end_flag = False
        #if found_end_flag and found_start_flag:
        #   print("found start and end")
        if found_end_flag and found_start_flag and start_line and end_line:
          #print('-----------------------------')
          #print("start: %s" % start_line, end='')
          #print("end: %s" % end_line)
          #print(f"start: {start_line_num} -- {start_line}", end='')
          #print(f"end: {end_line_num} -- {end_line}", end='')
          start_lines[start_line_num] = start_line
          end_lines[end_line_num] = end_line
          start_line_time = float(start_line.split("\t")[1])
          end_line_time = float(end_line.split("\t")[1])
          assert end_line_time > start_line_time, '结束点的时间不能比起始点小'
          found_start_flag = False
          start_line = ''
          found_end_flag = False
          end_line = ''
  print('================final start end========================')
  #for k1, v1, k2, v2 in zip(start_lines.keys(), start_lines.values(), end_lines.keys(), end_lines.values()):
  for (k1, v1), (k2, v2) in zip(start_lines.items(), end_lines.items()):
    print(f"start line: {k1}, {v1}", end='')
    #print(v1)
    print(f"end line: {k2}, {v2}", end='')


def get_target_marks(target_slice, nearpre_cnt, calc_end):
  marks = []
  """
  用于查找目标阶段的时间
  """
  # 先用 target_slice 和 nearpre_cnt 找到目标行
  # 再根据 calc_end 找到目标时间
  return marks


def extract_slice(lines, slices_name, nearpre_cnts, str_slices, str_slice_lineNum, num_idx, k1, k2, step):
  """
  顺序查找
  """
  # 顺序找距离最近和最远
  if nearpre_cnts[num_idx] in [1111, 2222]:
    for index in range(k1, k2, step):
      if str_slice_lineNum[num_idx] != 0:
        break
      for t_str in slices_name[num_idx]:
        if str_slice_lineNum[num_idx] == 0 and re.search(get_regex_strs(t_str, False), lines[index]):
          print(f"顺序最近最远 => num_idx:{num_idx} | {index}: {lines[index]}", end='')
          str_slices[num_idx] = lines[index]
          str_slice_lineNum[num_idx] = index
          break
  # 顺序计数查找
  else:
    match_cnt = 0
    for index in range(k1, k2, step):
      if match_cnt == nearpre_cnts[num_idx]:
        break
      for t_str in slices_name[num_idx]:
        if str_slice_lineNum[num_idx] == 0 and re.search(get_regex_strs(t_str, False), lines[index]):
          match_cnt += 1
          if match_cnt == nearpre_cnts[num_idx]:
            print(f"顺序计数 => num_idx:{num_idx} | {index}: {lines[index]}", end='')
            str_slices[num_idx] = lines[index]
            str_slice_lineNum[num_idx] = index
            break

def  reverse_extract_slice(lines, slices_name, nearpre_cnts, str_slices, str_slice_lineNum, num_idx, k1):
  """
  递归查找连续出现负数的情况
  """
  # 递归出口
  if nearpre_cnts[num_idx] < 0 and nearpre_cnts[num_idx+1] > 0:
    match_cnt = 0
    for index in range(str_slice_lineNum[num_idx+1], k1, -1):
      #if match_cnt == abs(nearpre_cnts[num_idx]):
      #  break
      for t_str in slices_name[num_idx]:
        if re.search(get_regex_strs(t_str, False), lines[index]):
          match_cnt += 1
          if match_cnt == abs(nearpre_cnts[num_idx]):
            print(f"逆序解析出 => num_idx:{num_idx} | {index}: {lines[index]}", end='')
            str_slices[num_idx] = lines[index]
            str_slice_lineNum[num_idx] = index
            return 

  # 连续出现负值的逆序,使用递归实现
  if nearpre_cnts[num_idx] < 0 and nearpre_cnts[num_idx+1] < 0:  
     reverse_extract_slice(lines, slices_name, nearpre_cnts, str_slices, str_slice_lineNum, num_idx + 1, k1)


def parse_data(file, final_out):
  """
  从总的 orig_out.txt 解析结果中拆解
  """
  # 存储获取的用于最后阶段耗时计算的时间
  global marks_t
  found_cnt = 0

  with open(file, encoding='utf-8') as f:
    lines = f.readlines()
  # 这里追加写入, 否则会清除 gen_desc 生成的各阶段说明
  outputFd = open(final_out, 'a', encoding="utf-8")

  head_stage= ""
  head_module = ""
  for hs in stages:
    if hs:
      head_stage += hs + '\t'
  head_stage += 'TOTAL' + '\n'
  for hm in owners:
    if hm:
      head_module += hm + '\t'
  head_module = re.sub('\t$', '', head_module) + '\n'
  print(f"head_stage:\n{head_stage}", end='')
  print(f"head_module:\n{head_module}", end='')
  outputFd.write(head_stage)
  outputFd.write(head_module)

  for (k1, v1), (k2, v2) in zip(start_lines.items(), end_lines.items()):
    # 存在一组数据里的目标行, 完全填满才算找到一组数据
    str_slices = ['']*len(calc_ends)
    # 存储对应的行号
    str_slice_lineNum = [0]*len(calc_ends)
    # 找到完全一组 flag
    found_whole = True
    found_match_file = ""
    # 存储计算时间原始值
    marks_t = [0.0]*len(calc_ends)
 
    str_slices[0] = v1
    str_slice_lineNum[0] = k1
    for index in range(k1, 0, -1):
       if "trace file:" in lines[index]:
        found_match_file = lines[index].split(":")[1]
        break
    print(f"whole data match file: {found_match_file}", end='')
    #print(f'str0:{str_slices[0]}', end='')
    marks_t[0] = float(str_slices[0].split("\t")[2])
    print(f"start time: {marks_t[0]}")
    
    for i, ref_p in enumerate(refer_points, 0):
      # 找到参考结束点 slice 所在的索引的位置, 减少重复工作
      if (ref_p == 3):
        str_slices[i] = v2
        str_slice_lineNum[i] = k2

    #assert False

    # 先找仅仅参考起点的
    for num_idx, line_num in enumerate(str_slice_lineNum, 0):
      if line_num == 0:
        # 离起始点最近的 slice
        if nearpre_cnts[num_idx] == 1111:
          extract_slice(lines, slices_name, nearpre_cnts, str_slices, str_slice_lineNum, num_idx, k1, k2+1, 1)
        # 离起始点最远的 slice
        elif nearpre_cnts[num_idx] == 2222:
          extract_slice(lines, slices_name, nearpre_cnts, str_slices, str_slice_lineNum, num_idx, k2+1 ,k1, -1)
    # 再根据已找到的查找需要参考的, 由于计数顺序查找和计数逆序查找互斥, 这里可以放在一起
    for num_idx, line_num in enumerate(str_slice_lineNum, 0):
      if line_num == 0:
        # 计数顺序查找
        if nearpre_cnts[num_idx] > 0:
          extract_slice(lines, slices_name, nearpre_cnts, str_slices, str_slice_lineNum, num_idx, str_slice_lineNum[num_idx-1], len(lines), 1)
          #assert False, "extract_slice err"
        # 计数逆序查找
        elif nearpre_cnts[num_idx] < 0:
          print(f"{slices_name[num_idx]}")
          reverse_extract_slice(lines, slices_name, nearpre_cnts, str_slices, str_slice_lineNum, num_idx, k1)
    
    # 检查有没有找到一组完全数据, 如果没有就 found_whole 置为 False
    p_cnt = 0
    for num, slice_str in zip(str_slice_lineNum, str_slices):
      p_cnt += 1
      if num != 0:
        print(f"{p_cnt} => {num}: {slice_str}", end='')
      else:
        found_whole = False
        print(f"{p_cnt} => {num}: {slice_str}\n", end='')
        print("目标起点和终点找到, 但没有找到一组完整的数据.")
        exit()
        #assert False, "not found a group data"
    # 如果不是递增的, 就表示这组数据有问题
    if not is_increase(str_slices, calc_ends):
      found_whole = False
    # 根据完全数据计算出阶段耗时并写入到文件
    if found_whole:
      found_cnt += 1
      outputFd.write(cal_stage_consumption(str_slices, calc_ends) + '\t\t\t\t' + found_match_file)
    print(f"\n ==== 找到 {found_cnt} 组完全数据 ==== \n")
  outputFd.close()

if __name__ == '__main__':
  trace_dir, src_json, template_sql, final_sql, orig_outFile, final_outFile = init_para(sys.argv[1], sys.argv[2])
  print(f"相关文件:\n{trace_dir}\n{src_json}\n{template_sql}\n{final_sql}\n{orig_outFile}\n{final_outFile}")
  parser_json(src_json)
  gen_sql(template_sql, final_sql, slices_name, thread_names)
  gen_desc(src_json, final_outFile)
  parse_all_trace(trace_dir, orig_outFile, final_sql)
  get_start_end_slice(orig_outFile, slices_name, refer_points)
  parse_data(orig_outFile, final_outFile)
