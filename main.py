import pandas as pd
import os
import openai
import argparse
from dotenv import load_dotenv

load_dotenv()

client = openai.OpenAI(
    api_key=os.getenv("OPENAI_API_KEY"),
    base_url=os.getenv("OPENAI_BASE_URL")
)

system_prompt="""你现在是一名药师，请将输入的药物名称列表中的药物名称进行纠正，并输出纠正后的药物名称列表，顺序与输入列表药物保持对应"""

prompt="""# Identity
你现在是一名专业药师，请将输入的药物名称列表中的药物名称进行纠正，并输出纠正后的药物名称列表，顺序与输入列表药物保持对应

# Input Format
输入药物名称列表使用```符号包围

# Output Format
输出纠正后的药物名称列表，顺序与输入列表药物保持对应，不要输出任何多余内容

# Rules
* 判断依据仅考虑药物名称，不考虑药物剂型
* 如果药物名称有误，请进行纠正，并将纠正后的药物名称按序放入输入列表
* 如果药物名称正确，将原药物名称按序放入输入列表，保持原药物名称不变

# Examples
Q: [玻璃酸钠滴眼液（海露）]
A: [玻璃酸钠滴眼液（海露）]

# Input Data
输入药物名称列表：```{input_data}```
"""

def read_drugs_excel(xlsx_path):
    """
    读取 drugs.xlsx 文件并转换为list格式。

    Args:
        xlsx_path (str): xlsx文件路径

    Returns:
        list: list格式的数据，每行数据为一个list，如果读取失败则返回None。
    """
    try:
        # 检查文件是否存在
        if not os.path.exists('drugs.xlsx'):
            print("错误：drugs.xlsx 文件不存在")
            return None
        
        df = pd.read_excel(xlsx_path)
        
        # 将DataFrame转换为按列组织的list格式
        # 每列数据作为一个list，所有列组成一个大的list
        drugs_list = [df[col].tolist() for col in df.columns]
        
        return drugs_list
    
    except Exception as e:
        print(f"读取文件时发生错误：{str(e)}")
        return None

def split_list_into_chunks(lst, chunk_size):
    """
    将一个list按照指定大小分组成二维list。

    Args:
        lst (list): 要分组的list。
        chunk_size (int): 每组的元素数量。

    Returns:
        list: 二维list，每个子列表包含指定数量的元素。
    """
    return [lst[i:i + chunk_size] for i in range(0, len(lst), chunk_size)]


def correct_drug_name(drug_list,thinking):
    """
    使用OpenAI API纠正药物名称列表中的错误药物名称。

    Args:
        drug_list (list): 要纠正的药物名称列表，每个元素是一个包含药物名称的列表。
        thinking (bool): 是否开启思考

    Returns:
        list: 纠正后的药物名称列表，每个元素是纠正后的结果字符串。
    """
    corrected_results = []
    
    for drugs in drug_list:
        user_prompt = prompt.format(input_data=drugs)
        reasoning_content = ""  # 定义完整思考过程
        answer_content = ""     # 定义完整回复
        is_answering = False 
        try:
            completion = client.chat.completions.create(
                model="qwen3-235b-a22b",
                messages=[
                    {"role":"system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.1,
                stream=True,
                extra_body={"enable_thinking": thinking}
            )
            for chunk in completion:
                if not chunk.choices:
                    print("\nUsage:")
                    print(chunk.usage)
                else:
                    delta = chunk.choices[0].delta
                    # 打印思考过程
                    if hasattr(delta, 'reasoning_content') and delta.reasoning_content != None:
                        # print(delta.reasoning_content, end='', flush=True)
                        reasoning_content += delta.reasoning_content
                    else:
                        # 开始回复
                        if delta.content != "" and is_answering is False:
                            is_answering = True
                        # 打印回复过程
                        # print(delta.content, end='', flush=True)
                        answer_content += delta.content
            # 将字符串转换为列表
            corrected_names = answer_content.strip('```')
            print(corrected_names)
            if corrected_names.startswith('[') and corrected_names.endswith(']'):
                try:
                    # 尝试使用eval安全地解析列表字符串
                    import ast
                    corrected_names = ast.literal_eval(corrected_names)
                except (ValueError, SyntaxError):
                    # 如果解析失败，保持原始字符串
                    pass
            corrected_results.append(corrected_names)
            
        except Exception as e:
            print(f"处理药物列表时发生错误：{str(e)}")
            corrected_results.append(drugs)  # 如果出错，保留原始列表
    
    return corrected_results

def gen_xlsx(corrected_results, original_xlsx_path, output_xlsx_path):
    """
    基于原始Excel文件创建包含更正后药物名称和是否更正标记的新Excel文件。

    Args:
        corrected_results (list): 纠正后的药物名称列表。
        original_xlsx_path (str): 原始Excel文件的路径。
        output_xlsx_path (str): 输出Excel文件的路径。

    Returns:
        bool: 操作成功返回True，失败返回False。
    """
    try:
        # 检查原始文件是否存在
        if not os.path.exists(original_xlsx_path):
            print(f"错误：{original_xlsx_path} 文件不存在")
            return False
        
        # 读取原始Excel文件
        df = pd.read_excel(original_xlsx_path)
        
        # 添加"更正后"列
        df['更正后'] = corrected_results
        
        # 添加"是否更正"列，比较原始数据和更正后数据
        # 假设原始数据在第一列
        original_column = df.columns[0]
        df['是否更正'] = [0 if str(original).strip() == str(corrected).strip() else 1 
                        for original, corrected in zip(df[original_column], corrected_results)]
        
        # 保存为新文件
        df.to_excel(output_xlsx_path, index=False)
        return True
        
    except Exception as e:
        print(f"生成Excel文件时发生错误：{str(e)}")
        return False

def batch_correct(dir_path, thinking=False):
    """
    批量处理指定目录下的所有Excel文件，进行药物名称纠正。

    Args:
        dir_path (str): 包含Excel文件的目录路径。
        thinking (bool): 是否开启思考模式，默认为False。

    Returns:
        None
    """
    for file in os.listdir(dir_path):
        if file.endswith('.xlsx') and not file.startswith('.~') and not file.startswith('correct-'):
            original_file_path = os.path.join(dir_path, file)
            output_file_path = os.path.join(dir_path, "correct-"+file)
            
            drugs_list = read_drugs_excel(original_file_path)
            print(f"处理文件：{original_file_path}")
            grouped_drugs = split_list_into_chunks(drugs_list[0], 10)
            corrected_results = correct_drug_name(grouped_drugs, thinking)
            corrected_results = [item for sublist in corrected_results for item in sublist]            
            gen_xlsx(corrected_results, original_file_path, output_file_path)


if __name__ == "__main__":
    # 解析命令行参数
    parser = argparse.ArgumentParser(description="批量纠正药物名称")
    parser.add_argument("--thinking", action="store_true", help="开启思考模式")
    parser.add_argument("--dir", type=str, default="./", help="处理文件的目录路径，默认为当前目录")
    
    args = parser.parse_args()
    
    print(f"处理目录：{args.dir}")
    print(f"思考模式：{'开启' if args.thinking else '关闭'}")
    
    batch_correct(args.dir, args.thinking)
    
    

